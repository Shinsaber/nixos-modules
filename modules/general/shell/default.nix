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
    # Prioritaire sur shell.vim (100) : `vim` n'est alors qu'un alias zsh vers nvim
    environment.variables.EDITOR = mkOverride 90 "nvim";
    programs.zsh.shellAliases = {
      vim = "nvim";
    };
  });
}
