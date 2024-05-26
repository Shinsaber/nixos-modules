{ config, pkgs, lib, ... }:

let cfg = config.shincraft.gui;
in
with lib;
with types;

{
  config = mkMerge [
    (mkIf cfg.plasma.enable
      {
        services = {
          xserver = {
            desktopManager.plasma5.enable = true;
            displayManager.sddm = {
              enable = true;
              wayland.enable = true;
            };
          };
        };

        environment.systemPackages = with pkgs; with libsForQt5; [
          sddm-kcm
          kcoreaddons
          #libsForQt5
          kio
          kile texlive.combined.scheme-full
          dolphin
          dolphin-plugins
          ark
          skanlite
          kate
          yakuake
          spectacle
          gwenview
          okular
          plasma-browser-integration
        ];
      }
    )
    (mkIf cfg.plasma.kdeconnect
      {
        environment.systemPackages = with pkgs; with libsForQt5; [
          kdeconnect
        ];
        networking.firewall = {
          allowedTCPPortRanges = [{
            from = 1714; to = 1764;
          }];
          allowedUDPPortRanges = [{
            from = 1714; to = 1764;
          }];
        };
      }
    )
  ];
}
