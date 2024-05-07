{ config, lib, nixvim, system, nix-unstable, ... }:
let
  cfg = config.shincraft.shell.nvim;

  nixvim' = nixvim.legacyPackages.${system};
  nixvimModule = {
    pkgs = nix-unstable.legacyPackages.${system};
    module = import ./nvim.nix; # import the module directly
    # You can use `extraSpecialArgs` to pass additional arguments to your module files
    #extraSpecialArgs = {
    #};
  };
  nvim = nixvim'.makeNixvimWithModule nixvimModule;
in
with lib;
{
  config = (mkIf cfg.enable {
    #environment.systemPackages = [nvim];
  });
}
