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
        default = 80;
        type    = ints.u16;
      };
    };
  };
in
with lib;
with types;
{
  options.shincraft.server = {
    nginx =  {
      enable = mkEnableOption "Install nginx in the systeme";
      mail = mkOption {
        default = null;
        type    = str;
        example = "user@domain.tld";
      };
      domain = mkOption {
        type    = attrsOf ( attrsOf ( submodule subDomainModule ) );
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      security.acme.acceptTerms = true;
      security.acme.defaults.email = cfg.mail;
      networking.firewall = {
        allowedTCPPorts = [
          80
          443
        ];
      };
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
          flip mapAttrsToList cfg.domain ( domain: subDomainConfig: 
            flip mapAttrsToList subDomainConfig ( subdomain: config: 
              { 
                name = "${subdomain}.${domain}";
                value = {
                  enableACME = true;
                  forceSSL = true;
                  locations."/" = {
                    proxyPass = "http://${config.host}:${toString config.port}";
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
