{ config, pkgs, lib, ... }:

let cfg = config.custom.gui;
in
with lib;
with types;

{
  imports =
  [
    ./audio.nix
    ./package.nix
    ./plasma.nix
  ];

  options.custom.gui = {
    enable = mkEnableOption "Enable Plasma gui";
    audio.pipewire.enable = mkEnableOption "Enable pipewire instead of pulseaudio";
    plasma = {
      enable = mkEnableOption "Enable Plasma wayland gui";
      kdeconnect = mkEnableOption "Enable KDE connect <3";
    };
    pkgs = {
      game.enable = mkEnableOption "Enable gui game package";
      art.enable = mkEnableOption "Enable gui art package";
      "3d".enable = mkEnableOption "Enable gui 3D package";
      audio.enable = mkEnableOption "Enable gui audio package";
      video.enable = mkEnableOption "Enable gui vidéo package";
      android.enable = mkEnableOption "Enable android package";
    };
  };

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

        services.printing.enable = true;

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
