{ config, lib, pkgs, ... }:
let 
  cfg = config.shincraft.server.auth;
in
with lib;
with types;
{
  options.shincraft.server.auth = {
    enable = mkEnableOption "Install openLDAP and KeyCloak in the systeme";
    suffix = mkOption {
      default = "dc=example,dc=com";
      type    = str;
      example = "dc=example,dc=com";
    };
    rootCN = mkOption {
      default = "admin";
      type    = str;
      example = "admin";
    };
    rootPW = mkOption {
      default = "{SSHA}p0zYqTRH4Ph8tzaMrl0FB1kZPLGFXJ2s";
      type    = str;
      example = "{SSHA}p0zYqTRH4Ph8tzaMrl0FB1kZPLGFXJ2s";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.openldap = {
        enable = true;

        /* enable plain connections only */
        urlList = [ "ldap:///" ];


        settings = {
          attrs = {
            olcLogLevel = "conns config";
          };

          children = {
            "cn=schema".includes = [
              "${pkgs.openldap}/etc/schema/core.ldif"
              "${pkgs.openldap}/etc/schema/cosine.ldif"
              "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
              "${pkgs.openldap}/etc/schema/nis.ldif"
              "${pkgs.openldap}/etc/schema/openldap.ldif"
              "${pkgs.openldap}/etc/schema/dyngroup.ldif"
            ];

            "olcDatabase={1}mdb".attrs = {
              objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];

              olcDatabase = "{1}mdb";
              olcDbDirectory = "/var/lib/openldap/data";

              olcSuffix = cfg.suffix;

              /* your admin account, do not use writeText on a production system */
              olcRootDN = "cn=${cfg.rootCN},${cfg.suffix}";
              olcRootPW.path = pkgs.writeText "olcRootPW" "${cfg.rootPW}";

              olcAccess = [
                /* custom access rules for userPassword attributes */
                ''{0}to attrs=userPassword
                    by self write
                    by dn.exact="cn=${cfg.rootCN},${cfg.suffix}" write
                    by anonymous auth
                    by * none''

                /* allow read on anything else */
                ''{1}to *
                    by dn.exact="cn=${cfg.rootCN},${cfg.suffix}" write
                    by * read''
              ];
            };
          };
        };
      };
    })
  ];
}
