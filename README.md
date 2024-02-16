# Fichier de configuration NixOS

Ressortir ma configuration pour mes poste et serveurs dans des modules standardisés. Avec des options pour les utilisés.

## Les options de config
```
config.custom
├──system
│  ├──docker      = Install docker in the systeme
│  └──batterysave = Activate systemd disable service on battery
├──tools
│  ├──hack.enable = Activate hacking tools set
│  └──ia.llama    = mkEnableOption "Activate hacking tools set";
├──users
│  └──[MyUser]
│     ├──user-config
│     │  ├──uid = Set UID
│     │  └──extraGroups  = Set other groups for the user
│     └──home-config
│        ├──packages     = List of package to install only for this user
│        ├──git
│        │  ├──enable    = Activate user config for git
│        │  ├──userName  = Git user name
│        │  └──userEmail = Git email
│        ├──ssh
│        │  ├──enable       = Activate user config for ssh
│        │  └──listAlias    = Add alias for SSH client
│        ├──vscode.enable   = Enable VSCodium and addon
│        ├──chromium.enable = Enable Chromium Browser
│        ├──kube.enable     = Install tools for managing kube cluster
│        ├──nodejs.enable   = Install yarn and Node tools
│        └──database.enable = Enable android package
├──shell
│  ├──vim
│  │  └──enable = Activate Vim advenced config
│  ├──nvim
│  │  └──enable = Activate NeoVim advenced config
│  └──zsh
│     ├──enable = Activate ZSH as default shell
│     └──powerlevel10k
│        ├──enable = Setup powerlevel10k for ZSH
│        └──setupInstantPrompt = Setup instant prompt, might crash zsh
└──gui
   ├──enable = Enable Plasma gui
   ├──audio
   │   └──pipewire
   │      └──enable = Enable pipewire instead of pulseaudio
   └──pkgs
      ├──game
      │  └──enable      = Enable gui game package
      ├──art.enable     = Enable gui art package
      ├──"3d".enable    = Enable gui 3D package
      ├──audio.enable   = Enable gui audio package
      ├──video.enable   = Enable gui vidéo package
      └──android.enable = Enable android package
```
