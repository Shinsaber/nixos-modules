{ config, lib, ... }:

let
  cfg     = config.shincraft.system.backup;
  jobs    = lib.filterAttrs (_: job: job.enable) cfg.jobs;
  dumpDir = config.services.postgresqlBackup.location;
  systemctl = "${config.systemd.package}/bin/systemctl";
in
with lib;
{
  config = mkIf cfg.enable {

    # Dumps PostgreSQL sans timer propre : chaque job déclenche les siens avant restic
    services.postgresqlBackup = mkIf (any (job: job.postgresDatabases != []) (attrValues jobs)) {
      enable      = true;
      databases   = unique (concatMap (job: job.postgresDatabases) (attrValues jobs));
      compression = "zstd";
      startAt     = [];
    };

    sops.secrets = mkIf (jobs != {}) ({
      "backup/s3-secret" = {};
    } // mapAttrs' (name: _: nameValuePair "backup/${name}-password" {}) jobs);

    # Identifiants S3 communs à tous les dépôts
    sops.templates."backup-s3.env" = mkIf (jobs != {}) {
      content = ''
        AWS_ACCESS_KEY_ID=${cfg.key}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."backup/s3-secret"}
        AWS_DEFAULT_REGION=${cfg.region}
      '';
    };

    # Un dépôt restic par job, chiffré avec son propre mot de passe
    services.restic.backups = mapAttrs (name: job: {
      initialize      = true;
      repository      = "s3:https://${cfg.hostname}/${cfg.bucket}/${config.networking.hostName}/${name}";
      passwordFile    = config.sops.secrets."backup/${name}-password".path;
      environmentFile = config.sops.templates."backup-s3.env".path;
      paths           = job.paths ++ map (db: "${dumpDir}/${db}.sql.zst") job.postgresDatabases;
      pruneOpts       = if job.pruneOpts != null then job.pruneOpts else cfg.pruneOpts;
      backupPrepareCommand = let
        commands = map (db: "${systemctl} start postgresqlBackup-${db}.service") job.postgresDatabases
          ++ optional (job.prepareCommand != "") job.prepareCommand;
      in if commands == [] then null else concatStringsSep "\n" commands;
      timerConfig = {
        OnCalendar         = cfg.startAt;
        Persistent         = true;
        RandomizedDelaySec = "15m";
      };
    }) jobs;

    assertions = [{
      assertion = config.shincraft.system.sops.enable;
      message   = "shincraft.system.backup : les secrets passent par sops, activer shincraft.system.sops.";
    }];
  };
}
