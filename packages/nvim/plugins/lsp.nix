{
  # LSP config
  plugins.lsp = {
    enable = true;
    servers = {
      nil_ls.enable = true;
      bashls.enable = true;
      dockerls.enable = true;
      docker-compose-language-service.enable = true;
      helm-ls.enable = true;
    };
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