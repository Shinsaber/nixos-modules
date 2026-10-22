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
      enable = mkEnableOption "Install nginx in the systeme";
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
  ];
}
