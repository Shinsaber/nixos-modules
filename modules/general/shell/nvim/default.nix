{ config, lib, ... }:
let
  cfg = config.shincraft.shell.nvim;
in
with lib;
{
  config = (mkIf cfg.enable {
    programs.nixvim = mkMerge [
      # Global config
      {
        enable = true;
        extraConfigVim = ''
        let mapleader=" "
        nnoremap <SPACE> <Nop>

        " Show line number
        set number
        " Relative number
        set relativenumber
        '';
      }

      # Which-key config
      {
        plugins.which-key= {
          enable = true; 
        };
      }

      # Telescope config
      {
        plugins.telescope = {
          enable = true;
          extensions = {
            file-browser = {
              enable = true;
              settings.hidden = { file_browser = false; folder_browser = true; };
            };
            media-files = { enable = true; };
            ui-select.enable = true;
            undo.enable = true;
          };
        };
        plugins.which-key.registrations."<leader>f" = "Telescope find";
        keymaps = [
          {
            key = "<leader>ff";
            action = "<cmd>Telescope find_files<cr>";
            option = {
              silent = false;
              desc = "Find files ";
            };
          }
          {
            key = "<leader>fg";
            action = "<cmd>Telescope live_grep<cr>";
            option = {
              silent = false;
              desc = "Live Grep";
            };
          }
          {
            key = "<leader>fb";
            action = "<cmd>Telescope buffers<cr>";
            option = {
              silent = false;
              desc = "Telescope buffers";
            };
          }
          {
            key = "<leader>fh";
            action = "<cmd>Telescope help_tags<cr>";
            option = {
              silent = false;
              desc = "Telescope help_tags";
            };
          }
        ];
      }
    ]; 
  });
}
