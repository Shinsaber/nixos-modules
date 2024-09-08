{ config, lib, pkgs, ... }:

let cfg = config.shincraft.gui;
in
with lib;
with types;
{
  config = mkMerge [
    (mkIf cfg.enable
      {
        environment.systemPackages = with pkgs; [
          filelight
          thunderbird
          onlyoffice-bin
          calibre
          pinta
          imagemagick
          pdfsam-basic
          pdfslicer
          keepassxc
          alacritty

          clementine
          vlc
          mpv
          #mplayer
          smplayer
          yt-dlp

          wine
          #anydesk
          #barrier
          ntfs3g
          #transgui
          nextcloud-client
          #(nextcloud-client.overrideAttrs (oldAttrs: rec {
          #    #buildInputs = [ inotify-tools libcloudproviders libsecret openssl pcre qtbase qtkeychain qttools qtwebengine qtquickcontrols2 qtgraphicaleffects qtwebsockets sqlite kio kcoreaddons ];
          #    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [extra-cmake-modules];
          #    buildInputs = oldAttrs.buildInputs ++ [libsForQt5.kio];
          #  }))
        ];
        #networking.firewall = {
        #  allowedTCPPorts = [
        #    39967
        #    24800 46393 # barrier
        #  ];
        #};
        programs.xwayland.enable = true;
        programs.firefox.enable = true;
      }
    )

    (mkIf cfg.pkgs.android.enable
      (mkMerge [
        {
          programs.adb.enable = true;
          environment.systemPackages = with pkgs; [
            adb-sync
          ];
          virtualisation.waydroid.enable = true;
        }
        ( import ./waydroid.nix {inherit config pkgs;} )
      ])
    )
    (mkIf cfg.pkgs.game.enable
      {
        programs.steam.enable = true;
        environment.systemPackages = with pkgs; [
          wesnoth
          appimage-run
          discord
        ];
      }
    )

    (mkIf cfg.pkgs.art.enable
      {
        environment.systemPackages = with pkgs; [
          krita
          gimp
          darktable
          inkscape
          pentablet-driver
        ];
      }
    )

    (mkIf cfg.pkgs."3d".enable
      {
        environment.systemPackages = with pkgs; [
          cura
          freecad
        ];
      }
    )

    (mkIf cfg.pkgs.audio.enable
      {
        environment.systemPackages = with pkgs; [
          audacity
          picard
          helm
        ];
      }
    )

    (mkIf cfg.pkgs.video.enable
      {
        environment.systemPackages = with pkgs; [
          mkvtoolnix
          mkvtoolnix-cli
          makemkv
          obs-studio
          openshot-qt
          olive-editor
          shotcut
          aegisub
          kodi
          ffmpeg
          davinci-resolve
        ];
      }
    )
 ];
}
