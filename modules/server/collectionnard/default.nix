{ config, lib, pkgs, ... }:

let
  cfg  = config.shincraft.server.collectionnard;
  sops = config.shincraft.system.sops.enable;

  user        = "collectionnard";
  stateDir    = "/var/lib/collectionnard";
  uploadDir   = "${stateDir}/uploads";
  secretName  = "collectionnard/jwt-secret";
  jwtSecret   = if cfg.jwtSecretFile != null then cfg.jwtSecretFile
                else if sops then config.sops.secrets.${secretName}.path
                else "/run/secrets/${secretName}";

  # PostgreSQL local en auth peer (socket Unix) : aucun mot de passe
  baseEnv = {
    DATABASE_URL   = "postgres://${user}@/${user}?host=/run/postgresql";
    MIGRATIONS_DIR = "${cfg.package}/share/collectionnard/db/migrations";
  };

  serverEnv = baseEnv // {
    PORT           = toString cfg.port;
    UPLOAD_DIR     = uploadDir;
    TRUSTED_PROXY  = "true";   # X-Real-IP posé par le nginx local
    SEED_ON_EMPTY  = "false";
    LOG_FORMAT     = "text";
  } // cfg.settings;

  # Le secret est lu depuis le credential systemd (fichier sops ou fourni par le host)
  startScript = pkgs.writeShellScript "collectionnard-start" ''
    JWT_SECRET="$(< "$CREDENTIALS_DIRECTORY/jwt-secret")"
    export JWT_SECRET
    exec ${lib.getExe cfg.package} serve
  '';

  # CLI d'administration (create-user, install-domain…) : sous l'utilisateur du service
  cli = pkgs.writeShellScriptBin "colec-server" ''
    ${lib.toShellVars baseEnv}
    export ${lib.concatStringsSep " " (lib.attrNames baseEnv)}
    if [ "$(id -un)" = ${user} ]; then
      exec ${lib.getExe cfg.package} "$@"
    fi
    exec /run/wrappers/bin/sudo -u ${user} env DATABASE_URL="$DATABASE_URL" MIGRATIONS_DIR="$MIGRATIONS_DIR" ${lib.getExe cfg.package} "$@"
  '';

  # Repris de web/nginx-security-headers.conf (à inclure dans chaque bloc qui pose un add_header)
  securityHeaders = ''
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;
    add_header Permissions-Policy "camera=(self), microphone=(), geolocation=()" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'" always;
  '';

  api = "http://127.0.0.1:${toString cfg.port}";
  proxyHeaders = ''
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  '';
in
with lib;
with types;
{
  options.shincraft.server.collectionnard = {
    enable = mkEnableOption "Install Collectionnard (gestion de collections) with PostgreSQL";

    hostName = mkOption {
      type        = str;
      example     = "colec.mondomaine.fr";
      description = "Nom de domaine du vhost nginx local (servi en HTTP, HTTPS terminé par le reverse proxy)";
    };

    package = mkOption {
      type        = package;
      default     = (pkgs.callPackage ./package.nix {}).server;
      description = "Paquet du serveur (binaire colec-server et migrations SQL)";
    };

    webPackage = mkOption {
      type        = package;
      default     = (pkgs.callPackage ./package.nix {}).web;
      description = "Paquet du front (fichiers statiques de la SPA)";
    };

    port = mkOption {
      type        = ints.u16;
      default     = 8085;
      description = "Port local de l'API (jamais ouvert dans le pare-feu, joint par le nginx local)";
    };

    openFirewall = mkOption {
      type        = bool;
      default     = false;
      description = "Ouvrir le port 80 (accès depuis le reverse proxy)";
    };

    trustedProxies = mkOption {
      type        = listOf str;
      default     = [];
      example     = [ "192.168.1.10" ];
      description = "Reverse proxies dont l'en-tête X-Real-IP est cru (IP réelle des clients pour la limite de connexions)";
    };

    jwtSecretFile = mkOption {
      type        = nullOr str;
      default     = null;
      example     = "/run/secrets/collectionnard-jwt";
      description = ''
        Fichier contenant la clé de signature des JWT (32 caractères minimum).
        Par défaut (`null`) : secret sops `${secretName}`.
      '';
    };

    settings = mkOption {
      type        = attrsOf str;
      default     = {};
      example     = { MEMBER_INVITES = "true"; EXTERNAL_USER_AGENT = "Collectionnard/1.0 (+https://colec.mondomaine.fr)"; };
      description = "Variables d'environnement supplémentaires du serveur (voir le README de Collectionnard)";
    };
  };

  config = mkIf cfg.enable {

    users.users.${user} = {
      isSystemUser = true;
      group        = user;
      home         = stateDir;
    };
    users.groups.${user} = {};

    environment.systemPackages = [ cli ];

    services.postgresql = {
      enable          = true;
      ensureDatabases = [ user ];
      # Propriétaire de sa base : les migrations créent les extensions pgcrypto et unaccent
      ensureUsers     = [{ name = user; ensureDBOwnership = true; }];
    };

    systemd.services.collectionnard = {
      description = "Collectionnard (API)";
      wantedBy    = [ "multi-user.target" ];
      requires    = [ "postgresql.target" ];
      after       = [ "postgresql.target" "network-online.target" ];
      wants       = [ "network-online.target" ];
      environment = serverEnv;

      serviceConfig = {
        User             = user;
        Group            = user;
        StateDirectory   = [ "collectionnard" "collectionnard/uploads" ];
        StateDirectoryMode = "0750";
        WorkingDirectory = stateDir;
        LoadCredential   = [ "jwt-secret:${jwtSecret}" ];
        # Migrations en attente appliquées à chaque démarrage (jamais de jeu de démonstration)
        ExecStartPre     = "${getExe cfg.package} migrate";
        ExecStart        = startScript;
        Restart          = "on-failure";
        RestartSec       = "5s";

        # Durcissement : seul le dossier d'état est inscriptible ; réseau sortant conservé
        # (Wikidata, BnF, MusicBrainz, TVmaze)
        UMask                   = "0027";
        NoNewPrivileges         = true;
        CapabilityBoundingSet   = "";
        AmbientCapabilities     = "";
        ProtectSystem           = "strict";
        ProtectHome             = true;
        PrivateTmp              = true;
        PrivateDevices          = true;
        DevicePolicy            = "closed";
        ProtectProc             = "invisible";
        ProcSubset              = "pid";
        ProtectHostname         = true;
        ProtectClock            = true;
        ProtectKernelTunables   = true;
        ProtectKernelModules    = true;
        ProtectKernelLogs       = true;
        ProtectControlGroups    = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces      = true;
        RestrictRealtime        = true;
        RestrictSUIDSGID        = true;
        LockPersonality         = true;
        MemoryDenyWriteExecute  = true;
        RemoveIPC               = true;
        SystemCallArchitectures = "native";
        SystemCallFilter        = [ "@system-service" "~@privileged" ];
        SystemCallErrorNumber   = "EPERM";
      };
    };

    # Équivalent de web/nginx.conf : SPA statique + proxy de l'API
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.hostName} = {
        root        = cfg.webPackage;
        extraConfig = ''
          client_max_body_size 10m;
          ${concatMapStrings (ip: "set_real_ip_from ${ip};\n") cfg.trustedProxies}
          real_ip_header X-Real-IP;
          gzip on;
          gzip_types text/plain text/css application/json application/javascript image/svg+xml application/wasm;
          ${securityHeaders}
        '';

        locations = {
          # Assets Vite (noms hachés) : cache long
          "/assets/".extraConfig = ''
            ${securityHeaders}
            add_header Cache-Control "public, max-age=31536000, immutable" always;
            try_files $uri =404;
          '';
          # Application installable : service worker et manifeste relus à chaque visite
          "~ ^/(sw\\.js|workbox-[^/]+\\.js|manifest\\.webmanifest)$".extraConfig = ''
            ${securityHeaders}
            add_header Cache-Control "no-cache" always;
            types {
              application/javascript js;
              application/manifest+json webmanifest;
            }
            try_files $uri =404;
          '';
          "/".tryFiles = "$uri $uri/ /index.html";

          # Envoi d'une image (sans ce bloc exact, le préfixe ci-dessous répondrait par une 301)
          "= /api/v1/uploads".extraConfig = ''
            proxy_pass ${api};
            ${proxyHeaders}
          '';
          # Images uploadées (noms UUID immuables) : cache long
          "/api/v1/uploads/".extraConfig = ''
            ${securityHeaders}
            add_header Cache-Control "public, max-age=31536000, immutable" always;
            proxy_pass ${api};
            ${proxyHeaders}
          '';
          # Import du catalogue : corps jusqu'à MAX_IMPORT_SIZE (20 Mio par défaut)
          "= /api/v1/import".extraConfig = ''
            client_max_body_size 20m;
            proxy_read_timeout 120s;
            proxy_pass ${api};
            ${proxyHeaders}
          '';
          # Sources externes : un aperçu enchaîne les appels (le serveur les borne à 2 min)
          "/api/v1/external/".extraConfig = ''
            proxy_read_timeout 150s;
            proxy_pass ${api};
            ${proxyHeaders}
          '';
          "/api/".extraConfig = ''
            proxy_pass ${api};
            ${proxyHeaders}
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 80 ];

    sops.secrets = mkIf (sops && cfg.jwtSecretFile == null) {
      ${secretName} = { restartUnits = [ "collectionnard.service" ]; };
    };

    # Sauvegarde (si shincraft.system.backup est activé) : base + images uploadées
    shincraft.system.backup.jobs.collectionnard = {
      postgresDatabases = [ user ];
      paths             = [ uploadDir ];
    };

    assertions = [{
      assertion = cfg.jwtSecretFile == null -> sops;
      message   = "shincraft.server.collectionnard : fournir jwtSecretFile ou activer shincraft.system.sops.";
    }];
  };
}
