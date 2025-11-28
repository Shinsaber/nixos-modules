# Module Build - Compilation et Génération à Distance

Ce module permet de configurer la compilation et la génération à distance dans NixOS, ainsi que la gestion des caches de substitution binaires.

## Vue d'ensemble

Le module `shincraft.system.build` fournit des options pour :

- **Builders distants** : Déléguer les compilations à des machines plus puissantes
- **Caches de substitution** : Télécharger des binaires pré-compilés
- **Configuration serveur** : Transformer une machine en builder distant
- **Paramètres de build** : Contrôler les timeouts, jobs parallèles, etc.

## Structure

```
build/
├── default.nix    # Définition des options
├── remote.nix     # Implémentation de la configuration
├── EXAMPLE.md     # Exemples d'utilisation détaillés
└── README.md      # Cette documentation
```

## Activation de base

```nix
{
  shincraft.system.build.remote.enable = true;
}
```

## Configuration rapide

### Builder distant simple

```nix
{
  shincraft.system.build.remote = {
    enable = true;

    builders.main = {
      hostName = "builder.local";
      system = [ "x86_64-linux" ];
      maxJobs = 8;
      sshUser = "nix-builder";
      sshKey = "/root/.ssh/id_builder";
    };
  };
}
```

### Ajouter un cache de substitution

```nix
{
  shincraft.system.build.remote = {
    enable = true;

    substituters.company = {
      url = "https://cache.company.com";
      publicKeys = [ "cache-key:ABC123..." ];
      priority = 30;
    };
  };
}
```

### Configurer comme builder distant

```nix
{
  shincraft.system.build.remote = {
    enable = true;
    acceptRemoteBuilds = true;
    authorizedBuilderKeys = [
      "ssh-ed25519 AAAAC... user@machine"
    ];
  };
}
```

## Options principales

### `shincraft.system.build.remote`

| Option                   | Type  | Défaut | Description                         |
| ------------------------ | ----- | ------ | ----------------------------------- |
| `enable`                 | bool  | false  | Active le module                    |
| `builders`               | attrs | {}     | Configuration des builders distants |
| `substituters`           | attrs | {}     | Configuration des caches            |
| `maxJobs`                | int?  | null   | Jobs parallèles locaux              |
| `buildCores`             | int?  | null   | Cœurs par job                       |
| `maxSilentTime`          | int   | 3600   | Timeout de silence (s)              |
| `timeout`                | int   | 36000  | Timeout total (s)                   |
| `buildersUseSubstitutes` | bool  | true   | Builders peuvent utiliser caches    |
| `alwaysAllowSubstitutes` | bool  | true   | Toujours permettre les caches       |
| `acceptRemoteBuilds`     | bool  | false  | Accepter builds distants            |
| `authorizedBuilderKeys`  | list  | []     | Clés SSH autorisées                 |
| `enableDebugTools`       | bool  | false  | Installer outils debug              |

## Configuration détaillée

### Builders distants

Chaque builder est défini par un ensemble d'attributs :

```nix
builders.<name> = {
  hostName = "...";              # Requis
  system = [ "x86_64-linux" ];   # null = auto
  sshUser = "nix-builder";       # Défaut
  sshKey = "/path/to/key";       # null = défaut
  maxJobs = 4;                   # Défaut
  speedFactor = 1;               # 1-3 typiquement
  supportedFeatures = [...];     # Liste des features
  mandatoryFeatures = [];        # Features obligatoires
  publicHostKey = null;          # Pour vérification
};
```

**Features courantes** :

- `nixos-test` : Tests NixOS
- `benchmark` : Benchmarks
- `big-parallel` : Builds très parallèles
- `kvm` : Virtualisation KVM

### Caches de substitution

```nix
substituters.<name> = {
  url = "https://...";           # Requis
  publicKeys = [ "..." ];        # Pour vérification
  priority = 40;                 # Plus bas = préféré
};
```

**Priorités standards** :

- 30 : Haute priorité (caches privés)
- 40 : Priorité normale (cache.nixos.org)
- 50 : Basse priorité (fallback)

## Workflow typique

### 1. Préparation de la clé SSH

```bash
# Sur la machine client
ssh-keygen -t ed25519 -f /root/.ssh/id_builder -N ""

# Copier sur le builder
ssh-copy-id -i /root/.ssh/id_builder.pub nix-builder@builder.local
```

### 2. Configuration du builder

```nix
# Sur builder.local
{
  shincraft.system.build.remote = {
    enable = true;
    acceptRemoteBuilds = true;
    authorizedBuilderKeys = [
      "ssh-ed25519 AAAAC... root@client"
    ];
  };
}
```

### 3. Configuration du client

```nix
# Sur le client
{
  shincraft.system.build.remote = {
    enable = true;
    builders.main = {
      hostName = "builder.local";
      sshKey = "/root/.ssh/id_builder";
      maxJobs = 8;
      speedFactor = 2;
    };
  };
}
```

### 4. Test

```bash
# Vérifier la connexion
nix store ping --store ssh://nix-builder@builder.local

# Build de test
nix build nixpkgs#hello
```

## Cas d'usage avancés

### Build ARM depuis x86_64

```nix
{
  shincraft.system.build.remote = {
    enable = true;
    builders = {
      arm-builder = {
        hostName = "raspberrypi.local";
        system = [ "aarch64-linux" ];
        maxJobs = 4;
        speedFactor = 1;
        sshUser = "nix-builder";
        sshKey = "/root/.ssh/id_builder";
      };
    };
  };
}
```

### Multiple caches avec priorités

```nix
{
  shincraft.system.build.remote = {
    enable = true;
    substituters = {
      private = {
        url = "https://nix-cache.company.internal";
        publicKeys = [ "..." ];
        priority = 20;  # Très prioritaire
      };
      nixos = {
        url = "https://cache.nixos.org";
        publicKeys = [ "cache.nixos.org-1:..." ];
        priority = 40;  # Standard
      };
      community = {
        url = "https://nix-community.cachix.org";
        publicKeys = [ "..." ];
        priority = 50;  # Fallback
      };
    };
  };
}
```

### Farm de builders

```nix
{
  shincraft.system.build.remote = {
    enable = true;
    builders = {
      fast1 = {
        hostName = "builder1.local";
        maxJobs = 16;
        speedFactor = 3;
      };
      fast2 = {
        hostName = "builder2.local";
        maxJobs = 16;
        speedFactor = 3;
      };
      slow = {
        hostName = "builder3.local";
        maxJobs = 4;
        speedFactor = 1;
      };
    };
    # Désactive les builds locaux
    maxJobs = 0;
  };
}
```

## Dépannage

Voir le fichier [EXAMPLE.md](./EXAMPLE.md) pour des exemples détaillés et des conseils de dépannage.

### Commandes utiles

```bash
# Vérifier la configuration
nix show-config | grep -E "(builders|substituters)"

# Voir les builders configurés
cat /etc/nix/machines

# Logs du daemon Nix
journalctl -u nix-daemon -f

# Forcer l'utilisation des builders
nix build --option builders-use-substitutes false ...
```

## Intégration avec d'autres modules

Ce module est compatible avec :

- `shincraft.system.nix.autoUpgrade` : Auto-upgrade utilisera les builders
- `shincraft.system.nix.optiStore` : Optimisation du store fonctionne avec les builds distants
- `shincraft.system.batterysave` : Les timers de build respectent le mode batterie

## Références

- [NixOS Manual - Distributed Builds](https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html)
- [Nix Manual - Substituters](https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-substituters)
- [Cachix - Binary Cache Hosting](https://cachix.org/)

## Auteur

Module créé pour le projet `nixos-modules` de Shinsaber.
