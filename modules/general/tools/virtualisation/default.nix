{ config, lib, pkgs, ... }:
let
  cfg = config.shincraft.tools.virtualisation;
in
with lib;
{
  config = mkMerge [
    (mkIf cfg.libvirt {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = [(pkgs.unstable.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd];
          };
        };
      };
    })

    (mkIf ( cfg.libvirt && config.shincraft.gui.enable ) {
      environment.systemPackages = with pkgs; [
        quickemu
        quickgui
        vagrant
      ];
      programs.virt-manager.enable = true;
    })

    (mkIf cfg.virtualbox {
      virtualisation.virtualbox.host.enable = true;
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
