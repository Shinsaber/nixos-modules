{ config, ... }:

{
  nixpkgs.overlays = [(self: super: {
    splash-boot = super.callPackage ./modules/splash/default.nix {
      theme = config.boot.plymouth.theme;
    };
  })];
}
