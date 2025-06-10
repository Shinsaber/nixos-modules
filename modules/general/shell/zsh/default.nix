{ config, lib, pkgs, ... }:

let cfg = config.shincraft.shell.zsh;
in
with lib;
with types;
{
  config = mkMerge [
    (mkIf cfg.enable {
      nixpkgs.overlays = [
        (self: super: {
          zsh-forgit              = super.callPackage ./plugin/zsh-forgit.nix { };
          zsh-autopair            = super.callPackage ./plugin/zsh-autopair.nix { };
          zsh-auto-notify         = super.callPackage ./plugin/zsh-auto-notify.nix { };
          zsh-fzf-history-search  = super.callPackage ./plugin/zsh-fzf-history-search.nix { };
        })
      ];

      programs.command-not-found.enable = true;
      environment.systemPackages = with pkgs; [
        bat
        fd
        ripgrep
        fzf
        libnotify
        difftastic
      ];
      programs.zsh = {
        enable = true;
        autosuggestions.enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        promptInit = ''
          ${pkgs.any-nix-shell}/bin/any-nix-shell zsh | source /dev/stdin
        '';

        shellAliases = {
          l   ="ls -Ah";
          la  ="ls -ah";
          ll  ="ls -lh";
          lla ="ls -lah";
          rm  ="rm -i";
          cp  ="cp -i";
          mv  ="mv -i";

          ls   ="ls --color=tty";
          grep = "grep --color=auto";
          cat  = "bat";

          kctx    = "kubectx";
          kns     = "kubens";
          kubectl = "kubecolor";
        };

        ohMyZsh = {
          enable = true;
          plugins = [
            "helm"
            "sudo"
            "forgit"
            "docker"
            "battery"
            "kubectl"
            "autopair"
            "colorize"
            "auto-notify"
            "you-should-use"
            "colored-man-pages"
            "command-not-found"
            "zsh-interactive-cd"
            #"zsh-fzf-history-search"
            "history-substring-search"
          ];
          customPkgs = with pkgs; [
            zsh-forgit
            #zsh-fzf-history-search
            zsh-autopair
            zsh-auto-notify
            zsh-you-should-use
          ];
        };
      };
      environment.etc.zshrc.text = ''
        source ${./zshrc.sh}
        source ${./fzf.sh}
      '';

      # Set as user shell.
      users = {
        defaultUserShell = pkgs.zsh;
        #users.root.shell = pkgs.zsh;
      };
    })

    (mkIf cfg.powerlevel10k.enable {
      programs.zsh.promptInit = ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${./p10k.zsh}
      '';
    })

    (mkIf (cfg.powerlevel10k.enable && cfg.powerlevel10k.setupInstantPrompt) {
      programs.zsh.interactiveShellInit = ''
        source ${./p10k-instant-prompt.zsh}
      '';
    })
  ];
}
