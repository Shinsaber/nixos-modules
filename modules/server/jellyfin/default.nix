{ config, lib, pkgs, ... }:

let cfg = config.shincraft.server;
in
with lib;
with types;
{
  imports = [
    (mkRemovedOptionModule [ "shincraft" "server" "jellyseerr" ] "Seerr est installé avec shincraft.server.jellyfin.")
  ];

  options.shincraft.server = {
    jellyfin = {
      enable       = mkEnableOption "Install Jellyfin media server (+ Seerr) in the system";
      openFirewall = mkOption {
        type        = bool;
        default     = false;
        description = "Ouvrir les ports de Jellyfin (8096, 8920, découverte) et de Seerr (5055) ; sinon passer par le reverse proxy";
      };
    };
    transmission = {
      enable       = mkEnableOption "Install transmission torrent client (+ Flood web UI)";
      openFirewall = mkOption {
        type        = bool;
        default     = false;
        description = "Ouvrir les ports RPC et pairs de transmission ainsi que celui de Flood";
      };
      whitelist    = mkOption {
        default     = "127.0.0.1";
        type        = str;
        example     = "127.0.0.1,192.168.0.1";
        description = "Adresses autorisées sur le RPC de transmission (`rpc-whitelist`)";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.jellyfin.enable {
      shincraft.system.vaapi = mkDefault true;
      environment.systemPackages = with pkgs; [
        mediainfo
        mkvtoolnix
      ];
      services.jellyfin = {
        enable       = true;
        openFirewall = cfg.jellyfin.openFirewall;
      };
      services.seerr = {
        enable       = true;
        openFirewall = cfg.jellyfin.openFirewall;
      };
    })
    (mkIf cfg.transmission.enable {
      services.transmission = {
        enable        = true;
        package       = pkgs.transmission_4;
        openRPCPort   = cfg.transmission.openFirewall;
        openPeerPorts = cfg.transmission.openFirewall;
        settings      = {
          rpc-bind-address = "0.0.0.0";
          rpc-whitelist    = cfg.transmission.whitelist;
        };
      };
      services.flood = {
        enable       = true;
        openFirewall = cfg.transmission.openFirewall;
        host         = "0.0.0.0";
      };
    })
  ];
}
