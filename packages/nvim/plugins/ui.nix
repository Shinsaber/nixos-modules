{
  plugins = {
    web-devicons.enable = true;
    tmux-navigator.enable = true;
    # Tabs, as understood by any other editor.
    barbar = {
      enable = true;
    };
    # This is a VS Code like winbar
    barbecue = {
      enable = true;
      settings.context_follow_icon_color = true;
    };
    # Botome info bar
    lualine = {
      enable = true;
      settings.options.globalstatus = true;
    };

    # Which-key config
    which-key = {
      enable = true;
    };

    cursorline = {
      enable = true;
      settings.cursorline.enable = true;
      settings.cursorword.enable = false;
    };

    noice = {
      enable = true;
      settings = {
        views = {
          cmdline = {
            backend = "popup";
            relative = "editor";
            position = {
              row = -1;
              col = 2;
            };
            size = {
              width = 60;
              height = "auto";
            };
            border = {
              style = "none";
              padding = [ 0 2 ];
            };
            win_options = {
              #winhighlight = "NormalFloat:RainbowRedD,FloatBorder:FloatBorder";
              winhighlight = {
                NormalFloat = "NoiceCmdlinePopup";
                #Normal = "NoiceCmdline";
                FloatTitle = "NoiceCmdlinePopupTitle";
                #FloatBorder = "NoiceCmdlinePopupBorder";
                #IncSearch   = "";
                #CurSearch   = "";
                Search = "NoiceCmdlinePopupSearch";
              };
            };
          };
          popupmenu = {
            backend = "popup";
            relative = "editor";
            position = {
              row = -2;
              col = 0;
            };
            size = {
              width = 56;
              height = "auto";
              max_height = 10;
            };
            border = {
              style = "none";
              padding = [ 0 4 ];
            };
            win_options = {
              winhighlight = {
                Normal = "NoicePopupmenu"; # change to NormalFloat to make it look like other floats
                #FloatBorder = "NoicePopupmenuBorder"; # border highlight
                CursorLine = "NoicePopupmenuSelected"; # used for highlighting the selected item
                PmenuMatch = "NoicePopupmenuMatch"; # used to highlight the part of the item that matches the input
              };
            };
          };
        };
        cmdline = {
          enabled = true;
          view = "cmdline";
        };
      };
    };
  };

  colorschemes.onedark.settings.highlights = {
    # https://github.com/folke/noice.nvim?tab=readme-ov-file#-highlight-groups
    # Sets the highlight for selected items within the picker.
    NoiceCmdline = { fg = "$fg"; bg = "$black"; fmt = "bold"; };
    NoiceCmdlinePopup = { fg = "$light_grey"; bg = "$black"; fmt = "bold"; };
    NoiceCmdlinePopupTitle = { fg = "$cyan"; fmt = "bold"; };
    NoiceCmdlinePopupSearch = { fg = "$green"; };
    NoicePopupmenu = { fg = "#b7bae0"; bg = "$bg0"; }; # change to NormalFloat to make it look like other floats
    NoicePopupmenuSelected = { bg = "$bg1"; }; # used for highlighting the selected item
    NoicePopupmenuMatch = { fg = "$dark_red"; }; # used to highlight the part of the item that matches the input
  };

  keymaps = [
    {
      key = "<A-x>";
      action = "<cmd>BufferClose<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
    {
      key = "<A-Right>";
      action = "<cmd>BufferNext<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
    {
      key = "<A-Left>";
      action = "<cmd>BufferPrevious<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
    {
      key = "<A-S-Right>";
      action = "<cmd>BufferMoveNext<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
    {
      key = "<A-S-Left>";
      action = "<cmd>BufferMovePrevious<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
    {
      key = "<C-A-s>";
      action = "<C-w>s";
      options = {
        silent = true;
        desc = "Split current window horizontally";
      };
    }
    {
      key = "<C-A-v>";
      action = "<C-w>v";
      options = {
        silent = true;
        desc = "Split current window vertically";
      };
    }
    {
      key = "<C-t>";
      action = "<cmd>TmuxNavigateLeft<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
    {
      key = "<C-s>";
      action = "<cmd>TmuxNavigateDown<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
    {
      key = "<C-r>";
      action = "<cmd>TmuxNavigateUp<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
    {
      key = "<C-n>";
      action = "<cmd>TmuxNavigateRight<cr>";
      options = {
        silent = true;
        desc = "";
      };
    }
  ];
}
