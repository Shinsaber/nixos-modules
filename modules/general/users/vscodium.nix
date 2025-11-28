{pkgs, ... }:
{
  enable = true;
  package = pkgs.vscode;
  mutableExtensionsDir = false;
  profiles.default.enableUpdateCheck = false;
  profiles.default.enableExtensionUpdateCheck = false;
  profiles.default.extensions = with pkgs.vscode-extensions; [
    # Nix file code
    bbenoist.nix
    jnoortheen.nix-ide
    # Java
    redhat.java
    mathiasfrohlich.kotlin
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
    hediet.vscode-drawio
    #continue.continue

    #github.copilot
    #github.copilot-chat
    
    ms-kubernetes-tools.vscode-kubernetes-tools
    redhat.vscode-yaml
    tim-koehler.helm-intellisense

    #vscodevim.vim
    redhat.vscode-yaml

  ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "copilot";
        publisher = "GitHub";
        version = "1.388.0";
        sha256 = "sha256-7RjK8+PNI+rIuRQfCwpvswAiz991dacRO2qYhcv1vhk=";
      }
      {
        name = "copilot-chat";
        publisher = "GitHub";
        version = "0.33.2";
        sha256 = "sha256-8TgwChU+849zSd+/j3pVR/0U96QJV3jLbyf8XhTVnys=";
      }
      # Puts a small, bored cat, an enthusiastic dog, a feisty snake, a rubber duck, or Clippy 📎 in your code editor.
      #tonybaloney.vscode-pets
      {
        name = "vscode-pets";
        publisher = "tonybaloney";
        version = "1.34.0";
        sha256 = "sha256-+4D9QKMB0BsIm8qy4ZNC5H87V21wgLD7ztrYJ/R3UJQ=";
      }
      # Dendron is an open-source, local-first, markdown-based, note-taking tool.
      {
        name = "dendron";
        publisher = "dendron";
        version = "0.124.0";
        sha256 = "sha256-/hxgmmiMUfBtPt5BcuNvtXs3LzDmPwDuUOyDf2udHws=";
      }
      #{
      #  name = "dendron-paste-image";
      #  publisher = "dendron";
      #  version = "1.1.1";
      #  sha256 = "sha256-SlW8MEWBgf8cJsdSzeegqPiAlEvlnrxuvrJJdhHwq2E=";
      #}
      #dendron.dendron-markdown-shortcuts
      {
        name = "kotlin";
        publisher = "fwcd";
        version = "0.2.35";
        sha256 = "sha256-UyiMacHjs8tbziQzrGlP5A+OSNuzIij1yFBTRuM6qmM=";
      }
  ];
  profiles.default.userSettings = {
    terminal.integrated.defaultProfile.linux = "bash";
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
      fontFamily = "'FiraCode Nerd Font', 'Droid Sans Mono', 'monospace', monospace";
      defaultFormatter = "esbenp.prettier-vscode";
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
    "[json]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
  };
  profiles.default.userTasks = {
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
