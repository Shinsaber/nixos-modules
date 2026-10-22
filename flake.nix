{
  description = "shinsaber-nixos-modules";

  inputs = {
    nix-unstable.url = "nixpkgs/nixos-unstable";
    nixos.url = "nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      # If using a stable channel you can use `url = "github:nix-community/nixvim/nixos-<version>"`
      #inputs.nixpkgs.follows = "nixos";
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
      system = "x86_64-linux";
      nixvim' = nixvim.legacyPackages.${system};
      nvim = nixvim'.makeNixvimWithModule {
        pkgs = import nixos { inherit system; config.allowUnfree = true; };
        module = import ./packages/nvim;
        extraSpecialArgs = self;
      };
      pkgsUnstable = import nix-unstable { inherit system; config.allowUnfree = true; };
    in
    {
      nixos = nixos;
      unstable = nix-unstable;
      packages.${system}.nixvim = nvim;
      nixosModules = {
        general = {
          imports = [
            ./packages
            ./modules/general
            home-manager.nixosModules.home-manager
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            { _module.args.packages = { nixvim = nvim; }; }
            { _module.args.unstable = pkgsUnstable; }
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
