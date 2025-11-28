{ config, lib, pkgs, ... }:
let
  cfg = config.shincraft.shell.vim;
  vimrc = import ./vimrc.nix;
  #markdown-preview-nvim-bin = pkgs.callPackage ./markdown-preview-nvim-bin.nix {  };
  #markdown-preview-nvim = pkgs.vimPlugins.markdown-preview-nvim.overrideAttrs (old: {
  #  postInstall = ''
  #    mkdir $target/app/bin
  #    ln -s ${markdown-preview-nvim-bn}/bin/markdown-preview-linux $target/app/bin/markdown-preview-linux
  #  '';
  #});
in
with lib;
{
  config = mkMerge [
    (mkIf cfg.enable {
      environment.variables = { EDITOR = "vim"; };

      environment.systemPackages = with pkgs; [
        ((vim-full.override {  }).customize{
          name = "vim";
          vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
            start = [
              vim-startify # This plugin provides a start screen for Vim.
              vim-nix
              vim-lastplace
              # The NERDTree is a file system explorer for the Vim editor.
              nerdtree
              nerdtree-git-plugin
              vim-buffergator # Buffergator is a plugin for listing, navigating between, and selecting buffers to edit
              tagbar # Tagbar is a Vim plugin that provides an easy way to browse the tags of the current file and get an overview of its structure.
              # Lean & mean status/tabline for vim that's light as air.
              vim-airline
              vim-airline-themes
              vim-airline-clock
              #
              vim-easy-align
              vim-multiple-cursors
              vim-indent-guides
              syntastic # Syntastic is a syntax checking plugin for Vim
              delimitMate # This plug-in provides automatic closing of quotes, parenthesis, brackets, etc.
              ## Always load the vim-devicons as the very last one
              vim-devicons # Add icons to your plugins
              #markdown-preview-nvim
            ];
            opt = [ elm-vim ];
          };
          vimrcConfig.customRC = vimrc.config;
        }
      )];
    })
  ];
}
