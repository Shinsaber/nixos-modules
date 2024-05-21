{ config, lib, ... }:
with lib;
mkMerge [
  # Global config
  {
    extraConfigVim = ''
    let mapleader=" "
    nnoremap <SPACE> <Nop>
    set timeoutlen=300

    " Show line number
    set number
    " Relative number
    set relativenumber

    " show existing tab with 2 spaces width
    set tabstop=2
    set shiftround                  "Round spaces to nearest shiftwidth multiple
    set nojoinspaces                "Don't convert spaces to tabs
    " when indenting with '>', use 2 spaces width
    set shiftwidth=2
    " On pressing tab, insert 2 spaces
    set expandtab
    " Be smart when using tabs ;)
    set smarttab
    '';

    colorschemes.onedark = {
      enable = true;
      settings = {
        style = "warmer";
        transparent = true;
      };
    };

    plugins.lualine = {
      enable = true;
      globalstatus = true;
    };
  }

  # Which-key config
  {
    plugins.which-key = {
      enable = true; 
    };
  }

  (import ./plugins/telescope.nix)
  (import ./plugins/lsp.nix)
  (import ./plugins/cmp.nix)
  (import ./plugins/treesitter.nix)
]
