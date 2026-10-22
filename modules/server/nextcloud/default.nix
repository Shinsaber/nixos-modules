{ config, lib, pkgs, ... }:

let
  cfg  = config.shincraft.server.nextcloud;
  sops = config.shincraft.system.sops.enable;

  # Fichier fourni par le host, sinon secret sops du même nom
  secretPath = file: name: if file != null then file
    else if sops then config.sops.secrets.${name}.path
    else "/run/secrets/${name}";

  s3SecretName   = "nextcloud/s3-secret";
  s3SecretFile   = secretPath cfg.s3.secretFile s3SecretName;
  oidcSecretName = "oidc/${cfg.oidc.clientId}";

  oidcSecretFile = secretPath cfg.oidc.clientSecretFile oidcSecretName;
in
with lib;
with types;
{
  options.shincraft.server.nextcloud = {
    enable = mkEnableOption "Install Nextcloud in the system";

    hostName = mkOption {
      type        = str;
      example     = "cloud.example.com";
      description = "Nom de domaine pour accéder à Nextcloud";
    };

    package = mkOption {
      type        = package;
      default     = pkgs.nextcloud33;
      description = "Paquet Nextcloud à utiliser";
    };

    https = mkOption {
      type        = bool;
      default     = true;
      description = "Activer HTTPS (nécessite un reverse proxy ou ACME)";
    };

    admin = {
      user = mkOption {
        type        = nullOr str;
        default     = null;
        example     = "admin";
        description = ''
          Compte administrateur créé à l'installation, avec `passwordFile`.
          Par défaut (`null`), aucun admin n'est créé : le créer ensuite en CLI avec
          `nextcloud-occ user:add --group admin <nom>`.
        '';
      };

      passwordFile = mkOption {
        type        = nullOr str;
        default     = null;
        example     = "/run/secrets/nextcloud-admin-password";
        description = "Chemin vers le fichier contenant le mot de passe admin (lu uniquement à l'installation)";
      };
    };

    dataDir = mkOption {
      type        = str;
      default     = "/var/lib/nextcloud";
      description = "Répertoire de stockage des données Nextcloud";
    };

    maxUploadSize = mkOption {
      type        = str;
      default     = "16G";
      description = "Taille maximale des fichiers uploadés";
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
      description = "Adresses des reverse proxies de confiance (`trusted_proxies`)";
    };

    apps = mkOption {
      type        = listOf str;
      default     = [];
      example     = [ "calendar" "contacts" "memories" "maps" "previewgenerator" ];
      description = ''
        Applications packagées dans nixpkgs (`<package>.packages.apps`), installées et activées
        par Nix. L'App Store est désactivé : toutes les apps passent par Nix.
      '';
    };

    extraApps = mkOption {
      type        = attrsOf package;
      default     = {};
      description = "Applications supplémentaires non packagées dans nixpkgs";
      example     = literalExpression ''
        {
          camerarawpreviews = pkgs.fetchNextcloudApp {
            url     = "https://github.com/ariselseng/camerarawpreviews/releases/download/v0.8.8/camerarawpreviews_nextcloud.tar.gz";
            hash    = "sha256-…";
            license = "agpl3Plus";
          };
        }
      '';
    };

    s3 = {
      enable = mkEnableOption "Stockage principal sur un bucket S3 (à choisir dès l'installation)";

      bucket = mkOption {
        type        = str;
        example     = "nextcloud";
        description = "Nom du bucket";
      };

      hostname = mkOption {
        type        = str;
        example     = "s3.gra.io.cloud.ovh.net";
        description = "Point d'accès S3";
      };

      region = mkOption {
        type        = str;
        example     = "gra";
        description = "Région du bucket";
      };

      key = mkOption {
        type        = str;
        description = "Identifiant de la clé d'accès (access key ID)";
      };

      secretFile = mkOption {
        type        = nullOr str;
        default     = null;
        example     = "/var/lib/secrets/nextcloud-s3-secret";
        description = ''
          Chemin vers le fichier contenant la clé secrète (lu par systemd, peut rester en root 0600).
          Par défaut (`null`) : secret sops `nextcloud/s3-secret` (nécessite `shincraft.system.sops`).
        '';
      };

      usePathStyle = mkOption {
        type        = bool;
        default     = false;
        description = "Adresser le bucket dans le chemin plutôt qu'en sous-domaine";
      };
    };

    oidc = {
      enable = mkEnableOption "Connexion SSO OpenID Connect (app user_oidc), par exemple avec Kanidm";

      name = mkOption {
        type        = str;
        default     = "Kanidm";
        description = "Nom du fournisseur, affiché sur le bouton de connexion";
      };

      clientId = mkOption {
        type        = str;
        default     = "nextcloud";
        description = "Identifiant du client OIDC";
      };

      discoveryUri = mkOption {
        type        = str;
        example     = "https://idm.example.com/oauth2/openid/nextcloud/.well-known/openid-configuration";
        description = "URL de découverte OpenID du fournisseur";
      };

      clientSecretFile = mkOption {
        type        = nullOr str;
        default     = null;
        description = ''
          Fichier contenant le secret du client, lisible par l'utilisateur nextcloud.
          Par défaut (`null`) : secret sops `oidc/<clientId>` (même valeur que côté fournisseur).
        '';
      };

      mappingUid = mkOption {
        type        = str;
        default     = "preferred_username";
        description = "Claim utilisé comme identifiant de l'utilisateur Nextcloud";
      };
    };

    onlyoffice = {
      enable = mkEnableOption "Édition de documents avec ONLYOFFICE (app onlyoffice, secret sops `onlyoffice/jwt-secret`)";

      documentServerUrl = mkOption {
        type        = str;
        example     = "https://office.example.com/";
        description = "URL publique du Document Server (`shincraft.server.onlyoffice`)";
      };
    };

    extraSettings = mkOption {
      type        = attrsOf anything;
      default     = {};
      description = "Paramètres supplémentaires pour la configuration Nextcloud";
    };
  };

  config = mkIf cfg.enable {

    services.nextcloud = {
      enable       = true;
      hostName     = cfg.hostName;
      package      = cfg.package;
      https        = cfg.https;
      datadir      = cfg.dataDir;
      maxUploadSize = cfg.maxUploadSize;

      # Apps entièrement gérées par Nix
      appstoreEnable  = false;
      extraApps       = genAttrs (cfg.apps ++ optional cfg.oidc.enable "user_oidc"
                                   ++ optional cfg.onlyoffice.enable "onlyoffice")
                          (name: cfg.package.packages.apps.${name}) // cfg.extraApps;
      extraAppsEnable = true;

      config = {
        adminuser     = cfg.admin.user;
        adminpassFile = cfg.admin.passwordFile;

        dbtype = "pgsql";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";

        objectstore.s3 = mkIf cfg.s3.enable {
          enable       = true;
          bucket       = cfg.s3.bucket;
          hostname     = cfg.s3.hostname;
          region       = cfg.s3.region;
          key          = cfg.s3.key;
          secretFile   = s3SecretFile;
          usePathStyle = cfg.s3.usePathStyle;
        };
      };

      settings = {
        default_phone_region = "FR";
        overwriteprotocol    = if cfg.https then "https" else "http";
        trusted_proxies      = cfg.trustedProxies;

        # Cache Redis
        memcache.local     = "\\OC\\Memcache\\Redis";
        memcache.locking   = "\\OC\\Memcache\\Redis";
        memcache.distributed = "\\OC\\Memcache\\Redis";
        redis = {
          host = "/run/redis-nextcloud/redis.sock";
          port = 0;
        };
      } // optionalAttrs cfg.onlyoffice.enable {
        onlyoffice.DocumentServerUrl = cfg.onlyoffice.documentServerUrl;
      } // cfg.extraSettings;

      # Réglages secrets fusionnés dans config.php (secret JWT d'ONLYOFFICE)
      secretFile = mkIf cfg.onlyoffice.enable config.sops.templates."nextcloud-secrets.json".path;

      phpOptions = {
        "opcache.interned_strings_buffer" = "16";
        "opcache.memory_consumption"      = "256";
        "opcache.revalidate_freq"         = "60";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 80 ];

    # Base de données PostgreSQL
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [
        {
          name = "nextcloud";
          ensureDBOwnership = true;
        }
      ];
    };

    # S'assurer que PostgreSQL démarre avant Nextcloud
    systemd.services."nextcloud-setup" = {
      requires = [ "postgresql.service" ];
      after    = [ "postgresql.service" ];
    };

    # Cache Redis
    services.redis.servers.nextcloud = {
      enable = true;
      user   = "nextcloud";
      port   = 0;
    };

    # Secrets sops (lorsque le host ne fournit pas de fichier)
    sops.secrets = mkIf sops (mkMerge [
      (mkIf (cfg.s3.enable && cfg.s3.secretFile == null) {
        ${s3SecretName} = { restartUnits = [ "phpfpm-nextcloud.service" ]; };
      })
      (mkIf (cfg.oidc.enable && cfg.oidc.clientSecretFile == null) {
        ${oidcSecretName} = {
          owner        = "nextcloud";
          restartUnits = [ "nextcloud-oidc-provider.service" ];
        };
      })
      (mkIf cfg.onlyoffice.enable {
        "onlyoffice/jwt-secret" = {};
      })
    ]);

    sops.templates."nextcloud-secrets.json" = mkIf cfg.onlyoffice.enable {
      content      = builtins.toJSON {
        onlyoffice.jwt_secret = config.sops.placeholder."onlyoffice/jwt-secret";
      };
      restartUnits = [ "phpfpm-nextcloud.service" ];
    };

    assertions = [
      {
        assertion = cfg.s3.enable && cfg.s3.secretFile == null -> sops;
        message   = "shincraft.server.nextcloud.s3 : définir secretFile ou activer shincraft.system.sops.";
      }
      {
        assertion = cfg.oidc.enable && cfg.oidc.clientSecretFile == null -> sops;
        message   = "shincraft.server.nextcloud.oidc : définir clientSecretFile ou activer shincraft.system.sops.";
      }
      {
        assertion = cfg.onlyoffice.enable -> sops;
        message   = "shincraft.server.nextcloud.onlyoffice : le secret JWT passe par sops, activer shincraft.system.sops.";
      }
    ];

    # Sauvegarde (si shincraft.system.backup est activé) : base + config.php (secret, passwordsalt, instanceid)
    shincraft.system.backup.jobs.nextcloud = {
      postgresDatabases = [ "nextcloud" ];
      paths             = [ "${config.services.nextcloud.home}/config" ];
    };

    # Déclare (ou met à jour) le fournisseur OIDC à chaque démarrage : la commande est idempotente.
    systemd.services.nextcloud-oidc-provider = mkIf cfg.oidc.enable {
      description = "Configuration du fournisseur OIDC de Nextcloud";
      wantedBy    = [ "multi-user.target" ];
      requires    = [ "nextcloud-setup.service" ];
      after       = [ "nextcloud-setup.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${config.services.nextcloud.occ}/bin/nextcloud-occ user_oidc:provider ${escapeShellArg cfg.oidc.name} \
          --clientid=${escapeShellArg cfg.oidc.clientId} \
          --clientsecret-file=${escapeShellArg oidcSecretFile} \
          --discoveryuri=${escapeShellArg cfg.oidc.discoveryUri} \
          --unique-uid=0 \
          --mapping-uid=${escapeShellArg cfg.oidc.mappingUid}
      '';
    };
  };
}
