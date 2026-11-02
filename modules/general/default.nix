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
        vscode.enable   = mkEnableOption "Enable VS Code (pkgs.vscode from nixpkgs unstable) with its extensions";
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
            default     = {};
            type        = attrs;
            example     = { "mon-serveur" = { HostName = "192.168.1.10"; User = "root"; }; };
            description = ''
              Alias SSH, écrits dans `programs.ssh.settings` de home-manager.
              Accepte les directives OpenSSH (`HostName`, `User`, `LocalForward`…) ou
              l'ancien format `matchBlocks` (`hostname`, `user`, `localForwards`…), converti automatiquement.
            '';
          };
        };
      };
      user-config = {
        uid = mkOption {
          default     = 1000;
          type        = ints.u16;
          example     = 1000;
          description = "UID de l'utilisateur";
        };
        extraGroups = mkOption {
          default     = [];
          type        = listOf str;
          example     = [ "wheel" "disk" ];
          description = "Groupes supplémentaires de l'utilisateur";
        };
        hashedPasswordFile = mkOption {
          default     = null;
          type        = nullOr str;
          example     = "/var/lib/secrets/moi-password";
          description = "Fichier contenant le mot de passe haché (`mkpasswd -m yescrypt`), lu à l'activation";
        };
        sopsPassword = mkEnableOption "mot de passe haché lu dans le secret sops `users/<nom>-password` (nécessite shincraft.system.sops)";
        openssh.authorizedKeys = mkOption {
          default     = [];
          type        = listOf str;
          example     = [ "ssh-ed25519 AAAAC3Nza... moi@poste" ];
          description = "Clés SSH publiques autorisées pour cet utilisateur";
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
    (mkRemovedOptionModule [ "shincraft" "system" "batterysave" ] "Retirée : déclarer les cibles ac/battery dans le host si besoin.")
    (mkRemovedOptionModule [ "shincraft" "system" "nix" "autoUpgrade" ] "Retirée : déployer depuis le poste (docs/proxmox.md).")
    (mkRemovedOptionModule [ "shincraft" "system" "nix" "optiStore" ] "Retirée : configurer nix.gc et nix.optimise dans le host.")
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
        default = {};
        type    = attrsOf ( submodule userModule );
      };
      gui = {
        enable = mkEnableOption "Enable GUI environment (fonts, keyboard, bluetooth, printing, basic tools)";
        keyboard = {
          layout  = mkOption {
            type        = str;
            default     = "fr";
            description = "Disposition clavier XKB (`services.xserver.xkb.layout`, reprise en console)";
          };
          variant = mkOption {
            type        = str;
            default     = "bepo";
            example     = "";
            description = "Variante XKB (`services.xserver.xkb.variant`)";
          };
        };
        audio.pipewire.enable = mkOption {
          type        = bool;
          default     = true;
          description = "Serveur audio PipeWire (ALSA, PulseAudio, WirePlumber). `false` : aucun serveur audio configuré.";
        };
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
        kanata        = {
          enable  = mkEnableOption "kanata keyboard remapping (space + jkl; = arrows)";
          devices = mkOption {
            type        = listOf str;
            default     = [];
            example     = [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ];
            description = "Claviers pris en charge par kanata (`ls /dev/input/by-path/`). Liste vide : kanata détecte tous les claviers.";
          };
        };
        vaapi         = mkEnableOption "Hardware Accelerators (Intel VA-API)";
        sops          = {
          enable          = mkEnableOption "Secrets chiffrés avec sops-nix (déchiffrés par la clé SSH host)";
          defaultSopsFile = mkOption {
            type        = nullOr path;
            default     = null;
            example     = literalExpression "./secrets/mavm.yaml";
            description = ''
              Fichier sops par défaut du host. Les modules serveur y cherchent leurs secrets
              sous des noms fixes (`nextcloud/s3-secret`, `romm/db-password`…).
            '';
          };
        };
        backup        = {
          enable    = mkEnableOption "Sauvegardes restic vers S3 (un dépôt et une clé de chiffrement par service)";
          bucket    = mkOption {
            type        = str;
            example     = "backups";
            description = "Bucket S3 commun ; chaque service a son dépôt `<bucket>/<host>/<service>`";
          };
          hostname  = mkOption {
            type        = str;
            example     = "s3.gra.io.cloud.ovh.net";
            description = "Point d'accès S3";
          };
          region    = mkOption {
            type        = str;
            example     = "gra";
            description = "Région S3";
          };
          key       = mkOption {
            type        = str;
            description = "Access key ID ; la clé secrète est le secret sops `backup/s3-secret`";
          };
          startAt   = mkOption {
            type        = str;
            default     = "*-*-* 03:00:00";
            description = "Heure des sauvegardes (format systemd OnCalendar)";
          };
          pruneOpts = mkOption {
            type        = listOf str;
            default     = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6" ];
            description = "Rétention par défaut (`restic forget --prune`)";
          };
          jobs      = mkOption {
            default     = {};
            description = ''
              Sauvegardes par service, remplies par les modules serveur (`nextcloud`, `kanidm`…)
              et complétables par le host. Chaque job a son dépôt et son mot de passe restic,
              secret sops `backup/<job>-password`.
            '';
            type        = attrsOf (submodule {
              options = {
                enable            = mkOption {
                  type        = bool;
                  default     = true;
                  description = "Activer cette sauvegarde";
                };
                paths             = mkOption {
                  type        = listOf str;
                  default     = [];
                  description = "Chemins sauvegardés";
                };
                postgresDatabases = mkOption {
                  type        = listOf str;
                  default     = [];
                  description = "Bases PostgreSQL à dumper (pg_dump) juste avant la sauvegarde";
                };
                prepareCommand    = mkOption {
                  type        = lines;
                  default     = "";
                  description = "Commandes lancées avant la sauvegarde (après les dumps)";
                };
                pruneOpts         = mkOption {
                  type        = nullOr (listOf str);
                  default     = null;
                  description = "Rétention propre à ce job (défaut : `backup.pruneOpts`)";
                };
              };
            });
          };
        };
        proxmoxGuest  = {
          enable      = mkEnableOption "Profil de VM invitée Proxmox (agent QEMU, pilotes virtio, SSH, bootloader)";
          firmware    = mkOption {
            type        = enum [ "bios" "uefi" ];
            example     = "uefi";
            description = ''
              Firmware de la VM dans Proxmox : `bios` (SeaBIOS, grub) ou `uefi` (OVMF, systemd-boot).
              Pas de valeur par défaut : un mauvais choix rend la VM non démarrable.
            '';
          };
          device      = mkOption {
            type        = str;
            default     = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
            description = "Disque système de la VM (cible de grub en BIOS et de disko).";
          };
          disko       = mkEnableOption "Partitionnement du disque système par disko (installation avec nixos-anywhere)";
          rootSshKeys = mkOption {
            type        = listOf str;
            default     = [];
            example     = [ "ssh-ed25519 AAAAC3Nza... moi@poste" ];
            description = "Clés SSH publiques autorisées pour root (installation et déploiement à distance).";
          };
        };
      };
      shell = {
        vim.enable    = mkEnableOption "Activate Vim advanced config";
        nixvim.enable = mkEnableOption "Activate NeoVim advanced config";
        tmux.enable   = mkEnableOption "Activate tmux advanced config";
        weatherCity   = mkOption {
          type        = nullOr str;
          default     = null;
          example     = "Paris";
          description = "Ville de la météo (barre tmux, variable `CITY` dans zsh). `null` : détection automatique par tmux-weather.";
        };
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
