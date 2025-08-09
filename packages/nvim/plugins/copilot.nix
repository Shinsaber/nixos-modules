{
  plugins = {
    copilot-chat = {
      enable = true;
      autoLoad = true;
      settings = {
        answer_header = " ";
        error_header = " ";
        question_header = "󰙊 ";
        auto_insert_mode = true;
      };
    };
    copilot-lua = {
      enable = true;
      autoLoad = true;
    };
  };
  plugins.which-key.settings.spec = [
    {
      __unkeyed = "<leader>c";
      group = "GitHub Copilot";
    }
  ];

  keymaps = [
    {
      key = "<leader>cp";
      action = "<cmd>CopilotChatPrompts<cr>";
      options = {
        silent = false;
        desc = "Selecting prompts";
      };
    }
    {
      key = "<leader>cm";
      action = "<cmd>CopilotChatModels<cr>";
      options = {
        silent = false;
        desc = "Selecting models";
      };
    }
    {
      key = "<leader>ca";
      action = "<cmd>CopilotChatAgents<cr>";
      options = {
        silent = false;
        desc = "Selecting agents";
      };
    }
    {
      key = "<leader>cc";
      action = "<cmd>CopilotChatToggle<cr>";
      options = {
        silent = false;
        desc = "Toggle chat window";
      };
    }
    {
      key = "<leader>cr";
      action = "<cmd>CopilotChatReset<cr>";
      options = {
        silent = false;
        desc = "Reset chat window";
      };
    }
    {
      key = "<leader>cs";
      action = "<cmd>CopilotChatSave ";
      options = {
        silent = false;
        desc = "Save chat history";
      };
    }
  ];
}

