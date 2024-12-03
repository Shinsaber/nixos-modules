{
  description = "shinsaber-nixos-modules";

  inputs = {
    nix-unstable.url = "nixpkgs/nixos-unstable";
    nixos.url = "nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    nixvim = {
      url = "github:nix-community/nixvim";
      # If using a stable channel you can use `url = "github:nix-community/nixvim/nixos-<version>"`
      inputs.nixpkgs.follows = "nix-unstable";
    };
  };

  outputs = { self, nixos, home-manager, nixvim, ... }:
    let
      system = "x86_64-linux";
      nixvim' = nixvim.legacyPackages.${system};
      nixvimModule = {
        module = import ./packages/nvim;
      };
      nvim = nixvim'.makeNixvimWithModule nixvimModule;
    in
    {
      nixos = nixos;
      packages.${system}.nixvim = nvim;
      nixosModules = {
        general = {
          imports = [
            ./modules/general
            home-manager.nixosModules.home-manager
            { _module.args.packages = { nixvim = nvim; }; }
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
