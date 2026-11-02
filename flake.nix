{
  description = "shinsaber-nixos-modules";

  inputs = {
    nix-unstable.url = "nixpkgs/nixos-unstable";
    nixos.url = "nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixos";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixos";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = { self, nixos, nix-unstable, home-manager, nixvim, disko, sops-nix, ... }:
    let
      systems       = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixos.lib.genAttrs systems;

      # Neovim (nixvim) et nixpkgs unstable pour une architecture donnée
      mkNixvim = system: nixvim.legacyPackages.${system}.makeNixvimWithModule {
        pkgs            = import nixos { inherit system; config.allowUnfree = true; };
        module          = import ./packages/nvim;
        extraSpecialArgs = self;
      };
      mkUnstable = system: import nix-unstable { inherit system; config.allowUnfree = true; };
    in
    {
      nixos    = nixos;
      unstable = nix-unstable;
      packages = forAllSystems (system: { nixvim = mkNixvim system; });
      checks   = forAllSystems (system: import ./tests { inherit self nixos system; });
      nixosModules = {
        general = {
          imports = [
            ./packages
            ./modules/general
            home-manager.nixosModules.home-manager
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            # Arguments de module calculés pour l'architecture du host, pas celle du poste
            ({ pkgs, ... }:
              let system = pkgs.stdenv.hostPlatform.system;
              in {
                _module.args.packages = { nixvim = mkNixvim system; };
                _module.args.unstable = mkUnstable system;
              })
          ];
        };
        server = {
          imports = [
            ./packages
            ./modules/server
          ];
        };
      };
    };
}
