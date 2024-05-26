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
            enable = true;
            layout = "fr";
            xkbVariant = "bepo";

            # Enable touchpad support
            libinput = {
              enable = true;
              touchpad.disableWhileTyping = true;
            };
          };

          unclutter = {
            enable = true;
            timeout = 5;
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

        environment.systemPackages = with pkgs; with libsForQt5; [
          pavucontrol
          easyeffects
          libnotify
          xclip
          wl-clipboard
          xdg-utils
        ];

        # Fonts
        fonts = {
          packages = with pkgs; [ emojione fira-code (nerdfonts.override { fonts = [ "FiraCode" ]; }) ];
          fontconfig.defaultFonts.monospace = [ "Fira Code" ];
          fontconfig.defaultFonts.emoji = [ "EmojiOne Color" ];
        };
      }
    )
  ];
}
