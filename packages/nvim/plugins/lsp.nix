{ pkgs, ... }:
{
  # LSP config
  plugins = {
    lsp = {
      enable = true;
      servers = {
        nil_ls = {
          enable = true;
          settings.formatting.command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
        };
        yamlls.enable = true;
        jsonls.enable = true;
        bashls.enable = true;
        ansiblels.enable = false;
        terraformls.enable = true;
        dockerls.enable = true;
        docker_compose_language_service.enable = true;
        helm_ls.enable = true;
        nginx_language_server.enable = true;
        # Prog
        java_language_server.enable = true;
        kotlin_language_server.enable = true;
        eslint.enable = true;
        elmls.enable = true;
        ts_ls.enable = true;
        rust_analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
        };
      };
    };
    lspkind = {
      enable = true;
      cmp.enable = true;
    };
    lsp-format = {
      enable = true;
    };
    #conform-nvim = {
    #enable = true;  };
  };

  # Configuration des groupes Which-key pour l'organisation des raccourcis
  plugins.which-key.settings.spec = [
    {
      __unkeyed = "<leader>l";
      group     = "LSP";
    }
    {
      __unkeyed = "<leader>d";
      group     = "Diagnostics";
    }
  ];

  colorschemes.onedark.settings.highlights = {
    #TelescopeMultiIcon      = { fg = "$black"; bg = "$black"; fmt = "bold"; };
  };

  keymaps = [
    # Raccourcis pour la navigation des diagnostics
    {
      key = "]d";
      action.__raw = "function() vim.diagnostic.goto_next() end";
      options = {
        silent = true;
        desc = "Aller au diagnostic suivant";
      };
    }
    {
      key = "[d";
      action.__raw = "function() vim.diagnostic.goto_prev() end";
      options = {
        silent = true;
        desc = "Aller au diagnostic précédent";
      };
    }
    {
      key = "]e";
      action.__raw = "function() vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR}) end";
      options = {
        silent = true;
        desc = "Aller à l'erreur suivante";
      };
    }
    {
      key = "[e";
      action.__raw = "function() vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR}) end";
      options = {
        silent = true;
        desc = "Aller à l'erreur précédente";
      };
    }
    {
      key = "]w";
      action.__raw = "function() vim.diagnostic.goto_next({severity = vim.diagnostic.severity.WARN}) end";
      options = {
        silent = true;
        desc = "Aller au warning suivant";
      };
    }
    {
      key = "[w";
      action.__raw = "function() vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.WARN}) end";
      options = {
        silent = true;
        desc = "Aller au warning précédent";
      };
    }
    # Raccourcis avec leader pour les diagnostics
    {
      key = "<leader>dd";
      action.__raw = "vim.diagnostic.open_float";
      options = {
        silent = true;
        desc = "Afficher les diagnostics de la ligne courante";
      };
    }
    {
      key = "<leader>dl";
      action = "<cmd>Telescope diagnostics bufnr=0<cr>";
      options = {
        silent = true;
        desc = "Liste des diagnostics du buffer courant";
      };
    }
    {
      key = "<leader>dL";
      action = "<cmd>Telescope diagnostics<cr>";
      options = {
        silent = true;
        desc = "Liste de tous les diagnostics";
      };
    }
    {
      key = "<leader>dq";
      action.__raw = "vim.diagnostic.setloclist";
      options = {
        silent = true;
        desc = "Ajouter les diagnostics à la location list";
      };
    }
    # Actions LSP courantes
    {
      key = "gd";
      action.__raw = "vim.lsp.buf.definition";
      options = {
        silent = true;
        desc = "Aller à la définition";
      };
    }
    {
      key = "gD";
      action.__raw = "vim.lsp.buf.declaration";
      options = {
        silent = true;
        desc = "Aller à la déclaration";
      };
    }
    {
      key = "gr";
      action.__raw = "vim.lsp.buf.references";
      options = {
        silent = true;
        desc = "Lister les références";
      };
    }
    {
      key = "gi";
      action.__raw = "vim.lsp.buf.implementation";
      options = {
        silent = true;
        desc = "Aller à l'implémentation";
      };
    }
    {
      key = "K";
      action.__raw = "vim.lsp.buf.hover";
      options = {
        silent = true;
        desc = "Afficher la documentation";
      };
    }
    {
      key = "<leader>lf";
      action.__raw = "vim.lsp.buf.format";
      options = {
        silent = true;
        desc = "Formater le code";
      };
    }
    {
      key = "<leader>lr";
      action.__raw = "vim.lsp.buf.rename";
      options = {
        silent = true;
        desc = "Renommer le symbole";
      };
    }
    {
      key = "<leader>la";
      action.__raw = "vim.lsp.buf.code_action";
      options = {
        silent = true;
        desc = "Actions de code";
      };
    }
  ];
}
