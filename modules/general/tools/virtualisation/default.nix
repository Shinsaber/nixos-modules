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
        };
      };
    })

    (mkIf ( cfg.libvirt && config.shincraft.gui.enable ) {
      environment.systemPackages = with pkgs; [
        quickemu
        quickgui
      ];
      programs.virt-manager.enable = true;
    })

    (mkIf cfg.virtualbox {
      virtualisation.virtualbox.host.enable = true;
      environment.systemPackages = with pkgs; [
        vagrant
      ];
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
