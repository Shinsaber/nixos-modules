{ config, lib, pkgs, ... }:

with lib;
with types;
let 
  cfg = config.shincraft.server.nginx;
  subDomainModule = { name, config, ... }:
  {
    options = {
      host = mkOption {
        default = "www";
        type    = str;
      };
      port = mkOption {
        default = "80";
        type    = ints.u16;
      };
    };
  };
  domainModule = { name, config, ... }:
  {
    options = mkOption {
      type = attrsOf ( submodule subDomainModule );
    };
  };
in
with lib;
with types;
{
  options.shincraft.server = {
    nginx =  {
      enable = mkEnableOption "Install nginx in the systeme";
      domain = mkOption {
        type    = attrsOf ( submodule domainModule );
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.nginx = {
        enable = true;

        # Use recommended settings
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        # Only allow PFS-enabled ciphers with AES256
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
        
        appendHttpConfig = ''
          # Minimize information leaked to other domains
          add_header 'Referrer-Policy' 'origin-when-cross-origin';

          # Disable embedding as a frame
          add_header X-Frame-Options DENY;

          # Prevent injection of code in other mime types (XSS Attacks)
          add_header X-Content-Type-Options nosniff;
        '';

        virtualHosts = listToAttrs ( flatten (
          flip mapAttrsToList cfg.domain ( domain: domainConfig: 
            flip mapAttrsToList domainConfig.proxy ( subdomain: config: 
              { 
                name = "${subdomain}.${domain}";
                value = {
                  addSSL = true;
                  enableACME = true;
                  locations."/" = {
                    proxyPass = "http://${config.host}:${config.port}";
                    proxyWebsockets = true; # needed if you need to use WebSocket
                  };
                };
              }
            )
          )
        ));
      };
    })
  ];
}
