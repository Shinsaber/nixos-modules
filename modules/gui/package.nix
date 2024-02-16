{ config, lib, pkgs, ... }:

let cfg = config.custom.gui;
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
          kile
          texlive.combined.scheme-full
          imagemagick
          pdfsam-basic
          pdfslicer
          keepassxc

          clementine
          vlc
          mpv
          #mplayer
          smplayer
          youtube-dl
          yt-dlp

          wine
          anydesk
          barrier
          transgui
          nextcloud-client
          #(nextcloud-client.overrideAttrs (oldAttrs: rec {
          #    #buildInputs = [ inotify-tools libcloudproviders libsecret openssl pcre qtbase qtkeychain qttools qtwebengine qtquickcontrols2 qtgraphicaleffects qtwebsockets sqlite kio kcoreaddons ];
          #    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [extra-cmake-modules];
          #    buildInputs = oldAttrs.buildInputs ++ [libsForQt5.kio];
          #  }))
        ];
        networking.firewall = {
          allowedTCPPorts = [
            39967
            24800
          ];
        };
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
