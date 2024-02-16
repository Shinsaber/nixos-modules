{lib, ...}:
with lib;
{
  imports =
  [
    ./zsh
    ./vim
    ./nvim
  ];

  options.custom.shell = {
    vim.enable  = mkEnableOption "Activate Vim advenced config";
    nvim.enable = mkEnableOption "Activate NeoVim advenced config";
    zsh = {
      enable = mkEnableOption "Activate ZSH as default shell";
      powerlevel10k = {
        enable = mkEnableOption "Setup powerlevel10k for ZSH";
        setupInstantPrompt = mkEnableOption "Setup instant prompt, might crash zsh";
      };
    };
  };
}
