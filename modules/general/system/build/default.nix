{ config, lib, pkgs, ... }:

with lib;
with types;

let
  # Type pour définir un builder distant
  builderType = submodule {
    options = {
      hostName = mkOption {
        type = str;
        example = "builder.example.com";
        description = "Nom d'hôte ou adresse IP du builder distant";
      };

      system = mkOption {
        type = nullOr (listOf str);
        default = null;
        example = [ "x86_64-linux" "aarch64-linux" ];
        description = "Systèmes supportés par le builder (null = détecter automatiquement)";
      };

      sshUser = mkOption {
        type = str;
        default = "nix-builder";
        description = "Utilisateur SSH pour se connecter au builder";
      };

      sshKey = mkOption {
        type = nullOr path;
        default = null;
        example = "/root/.ssh/id_builder";
        description = "Chemin vers la clé SSH privée pour l'authentification";
      };

      maxJobs = mkOption {
        type = int;
        default = 4;
        description = "Nombre maximum de jobs parallèles sur ce builder";
      };

      speedFactor = mkOption {
        type = int;
        default = 1;
        example = 2;
        description = "Facteur de vitesse (plus élevé = préféré pour les builds)";
      };

      supportedFeatures = mkOption {
        type = listOf str;
        default = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        example = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        description = "Features supportées par le builder";
      };

      mandatoryFeatures = mkOption {
        type = listOf str;
        default = [ ];
        example = [ "big-parallel" ];
        description = "Features obligatoires que le builder doit avoir";
      };

      publicHostKey = mkOption {
        type = nullOr str;
        default = null;
        example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJz...";
        description = "Clé publique de l'hôte pour vérifier l'identité";
      };
    };
  };
in
{
  imports = [
    ./remote.nix
  ];

  config.shincraft.system.build = {
    remote = {
      enable = mkEnableOption "Configuration des builders distants pour les builds Nix.";

      # Builders distants
      builders = mkOption {
        type = attrsOf builderType;
        default = { };
        example = literalExpression ''
          {
            fast-builder = {
              hostName = "builder.example.com";
              system = [ "x86_64-linux" ];
              maxJobs = 8;
              speedFactor = 2;
              sshUser = "nix-builder";
              sshKey = "/root/.ssh/id_builder";
            };
          }
        '';
        description = ''
          Configuration des machines de build distantes.
          Chaque builder est identifié par un nom et contient sa configuration.
        '';
      };
    };

    # Paramètres de build local
    maxJobs = mkOption {
      type = nullOr int;
      default = null;
      example = 4;
      description = ''
        Nombre maximum de jobs de build en parallèle localement.
        Si null, utilise le nombre de CPUs.
      '';
    };

    buildCores = mkOption {
      type = nullOr int;
      default = null;
      example = 0;
      description = ''
        Nombre de cœurs disponibles pour chaque job de build.
        0 = utiliser tous les cœurs disponibles.
        Si null, utilise la valeur par défaut de Nix.
      '';
    };

    # Timeouts
    maxSilentTime = mkOption {
      type = int;
      default = 3600;
      example = 7200;
      description = ''
        Temps maximum (en secondes) qu'un build peut rester silencieux
        avant d'être considéré comme bloqué et terminé.
      '';
    };

    timeout = mkOption {
      type = int;
      default = 36000;
      example = 72000;
      description = ''
        Temps maximum (en secondes) qu'un build peut prendre
        avant d'être terminé de force.
      '';
    };

    # Configuration pour accepter des builds distants
    acceptRemoteBuilds = mkOption {
      type = bool;
      default = false;
      description = ''
        Si true, configure cette machine pour accepter des builds
        venant d'autres machines (agit comme un builder distant).
      '';
    };

    authorizedBuilderKeys = mkOption {
      type = listOf str;
      default = [ ];
      example = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJz... builder@machine1"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB... builder@machine2"
      ];
      description = ''
        Clés SSH publiques autorisées à se connecter en tant que nix-builder
        pour effectuer des builds distants sur cette machine.
      '';
    };

    # Outils de debug
    enableDebugTools = mkOption {
      type = bool;
      default = false;
      description = ''
        Si true, installe des outils utiles pour debugger les builds
        (nix-tree, nix-diff, nix-output-monitor).
      '';
    };
  };
}
