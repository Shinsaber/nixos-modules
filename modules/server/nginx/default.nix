{ config, lib, pkgs, ... }:
with lib;
with types;
let 
  cfg = config.shincraft.server;
  subDomainModule = { name, config, ... }:
  {
    options = {
      host = mkOption {
        default = "www";
        type    = str;
      };
      port = mkOption {
        default = 80;
        type    = ints.u16;
      };
      protocol = mkOption {
        default     = "http";
        type        = enum [ "http" "https" ];
        description = "Protocole vers le backend (`https` pour Kanidm, certificat non vérifié)";
      };
      maxBodySize = mkOption {
        default     = null;
        type        = nullOr str;
        example     = "16G";
        description = "Taille maximale d'une requête (`client_max_body_size`, 1m par défaut dans nginx)";
      };
      allowFrom = mkOption {
        default     = [];
        type        = listOf str;
        example     = [ "10.8.0.0/24" "192.168.1.0/24" ];
        description = ''
          Adresses ou réseaux autorisés (ex. le VPN) ; les autres reçoivent une 403.
          Liste vide : accès ouvert. Le challenge ACME reste accessible pour le renouvellement.
        '';
      };
    };
  };
in
with lib;
with types;
{
  options.shincraft.server = {
    nginx =  {
      enable = mkEnableOption "Install nginx in the system";
      mail = mkOption {
        default     = null;
        type        = nullOr str;
        example     = "user@domain.tld";
        description = "Email du compte ACME (Let's Encrypt)";
      };
      domain = mkOption {
        default     = {};
        type        = attrsOf ( attrsOf ( submodule subDomainModule ) );
        example     = { "domain.tld"."www" = { host = "127.0.0.1"; port = 8080; }; };
        description = "Reverse proxy par domaine puis sous-domaine";
      };
      jsonLog = mkOption {
        default     = true;
        type        = bool;
        description = ''
          Écrire aussi le journal d'accès en JSON (`/var/log/nginx/access.json.log`, une requête par ligne)
          pour l'analyse avec `jq` : vhost, backend, statut du backend, durée…
        '';
      };
      fail2ban = {
        enable = mkEnableOption "Bannir (fail2ban) les clients qui scannent nginx ; active aussi la prison sshd";
        ignoreIP = mkOption {
          default     = [];
          type        = listOf str;
          example     = [ "192.168.1.0/24" "10.8.0.0/24" ];
          description = "Adresses ou réseaux jamais bannis (réseau local, VPN), en plus de localhost";
        };
        maxRetry = mkOption {
          default     = 20;
          type        = ints.positive;
          description = ''
            Nombre de requêtes en erreur (400, 403, 404, 405, 444) tolérées par client
            en 10 minutes avant bannissement. Les robots qui testent des chemins
            (`/env.js`, `/docs/swagger.json`…) en produisent des centaines.
          '';
        };
        ignorePaths = mkOption {
          default     = [ "/remote.php/dav/" "/remote.php/webdav/" ];
          type        = listOf str;
          example     = [ "/remote.php/dav/" "/api/" ];
          description = ''
            Préfixes de chemins ignorés par les prisons `nginx-scan` et `nginx-sensitive`.
            Par défaut le WebDAV de Nextcloud : les clients de synchronisation font un `HEAD`
            (404) avant chaque envoi de fichier, et les fichiers synchronisés peuvent s'appeler
            `.env` ou `.git/…`.
          '';
        };
        bantime = mkOption {
          default     = "1h";
          type        = str;
          example     = "1d";
          description = "Durée du premier bannissement ; elle double à chaque récidive (max 1 semaine)";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.nginx.enable {
      security.acme.acceptTerms = true;
      security.acme.defaults.email = cfg.nginx.mail;
      networking.firewall = {
        allowedTCPPorts = [
          80
          443
        ];
      };
      services.nginx = {
        enable = true;

        # Use recommended settings
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        # Only allow PFS-enabled ciphers with AES256
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
        
        # Format « combined » suivi du vhost, du statut du backend et de la durée : les filtres
        # fail2ban (ancrés en début de ligne) restent compatibles.
        commonHttpConfig = ''
          log_format shincraft '$remote_addr - $remote_user [$time_local] "$request" '
                               '$status $body_bytes_sent "$http_referer" "$http_user_agent" '
                               '"$host" $upstream_status $request_time';
          access_log /var/log/nginx/access.log shincraft;
        '' + optionalString cfg.nginx.jsonLog ''
          log_format shincraft_json escape=json '{"time":"$time_iso8601","remote_addr":"$remote_addr",'
            '"remote_user":"$remote_user","host":"$host","method":"$request_method","uri":"$request_uri",'
            '"protocol":"$server_protocol","status":$status,"body_bytes_sent":$body_bytes_sent,'
            '"request_time":$request_time,"upstream_addr":"$upstream_addr","upstream_status":"$upstream_status",'
            '"upstream_response_time":"$upstream_response_time","referer":"$http_referer",'
            '"user_agent":"$http_user_agent","request_id":"$request_id"}';
          access_log /var/log/nginx/access.json.log shincraft_json;
        '';

        appendHttpConfig = ''
          # Minimize information leaked to other domains
          add_header 'Referrer-Policy' 'origin-when-cross-origin';

          # Disable embedding as a frame
          #add_header X-Frame-Options DENY;

          # Prevent injection of code in other mime types (XSS Attacks)
          add_header X-Content-Type-Options nosniff;
        '';

        virtualHosts = mkMerge [
          (listToAttrs ( flatten (
            flip mapAttrsToList cfg.nginx.domain ( domain: subDomainConfig: 
              flip mapAttrsToList subDomainConfig ( subdomain: config: 
                { 
                  name = "${subdomain}.${domain}";
                  value = {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" = {
                      proxyPass = "${config.protocol}://${config.host}:${toString config.port}";
                      proxyWebsockets = true; # needed if you need to use WebSocket
                      # Filtrage sur la location et non sur le server : la location ACME
                      # (/.well-known/acme-challenge) doit rester joignable par Let's Encrypt.
                      extraConfig = concatStringsSep "\n" (
                        optional (config.maxBodySize != null) "client_max_body_size ${config.maxBodySize};"
                        ++ map (net: "allow ${net};") config.allowFrom
                        ++ optional (config.allowFrom != []) "deny all;"
                      );
                    };
                  };
                }
              )
            )
          )))
        ];
      };
    })

    (mkIf (cfg.nginx.enable && cfg.nginx.fail2ban.enable) {
      services.fail2ban = {
        enable   = true;
        ignoreIP = cfg.nginx.fail2ban.ignoreIP;
        bantime  = cfg.nginx.fail2ban.bantime;
        # Récidive : la durée de bannissement double à chaque nouveau ban, jusqu'à une semaine
        bantime-increment = {
          enable  = true;
          maxtime = "365d";
        };
        jails =
          let
            # Le journal d'accès est un fichier (le backend systemd par défaut ne lit que le journal) ;
            # les erreurs nginx (deny, limit_req…) sont dans le journal : backend systemd hérité de DEFAULT.
            accessLog = {
              backend = "auto";
              logpath = "/var/log/nginx/access.log";
            };
            ignorePaths = optionalAttrs (cfg.nginx.fail2ban.ignorePaths != []) {
              ignoreregex = ''^<HOST> - \S+ \[\] "\S+ (?:${concatMapStringsSep "|" escapeRegex cfg.nginx.fail2ban.ignorePaths})'';
            };
            # Fichiers que seul un scanner demande (secrets, dépôts, sauvegardes, WordPress…),
            # cherchés dans le chemin (pas dans la query string)
            sensitivePaths = concatStringsSep "|" [
              ''/\.(?:env|git|svn|hg|aws|ssh|docker|htaccess|htpasswd|DS_Store)\b''
              ''\.env\b''
              ''\.(?:bak|old|orig|save|swp|sql)\b''
              ''wp-(?:admin|config|content|includes|login)''
              ''xmlrpc\.php''
              ''phpinfo''
              ''/(?:secrets|credentials)\.(?:json|ya?ml)''
              ''laravel\.log''
              ''web\.config''
              ''(?<= )/vendor/''
              ''/server-(?:info|status)\b''
              ''/cgi-bin/''
              ''/actuator\b''
            ];
          in {
            # Scanners : trop de réponses 4xx (chemins inexistants, interdits, méthode refusée…)
            nginx-scan = {
              settings = accessLog // {
                findtime = "10m";
                maxretry = cfg.nginx.fail2ban.maxRetry;
              };
              filter.Definition = {
                failregex   = ''^<HOST> - \S+ \[\] "[^"]*" (?:400|403|404|405|444)'';
                datepattern = ''^[^\[]*\[({DATE})'';
              } // ignorePaths;
            };
            # Chemins sensibles : ban dès la 3e tentative, quel que soit le code de réponse
            # (un backend qui redirige, 30x, ou répond 200 ne protège pas le scanner)
            nginx-sensitive = {
              settings = accessLog // {
                findtime = "1h";
                maxretry = 3;
              };
              filter.Definition = {
                failregex   = ''^<HOST> - \S+ \[\] "[A-Z]+ [^" ?]*(?:${sensitivePaths})'';
                datepattern = ''^[^\[]*\[({DATE})'';
              } // ignorePaths;
            };
            # Chemins typiques des robots (phpmyadmin, wp-login.php, cgi-bin…) : ban dès la 2e tentative
            nginx-botsearch.settings = accessLog // { maxretry = 2; };
            # Requêtes malformées (400)
            nginx-bad-request.settings = accessLog // { maxretry = 5; };
            # 403 « access forbidden by rule » : clients hors `allowFrom` qui insistent
            nginx-forbidden.settings = { maxretry = 5; };
            # Dépassement de `limit_req` si un vhost en définit
            nginx-limit-req.settings = {};
          };
      };
    })
  ];
}
