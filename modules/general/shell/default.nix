{config, lib, packages, ...}:
let
  cfg = config.shincraft.shell.nvim;
in
with lib;
{
  imports =
  [
    ./zsh
    ./vim
    ./packages.nix
  ];

  config = (mkIf cfg.enable {
    environment.systemPackages = [packages.nvim];
  });
}
