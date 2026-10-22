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
│  ├──sops
│  │  ├──enable          = Secrets chiffrés avec sops-nix (clé SSH host)
│  │  └──defaultSopsFile = Fichier sops du host (voir docs/secrets.md)
│  ├──backup
│  │  ├──enable    = Sauvegardes restic vers S3, un dépôt + une clé par service
│  │  ├──bucket    = Bucket commun (dépôts <bucket>/<host>/<job>)
│  │  ├──hostname  = Point d'accès S3
│  │  ├──region    = Région S3
│  │  ├──key       = Access key ID (secret sops backup/s3-secret)
│  │  ├──startAt   = Heure des sauvegardes (défaut : 03:00)
│  │  ├──pruneOpts = Rétention (défaut : 7 jours, 4 semaines, 6 mois)
│  │  └──jobs."<job>" = Remplis par les modules (nextcloud, kanidm, romm) : paths, postgresDatabases, prepareCommand, pruneOpts, enable
│  ├──proxmoxGuest
│  │  ├──enable      = Profil de VM invitée Proxmox (agent QEMU, virtio, SSH, bootloader)
│  │  ├──firmware    = "bios" (grub) ou "uefi" (systemd-boot), obligatoire
│  │  ├──device      = Disque système (défaut : scsi0)
│  │  ├──disko       = Partitionne le disque système avec disko (nixos-anywhere)
│  │  └──rootSshKeys = Clés SSH publiques autorisées pour root
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
│  └──domain."<domaine>"."<sous-domaine>"
│     ├──host        = Backend host (default: www)
│     ├──port        = Backend port (default: 80)
│     ├──protocol    = Backend protocol: http (default) or https
│     ├──maxBodySize = client_max_body_size (ex. "16G")
│     └──allowFrom   = Allowed networks, others get 403 (ex. VPN)
├──jellyfin   = Install Jellyfin media server (+ Seerr) with hardware acceleration
├──jellyseerr = (déclarée mais sans effet : Seerr est installé avec jellyfin)
├──transmission
│  ├──enable    = Install transmission torrent client
│  └──whitelist = IP whitelist for web interface
├──nextcloud
│  ├──enable         = Install Nextcloud (PostgreSQL + Redis)
│  ├──hostName       = Domain name used to reach Nextcloud
│  ├──package        = Nextcloud package (default: nextcloud33)
│  ├──https          = Enable HTTPS (default: true)
│  ├──admin
│  │  ├──user         = Admin created at install (default: none, use nextcloud-occ)
│  │  └──passwordFile = Path to a file containing the admin password
│  ├──dataDir        = Data directory (default: /var/lib/nextcloud)
│  ├──maxUploadSize  = Max upload size (default: 16G)
│  ├──openFirewall   = Open port 80 for the reverse proxy
│  ├──trustedProxies = Reverse proxy addresses (trusted_proxies)
│  ├──apps           = Apps packaged in nixpkgs, by name (App Store disabled)
│  ├──extraApps      = Other apps (fetchNextcloudApp)
│  ├──s3
│  │  ├──enable       = S3 primary storage (choose at install time)
│  │  ├──bucket       = Bucket name
│  │  ├──hostname     = S3 endpoint (ex. s3.gra.io.cloud.ovh.net)
│  │  ├──region       = Region (ex. gra)
│  │  ├──key          = Access key ID
│  │  ├──secretFile   = Secret key file (default: sops nextcloud/s3-secret)
│  │  └──usePathStyle = Path-style bucket addressing (default: false)
│  ├──oidc
│  │  ├──enable           = SSO login with user_oidc (ex. Kanidm)
│  │  ├──name             = Provider name on the login button (default: Kanidm)
│  │  ├──clientId         = OIDC client ID (default: nextcloud)
│  │  ├──discoveryUri     = OpenID discovery URL
│  │  ├──clientSecretFile = Client secret file (default: sops oidc/<clientId>)
│  │  └──mappingUid       = Claim used as user ID (default: preferred_username)
│  ├──onlyoffice
│  │  ├──enable            = Edit documents with ONLYOFFICE (sops onlyoffice/jwt-secret)
│  │  └──documentServerUrl = Public URL of the Document Server
│  └──extraSettings  = Extra Nextcloud settings
├──kanidm
│  ├──enable               = Install Kanidm identity provider (OIDC, TOTP, passkeys)
│  ├──domain               = Public domain (also the account identity, do not change)
│  ├──package              = Kanidm package (default: kanidmWithSecretProvisioning_1_11)
│  ├──port                 = HTTPS port (default: 8443)
│  ├──openFirewall         = Open the port for the reverse proxy
│  ├──tls.chainFile/keyFile = TLS certificate (default: generated self-signed)
│  ├──adminPasswordFile    = admin password (default: sops kanidm/admin-password)
│  ├──idmAdminPasswordFile = idm_admin password (default: sops kanidm/idm-admin-password)
│  └──oauth2."<client>"
│     ├──displayName   = Name in the Kanidm portal
│     ├──originUrl     = Exact OAuth2 redirect URL(s)
│     ├──originLanding = Service home page
│     ├──group         = Access group (default: <client>_users)
│     ├──scopes        = Granted scopes (default: openid email profile)
│     └──secretFile    = Client secret file (default: sops oidc/<client>)
├──onlyoffice
│  ├──enable                = Install ONLYOFFICE Document Server (PostgreSQL + RabbitMQ)
│  ├──hostName              = Public domain of the Document Server
│  ├──openFirewall          = Open port 80 for the reverse proxy
│  ├──jwtSecretFile         = JWT secret shared with Nextcloud (default: sops onlyoffice/jwt-secret)
│  └──allowLocalConnections = Allow downloads from private IPs (internal DNS, VPN)
└──romm
   ├──enable        = Install RomM (ROM Manager) with MariaDB (Podman containers)
   ├──port          = Listening port (default: 8095)
   ├──rommDataPath  = Path of the ROM library (resources/, library/, assets/)
   ├──db
   │  ├──name = MariaDB database name (default: romm)
   │  └──user = MariaDB user (default: romm-user)
   ├──screenscraper
   │  ├──enable = Enable ScreenScraper (sops romm/screenscraper-password)
   │  └──user   = ScreenScraper user
   ├──retroachievements.enable = Enable RetroAchievements (sops romm/retroachievements-api-key)
   ├──steamgriddb.enable       = Enable SteamGridDB (sops romm/steamgriddb-api-key)
   ├──hasheous.enable          = Enable Hasheous metadata provider (default: true)
   └──configFile               = RomM config.yml (default: ./modules/server/romm/config.yml)
```

> Les secrets (RomM, Kanidm, S3 et OIDC de Nextcloud) passent par sops-nix
> (`shincraft.system.sops`) : noms attendus et mise en place dans [docs/secrets.md](docs/secrets.md).

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

### VM Proxmox

Création de la VM, installation avec nixos-anywhere et mises à jour à distance :
voir [docs/proxmox.md](docs/proxmox.md).

### Nextcloud

Compte admin en CLI, apps gérées par Nix, reverse proxy et stockage S3 :
voir [docs/nextcloud.md](docs/nextcloud.md).

### Sauvegardes

restic vers S3, un dépôt et une clé de chiffrement par service :
voir [docs/backup.md](docs/backup.md).

### Kanidm (SSO)

Fournisseur d'identité OIDC avec TOTP et passkeys, comptes et branchement de Nextcloud :
voir [docs/kanidm.md](docs/kanidm.md). Secrets : [docs/secrets.md](docs/secrets.md).

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
