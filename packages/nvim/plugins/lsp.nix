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
        ansiblels.enable = true;
        terraformls.enable = true;
        dockerls.enable = true;
        docker_compose_language_service.enable = true;
        helm_ls.enable = true;
        nginx_language_server.enable = true;
        # Prog
        java_language_server.enable = true;
        kotlin_language_server.enable = true;
        eslint.enable = true;
        vuels.enable = false;
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
