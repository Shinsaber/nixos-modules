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

    highlight = {
      RainbowRedD    = {fg = "#8c444a"; bold = true;};
      RainbowYellowD = {fg = "#8c754b"; bold = true;};
      RainbowBlueD   = {fg = "#39668c"; bold = true;};
      RainbowOrangeD = {fg = "#8c6744"; bold = true;};
      RainbowGreenD  = {fg = "#6e8c57"; bold = true;};
      RainbowVioletD = {fg = "#7d4c8c"; bold = true;};
      RainbowCyanD   = {fg = "#3e848c"; bold = true;};
      RainbowRed     = {fg = "#E06C75"; bold = true;};
      RainbowYellow  = {fg = "#E5C07B"; bold = true;};
      RainbowBlue    = {fg = "#61AFEF"; bold = true;};
      RainbowOrange  = {fg = "#D19A66"; bold = true;};
      RainbowGreen   = {fg = "#98C379"; bold = true;};
      RainbowViolet  = {fg = "#C678DD"; bold = true;};
      RainbowCyan    = {fg = "#56B6C2"; bold = true;};
    };

    plugins = {
      lualine = {
        enable = true;
        globalstatus = true;
      };
      # Which-key config
      which-key = {
        enable = true; 
      };
      # Indent-O-matic
      indent-o-matic.enable = true;
    };
  }

  (import ./plugins/telescope.nix)
  (import ./plugins/lsp.nix)
  (import ./plugins/cmp.nix)
  (import ./plugins/treesitter.nix)
]
