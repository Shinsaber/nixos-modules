{
  description = "shinsaber-nixos-modules";

  inputs = {
    nix-unstable.url = "nixpkgs/nixos-unstable";
    nixos.url        = "nixpkgs/nixos-23.11";
    home-manager.url = "github:rycee/home-manager/release-23.11";
    nixvim = {
      url = "github:nix-community/nixvim";
      # If using a stable channel you can use `url = "github:nix-community/nixvim/nixos-<version>"`
      inputs.nixpkgs.follows = "nix-unstable";
    };
  };

  outputs = { nixos, home-manager, nixvim, ... }: {
    nixos        = nixos;
    nixosModules = {
      general  = {
        imports = [
          ./modules/general
          nixvim.nixosModules.nixvim
          home-manager.nixosModules.home-manager
        ];
      };
      server   = import ./modules/server;
    };
  };
}
