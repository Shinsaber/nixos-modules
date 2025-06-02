{ config, pkgs, lib, ... }:

let cfg = config.shincraft.gui;
in
with lib;
with types;

{
  imports =
  [
    ./audio.nix
    ./package.nix
    ./manager/plasma.nix
  ];

  config = mkMerge [
    (mkIf cfg.enable
      {
        # GUI
        environment.sessionVariables.NIXOS_OZONE_WL = "1";
        services = {
          xserver = {
            xkb.layout = "fr";
            xkb.variant = "bepo";
          };

          unclutter = {
            enable = true;
            timeout = 5;
          };

          # Enable touchpad support
          libinput = {
            enable = true;
            touchpad.disableWhileTyping = true;
          };
        };

        console.useXkbConfig = true;

        # Bluetooth
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
        };

        services = {
          printing.enable     = true;
          languagetool.enable = true;
        };

        environment.systemPackages = with pkgs; with kdePackages; [
          pavucontrol
          easyeffects
          libnotify
          xclip
          wl-clipboard
          xdg-utils
        ];

        # Fonts
        fonts = {
          packages = with pkgs; [ emojione nerd-fonts.fira-code ];
          fontconfig.defaultFonts.monospace = [ "FiraCode Nerd Font" ];
          fontconfig.defaultFonts.emoji = [ "EmojiOne Color" ];
        };
      }
    )
  ];
}
