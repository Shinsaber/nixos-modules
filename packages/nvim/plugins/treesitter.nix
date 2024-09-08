{
  # CMP config
  plugins = {
    treesitter = {
      enable = true;
    };

    treesitter-context = {
      enable = true;
      settings = {
        mode = "topline"; # one of “cursor”, “topline”
      };
    };

    twilight = {
      enable = true;
      settings = {
        treesitter = true;
        dimming = {
          alpha = 0.35;
          color = ["#e0e0e0"];
        };
      };
    };

    indent-blankline = {
      enable = true;
      settings = {
        indent.highlight = [
          "RainbowRedD"
          "RainbowYellowD"
          "RainbowBlueD"
          "RainbowOrangeD"
          "RainbowGreenD"
          "RainbowVioletD"
          "RainbowCyanD"
        ];
        scope = {
          enabled = false;
          show_exact_scope = true;
          #char = "#";
        };
      };
    };

    rainbow-delimiters = {
      enable = true;
      highlight = [
        "RainbowRed"
        "RainbowYellow"
        "RainbowBlue"
        "RainbowOrange"
        "RainbowGreen"
        "RainbowViolet"
        "RainbowCyan"
      ];
    };
  };

  plugins.which-key.settings.spec = [
    {
      __unkeyed = "<leader>h";
      group     = "Highlight";
    }
  ];
  colorschemes.onedark.settings.highlights = {
    #TelescopeMultiIcon      = { fg = "$black"; bg = "$black"; fmt = "bold"; };
  };

  keymaps = [
    {
      key = "<leader>hf";
      action = "<cmd>Twilight<cr>";
      options= {
        silent = false;
        desc = "Highlight fonction";
      };
    }
  ];
}
