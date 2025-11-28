{ lib, ... }:

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
          user = {
            name  = mkOption {
              default = "";
              type    = str;
            };
            email = mkOption {
              default = "";
              type    = str;
            };
          };
        };
        vscode.enable   = mkEnableOption "Enable VSCodium";
        chromium.enable = mkEnableOption "Enable Chromium Browser";
        kube.enable     = mkEnableOption "Install tools for managing kube cluster";
        nodejs.enable   = mkEnableOption "Install yarn";
        java.enable     = mkEnableOption "Install Java tool";
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
in
{
  imports = [
    ./gui
    ./system
    ./shell
    ./tools
    ./users
  ];

  options = {
    boot.plymouth = {
      name = mkOption {
        default = "NixOS";
        type    = str;
      };
      colorNormal = mkOption {
        default = "Color(0.2400, 0.3500, 0.5900)";
        type    = str;
      };
      colorTinted = mkOption {
        default = "Color(0.3600, 0.5200, 0.6700)";
        type    = str;
      };
    };
    shincraft = {
      users  = mkOption {
        type = attrsOf ( submodule userModule );
      };
      gui = {
        enable = mkEnableOption "Enable Plasma gui";
        audio.pipewire.enable = mkEnableOption "Enable pipewire instead of pulseaudio";
        plasma = {
          enable     = mkEnableOption "Enable Plasma wayland gui";
          kdeconnect = mkEnableOption "Enable KDE connect <3";
        };
        pkgs = {
          game.enable    = mkEnableOption "Enable gui game package";
          art.enable     = mkEnableOption "Enable gui art package";
          "3d".enable    = mkEnableOption "Enable gui 3D package";
          audio.enable   = mkEnableOption "Enable gui audio package";
          video.enable   = mkEnableOption "Enable gui vidéo package";
          android.enable = mkEnableOption "Enable android package";
        };
      };
      system = {
        kanata        = mkEnableOption "Enable kanata service";
        vaapi         = mkEnableOption "Hardware Accelerators";
        batterysave   = mkEnableOption "Activate systemd disable service on battery";
        nix = {
          autoUpgrade = mkEnableOption "Activate nix autoUpgrade at 12h-14h";
          optiStore   = mkEnableOption "Enable optimisation et garbage collecte";
        };
        cortex = {
          enable = mkEnableOption "Cortex XDR Agent";

          distributionId = mkOption {
            type = types.str;
            example = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
            description = "Distribution ID for Cortex XDR";
          };

          distributionServer = mkOption {
            type = types.str;
            default = "https://distributions.traps.paloaltonetworks.com/";
            description = "Distribution server URL for Cortex XDR";
          };
        };
      };
      shell = {
        vim.enable    = mkEnableOption "Activate Vim advenced config";
        nixvim.enable = mkEnableOption "Activate NeoVim advenced config";
        tmux.enable   = mkEnableOption "Activate tmux advenced config";
        zsh = {
          enable = mkEnableOption "Activate ZSH as default shell";
          powerlevel10k = {
            enable = mkEnableOption "Setup powerlevel10k for ZSH";
            setupInstantPrompt = mkEnableOption "Setup instant prompt, might crash zsh";
          };
        };
      };
      tools = {
        hack.enable  = mkEnableOption "Activate hacking tools set";
        ia.llama     = mkEnableOption "Activate IA llama tools set";
        java7 = {
          enable = mkEnableOption "Enable OpenJDK 7 for legacy applications";
          setAsDefault = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Si activé, définit Java 7 comme la version par défaut du système.
              ATTENTION: Cela peut casser d'autres applications qui nécessitent des versions plus récentes.
            '';
          };
        };
        virtualisation = {
          docker     = mkEnableOption "Activate Docker virtualisation";
          libvirt    = mkEnableOption "Activate Libvirt virtualisation (qemu)";
          virtualbox = mkEnableOption "Activate VirtualBox virtualisation";
        };
      };
    };
  };
}
