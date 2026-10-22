{ config, lib, ... }:

let
  cfg = config.shincraft.system.proxmoxGuest;

  # Toutes les valeurs du layout en mkDefault pour que le host puisse les surcharger,
  # sauf les `type` : disko s'en sert pour choisir le sous-module (`content`, table…).
  overridable = lib.mapAttrsRecursive (path: v: if lib.last path == "type" then v else lib.mkDefault v);
in
with lib;
{
  config = mkIf cfg.enable (mkMerge [
    {
      services = {
        qemuGuest.enable = true;
        acpid.enable     = true;
        openssh.enable   = true;
      };

      boot.initrd.availableKernelModules = [
        "ata_piix" "uhci_hcd" "sd_mod" "sr_mod"
        "virtio_pci" "virtio_scsi" "virtio_blk" "virtio_net"
      ];
      boot.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];

      # Accès root par clé uniquement (PermitRootLogin = prohibit-password par défaut),
      # utilisé par nixos-anywhere puis par `nixos-rebuild --target-host root@…`.
      users.users.root.openssh.authorizedKeys.keys = cfg.rootSshKeys;
    }

    (mkIf (cfg.firmware == "bios") {
      boot.loader.grub.enable = true;
    })

    # Sans disko, grub doit connaître le disque ; avec disko (layout du module ou du host),
    # il le déduit de la partition EF02.
    (mkIf (cfg.firmware == "bios" && config.disko.devices.disk == {}) {
      boot.loader.grub.device = mkDefault cfg.device;
    })

    (mkIf (cfg.firmware == "uefi") {
      boot.loader = {
        systemd-boot.enable      = true;
        efi.canTouchEfiVariables = true;
      };
    })

    # Disque système : table GPT, partition de boot, racine ext4 sur le reste.
    # Les points de montage sont générés par disko (par label de partition, sans UUID).
    (mkIf cfg.disko {
      disko.devices.disk.main = overridable {
        type    = "disk";
        device  = cfg.device;
        content = {
          type       = "gpt";
          partitions = (if cfg.firmware == "bios" then {
            boot = {
              size     = "1M";
              type     = "EF02";
              priority = 1;
            };
          } else {
            ESP = {
              size     = "512M";
              type     = "EF00";
              priority = 1;
              content  = {
                type         = "filesystem";
                format       = "vfat";
                mountpoint   = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
          }) // {
            root = {
              size    = "100%";
              content = {
                type       = "filesystem";
                format     = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    })
  ]);
}
