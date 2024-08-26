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

        environment.systemPackages = with pkgs; with libsForQt5; [
          sddm-kcm
          kcoreaddons
          #libsForQt5
          kio
          kile
          texlive.combined.scheme-full
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
        programs.kdeconnect.enable = true;
      }
    )
  ];
}
