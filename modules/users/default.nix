{ config, lib, pkgs, ... }:
with lib;
with types;  
let
  userModule = { name, config, ... }:
  {
    options = {
      home-config = {
        packages = mkOption {
          default = [];
          type    = listOf package;
        };
        git = {
          enable    = mkOption {
            default = false;
            type    = bool;
          };
          userName  = mkOption {
            default = "";
            type    = str;
          };
          userEmail = mkOption {
            default = "";
            type    = str;
          };
        };
        vscode.enable   = mkEnableOption "Enable VSCodium";
        chromium.enable = mkEnableOption "Enable Chromium Browser";
        kube.enable     = mkEnableOption "Install tools for managing kube cluster";
        nodejs.enable   = mkEnableOption "Install yarn";
        database.enable = mkEnableOption "Install tools for database work";
        ssh = {
          enable    = mkOption {
            default = false;
            type    = bool;
          };
          listAlias = mkOption {
            default = {};
            type    = attrs;
          };
        };
      };
      user-config = {
        uid = mkOption {
          default     = "1000";
          type        = ints.u16;
          example     = "1000";
          description = ''
          '';
        };
        extraGroups = mkOption {
          default     = [ "" ];
          type        = listOf str;
          example     = [ "wheel" "disk" ];
          description = ''
          '';
        };
      };  
    };
  };
  vscodeConfig = (import ./vscodium.nix){inherit pkgs;};
in
{
  options.custom.users = mkOption {
    type = attrsOf ( submodule userModule );
  };

  config =
  let
    mapUsers = f: attrsets.mapAttrs f config.custom.users;
  in
  {
    users.users = mapUsers ( name: cfg: if name != "root" then {
      isNormalUser = true;
      uid          = cfg.user-config.uid;
      group        = "users";
      extraGroups  = cfg.user-config.extraGroups;
      useDefaultShell = true;
    } else {});

    home-manager.users = mapUsers ( name: cfg: {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      home.username = name;

      home.sessionPath = [
        #"$HOME/.local/bin"
      ];

      home.sessionVariables = {
        #FOO = "BAR";
        #BAR = "${config.home.sessionVariables.FOO} World!";
      };

      home.packages = with pkgs; mkMerge 
      [
        cfg.home-config.packages
        (mkIf cfg.home-config.kube.enable [
          kubecm
          kubectl
          kubecolor
          kubectx
          kube-bench
          #kubernetes-helm
          (wrapHelm kubernetes-helm {
            plugins = with pkgs.kubernetes-helmPlugins; [
              helm-secrets
              helm-diff
              helm-git
            ];
          })
          helmfile
          azure-cli
          terraform
          (grafana-loki.overrideAttrs (oldAttrs: {
              subPackages = [ "cmd/logcli" ];
              preFixup = "";
            }))
        ])
        (mkIf ( cfg.home-config.kube.enable && config.custom.gui.enable ) [
          openlens
        ])
        (mkIf ( cfg.home-config.database.enable && config.custom.gui.enable ) [
          dbeaver
        ])
        (mkIf cfg.home-config.nodejs.enable [
          nodejs
          yarn
          yarn2nix
        ])
        (mkIf config.custom.system.docker [ 
          dive
        ])
        [
        ]
      ];

      programs = {
        btop = {
          enable = true;
          settings = {
            # https://github.com/aristocratos/btop#configurability
            color_theme = "Default";
            theme_background = false;
          };
        };
        vscode = (mkIf cfg.home-config.vscode.enable vscodeConfig);
        git = (mkIf cfg.home-config.git.enable {
          # package = pkgs.gitAndTools.gitFull;
          enable = cfg.home-config.git.enable;
          delta.enable = false;
          delta.options = {
            decorations = {
              commit-decoration-style = "bold yellow box ul";
              file-decoration-style = "none";
              file-style = "bold yellow box";
              hunk-header-decoration-style = "yellow box";
            };
            line-number = {
              line-numbers = true;
              line-numbers-right-style = "cyan";
              line-numbers-left-style = "cyan";
              line-numbers-zero-style = "#cccccc";
              line-numbers-minus-style = "bold #aa0000";
              line-numbers-plus-style = "bold #00aa00";
            };
            side-by-side = true;
            features = "decorations line-number";
            whitespace-error-style = "22 reverse";
          };
          difftastic.enable = true;
          userName = cfg.home-config.git.userName;
          userEmail = cfg.home-config.git.userEmail;
          aliases = {
            co = "checkout";
            c = "commit";
            ca = "commit --amend";
            s = "status";
            st = "status";
            b = "branch";
            p = "pull --rebase";
            pu = "push";
          };
          ignores = [ "*~" "*.swp" ];
          extraConfig = {
            init.defaultBranch = "master";
            core.editor = "vim";
            #protocol.keybase.allow = "always";
            #credential.helper = "store --file ~/.git-credentials";
            pull.rebase = "false";
          };
        });
        ssh = (mkIf cfg.home-config.ssh.enable {
          enable = true;
          compression = true;
          controlMaster = "yes";
          controlPersist = "10m";
          #hashKnownHost = false;
          matchBlocks = cfg.home-config.ssh.listAlias;
        });
        chromium = (mkIf cfg.home-config.chromium.enable {
          enable = true;
        });
      };

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "21.03";
    });
  };
}
