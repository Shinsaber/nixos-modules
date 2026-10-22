{ config, lib, pkgs, ... }:

with lib;
with types;
let
  cfg  = config.shincraft.server.onlyoffice;
  sops = config.shincraft.system.sops.enable;

  jwtSecretName = "onlyoffice/jwt-secret";
  jwtSecretFile = if cfg.jwtSecretFile != null then cfg.jwtSecretFile
    else if sops then config.sops.secrets.${jwtSecretName}.path
    else "/run/secrets/${jwtSecretName}";

  nonceFile = "/var/lib/onlyoffice-nonce/nonce.conf";
in
{
  options.shincraft.server.onlyoffice = {
    enable = mkEnableOption "Install ONLYOFFICE Document Server (édition de documents pour Nextcloud)";

    hostName = mkOption {
      type        = str;
      example     = "office.example.com";
      description = "Nom de domaine public du Document Server (vhost nginx local)";
    };

    openFirewall = mkOption {
      type        = bool;
      default     = false;
      description = "Ouvrir le port 80 (accès depuis le reverse proxy)";
    };

    jwtSecretFile = mkOption {
      type        = nullOr str;
      default     = null;
      description = ''
        Fichier contenant le secret JWT partagé avec Nextcloud, lisible par l'utilisateur onlyoffice.
        Par défaut (`null`) : secret sops `onlyoffice/jwt-secret` (même valeur côté Nextcloud).
      '';
    };

    allowLocalConnections = mkOption {
      type        = bool;
      default     = false;
      description = ''
        Autoriser le Document Server à télécharger des fichiers depuis des adresses privées :
        nécessaire si le nom de Nextcloud résout vers une IP locale (DNS interne, VPN).
      '';
    };
  };

  config = mkIf cfg.enable {

    services.onlyoffice = {
      enable                = true;
      hostname              = cfg.hostName;
      jwtSecretFile         = jwtSecretFile;
      securityNonceFile     = nonceFile;
      allowLocalConnections = cfg.allowLocalConnections;
    };

    sops.secrets = mkIf (sops && cfg.jwtSecretFile == null) {
      ${jwtSecretName} = {
        owner        = "onlyoffice";
        restartUnits = [ "onlyoffice-docservice.service" ];
      };
    };

    assertions = [{
      assertion = cfg.jwtSecretFile == null -> sops;
      message   = "shincraft.server.onlyoffice : définir jwtSecretFile ou activer shincraft.system.sops.";
    }];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 80 ];

    # Nonce des liens sécurisés : interne à la machine (nginx + docservice), généré une seule fois
    systemd.services.onlyoffice-nonce = {
      description = "Nonce des liens sécurisés ONLYOFFICE";
      wantedBy    = [ "onlyoffice-docservice.service" "nginx.service" ];
      before      = [ "onlyoffice-docservice.service" "nginx.service" ];
      path        = [ pkgs.openssl ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        [ -s ${nonceFile} ] && exit 0
        install -d -m 0750 -o root -g onlyoffice ${dirOf nonceFile}
        umask 0027
        echo "set \$secure_link_secret \"$(openssl rand -hex 24)\";" > ${nonceFile}
        chgrp onlyoffice ${nonceFile}
      '';
    };
  };
}
