{ config, lib, pkgs, ... }:

let cfg = config.custom.system;
in
with lib;
with types;

{
  options.custom.system = {
    vaapi = mkEnableOption "Hardware Accelerators";
    docker = mkEnableOption "Install docker in the systeme";
    batterysave = mkEnableOption "Activate systemd disable service on battery";
  };

  config = mkMerge [
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

    (mkIf cfg.docker {
      virtualisation.docker = {
        enable = true;
        liveRestore = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
    })
  ];
}
