{ config, lib, pkgs, ... }:

let cfg = config.shincraft.system;
in
with lib;
with types;

{
  imports = [
    ./splash
    ./proxmox-guest.nix
    ./sops.nix
    ./backup.nix
  ];

  config = mkMerge [
    (mkIf cfg.kanata.enable {
      services.kanata = {
        enable = true;
        keyboards = {
          internalKeyboard = {
            # Liste vide : kanata détecte lui-même les claviers
            devices = cfg.kanata.devices;
            extraDefCfg = "process-unmapped-keys yes";
            config = ''
              (defsrc
                spc j k l ;
              )
              (defvar
                tap-time 200
                hold-time 500
              )
              (defalias
                spc (tap-hold $tap-time $hold-time spc (layer-toggle arrow))
              )
              (deflayer base
                @spc j k l ;
              )
              (deflayer arrow
                _ left down up right
              )
            '';
          };
        };
      };
    })

    (mkIf cfg.vaapi {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
          (intel-vaapi-driver.override { enableHybridCodec = true; })
          libva-vdpau-driver
          libvdpau-va-gl
          intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        ];
      };
    })

    {
      nix = {
        settings = {
          experimental-features = "nix-command flakes";
        };
        registry = {
          unstable = {
            from = {
              id = "unstable";
              type = "indirect";
            };
            to = {
              type  = "github";
              owner = "NixOS";
              ref   = "nixpkgs-unstable";
              repo  = "nixpkgs";
            };
          };
        };
      };
    }
  ];
}
