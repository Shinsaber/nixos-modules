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
        #vuels.enable = true;
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



  #map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', 'Hover documentation')
  #map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', 'Go to definition')
  #map('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', 'Go to declaration')
  #map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', 'Go to implementation')
  #map('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', 'Go to type definition')
  #map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', 'Go to reference')
  #map('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', 'Show function signature')
  #map('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', 'Rename symbol')
  #map('n', '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', 'Format file')
  #map('x', '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', 'Format selection')
  #map('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', 'Execute code action')