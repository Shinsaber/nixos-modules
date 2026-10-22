{ config, lib, pkgs, ... }:

with lib;
with types;
let
  cfg  = config.shincraft.server.kanidm;
  sops = config.shincraft.system.sops.enable;

  # Fichier fourni par le host, sinon secret sops du même nom
  secretPath = file: name: if file != null then file
    else if sops then config.sops.secrets.${name}.path
    else "/run/secrets/${name}";

  selfSigned = cfg.tls.chainFile == null;
  tlsDir     = "/var/lib/kanidm-tls";

  # Secrets attendus dans sops : nom → fichier fourni par le host (null = sops)
  sopsSecrets = filterAttrs (_: file: file == null) ({
    "kanidm/admin-password"     = cfg.adminPasswordFile;
    "kanidm/idm-admin-password" = cfg.idmAdminPasswordFile;
  } // mapAttrs' (name: client: nameValuePair "oidc/${name}" client.secretFile) cfg.oauth2);

  oauth2Module = { name, ... }: {
    options = {
      displayName = mkOption {
        type        = str;
        example     = "Nextcloud";
        description = "Nom affiché dans le portail Kanidm";
      };
      originUrl = mkOption {
        type        = either str (listOf str);
        example     = "https://cloud.example.com/apps/user_oidc/code";
        description = "URL(s) de redirection OAuth2 exactes du service";
      };
      originLanding = mkOption {
        type        = str;
        example     = "https://cloud.example.com";
        description = "Page d'accueil du service (lien du portail Kanidm)";
      };
      group = mkOption {
        type        = str;
        default     = "${name}_users";
        description = "Groupe Kanidm autorisé à se connecter (créé par le module, membres gérés dans Kanidm)";
      };
      scopes = mkOption {
        type        = listOf str;
        default     = [ "openid" "email" "profile" ];
        description = "Scopes accordés aux membres du groupe";
      };
      secretFile = mkOption {
        type        = nullOr str;
        default     = null;
        description = ''
          Fichier contenant le secret du client, lisible par l'utilisateur kanidm.
          Par défaut (`null`) : secret sops `oidc/<nom>` (même valeur que côté service).
        '';
      };
    };
  };
in
{
  options.shincraft.server.kanidm = {
    enable = mkEnableOption "Install Kanidm identity provider (OIDC, TOTP, passkeys)";

    domain = mkOption {
      type        = str;
      example     = "idm.example.com";
      description = ''
        Nom de domaine public de Kanidm (sert aussi d'identifiant des comptes :
        le changer plus tard invalide les passkeys).
      '';
    };

    package = mkOption {
      type        = package;
      default     = pkgs.kanidmWithSecretProvisioning_1_11;
      description = "Paquet Kanidm (version explicite, avec le support du provisioning des secrets)";
    };

    port = mkOption {
      type        = ints.u16;
      default     = 8443;
      description = "Port HTTPS d'écoute de Kanidm";
    };

    openFirewall = mkOption {
      type        = bool;
      default     = false;
      description = "Ouvrir le port de Kanidm (accès depuis le reverse proxy)";
    };

    tls = {
      chainFile = mkOption {
        type        = nullOr str;
        default     = null;
        description = ''
          Chaîne de certificats PEM. Par défaut (`null`), un certificat auto-signé est généré
          dans ${tlsDir} : suffisant derrière un reverse proxy qui termine le TLS public.
        '';
      };
      keyFile = mkOption {
        type        = nullOr str;
        default     = null;
        description = "Clé privée PEM correspondant à `chainFile`";
      };
    };

    adminPasswordFile = mkOption {
      type        = nullOr str;
      default     = null;
      description = "Mot de passe du compte `admin` (défaut : secret sops `kanidm/admin-password`)";
    };

    idmAdminPasswordFile = mkOption {
      type        = nullOr str;
      default     = null;
      description = "Mot de passe du compte `idm_admin` (défaut : secret sops `kanidm/idm-admin-password`)";
    };

    oauth2 = mkOption {
      type        = attrsOf (submodule oauth2Module);
      default     = {};
      description = "Clients OIDC déclarés dans Kanidm (le nom est l'identifiant du client)";
      example     = literalExpression ''
        {
          nextcloud = {
            displayName   = "Nextcloud";
            originUrl     = "https://cloud.example.com/apps/user_oidc/code";
            originLanding = "https://cloud.example.com";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {

    services.kanidm = {
      package = cfg.package;

      server = {
        enable   = true;
        settings = {
          domain      = cfg.domain;
          origin      = "https://${cfg.domain}";
          bindaddress = "0.0.0.0:${toString cfg.port}";
          tls_chain   = if selfSigned then "${tlsDir}/chain.pem" else cfg.tls.chainFile;
          tls_key     = if selfSigned then "${tlsDir}/key.pem"   else cfg.tls.keyFile;

          # Export cohérent de la base chaque nuit (avant restic, 03:00 par défaut), 7 versions locales
          online_backup = {
            schedule = mkDefault "00 02 * * *";
            versions = mkDefault 7;
          };
        };
      };

      # CLI `kanidm` sur le serveur (gestion des comptes, liens de réinitialisation)
      client = {
        enable        = true;
        settings.uri  = "https://${cfg.domain}";
      };

      provision = {
        enable               = true;
        instanceUrl          = "https://localhost:${toString cfg.port}";
        adminPasswordFile    = secretPath cfg.adminPasswordFile "kanidm/admin-password";
        idmAdminPasswordFile = secretPath cfg.idmAdminPasswordFile "kanidm/idm-admin-password";

        # Groupes d'accès des clients ; membres ajoutés dans Kanidm, jamais écrasés par Nix
        groups = mapAttrs' (_: client: nameValuePair client.group {
          overwriteMembers = mkDefault false;
        }) cfg.oauth2;

        systems.oauth2 = mapAttrs (name: client: {
          displayName         = client.displayName;
          originUrl           = client.originUrl;
          originLanding       = client.originLanding;
          basicSecretFile     = secretPath client.secretFile "oidc/${name}";
          preferShortUsername = true;
          scopeMaps.${client.group} = client.scopes;
        }) cfg.oauth2;
      };
    };

    sops.secrets = mkIf sops (mapAttrs (_: _: {
      owner        = "kanidm";
      restartUnits = [ "kanidm.service" ];
    }) sopsSecrets);

    assertions = [
      {
        assertion = sopsSecrets != {} -> sops;
        message   = "shincraft.server.kanidm : fournir les fichiers de secrets ou activer shincraft.system.sops.";
      }
      {
        assertion = (cfg.tls.chainFile == null) == (cfg.tls.keyFile == null);
        message   = "shincraft.server.kanidm.tls : chainFile et keyFile vont ensemble.";
      }
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    # Sauvegarde (si shincraft.system.backup est activé) : exports de online_backup.
    # Comptes, groupes, mots de passe, TOTP, passkeys et clés de signature OIDC.
    shincraft.system.backup.jobs.kanidm = {
      paths = [ config.services.kanidm.server.settings.online_backup.path ];
    };

    # Certificat auto-signé (CA locale + certificat serveur), généré une seule fois
    systemd.services.kanidm-tls = mkIf selfSigned {
      description = "Certificat TLS auto-signé de Kanidm";
      wantedBy    = [ "kanidm.service" ];
      before      = [ "kanidm.service" ];
      path        = [ pkgs.openssl ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        [ -s ${tlsDir}/chain.pem ] && exit 0
        install -d -m 0750 -o kanidm -g kanidm ${tlsDir}
        cd ${tlsDir}
        ec="-newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes"
        openssl req -x509 $ec -days 3650 -subj "/CN=Kanidm local CA" -keyout ca.key -out ca.pem
        openssl req $ec -subj "/CN=${cfg.domain}" -keyout key.pem -out server.csr
        openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -days 3650 \
          -out server.pem -extfile <(printf '%s\n' \
            "basicConstraints=critical,CA:FALSE" \
            "keyUsage=critical,digitalSignature" \
            "extendedKeyUsage=serverAuth" \
            "subjectAltName=DNS:${cfg.domain},DNS:localhost,IP:127.0.0.1")
        cat server.pem ca.pem > chain.pem
        rm -f server.csr ca.key ca.srl
        chown kanidm:kanidm key.pem chain.pem
        chmod 0400 key.pem
      '';
    };
  };
}
