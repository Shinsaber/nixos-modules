{ config, lib, pkgs, ... }:

let cfg = config.shincraft.system;
in
with lib;
with types;

{
  imports = [
    ./splash
  ];

  config = mkMerge [
    (mkIf cfg.nix.autoUpgrade {
      system = {
        # Periodically automatically run `nixos-rebuild switch`.
        autoUpgrade = {
          enable = true;
          flake = "/etc/nixos";
          #flags = [ "--recreate-lock-file" "--commit-lock-file" ];
          flags = [ "--recreate-lock-file" ];
          dates = "12:30";
        };
      };
    })

    (mkIf cfg.nix.optiStore {
      nix = {
        # Auto cleanups
        settings.auto-optimise-store = true;
        gc = {
          automatic = true;
          dates = "13:00";
          options = "--delete-older-than 30d";
        };
        optimise = {
          automatic = true;
          dates = [ "13:15" ];
        };
      };
    })

    (mkIf cfg.vaapi {
      # 1. enable vaapi on OS-level
      nixpkgs.config.packageOverrides = pkgs: {
        vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
      };
      hardware.opengl = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
          intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        ];
      };
    })

    (mkIf cfg.batterysave {
      systemd.targets.ac = {
        description = "On AC power";
        unitConfig = {
          DefaultDependencies = "no";
          Conflicts = "battery.target";
        };
      };

      systemd.targets.battery = {
        description = "On battery power";
        unitConfig = {
          DefaultDependencies = "no";
          Conflicts = "ac.target";
        };
      };

      services.udev.extraRules = ''
        SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl start battery.target"
        SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl start ac.target"
      '';

      systemd.timers.nixos-upgrade = {
        wantedBy = [ "ac.target" ];
        partOf = [ "ac.target" ];
      };

      systemd.timers.nix-gc = {
        wantedBy = [ "ac.target" ];
        partOf = [ "ac.target" ];
      };

      systemd.timers.nix-optimise = {
        wantedBy = [ "ac.target" ];
        partOf = [ "ac.target" ];
      };
    })
  ];
}
