# Poste de travail : GUI complète, shell, outils, deux utilisateurs.
{
  module = { ... }: {
    networking.hostName = "poste";
    fileSystems."/" = { device = "/dev/disk/by-label/root"; fsType = "ext4"; };
    boot.loader.grub.device = "/dev/sda";

    shincraft = {
      gui = {
        enable           = true;
        keyboard.variant = "";
        plasma           = { enable = true; kdeconnect = true; };
        pkgs = {
          game.enable    = true;
          art.enable     = true;
          "3d".enable    = true;
          audio.enable   = true;
          video.enable   = true;
          android.enable = true;
        };
      };
      system.kanata.enable = true;
      shell = {
        zsh = {
          enable        = true;
          powerlevel10k = { enable = true; setupInstantPrompt = true; };
        };
        nixvim.enable = true;
        tmux.enable   = true;
        weatherCity   = "Testville";
      };
      tools = {
        hack.enable    = true;
        ia.llama       = true;
        virtualisation = { docker = true; libvirt = true; virtualbox = true; };
      };
      users = {
        moi = {
          user-config = {
            extraGroups            = [ "wheel" ];
            sopsPassword           = true;
            openssh.authorizedKeys = [ "ssh-ed25519 AAAATEST moi@poste" ];
          };
          home-config = {
            git = { enable = true; user = { name = "Moi"; email = "moi@mondomaine.fr"; }; };
            ssh = {
              enable    = true;
              listAlias = {
                srv    = { HostName = "192.168.1.10"; User = "root"; };
                ancien = { hostname = "192.168.1.11"; user = "root"; port = 22; };
              };
            };
            vscode.enable   = true;
            chromium.enable = true;
            kube.enable     = true;
            nodejs.enable   = true;
            java.enable     = true;
            database.enable = true;
          };
        };
        autre.user-config = {
          uid                = 1001;
          hashedPasswordFile = "/var/lib/secrets/autre";
        };
      };
    };
  };

  checks = { config, pkgs, lib }:
    let
      hm = config.home-manager.users.moi;
      # home-manager range chaque bloc de `programs.ssh.settings` dans un nœud de DAG (`data`)
      sshBlock = name: let v = hm.programs.ssh.settings.${name}; in v.data or v;
    in {
      xkbVariantVide   = config.services.xserver.xkb.layout == "fr" && config.services.xserver.xkb.variant == "";
      pipewireParDefaut = config.services.pipewire.enable && !(config.services ? pulseaudio && config.services.pulseaudio.enable);
      kanataTousClaviers = config.services.kanata.keyboards.internalKeyboard.devices == [];
      waydroidSansCage = config.virtualisation.waydroid.enable && !(config.systemd.services ? cage-tty);
      splashBootDansOverlay = pkgs ? splash-boot;
      editeurNvim      = config.environment.variables.EDITOR == "nvim";
      cityDansZshrc    = lib.hasInfix "export CITY=Testville" config.environment.etc.zshrc.text;
      meteoDansTmux    = lib.hasInfix ''@tmux-weather-location "Testville"'' config.programs.tmux.extraConfig;
      fzfTabCharge     = lib.hasInfix "fzf-tab" config.programs.zsh.promptInit;
      dockerRootless   = config.virtualisation.docker.rootless.enable;
      libvirtAvecGui   = config.virtualisation.libvirtd.enable && config.programs.virt-manager.enable;
      motDePasseSops   = config.users.users.moi.hashedPasswordFile == config.sops.secrets."users/moi-password".path
                         && config.sops.secrets."users/moi-password".neededForUsers;
      motDePasseFichier = config.users.users.autre.hashedPasswordFile == "/var/lib/secrets/autre"
                          && !(config.sops.secrets ? "users/autre-password");
      clesSsh          = config.users.users.moi.openssh.authorizedKeys.keys == [ "ssh-ed25519 AAAATEST moi@poste" ];
      uidDistincts     = config.users.users.moi.uid == 1000 && config.users.users.autre.uid == 1001;
      vscodeActif      = hm.programs.vscode.enable;
      sshAliasOpenssh  = (sshBlock "srv").HostName == "192.168.1.10";
      sshAliasAncien   = (sshBlock "ancien").HostName == "192.168.1.11" && (sshBlock "ancien").Port == 22;
      gitUtilisateur   = hm.programs.git.settings.user.email == "moi@mondomaine.fr";
    };
}
