{ config, lib, pkgs, ... }:

let
  cfg = config.shincraft.server.romm;
in
with lib;
with types;
{
  options.shincraft.server.romm = {
    enable = mkEnableOption "Install RomM (ROM Manager) in the system";
    port = mkOption {
      type    = ints.u16;
      default = 8095;
      description = "Port d'écoute du service RomM";
    };

    rommDataPath = mkOption {
      type        = str;
      example     = "/data/romm/library";
      description = "Chemin vers la bibliothèque de ROMs";
    };

    db = {
      name = mkOption {
        type        = str;
        default     = "romm";
        description = "Nom de la base de données MariaDB";
      };

      user = mkOption {
        type        = str;
        default     = "romm-user";
        description = "Utilisateur de la base de données MariaDB";
      };

      password = mkOption {
        type        = str;
        description = "Mot de passe de l'utilisateur de la base de données";
      };

      rootPassword = mkOption {
        type        = str;
        description = "Mot de passe root de MariaDB";
      };
    };

    authSecretKey = mkOption {
      type        = str;
      description = "Clé secrète pour l'authentification RomM (générée avec `openssl rand -hex 32`)";
    };

    screenscraper = {
      user = mkOption {
        type        = str;
        default     = "";
        description = "Nom d'utilisateur ScreenScraper";
      };

      password = mkOption {
        type        = str;
        default     = "";
        description = "Mot de passe ScreenScraper";
      };
    };

    retroachievements.apiKey = mkOption {
      type        = str;
      default     = "";
      description = "Clé API RetroAchievements";
    };

    steamgriddb.apiKey = mkOption {
      type        = str;
      default     = "";
      description = "Clé API SteamGridDB";
    };

    configFile = mkOption {
      type        = package;
      default     = pkgs.writeText "romm-config.yml" (builtins.readFile ./config.yml);
      description = "Fichier de configuration RomM (config.yml)";
    };

    hasheous.enable = mkOption {
      type        = bool;
      default     = true;
      description = "Activer le fournisseur de métadonnées Hasheous";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {

      # Création des répertoires nécessaires
      systemd.tmpfiles.rules = [
        "d /var/lib/romm/redis     0755 root root -"
        "d /var/lib/romm/db        0755 root root -"
      ];

      virtualisation.oci-containers.containers = {

        romm-db = {
          image = "mariadb:12.2.2";
          networks  = [ "romm-network" ];
          environment = {
            MARIADB_ROOT_PASSWORD = cfg.db.rootPassword;
            MARIADB_DATABASE      = cfg.db.name;
            MARIADB_USER          = cfg.db.user;
            MARIADB_PASSWORD      = cfg.db.password;
          };
          volumes = [
            "/var/lib/romm/db:/var/lib/mysql"
          ];
        };

        romm = {
          image = "rommapp/romm:4.7.0";
          dependsOn = [ "romm-db" ];
          networks  = [ "romm-network" ];
          environment = {
            DB_HOST                   = "romm-db";
            DB_NAME                   = cfg.db.name;
            DB_USER                   = cfg.db.user;
            DB_PASSWD                 = cfg.db.password;
            ROMM_AUTH_SECRET_KEY      = cfg.authSecretKey;
            SCREENSCRAPER_USER        = cfg.screenscraper.user;
            SCREENSCRAPER_PASSWORD    = cfg.screenscraper.password;
            RETROACHIEVEMENTS_API_KEY = cfg.retroachievements.apiKey;
            STEAMGRIDDB_API_KEY       = cfg.steamgriddb.apiKey;
            HASHEOUS_API_ENABLED      = if cfg.hasheous.enable then "true" else "false";
          };
          volumes = [
            "/var/lib/romm/redis:/redis-data"
            "${cfg.configFile}:/romm/config/config.yml"
            "${cfg.rommDataPath}/resources:/romm/resources"
            "${cfg.rommDataPath}/library:/romm/library"
            "${cfg.rommDataPath}/assets:/romm/assets"
          ];
          ports = [
            "${toString cfg.port}:8080"
          ];
        };

      };
    })
  ];
} 