{ config, lib, pkgs, ... }:
let
  cfg = config.custom.shell.nvim;
in
with lib;
{
  config = mkMerge [
    (mkIf cfg.enable {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        configure = {
          customRC = ''
            set number
          '';
          packages.myVimPackage = with pkgs.vimPlugins; {
            # loaded on launch
            start = [
              nvim-colorizer-lua
              telescope-nvim
              plenary-nvim
              nvim-tree-lua
            ];
            # manually loadable by calling `:packadd $plugin-name`
            opt = [ ];
          };
        };
      };
    })
  ];
}
