{config, lib, packages, ...}:
let
  cfg = config.shincraft.shell;
in
with lib;
{
  imports =
  [
    ./zsh
    ./vim
    ./tmux
    ./packages.nix
  ];

  config = (mkIf cfg.nixvim.enable {
    environment.systemPackages = [packages.nixvim];
  });
}
