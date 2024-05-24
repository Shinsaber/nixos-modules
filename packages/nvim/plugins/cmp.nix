{
  # CMP config
  plugins = {
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-d>"     = "cmp.mapping.scroll_docs(-4)";
          "<C-e>"     = "cmp.mapping.close()";
          "<C-f>"     = "cmp.mapping.scroll_docs(4)";
          "<CR>"      = "cmp.mapping.confirm({ select = true })";
          "<S-Tab>"   = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          "<Tab>"     = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
        };
        sources = [
          {name = "nvim_lsp";}
          {name = "buffer";}
          {name = "treesitter";}
        ];
      };
    };
    #cmp-nvim-lsp.enable = true;
    #cmp-buffer.enable = true;
    #cmp-treesitter.enable = true;
  };
  #plugins.which-key.registrations."<leader>f" = {name = "Telescope find";};
  colorschemes.onedark.settings.highlights = {
    #TelescopeMultiIcon      = { fg = "$black"; bg = "$black"; fmt = "bold"; };
  };
  keymaps = [
    #{
    #  key = "<leader>ff";
    #  action = "<cmd>Telescope find_files<cr>";
    #  options= {
    #    silent = false;
    #    desc = "Find files ";
    #  };
    #}
  ];
}
