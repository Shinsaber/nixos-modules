{ config, lib, pkgs, ... }:

let
  cfg = config.shincraft.server.nextcloud;
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
        type        = str;
        default     = "admin";
        description = "Nom de l'utilisateur administrateur";
      };

      passwordFile = mkOption {
        type        = str;
        example     = "/run/secrets/nextcloud-admin-password";
        description = "Chemin vers le fichier contenant le mot de passe admin";
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

    extraApps = mkOption {
      type        = attrsOf package;
      default     = {};
      description = "Applications Nextcloud supplémentaires à installer";
      example     = literalExpression ''
        with config.services.nextcloud.package.packages.apps; {
          inherit contacts calendar tasks;
        }
      '';
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

      autoUpdateApps.enable = true;

      extraApps      = cfg.extraApps;
      extraAppsEnable = true;

      config = {
        adminuser     = cfg.admin.user;
        adminpassFile = cfg.admin.passwordFile;

        dbtype = "pgsql";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
      };

      settings = {
        default_phone_region = "FR";
        overwriteprotocol    = if cfg.https then "https" else "http";

        # Cache Redis
        memcache.local     = "\\OC\\Memcache\\Redis";
        memcache.locking   = "\\OC\\Memcache\\Redis";
        memcache.distributed = "\\OC\\Memcache\\Redis";
        redis = {
          host = "/run/redis-nextcloud/redis.sock";
          port = 0;
        };
      } // cfg.extraSettings;

      phpOptions = {
        "opcache.interned_strings_buffer" = "16";
        "opcache.memory_consumption"      = "256";
        "opcache.revalidate_freq"         = "60";
      };
    };

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
  };
}
