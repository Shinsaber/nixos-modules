{ config, lib, pkgs, unstable, ... }:
with lib;
with types;  
let
  vscodeConfig = (import ./vscodium.nix){pkgs = unstable;};

  # Conversion des alias SSH de l'ancien format home-manager (`programs.ssh.matchBlocks`,
  # clés en camelCase) vers `programs.ssh.settings` (directives OpenSSH).
  # Les clés déjà au format OpenSSH (ex. `HostName`) sont conservées telles quelles.
  sshLegacyKeys = {
    hostname            = "HostName";
    user                = "User";
    port                = "Port";
    identityFile        = "IdentityFile";
    identitiesOnly      = "IdentitiesOnly";
    identityAgent       = "IdentityAgent";
    proxyCommand        = "ProxyCommand";
    proxyJump           = "ProxyJump";
    forwardAgent        = "ForwardAgent";
    forwardX11          = "ForwardX11";
    forwardX11Trusted   = "ForwardX11Trusted";
    localForwards       = "LocalForward";
    remoteForwards      = "RemoteForward";
    dynamicForwards     = "DynamicForward";
    serverAliveInterval = "ServerAliveInterval";
    serverAliveCountMax = "ServerAliveCountMax";
    sendEnv             = "SendEnv";
    setEnv              = "SetEnv";
    compression         = "Compression";
    checkHostIP         = "CheckHostIP";
    certificateFile     = "CertificateFile";
    addressFamily       = "AddressFamily";
    addKeysToAgent      = "AddKeysToAgent";
    hashKnownHosts      = "HashKnownHosts";
    userKnownHostsFile  = "UserKnownHostsFile";
    controlMaster       = "ControlMaster";
    controlPath         = "ControlPath";
    controlPersist      = "ControlPersist";
    kexAlgorithms       = "KexAlgorithms";
  };
  sshAliasToSettings = alias:
    let
      extraOptions = alias.extraOptions or {};
      header =
        if alias ? match then { header = "Match ${alias.match}"; }
        else if alias ? host then { header = "Host ${alias.host}"; }
        else {};
      renamed = mapAttrs' (key: value: nameValuePair (sshLegacyKeys.${key} or key) value)
        (removeAttrs alias [ "extraOptions" "match" "host" ]);
    in
    header // renamed // extraOptions;
in
{
  config =
  let
    mapUsers = f: attrsets.mapAttrs f config.shincraft.users;
  in
  {
    users.users = mapUsers ( name: cfg: if name != "root" then {
      isNormalUser = true;
      uid          = cfg.user-config.uid;
      group        = "users";
      extraGroups  = cfg.user-config.extraGroups;
      useDefaultShell = true;
    } else {});
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
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
          stern
          #kubernetes-helm
          (wrapHelm kubernetes-helm {
            plugins = with pkgs.kubernetes-helmPlugins; [
              #helm-secrets
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
        (mkIf ( cfg.home-config.kube.enable && config.shincraft.gui.enable ) [
          freelens
          jet-pilot
        ])
        (mkIf ( cfg.home-config.database.enable && config.shincraft.gui.enable ) [
          dbeaver-bin
        ])
        (mkIf cfg.home-config.nodejs.enable [
          nodejs
          yarn
          yarn2nix
        ])
        (mkIf config.shincraft.tools.virtualisation.docker [ 
          dive
        ])
        (mkIf cfg.home-config.java.enable [ 
          sbt
        ])
        [
        ]
      ];

      programs = {
        java.enable = cfg.home-config.java.enable;
        btop = {
          enable = true;
          settings = {
            # https://github.com/aristocratos/btop#configurability
            color_theme = "Default";
            theme_background = false;
          };
        };
        difftastic = {
          enable = true;
          git.enable = true;
        };
        delta = {
          enable = false;
          options = {
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
        };
        vscode = (mkIf cfg.home-config.vscode.enable vscodeConfig);
        git = (mkIf cfg.home-config.git.enable {
          # package = pkgs.gitAndTools.gitFull;
          enable = cfg.home-config.git.enable;
          settings = {
            user = {
              name  = cfg.home-config.git.user.name;
              email = cfg.home-config.git.user.email;
            };
            alias = {
              co = "checkout";
              c  = "commit";
              ca = "commit --amend";
              s  = "status";
              st = "status";
              b  = "branch";
              p  = "pull --rebase";
              pu = "push";
            };
            init.defaultBranch = "main";
            core.pager = "bat --paging=always";
            #protocol.keybase.allow = "always";
            #credential.helper = "store --file ~/.git-credentials";
            pull.rebase = "false";
          };
          ignores = [ "*~" "*.swp" ];
        });
        ssh = (mkIf cfg.home-config.ssh.enable {
          enable = true;
          # Les anciennes valeurs par défaut de home-manager sont reprises explicitement dans "*"
          enableDefaultConfig = false;
          settings = mkMerge [
            {
              "*" = {
                ForwardAgent        = false;
                AddKeysToAgent      = "no";
                Compression         = true;
                ServerAliveInterval = 0;
                ServerAliveCountMax = 3;
                HashKnownHosts      = false;
                UserKnownHostsFile  = "~/.ssh/known_hosts";
                ControlMaster       = "auto";
                ControlPath         = "~/.ssh/master-%r@%n:%p";
                ControlPersist      = "10m";
              };
            }
            (mapAttrs (_: sshAliasToSettings) cfg.home-config.ssh.listAlias)
          ];
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
