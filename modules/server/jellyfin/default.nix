{ config, lib, pkgs, ... }:

let cfg = config.custom.server;
in
with lib;
with types;
{
  options.custom.server = {
    jellyfin = mkEnableOption "Install jellyfin in the systeme";
    transmission = {
      enable = mkEnableOption "Install transmission torrent client";
      whitelist = mkOption {
        default = "127.0.0.1";
        type    = str;
        example = "127.0.0.1,192.168.0.1";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.jellyfin {
      custom.system.vaapi = mkDefault true;
      environment.systemPackages = [
        pkgs.jellyfin
        pkgs.jellyfin-web
        pkgs.jellyfin-ffmpeg
      ];
      services.jellyfin = {
        enable       = true;
        openFirewall = true;
      };
    })
    (mkIf cfg.transmission.enable {
      services.transmission = { 
        enable      = true; #Enable transmission daemon
        openRPCPort = true; #Open firewall for RPC
        settings    = {     #Override default settings
          rpc-bind-address = "0.0.0.0"; #Bind to own IP
          rpc-whitelist    = cfg.transmission.whitelist; #Whitelist your remote machine
        };
      };
    })
  ];
}