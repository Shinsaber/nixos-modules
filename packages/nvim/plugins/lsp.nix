{ pkgs, ... }:
{
  # LSP config
  plugins = {
    lsp = {
      enable = true;
      servers = {
        nil-ls = {
          enable = true;
          settings.formatting.command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
        };
        yamlls.enable = true;
        jsonls.enable = true;
        bashls.enable = true;
        ansiblels.enable = true;
        terraformls.enable = true;
        dockerls.enable = true;
        docker-compose-language-service.enable = true;
        helm-ls.enable = true;
        nginx-language-server.enable = true;
        # Prog
        java-language-server.enable = true;
        kotlin-language-server.enable = true;
        eslint.enable = true;
        vuels.enable = true;
        elmls.enable = true;
        tsserver.enable = true;
        rust-analyzer = {
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
