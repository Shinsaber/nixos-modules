{
  description = "shinsaber-nixos-modules";

  inputs = {
    nix-unstable.url = "nixpkgs/nixos-unstable";
    nixos.url = "nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      # If using a stable channel you can use `url = "github:nix-community/nixvim/nixos-<version>"`
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = { self, nixos, nix-unstable, home-manager, nixvim, ... }:
    let
      system = "x86_64-linux";
      nixvim' = nixvim.legacyPackages.${system};
      nixvimModule = {
        module = import ./packages/nvim;
      };
      nvim = nixvim'.makeNixvimWithModule nixvimModule;
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
