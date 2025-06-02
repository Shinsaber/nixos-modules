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
          desktopManager.plasma6.enable = true;
          displayManager.sddm = {
            enable = true;
            wayland.enable = true;
          };
        };

        environment.systemPackages = with pkgs; with kdePackages; [
          sddm-kcm
          kcoreaddons
          #libsForQt5
          kio
          kile
          filelight
          texlive.combined.scheme-full
          dolphin
          dolphin-plugins
          ark
          skanlite
          kate
          yakuake # Drop-down terminal emulator based on Konsole technologies
          spectacle
          gwenview
          okular
          zanshin # Getting Things Done application which aims at getting your mind like water
          plasma-browser-integration
          # xwaylandvideobridge # Utility to allow streaming Wayland windows to X applications

          kzones # KDE KWin Script for snapping windows into zones
          darkly # Modern style for Qt applications (fork of Lightly)
        ];
      }
    )
    (mkIf cfg.plasma.kdeconnect
      {
        programs.kdeconnect.enable = true;
      }
    )
  ];
}
