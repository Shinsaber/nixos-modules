# Serveur : VM Proxmox UEFI avec disko, tous les services, firewall fermé sauf nginx et SSH.
{
  server = true;

  module = { ... }: {
    networking.hostName = "srv";

    shincraft = {
      system.proxmoxGuest = {
        enable      = true;
        firmware    = "uefi";
        disko       = true;
        rootSshKeys = [ "ssh-ed25519 AAAATEST moi@poste" ];
      };
      system.backup = {
        enable   = true;
        bucket   = "backups";
        hostname = "s3.example.com";
        region   = "gra";
        key      = "AKIATEST";
      };
      shell.zsh.enable = true;   # sans tmux : fzf-tab doit quand même être chargé

      server = {
        nginx = {
          enable = true;
          mail   = "admin@mondomaine.fr";
          domain."mondomaine.fr" = {
            files = { host = "192.168.1.20"; maxBodySize = "16G"; allowFrom = [ "10.8.0.0/24" ]; };
            idm   = { host = "192.168.1.30"; port = 8443; protocol = "https"; };
          };
          fail2ban = { enable = true; ignoreIP = [ "192.168.1.0/24" ]; maxRetry = 30; };
        };
        jellyfin.enable     = true;   # openFirewall false par défaut
        transmission.enable = true;
        nextcloud = {
          enable   = true;
          hostName = "cloud.mondomaine.fr";
          apps     = [ "calendar" ];
          s3 = { enable = true; bucket = "nextcloud"; hostname = "s3.example.com"; region = "gra"; key = "AKIATEST"; };
          oidc = {
            enable       = true;
            discoveryUri = "https://idm.mondomaine.fr/oauth2/openid/nextcloud/.well-known/openid-configuration";
            ssoOnly      = true;
          };
          onlyoffice = { enable = true; documentServerUrl = "https://office.mondomaine.fr/"; };
        };
        kanidm = {
          enable = true;
          domain = "idm.mondomaine.fr";
          oauth2.nextcloud = {
            displayName   = "Nextcloud";
            originUrl     = "https://cloud.mondomaine.fr/apps/user_oidc/code";
            originLanding = "https://cloud.mondomaine.fr";
          };
        };
        onlyoffice = { enable = true; hostName = "office.mondomaine.fr"; };
        collectionnard = {
          enable         = true;
          hostName       = "colec.mondomaine.fr";
          trustedProxies = [ "192.168.1.10" ];
          settings       = { MEMBER_INVITES = "true"; };
        };
        romm = {
          enable        = true;
          rommDataPath  = "/srv/romm";
          screenscraper = { enable = true; user = "moi"; };
        };
      };
    };
  };

  checks = { config, pkgs, lib }:
    let
      ports    = lib.sort lib.lessThan (lib.unique config.networking.firewall.allowedTCPPorts);
      vhosts   = config.services.nginx.virtualHosts;
      files    = vhosts."files.mondomaine.fr".locations."/";
      secrets  = [
        "romm/db-password" "romm/screenscraper-password" "backup/s3-secret" "backup/nextcloud-password"
        "backup/kanidm-password" "backup/romm-password" "kanidm/admin-password" "oidc/nextcloud"
        "nextcloud/s3-secret" "onlyoffice/jwt-secret" "collectionnard/jwt-secret" "backup/collectionnard-password"
      ];
    in {
      firewallFerme     = ports == [ 22 80 443 8095 ];   # SSH (proxmoxGuest), nginx et RomM (openFirewall par défaut)
      vaapiParJellyfin  = config.shincraft.system.vaapi
                          && lib.elem "intel-vaapi-driver" (map (p: p.pname) config.hardware.graphics.extraPackages);
      uefiDisko         = config.boot.loader.systemd-boot.enable
                          && config.disko.devices.disk.main.content.partitions ? ESP
                          && config.fileSystems."/".fsType == "ext4";
      rootParCle        = config.users.users.root.openssh.authorizedKeys.keys == [ "ssh-ed25519 AAAATEST moi@poste" ];
      fzfTabSansTmux    = lib.hasInfix "fzf-tab" config.programs.zsh.promptInit && !config.programs.tmux.enable;
      nginxAllowFrom    = lib.hasInfix "allow 10.8.0.0/24;" files.extraConfig && lib.hasInfix "deny all;" files.extraConfig
                          && lib.hasInfix "client_max_body_size 16G;" files.extraConfig;
      nginxBackendHttps = lib.hasPrefix "https://" vhosts."idm.mondomaine.fr".locations."/".proxyPass;
      fail2banNginx     = config.services.fail2ban.enable
                          && lib.all (j: config.services.fail2ban.jails ? ${j}) [ "nginx-scan" "nginx-sensitive" "nginx-botsearch" "nginx-bad-request" "nginx-forbidden" "nginx-limit-req" "sshd" ]
                          && config.services.fail2ban.jails.nginx-scan.settings.maxretry == 30
                          && lib.hasInfix "192.168.1.0/24" config.services.fail2ban.jails.DEFAULT.settings.ignoreip
                          && config.environment.etc ? "fail2ban/filter.d/nginx-scan.conf"
                          && lib.hasInfix ''/remote\.php/dav/'' config.services.fail2ban.jails.nginx-scan.filter.Definition.ignoreregex
                          && lib.hasInfix ''/remote\.php/dav/'' config.services.fail2ban.jails.nginx-sensitive.filter.Definition.ignoreregex;
      nginxLogs         = lib.hasInfix "access_log /var/log/nginx/access.log shincraft;" config.services.nginx.commonHttpConfig
                          && lib.hasInfix "access_log /var/log/nginx/access.json.log shincraft_json;" config.services.nginx.commonHttpConfig;
      jobsRestic        = lib.sort lib.lessThan (lib.attrNames config.services.restic.backups) == [ "collectionnard" "kanidm" "nextcloud" "romm" ];
      dumpPostgres      = lib.sort lib.lessThan config.services.postgresqlBackup.databases == [ "collectionnard" "nextcloud" ];
      secretsSops       = lib.all (n: config.sops.secrets ? ${n}) secrets;
      nextcloudApps     = lib.all (a: config.services.nextcloud.extraApps ? ${a}) [ "calendar" "user_oidc" "onlyoffice" ];
      nextcloudS3       = config.services.nextcloud.config.objectstore.s3.enable;
      nextcloudSsoOnly  = config.services.nextcloud.settings.hide_login_form
                          && lib.hasInfix "--value=0 user_oidc allow_multiple_user_backends"
                               config.systemd.services.nextcloud-oidc-provider.script;
      kanidmGroupe      = config.services.kanidm.provision.groups ? nextcloud_users
                          && config.services.kanidm.provision.systems.oauth2 ? nextcloud;
      rommConteneurs    = config.virtualisation.oci-containers.containers ? romm
                          && config.virtualisation.oci-containers.containers ? romm-db;
      # Arrêt propre de MariaDB : podman stop laisse 90 s, systemd 120 s
      rommDbArret       = lib.elem "--stop-timeout=90" config.virtualisation.oci-containers.containers.romm-db.extraOptions
                          && config.systemd.services.podman-romm-db.serviceConfig.TimeoutStopSec > 90;
      onlyofficeJwt     = config.services.onlyoffice.jwtSecretFile == config.sops.secrets."onlyoffice/jwt-secret".path;
      onlyofficeScheme  = lib.hasInfix "X-Forwarded-Proto $onlyoffice_scheme;" config.services.nginx.virtualHosts."office.mondomaine.fr".extraConfig
                          && !lib.hasInfix "X-Forwarded-Proto $scheme;" config.services.nginx.virtualHosts."office.mondomaine.fr".extraConfig;
      onlyofficeAmqpV4  = lib.hasPrefix "amqp://guest:guest@127.0.0.1:" config.services.onlyoffice.rabbitmqUrl
                          && lib.hasPrefix "127.0.0.1:" config.services.rabbitmq.configItems."listeners.tcp.1";
      # Kanidm et Nextcloud sur la même machine partagent `oidc/nextcloud` : Kanidm en est
      # propriétaire, Nextcloud le copie dans son RuntimeDirectory (pas de conflit de owner)
      oidcPartage       = config.sops.secrets."oidc/nextcloud".owner == "kanidm"
                          && config.systemd.services.nextcloud-oidc-provider.serviceConfig.RuntimeDirectory == "nextcloud-oidc-provider";
      # Collectionnard : PostgreSQL en peer, secret JWT en credential systemd, service durci
      colecService      = let svc = config.systemd.services.collectionnard; in
                          lib.hasPrefix "postgres://collectionnard@/collectionnard?host=/run/postgresql" svc.environment.DATABASE_URL
                          && svc.environment.MEMBER_INVITES == "true"
                          && svc.serviceConfig.LoadCredential == [ "jwt-secret:${config.sops.secrets."collectionnard/jwt-secret".path}" ]
                          && svc.serviceConfig.ProtectSystem == "strict" && svc.serviceConfig.NoNewPrivileges
                          && lib.elem "postgresql.target" svc.requires;
      colecBase         = lib.elem "collectionnard" config.services.postgresql.ensureDatabases;
      colecNginx        = let vh = vhosts."colec.mondomaine.fr"; in
                          lib.hasInfix "set_real_ip_from 192.168.1.10;" vh.extraConfig
                          && lib.hasInfix "proxy_pass http://127.0.0.1:8085;" vh.locations."/api/".extraConfig
                          && lib.hasInfix "client_max_body_size 20m;" vh.locations."= /api/v1/import".extraConfig;
    };
}
