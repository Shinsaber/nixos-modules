{
  # Telescope config
  plugins.telescope = {
    enable = true;
    extensions = {
      file-browser = {
        enable = true;
        settings.hidden = { file_browser = false; folder_browser = true; };
      };
      media-files = { 
        enable = true;
        dependencies.chafa.enable = true;
      };
      ui-select.enable = true;
      undo.enable = true;
    };
    settings.defaults = {
      sorting_strategy = "ascending";
      layout_config = {
        horizontal = {
          prompt_position = "top";
        };
      };
    };
  };
  plugins.which-key.registrations."<leader>f" = {name = "Telescope find";};
  colorschemes.onedark.settings.highlights = {
    # https://github.com/nvim-telescope/telescope.nvim/blob/fac83a556e7b710dc31433dec727361ca062dbe9/plugin/telescope.lua#L11
    # Sets the highlight for selected items within the picker.
    TelescopeSelection      = { fg = "$fg"; fmt = "bold"; };
    TelescopeSelectionCaret = { fg = "$green"; bg = "$green"; fmt = "bold"; };
    TelescopeMultiSelection = { fg = "#b7bae0"; fmt = "bold"; };
    TelescopeMultiIcon      = { fg = "$black"; bg = "$black"; fmt = "bold"; };

    TelescopePreviewTitle  = { fg = "$grey"; fmt = "bold"; };
    TelescopePreviewNormal = { bg = "$bg0";};
    TelescopePreviewBorder = { fg = "$bg0"; bg = "$bg0";};

    TelescopePromptTitle   = { fg = "$cyan"; fmt = "bold"; };
    TelescopePromptPrefix  = { fg = "$dark_red"; fmt = "bold"; };
    TelescopePromptCounter = { fg = "$grey"; };
    TelescopePromptNormal  = { fg = "$light_grey"; bg = "$bg3"; fmt = "bold"; };
    TelescopePromptBorder  = { fg = "$bg3"; bg = "$bg3"; };

    TelescopeResultsTitle  = { fg = "$grey"; fmt = "bold"; };
    TelescopeResultsNormal = { bg = "$black";};
    TelescopeResultsBorder = { fg = "$black"; bg = "$black";};

    # Used for highlighting characters that you match.
    TelescopeMatching = { fg = "$dark_purple"; fmt = "bold"; };
  };
  keymaps = [
    {
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<cr>";
      options= {
        silent = false;
        desc = "Find files ";
      };
    }
    {
      key = "<leader>fg";
      action = "<cmd>Telescope live_grep<cr>";
      options = {
        silent = false;
        desc = "Live Grep";
      };
    }
    {
      key = "<leader>fb";
      action = "<cmd>Telescope buffers<cr>";
      options = {
        silent = false;
        desc = "Telescope buffers";
      };
    }
    {
      key = "<leader>fh";
      action = "<cmd>Telescope help_tags<cr>";
      options = {
        silent = false;
        desc = "Telescope help_tags";
      };
    }
  ];
}