{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.shincraft.system.build;

in
{
  config = mkIf cfg.remote.enable {
    # Configuration des builders distants
    nix.buildMachines = mapAttrsToList (name: builder: {
      hostName = builder.hostName;
      sshUser = builder.sshUser;
      sshKey = builder.sshKey;
      system = builder.system;
      maxJobs = builder.maxJobs;
      speedFactor = builder.speedFactor;
      supportedFeatures = builder.supportedFeatures;
      mandatoryFeatures = builder.mandatoryFeatures;
      publicHostKey = builder.publicHostKey;
    }) cfg.remote.builders;

    # Activer les builds distribués
    nix.distributedBuilds = mkIf (cfg.builders != { }) true;

    # Configuration des caches de substitution
    nix.settings = mkMerge [
      # Paramètres généraux de build
      {
        # Nombre de jobs locaux
        max-jobs = mkIf (cfg.maxJobs != null) cfg.maxJobs;
        
        # Nombre de jobs de build en parallèle
        cores = mkIf (cfg.buildCores != null) cfg.buildCores;
        
        # Timeout pour les builds
        max-silent-time = cfg.maxSilentTime;
        timeout = cfg.timeout;
      }

      # Configuration pour permettre à d'autres machines de se connecter en tant que builder
      (mkIf cfg.acceptRemoteBuilds {
        trusted-users = mkDefault [ "nix-builder" ];
      })
    ];

    # Créer l'utilisateur nix-builder si on accepte les builds distants
    users.users = mkIf cfg.acceptRemoteBuilds {
      nix-builder = {
        isSystemUser = true;
        group = "nix-builder";
        shell = pkgs.bashInteractive;
        openssh.authorizedKeys.keys = cfg.authorizedBuilderKeys;
      };
    };

    users.groups = mkIf cfg.acceptRemoteBuilds {
      nix-builder = { };
    };

    # Packages utiles pour le debugging
    environment.systemPackages = mkIf cfg.enableDebugTools (with pkgs; [
      nix-tree  # Visualiser les dépendances
      nix-diff  # Comparer les dérivations
      nix-output-monitor  # Monitorer les builds
    ]);
  };
}
