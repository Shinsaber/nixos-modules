# Fichier de configuration NixOS

Ressortir ma configuration pour mes postes et serveurs dans des modules standardisés. Avec des options pour les utilisés.

## Les options de config

### Modules généraux (`config.shincraft`)

```
config.shincraft
├──system
│  ├──kanata        = Activate kanata keyboard remapping (space + jkl; = arrows)
│  ├──vaapi         = Hardware Accelerators (Intel VAAPI)
│  ├──batterysave   = Activate systemd disable service on battery
│  └──nix
│     ├──autoUpgrade = Activate nix autoUpgrade at 12h-14h
│     └──optiStore   = Enable optimisation et garbage collecte
├──tools
│  ├──hack.enable    = Activate hacking tools set (wireshark, nmap, dig, glances)
│  ├──ia.llama       = Activate IA llama tools set (ollama + nextjs-ui)
│  ├──java7
│  │  ├──enable       = Enable OpenJDK 7 for legacy applications
│  │  └──setAsDefault = Set Java 7 as default system Java (not recommended)
│  └──virtualisation
│     ├──docker      = Activate Docker virtualisation
│     ├──libvirt     = Activate Libvirt virtualisation (qemu with UEFI/TPM support)
│     └──virtualbox  = Activate VirtualBox virtualisation
├──users
│  └──[MyUser]
│     ├──user-config
│     │  ├──uid         = Set UID (default: 1000)
│     │  └──extraGroups = Set other groups for the user
│     └──home-config
│        ├──packages      = List of package to install only for this user
│        ├──git
│        │  ├──enable     = Activate user config for git
│        │  └──user
│        │     ├──name    = Git user name
│        │     └──email   = Git email
│        ├──ssh
│        │  ├──enable       = Activate user config for ssh
│        │  └──listAlias    = Add alias for SSH client (see below)
│        ├──vscode.enable   = Enable VSCodium and addon
│        ├──chromium.enable = Enable Chromium Browser
│        ├──kube.enable     = Install tools for managing kube cluster
│        ├──nodejs.enable   = Install yarn and Node tools
│        ├──java.enable     = Install Java tools
│        └──database.enable = Install database tools (DBeaver)
├──shell
│  ├──vim.enable    = Activate Vim advenced config
│  ├──nixvim.enable = Activate NeoVim advenced config (nixvim)
│  ├──tmux.enable   = Activate tmux advenced config
│  └──zsh
│     ├──enable  = Activate ZSH as default shell
│     └──powerlevel10k
│        ├──enable             = Setup powerlevel10k for ZSH
│        └──setupInstantPrompt = Setup instant prompt, might crash zsh
└──gui
   ├──enable = Enable GUI environment (fonts, basic tools)
   ├──plasma
   │  ├──enable     = Enable Plasma 6 wayland gui
   │  └──kdeconnect = Enable KDE connect
   ├──audio
   │  └──pipewire
   │     └──enable = Enable pipewire instead of pulseaudio
   └──pkgs
      ├──game.enable    = Enable gui game packages (Steam, Discord, Wesnoth)
      ├──art.enable     = Enable gui art packages (Krita, GIMP, Darktable, Inkscape)
      ├──"3d".enable    = Enable gui 3D packages (FreeCAD)
      ├──audio.enable   = Enable gui audio packages (Audacity, Picard)
      ├──video.enable   = Enable gui video packages (OBS, OpenShot, Shotcut, FFmpeg)
      └──android.enable = Enable android packages (ADB, Waydroid)
```

### Modules serveur (`config.shincraft.server`)

```
config.shincraft.server
├──nginx
│  ├──enable = Install nginx with SSL/TLS configuration
│  ├──mail   = Email for ACME/Let's Encrypt certificates
│  └──domain = Configuration per domain and subdomain
├──jellyfin   = Install Jellyfin media server (+ Seerr) with hardware acceleration
├──jellyseerr = (déclarée mais sans effet : Seerr est installé avec jellyfin)
├──transmission
│  ├──enable    = Install transmission torrent client
│  └──whitelist = IP whitelist for web interface
├──nextcloud
│  ├──enable        = Install Nextcloud (PostgreSQL + Redis)
│  ├──hostName      = Domain name used to reach Nextcloud
│  ├──package       = Nextcloud package (default: nextcloud33)
│  ├──https         = Enable HTTPS (default: true)
│  ├──admin
│  │  ├──user         = Admin user name (default: admin)
│  │  └──passwordFile = Path to a file containing the admin password
│  ├──dataDir       = Data directory (default: /var/lib/nextcloud)
│  ├──maxUploadSize = Max upload size (default: 16G)
│  ├──extraApps     = Extra Nextcloud apps
│  └──extraSettings = Extra Nextcloud settings
├──romm
│  ├──enable        = Install RomM (ROM Manager) with MariaDB (Podman containers)
│  ├──port          = Listening port (default: 8095)
│  ├──rommDataPath  = Path of the ROM library (resources/, library/, assets/)
│  ├──db
│  │  ├──name         = MariaDB database name (default: romm)
│  │  ├──user         = MariaDB user (default: romm-user)
│  │  ├──password     = MariaDB user password
│  │  └──rootPassword = MariaDB root password
│  ├──authSecretKey = RomM auth secret (`openssl rand -hex 32`)
│  ├──screenscraper
│  │  ├──user     = ScreenScraper user
│  │  └──password = ScreenScraper password
│  ├──retroachievements.apiKey = RetroAchievements API key
│  ├──steamgriddb.apiKey       = SteamGridDB API key
│  ├──hasheous.enable          = Enable Hasheous metadata provider (default: true)
│  └──configFile               = RomM config.yml (default: ./modules/server/romm/config.yml)
└──auth
   ├──enable = Install OpenLDAP and KeyCloak authentication
   ├──suffix = LDAP suffix (default: dc=example,dc=com)
   ├──name   = Organization name
   ├──rootCN = Root CN for LDAP admin
   └──rootPW = Root password for LDAP admin
```

> ⚠ Les mots de passe et clés passés en chaîne (`romm.*`, `auth.rootPW`) sont copiés
> dans `/nix/store`, lisible par tous les utilisateurs de la machine. Voir
> [docs/secrets.md](docs/secrets.md).

### Plymouth (`config.boot.plymouth`)

Options ajoutées par `nixosModules.general` pour le thème de démarrage :

```
config.boot.plymouth
├──name        = Name displayed on the splash (default: NixOS)
├──colorNormal = Color(r, g, b) (default: Color(0.2400, 0.3500, 0.5900))
└──colorTinted = Color(r, g, b) (default: Color(0.3600, 0.5200, 0.6700))
```

### Alias SSH (`home-config.ssh.listAlias`)

Les alias sont écrits dans `programs.ssh.settings` de home-manager. Les deux formats sont
acceptés : directives OpenSSH (recommandé) ou ancien format `matchBlocks`, converti
automatiquement.

```nix
ssh = {
  enable = true;
  listAlias = {
    "mon-serveur" = {
      HostName     = "192.168.1.10";
      User         = "root";
      LocalForward = [ { bind.port = 3306; host.address = "localhost"; host.port = 3306; } ];
    };
    # Ancien format, toujours accepté
    "autre" = { hostname = "192.168.1.11"; user = "root"; port = 22; };
  };
};
```

## Packages personnalisés

Ce flake inclut également des packages personnalisés :

- **`nixvim`** : Configuration Neovim avancée avec LSP, Telescope, et plugins
- **`openjdk7`** : OpenJDK 7 pour applications legacy (avec `maven-3-8-4` et `java7-helper`)
- **`jellyfin-web`** : Version modifiée avec skip-intro-button intégré
- **`freelens`** : Client graphique Kubernetes

## Exemples d'utilisation

### Configuration basique pour poste de travail

```nix
{
  imports = [ inputs.nixos-modules.nixosModules.general ];

  shincraft = {
    gui.enable = true;
    gui.plasma.enable = true;
    gui.audio.pipewire.enable = true;

    shell.zsh.enable = true;
    shell.zsh.powerlevel10k.enable = true;

    users.myuser = {
      user-config = {
        uid = 1000;
        extraGroups = [ "wheel" "networkmanager" ];
      };
      home-config = {
        git = {
          enable = true;
          user = {
            name  = "Mon Nom";
            email = "mon@email.com";
          };
        };
        vscode.enable = true;
        nodejs.enable = true;
      };
    };
  };
}
```

### Configuration serveur media

```nix
{
  imports = [
    inputs.nixos-modules.nixosModules.general
    inputs.nixos-modules.nixosModules.server
  ];

  shincraft = {
    system.vaapi = true; # Hardware acceleration

    server = {
      jellyfin = true;
      nginx = {
        enable = true;
        mail = "admin@mondomaine.fr";
        domain."mondomaine.fr"."jellyfin" = {
          host = "127.0.0.1";
          port = 8096;
        };
      };
    };
  };
}
```

### Configuration développeur avec virtualisation

```nix
{
  imports = [ inputs.nixos-modules.nixosModules.general ];

  shincraft = {
    tools.virtualisation.docker = true;
    tools.virtualisation.libvirt = true;

    shell.nixvim.enable = true; # NeoVim configuré

    users.dev = {
      user-config.extraGroups = [ "wheel" "docker" "libvirtd" ];
      home-config = {
        kube.enable = true;
        database.enable = true;
        nodejs.enable = true;
        java.enable = true;
      };
    };
  };
}
```

## Extensions et plugins inclus

### Shell (ZSH)

- **powerlevel10k** : Thème moderne avec prompt rapide
- **forgit** : Interface fzf pour git
- **auto-notify** : Notifications pour commandes longues
- **autopair** : Auto-fermeture des guillemets/parenthèses
- **you-should-use** : Suggestions d'alias

### NeoVim

- **LSP** : Support pour Nix, YAML, JSON, Bash, Terraform, Docker, etc.
- **Telescope** : Recherche fuzzy de fichiers
- **Treesitter** : Coloration syntaxique avancée
- **Which-key** : Aide pour les raccourcis clavier

### VSCodium

- Extensions Nix, GitLab, Kubernetes, Docker
- GitHub Copilot & Copilot Chat
- Support markdown et PlantUML
- Prettier pour le formatage
