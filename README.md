# Modules NixOS shincraft

Flake de modules NixOS réutilisables pour mes postes de travail et mes serveurs, exposés sous
l'espace d'options `shincraft.*`. Il ne contient aucune machine : les hosts vivent dans un dépôt
séparé qui importe `nixosModules.general` (postes et serveurs) et, pour les serveurs,
`nixosModules.server` en plus. Versions : NixOS 26.05, home-manager 26.05, nixvim 26.05.

## Les options de config

### Modules généraux (`config.shincraft`)

```
config.shincraft
├──system
│  ├──kanata
│  │  ├──enable  = Activate kanata keyboard remapping (space + jkl; = arrows)
│  │  └──devices = Claviers pris en charge (défaut : tous)
│  ├──vaapi         = Hardware Accelerators (Intel VA-API)
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
│  │  └──jobs."<job>" = Remplis par les modules (nextcloud, kanidm, romm, collectionnard) : paths, postgresDatabases, prepareCommand, pruneOpts, enable
│  └──proxmoxGuest
│     ├──enable      = Profil de VM invitée Proxmox (agent QEMU, virtio, SSH, bootloader)
│     ├──firmware    = "bios" (grub) ou "uefi" (systemd-boot), obligatoire
│     ├──device      = Disque système (défaut : scsi0)
│     ├──disko       = Partitionne le disque système avec disko (nixos-anywhere)
│     └──rootSshKeys = Clés SSH publiques autorisées pour root
├──tools
│  ├──hack.enable    = Activate hacking tools set (wireshark, nmap, dig, sslscan, testssl, glances)
│  ├──ia.llama       = Activate IA llama tools set (ollama + nextjs-ui)
│  ├──java7
│  │  ├──enable       = Enable OpenJDK 7 for legacy applications
│  │  └──setAsDefault = Set Java 7 as default system Java (not recommended)
│  └──virtualisation
│     ├──docker      = Activate Docker virtualisation (daemon système + mode rootless ; dive pour les utilisateurs)
│     ├──libvirt     = Activate Libvirt virtualisation (qemu_kvm, swtpm ; virt-manager et quickemu si gui.enable)
│     └──virtualbox  = Activate VirtualBox virtualisation (+ vagrant)
├──users
│  └──[MyUser]
│     ├──user-config
│     │  ├──uid         = Set UID (default: 1000 ; à renseigner dès le deuxième utilisateur)
│     │  ├──extraGroups = Set other groups for the user
│     │  ├──hashedPasswordFile     = Fichier du mot de passe haché (mkpasswd -m yescrypt)
│     │  ├──sopsPassword           = Mot de passe haché depuis le secret sops users/<nom>-password
│     │  └──openssh.authorizedKeys = Clés SSH publiques autorisées
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
│        ├──vscode.enable   = Install VS Code (pkgs.vscode de nixpkgs unstable) et ses extensions
│        ├──chromium.enable = Enable Chromium Browser
│        ├──kube.enable     = Install tools for managing kube cluster (kubectl, kubectx, helm, helmfile, stern, terraform, azure-cli… ; freelens et jet-pilot si gui.enable)
│        ├──nodejs.enable   = Install yarn and Node tools
│        ├──java.enable     = Install Java tools (programs.java + sbt)
│        └──database.enable = Install database tools (DBeaver, si gui.enable)
├──shell
│  ├──vim.enable    = Activate Vim advanced config (EDITOR=vim)
│  ├──nixvim.enable = Activate NeoVim advanced config (nixvim ; EDITOR=nvim, alias vim=nvim)
│  ├──tmux.enable   = Activate tmux advanced config (catppuccin, menu, kubectx, météo)
│  ├──weatherCity   = Ville de la météo tmux et variable CITY de zsh (défaut : détection automatique)
│  └──zsh
│     ├──enable  = Activate ZSH as default shell
│     └──powerlevel10k
│        ├──enable             = Setup powerlevel10k for ZSH
│        └──setupInstantPrompt = Setup instant prompt, might crash zsh
└──gui
   ├──enable = Enable GUI environment (polices, Bluetooth, impression, Firefox, outils de base)
   ├──keyboard
   │  ├──layout  = Disposition XKB (défaut : fr)
   │  └──variant = Variante XKB (défaut : bepo)
   ├──plasma
   │  ├──enable     = Enable Plasma 6 wayland gui
   │  └──kdeconnect = Enable KDE connect
   ├──audio
   │  └──pipewire
   │     └──enable = Serveur audio PipeWire (défaut : true ; false = aucun serveur audio)
   └──pkgs
      ├──game.enable    = Enable gui game packages (Steam, Discord, Wesnoth, appimage-run)
      ├──art.enable     = Enable gui art packages (Krita, GIMP, Darktable, Inkscape, pilote XP-Pen)
      ├──"3d".enable    = Enable gui 3D packages (FreeCAD)
      ├──audio.enable   = Enable gui audio packages (Audacity, Picard)
      ├──video.enable   = Enable gui video packages (OBS, Shotcut, Kodi, MakeMKV, MKVToolNix, Aegisub, FFmpeg, DaVinci Resolve)
      └──android.enable = Enable android packages (adb-sync, Waydroid)
```

### Modules serveur (`config.shincraft.server`)

`nixosModules.server` s'importe toujours avec `nixosModules.general` : les modules serveur
s'appuient sur `shincraft.system.sops` (secrets) et `shincraft.system.backup` (sauvegardes).

```
config.shincraft.server
├──nginx
│  ├──enable = Install nginx with SSL/TLS configuration
│  ├──mail   = Email for ACME/Let's Encrypt certificates
│  ├──domain."<domaine>"."<sous-domaine>"
│  │  ├──host        = Backend host (default: www)
│  │  ├──port        = Backend port (default: 80)
│  │  ├──protocol    = Backend protocol: http (default) or https
│  │  ├──maxBodySize = client_max_body_size (ex. "16G")
│  │  └──allowFrom   = Allowed networks, others get 403 (ex. VPN)
│  ├──jsonLog = Journal d'accès JSON en plus (/var/log/nginx/access.json.log, défaut : true)
│  └──fail2ban
│     ├──enable      = Bannir les clients qui scannent nginx (4xx en rafale, chemins sensibles .env/.git/wp-…) + prison sshd
│     ├──ignoreIP    = Réseaux jamais bannis (ex. LAN, VPN)
│     ├──maxRetry    = Réponses 4xx tolérées par client en 10 min (défaut : 20)
│     ├──ignorePaths = Chemins ignorés par nginx-scan et nginx-sensitive (défaut : WebDAV Nextcloud)
│     └──bantime     = Premier bannissement (défaut : "1h", double à chaque récidive)
├──jellyfin
│  ├──enable       = Install Jellyfin media server (+ Seerr), active system.vaapi par défaut
│  └──openFirewall = Ouvrir les ports de Jellyfin et Seerr (défaut : false, passer par nginx)
├──transmission
│  ├──enable       = Install transmission 4 (RPC sur 0.0.0.0) + interface web Flood
│  ├──openFirewall = Ouvrir les ports RPC, pairs et Flood (défaut : false)
│  └──whitelist    = IP autorisées sur le RPC de transmission (rpc-whitelist)
├──nextcloud
│  ├──enable         = Install Nextcloud (PostgreSQL + Redis)
│  ├──hostName       = Domain name used to reach Nextcloud
│  ├──package        = Nextcloud package (default: nextcloud34)
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
│  │  ├──mappingUid       = Claim used as user ID (default: preferred_username)
│  │  └──ssoOnly          = SSO login only, password form hidden (default: false)
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
├──romm
│  ├──enable        = Install RomM (ROM Manager) with MariaDB (Podman containers)
│  ├──port          = Listening port (default: 8095)
│  ├──openFirewall  = Declare the port in networking.firewall, for traceability only: podman bypasses the firewall (default: true)
│  ├──rommDataPath  = Path of the ROM library (resources/, library/, assets/)
│  ├──db
│  │  ├──name = MariaDB database name (default: romm)
│  │  └──user = MariaDB user (default: romm-user)
│  ├──screenscraper
│  │  ├──enable = Enable ScreenScraper (sops romm/screenscraper-password)
│  │  └──user   = ScreenScraper user
│  ├──retroachievements.enable = Enable RetroAchievements (sops romm/retroachievements-api-key)
│  ├──steamgriddb.enable       = Enable SteamGridDB (sops romm/steamgriddb-api-key)
│  ├──hasheous.enable          = Enable Hasheous metadata provider (default: true)
│  └──configFile               = RomM config.yml (default: ./modules/server/romm/config.yml)
└──collectionnard
   ├──enable         = Install Collectionnard, built from a release (hardened systemd service + PostgreSQL)
   ├──hostName       = Domain of the local nginx vhost (HTTP, TLS on the reverse proxy)
   ├──package        = Server package (default: ./modules/server/collectionnard/package.nix)
   ├──webPackage     = Front-end package (same file)
   ├──port           = Local API port, never opened (default: 8085)
   ├──openFirewall   = Open port 80 for the reverse proxy
   ├──trustedProxies = Reverse proxies trusted for X-Real-IP
   ├──jwtSecretFile  = JWT signing key file (default: sops collectionnard/jwt-secret)
   └──settings       = Extra server environment (MEMBER_INVITES, EXTERNAL_USER_AGENT…)
```

Collectionnard : version et hashes dans `package.nix` ; administration avec la commande
`colec-server` (lancée sous l'utilisateur du service), ex. `colec-server create-user <nom> <email> --admin`
puis `colec-server install-domain --all`.

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

Le module ajoute à l'overlay le paquet `pkgs.splash-boot` (thème `vortex` avec le logo et les
couleurs ci-dessus) mais ne l'active pas : c'est le host qui le branche.

```nix
boot.plymouth = {
  enable        = true;
  theme         = "vortex";
  themePackages = lib.mkForce [ pkgs.splash-boot ];
};
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

## Tests

```sh
nix flake check
```

Deux configurations synthétiques dans [tests/](tests/) (poste de travail, serveur) activent les
options et vérifient le résultat de l'évaluation : firewall fermé par défaut, secrets sops déclarés,
jobs de sauvegarde, reverse proxy… Rien n'est construit. Toute option ajoutée ou modifiée doit y
être couverte.

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
      jellyfin.enable = true;
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

- **powerlevel10k** : Thème moderne avec prompt rapide (instant prompt en option)
- **forgit** : Interface fzf pour git
- **auto-notify** : Notifications pour commandes longues (notify-send en local, séquences
  OSC 99/777 ou cloche à travers SSH et tmux)
- **autopair** : Auto-fermeture des guillemets/parenthèses
- **you-should-use** : Suggestions d'alias
- **fzf-tab** : Complétion via fzf
- **any-nix-shell** : Prompt conservé dans `nix shell`
- Plugins oh-my-zsh : git, helm, sudo, docker, kubectl, battery, colorize, colored-man-pages,
  history-substring-search, zsh-interactive-cd, command-not-found

### NeoVim (`shell.nixvim.enable`)

- **LSP** : Nix (nil), YAML, JSON, Bash, Terraform, Docker et Compose, Helm, nginx, Java,
  Kotlin, TypeScript/ESLint, Elm, Rust
- **nvim-cmp** + lspkind : Complétion
- **Telescope** : Recherche fuzzy de fichiers
- **Treesitter** : Coloration syntaxique avancée
- **Which-key** : Aide pour les raccourcis clavier
- Interface : barbar, lualine, noice, indent-blankline, rainbow-delimiters, thème onedark
- `packages/nvim/plugins/copilot.nix` existe mais n'est pas importé

### VS Code (`home-config.vscode.enable`)

Paquet `vscode` de nixpkgs unstable (et non VSCodium), extensions gérées par Nix
(`mutableExtensionsDir = false`) :

- Nix (nix-ide + nil), YAML, Kubernetes, Helm, containers, GitLab Workflow
- Java, Kotlin, Gradle, Maven
- Remote SSH, Project Manager, Claude Code
- Markdown All in One, PlantUML, Draw.io, Dendron, LanguageTool
- Prettier (`formatOnSave` activé)
