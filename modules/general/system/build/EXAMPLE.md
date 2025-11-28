# Exemple de configuration pour le build distant avec NixOS

Ce fichier montre comment configurer les options de build distant dans vos modules NixOS.

## Configuration de base

```nix
{
  shincraft.system.build.remote = {
    enable = true;

    # Configuration d'un builder distant
    builders = {
      fast-server = {
        hostName = "192.168.1.100";
        system = [ "x86_64-linux" ];
        maxJobs = 8;
        speedFactor = 2;
        sshUser = "nix-builder";
        sshKey = "/root/.ssh/id_builder_ed25519";
      };
    };

    # Configuration de caches de substitution
    substituters = {
      nixos-cache = {
        url = "https://cache.nixos.org";
        publicKeys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
      };
    };

    # Paramètres de build
    maxJobs = 4;
    buildCores = 0;  # 0 = utiliser tous les cœurs
  };
}
```

## Configuration avancée avec plusieurs builders

```nix
{
  shincraft.system.build.remote = {
    enable = true;

    builders = {
      # Builder principal pour x86_64
      main-builder = {
        hostName = "builder1.local";
        system = [ "x86_64-linux" ];
        maxJobs = 16;
        speedFactor = 3;
        sshUser = "nix-builder";
        sshKey = "/root/.ssh/id_builder";
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      };

      # Builder ARM pour cross-compilation
      arm-builder = {
        hostName = "builder2.local";
        system = [ "aarch64-linux" ];
        maxJobs = 8;
        speedFactor = 2;
        sshUser = "nix-builder";
        sshKey = "/root/.ssh/id_builder";
        supportedFeatures = [ "nixos-test" ];
      };
    };

    # Caches multiples
    substituters = {
      nixos-official = {
        url = "https://cache.nixos.org";
        publicKeys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
        priority = 40;  # Priorité standard
      };

      company-cache = {
        url = "https://nix-cache.company.internal";
        publicKeys = [
          "company-cache:AAAA...="
        ];
        priority = 30;  # Plus prioritaire
      };
    };

    # Timeouts personnalisés
    maxSilentTime = 7200;  # 2 heures
    timeout = 72000;       # 20 heures

    # Options avancées
    buildersUseSubstitutes = true;
    alwaysAllowSubstitutes = true;
    allowUnfreeOnBuilders = true;

    # Outils de débogage
    enableDebugTools = true;
  };
}
```

## Configurer une machine comme builder distant

Pour qu'une machine accepte des builds distants :

```nix
{
  shincraft.system.build.remote = {
    enable = true;
    acceptRemoteBuilds = true;

    # Clés SSH autorisées à se connecter en tant que builder
    authorizedBuilderKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJz... laptop@home"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAb... desktop@work"
    ];
  };
}
```

## Préparation de la clé SSH

Sur la machine qui va lancer les builds :

```bash
# Générer une clé SSH dédiée pour les builds
ssh-keygen -t ed25519 -f /root/.ssh/id_builder_ed25519 -N ""

# Copier la clé publique sur le builder
ssh-copy-id -i /root/.ssh/id_builder_ed25519.pub nix-builder@builder.local
```

## Tester la configuration

```bash
# Vérifier que les builders sont accessibles
nix store ping --store ssh://nix-builder@builder.local

# Lancer un build de test sur les builders distants
nix build --print-build-logs --builders '@/etc/nix/machines' nixpkgs#hello

# Monitorer les builds en temps réel (si enableDebugTools = true)
nom build nixpkgs#hello  # nom = nix-output-monitor
```

## Options disponibles

### Builders distants (`shincraft.system.build.remote.builders.<name>`)

- `hostName` : Nom d'hôte ou IP du builder
- `system` : Liste des systèmes supportés (null = auto-détection)
- `sshUser` : Utilisateur SSH (défaut: "nix-builder")
- `sshKey` : Chemin vers la clé SSH privée
- `maxJobs` : Nombre max de jobs parallèles (défaut: 4)
- `speedFactor` : Facteur de vitesse, plus élevé = préféré (défaut: 1)
- `supportedFeatures` : Features supportées (défaut: ["nixos-test", "benchmark", "big-parallel", "kvm"])
- `mandatoryFeatures` : Features obligatoires (défaut: [])
- `publicHostKey` : Clé publique de l'hôte pour vérification

### Caches de substitution (`shincraft.system.build.remote.substituters.<name>`)

- `url` : URL du cache
- `publicKeys` : Liste des clés publiques pour vérification
- `priority` : Priorité (plus faible = préféré, défaut: 40)

### Paramètres de build

- `maxJobs` : Jobs locaux max (null = nb de CPUs)
- `buildCores` : Cœurs par job (0 = tous, null = défaut)
- `maxSilentTime` : Timeout de silence (défaut: 3600s)
- `timeout` : Timeout total (défaut: 36000s)
- `buildersUseSubstitutes` : Builders peuvent utiliser les caches (défaut: true)
- `alwaysAllowSubstitutes` : Toujours permettre les caches (défaut: true)
- `allowUnfreeOnBuilders` : Autoriser unfree sur builders (défaut: false)

### Configuration serveur

- `acceptRemoteBuilds` : Accepter les builds distants (défaut: false)
- `authorizedBuilderKeys` : Clés SSH autorisées (défaut: [])
- `enableDebugTools` : Installer outils de debug (défaut: false)

## Dépannage

### Les builders ne sont pas utilisés

```bash
# Vérifier la configuration
nix show-config | grep builders

# Tester la connexion SSH
ssh -i /root/.ssh/id_builder nix-builder@builder.local

# Vérifier les logs de build
journalctl -u nix-daemon -f
```

### Problèmes de clés SSH

```bash
# Vérifier les permissions
ls -la /root/.ssh/id_builder*

# Les permissions doivent être 600 pour la clé privée
chmod 600 /root/.ssh/id_builder
```

### Les substituts ne fonctionnent pas

```bash
# Vérifier les substituters configurés
nix show-config | grep substituters

# Tester un cache manuellement
nix store ping --store https://cache.nixos.org
```
