{ config, lib, pkgs, ... }:

let
  cfg = config.shincraft.server.romm;
  ph  = config.sops.placeholder;

  # Secrets attendus dans le fichier sops du host
  secrets = [ "romm/db-password" "romm/db-root-password" "romm/auth-secret-key" ]
    ++ lib.optional cfg.screenscraper.enable     "romm/screenscraper-password"
    ++ lib.optional cfg.retroachievements.enable "romm/retroachievements-api-key"
    ++ lib.optional cfg.steamgriddb.enable       "romm/steamgriddb-api-key";

  # Dump MariaDB pour les sauvegardes : le mot de passe root est lu dans l'environnement du
  # conteneur (MARIADB_ROOT_PASSWORD), il n'apparaît sur aucune ligne de commande de l'hôte.
  dumpDir    = "/var/backup/romm";
  dumpScript = pkgs.writeShellScript "romm-db-dump" ''
    set -euo pipefail
    ${pkgs.podman}/bin/podman exec romm-db sh -c \
      'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb-dump -uroot --single-transaction --routines --events --databases "$MARIADB_DATABASE"' \
      | ${pkgs.zstd}/bin/zstd -q -c > ${dumpDir}/romm.sql.zst.tmp
    mv ${dumpDir}/romm.sql.zst.tmp ${dumpDir}/romm.sql.zst
  '';
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

    # Traçabilité uniquement : le port publié par podman (DNAT puis FORWARD) contourne le
    # pare-feu NixOS (chaîne INPUT), il est donc joignable même à false.
    openFirewall = mkOption {
      type        = bool;
      default     = true;
      description = "Déclarer le port de RomM dans networking.firewall (traçabilité : podman le publie de toute façon)";
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
    };

    screenscraper = {
      enable = mkEnableOption "Fournisseur de métadonnées ScreenScraper (secret sops `romm/screenscraper-password`)";

      user = mkOption {
        type        = str;
        default     = "";
        description = "Nom d'utilisateur ScreenScraper";
      };
    };

    retroachievements.enable = mkEnableOption "RetroAchievements (secret sops `romm/retroachievements-api-key`)";
    steamgriddb.enable       = mkEnableOption "SteamGridDB (secret sops `romm/steamgriddb-api-key`)";

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

      networking.firewall.allowedTCPPorts = optional cfg.openFirewall cfg.port;

      # Création des répertoires nécessaires
      systemd.tmpfiles.rules = [
        "d /var/lib/romm/redis     0755 root root -"
        "d /var/lib/romm/db        0755 root root -"
        "d ${dumpDir}             0700 root root -"
      ];

      # Sauvegarde (si shincraft.system.backup est activé) : dump de la base MariaDB.
      # La bibliothèque et les assets (rommDataPath) ne sont pas inclus.
      shincraft.system.backup.jobs.romm = {
        paths          = [ dumpDir ];
        prepareCommand = "${dumpScript}";
      };

      # Networks
      systemd.services."podman-romm-network" = {
        path = [ pkgs.podman ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.podman}/bin/podman network rm -f romm-network";
        };
        script = ''
          podman network inspect romm-network || podman network create romm-network
        '';
        before   = [ "podman-romm.service" "podman-romm-db.service" ];
        wantedBy = [ "podman-romm.service" "podman-romm-db.service" ];
      };

      virtualisation.oci-containers.containers = {

        romm-db = {
          image = "mariadb:13.0.2";
          networks  = [ "romm-network" ];
          environment = {
            MARIADB_DATABASE      = cfg.db.name;
            MARIADB_USER          = cfg.db.user;
          };
          environmentFiles = [ config.sops.templates."romm-db.env".path ];
          volumes = [
            "/var/lib/romm/db:/var/lib/mysql"
          ];
          # podman stop tue le conteneur après 10 s par défaut : laisser à MariaDB le temps
          # de s'arrêter proprement (sinon tc.log corrompu au redémarrage). < TimeoutStopSec (120 s).
          extraOptions = [ "--stop-timeout=90" ];
        };

        romm = {
          image = "rommapp/romm:5.4.1";
          dependsOn = [ "romm-db" ];
          networks  = [ "romm-network" ];
          environment = {
            DB_HOST                   = "romm-db";
            DB_NAME                   = cfg.db.name;
            DB_USER                   = cfg.db.user;
            SCREENSCRAPER_USER        = cfg.screenscraper.user;
            HASHEOUS_API_ENABLED      = if cfg.hasheous.enable then "true" else "false";
          };
          environmentFiles = [ config.sops.templates."romm.env".path ];
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

      # Secrets : fichiers d'environnement générés par sops à l'activation (hors /nix/store).
      # MariaDB ne lit ses mots de passe qu'à la création de la base.
      sops.secrets = genAttrs secrets (_: {});

      sops.templates."romm-db.env" = {
        content = ''
          MARIADB_ROOT_PASSWORD=${ph."romm/db-root-password"}
          MARIADB_PASSWORD=${ph."romm/db-password"}
        '';
        restartUnits = [ "podman-romm-db.service" ];
      };

      sops.templates."romm.env" = {
        content = concatStringsSep "\n" ([
          "DB_PASSWD=${ph."romm/db-password"}"
          "ROMM_AUTH_SECRET_KEY=${ph."romm/auth-secret-key"}"
        ]
        ++ optional cfg.screenscraper.enable     "SCREENSCRAPER_PASSWORD=${ph."romm/screenscraper-password"}"
        ++ optional cfg.retroachievements.enable "RETROACHIEVEMENTS_API_KEY=${ph."romm/retroachievements-api-key"}"
        ++ optional cfg.steamgriddb.enable       "STEAMGRIDDB_API_KEY=${ph."romm/steamgriddb-api-key"}"
        ) + "\n";
        restartUnits = [ "podman-romm.service" ];
      };

      assertions = [{
        assertion = config.shincraft.system.sops.enable;
        message   = "shincraft.server.romm : les secrets passent par sops, activer shincraft.system.sops.";
      }];
    })
  ];
} 