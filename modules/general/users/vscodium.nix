{pkgs, ... }:
{
  enable = true;
  package = (pkgs.vscodium.override {
    commandLineArgs = "--ozone-platform=x11";
  });
  mutableExtensionsDir = false;
  enableUpdateCheck = false;
  enableExtensionUpdateCheck = false;
  extensions = with pkgs.vscode-extensions; [
    # Nix file code
    bbenoist.nix
    jnoortheen.nix-ide
    # Java
    redhat.java
    # The Remote - SSH extension lets you use any remote machine with a SSH server as your development environment. This can greatly simplify development and troubleshooting in a wide variety of situations.
    ms-vscode-remote.remote-ssh
    # It helps you to easily access your projects, no matter where they are located. Don't miss those important projects anymore.
    alefragnani.project-manager
    # LanguageTool integration for VS Code
    davidlday.languagetool-linter

    #ms-toolsai.jupyter
    #johnpapa.vscode-peacock

    # All you need for Markdown (keyboard shortcuts, table of contents, auto preview and more).
    yzhang.markdown-all-in-one
    # Rich PlantUML support for Visual Studio Code.
    jebbs.plantuml
    # Prettier is an opinionated code formatter. It enforces a consistent style by parsing your code and re-printing it with its own rules that take the maximum line length into account, wrapping code when necessary.
    esbenp.prettier-vscode
    # This extension integrates GitLab into Visual Studio Code.
    gitlab.gitlab-workflow

    #vscodevim.vim
    redhat.vscode-yaml
    # Java
    redhat.java

  ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "vscode-drawio";
        publisher = "hediet";
        version = "1.6.6";
        sha256 = "sha256-SPcSnS7LnRL5gdiJIVsFaN7eccrUHSj9uQYIQZllm0M=";
      }
      # Puts a small, bored cat, an enthusiastic dog, a feisty snake, a rubber duck, or Clippy 📎 in your code editor.
      #tonybaloney.vscode-pets
      {
        name = "vscode-pets";
        publisher = "tonybaloney";
        version = "1.25.1";
        sha256 = "sha256-as3e2LzKBSsiGs/UGIZ06XqbLh37irDUaCzslqITEJQ=";
      }
      # Dendron is an open-source, local-first, markdown-based, note-taking tool.
      {
        name = "dendron";
        publisher = "dendron";
        version = "0.124.0";
        sha256 = "sha256-/hxgmmiMUfBtPt5BcuNvtXs3LzDmPwDuUOyDf2udHws=";
      }
      {
        name = "dendron-paste-image";
        publisher = "dendron";
        version = "1.1.1";
        sha256 = "sha256-SlW8MEWBgf8cJsdSzeegqPiAlEvlnrxuvrJJdhHwq2E=";
      }
      #dendron.dendron-markdown-shortcuts
      # https://marketplace.visualstudio.com/items?itemName=Continue.continue
      # Open-source autopilot for software development - bring the power of ChatGPT to your IDE
      {
        name = "continue";
        publisher = "Continue";
        version = "0.7.64";
        sha256 = "sha256-spZZOgdnx9GWKv1VjbTSAUYX3D64AzQO4jhHtmQ42ck=";
      }
  ];
  userSettings = {
    files.autoSave = "off";
    files.exclude = {
      "**/.git"      = true;
      "**/.svn"      = true;
      "**/.hg"       = true;
      "**/.mvn"      = true;
      "**/CVS"       = true;
      "**/.DS_Store" = true;
      "**/Thumbs.db" = true;
      "/target"      = true;
    };
    nix = {
      enableLanguageServer = true;
      serverPath = "nil";
      formatterPath = "nixpkgs-fmt";
    };
    editor = {
      formatOnSave = true;
      tabSize = 2;
      bracketPairColorization = {
        enabled = true;
        independentColorPoolPerBracketType = false;
      }; 
    };
    languageToolLinter.languageTool.ignoredWordsGlobal = [
      "opnsense"
    ];
    gitlab.showPipelineUpdateNotifications = true;
    hediet.vscode-drawio = {
      offline = true;
      theme = "dark"; # automatic, min, atlas, dark, Kennedy, sketch
      resizeImages = null;
    };
    vscode-pets = {
      petSize = "large";
      position = "explorer";
      petColor = "black";
    };
    projectManager.tags = [
      "Personal"
      "Professional"
      "OpenSource"
    ];
    continue.telemetryEnabled = false;
    redhat.telemetry.enabled = false;
  };
  userTasks = {
    #version = "2.0.0";
    #tasks = [
    #    {
    #    type = "shell";
    #    label = "Hello task";
    #    command = "hello";
    #    }
    #];
  };
}
