{ config, lib, ... }:

{
  boot.plymouth.logo = lib.mkDefault ./nixos.png;
  nixpkgs.overlays = [(self: super: {
    splash-boot = super.callPackage ./pkgs.nix {
      theme       = config.boot.plymouth.theme;
      logo        = config.boot.plymouth.logo;
      name        = config.boot.plymouth.name;
      colorNormal = config.boot.plymouth.colorNormal;
      colorTinted = config.boot.plymouth.colorTinted;
    };
  })];
}
