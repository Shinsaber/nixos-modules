# Déployer une VM NixOS dans Proxmox

Procédure pour créer une VM Proxmox et y installer une configuration de host qui utilise
ces modules, avec [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) et
[disko](https://github.com/nix-community/disko).

Tout part du **poste d'administration** : la configuration est évaluée et construite
localement, puis poussée par SSH. La VM n'a jamais besoin d'accéder au dépôt des hosts
(qui peut donc rester privé, et dont l'input vers ces modules peut être un `path:` local).

Les valeurs ci-dessous sont des exemples (`mavm`, `mondomaine.fr`, `192.168.1.50`, VMID `120`).

## Le module `shincraft.system.proxmoxGuest`

Il regroupe ce que toute VM Proxmox répète : agent QEMU, pilotes virtio dans l'initrd,
`acpid`, SSH, bootloader, et en option le partitionnement du disque système.

| Option        | Rôle                                                                              |
|---------------|-----------------------------------------------------------------------------------|
| `enable`      | Active le profil                                                                  |
| `firmware`    | `"bios"` (SeaBIOS + grub) ou `"uefi"` (OVMF + systemd-boot) — **obligatoire**     |
| `device`      | Disque système (défaut : `/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0`)  |
| `disko`       | Partitionne le disque système avec disko (GPT, boot, racine ext4 sur le reste)    |
| `rootSshKeys` | Clés SSH publiques autorisées pour root                                           |

Avec `disko = true`, les `fileSystems` du disque système sont générés automatiquement
(par label de partition) : **plus aucun UUID à recopier**. Les disques de données
supplémentaires restent déclarés à la main dans le host, pour que disko ne les reformate
jamais.

### Personnaliser le partitionnement

Le layout du module est déclaré sous `disko.devices.disk.main`, avec toutes ses valeurs en
`mkDefault` : le host peut donc le modifier ou le compléter directement.

**Changer une valeur** (taille de l'ESP, système de fichiers de la racine…) :

```nix
disko.devices.disk.main.content.partitions = {
  ESP.size              = "1G";
  root.content.format   = "xfs";
};
```

**Ajouter un disque de données** (ici `scsi1` en btrfs avec sous-volumes) :

```nix
disko.devices.disk.data = {
  type    = "disk";
  device  = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
  content = {
    type       = "gpt";
    partitions.data = {
      size    = "100%";
      content = {
        type       = "btrfs";
        subvolumes = {
          data    = { mountpoint = "/srv/data";    mountOptions = [ "noatime" "compress=zstd" ]; };
          backup  = { mountpoint = "/srv/backup";  mountOptions = [ "noatime" "compress=zstd" ]; };
        };
      };
    };
  };
};
```

**Changer la nature d'un élément** : les champs `type` (`filesystem`, `btrfs`, `EF02`…)
ne sont pas en `mkDefault`, car disko s'en sert pour choisir la structure. Pour par exemple
passer la racine en btrfs, remplacer tout le bloc avec `mkForce` :

```nix
disko.devices.disk.main.content.partitions.root.content = lib.mkForce {
  type       = "btrfs";
  subvolumes = {
    "/root".mountpoint = "/";
    "/nix"  = { mountpoint = "/nix"; mountOptions = [ "noatime" "compress=zstd" ]; };
  };
};
```

**Layout entièrement personnalisé** : laisser `disko = false` et écrire son propre
`disko.devices` dans le host. Le module disko reste importé ; `proxmoxGuest` gère toujours
le reste (et, en BIOS, laisse disko indiquer le disque à grub).

> ⚠ nixos-anywhere **formate tous les disques déclarés** dans `disko.devices`. Un disque qui
> contient déjà des données (réinstallation du système, disque réattaché) ne doit pas y
> figurer : le déclarer dans `fileSystems` comme d'habitude. Un simple `nixos-rebuild`,
> lui, ne formate jamais rien.

### BIOS ou UEFI ?

Pour une nouvelle VM, **UEFI** est conseillé :
- systemd-boot est plus simple que grub et ne dépend pas du chemin du disque ;
- le passthrough PCIe (GPU pour le transcodage, par exemple) fonctionne nettement mieux en
  `q35` + OVMF ;
- Secure Boot reste possible plus tard (lanzaboote).

Contrepartie : un disque EFI (`efidisk0`) en plus dans Proxmox, et il faut **décocher
« Pre-Enroll keys »**, sinon Secure Boot est actif et l'ISO NixOS ne démarre pas.

Une VM existante en BIOS n'a aucune raison de changer : passer en UEFI implique de
réinstaller.

## 1. Préparer le fichier du host

Dans le dépôt des hosts, créer `hosts/mavm.nix` :

```nix
{ config, pkgs, lib, ... }:
{
  shincraft = {
    system.proxmoxGuest = {
      enable      = true;
      firmware    = "uefi";
      disko       = true;
      rootSshKeys = [ "ssh-ed25519 AAAAC3Nza... moi@poste" ];
    };
    users.moi = {
      user-config.extraGroups = [ "wheel" ];
    };
    shell.zsh.enable = true;
  };

  networking = {
    hostName = "mavm";
    domain   = "mondomaine.fr";
  };
  time.timeZone = "Europe/Paris";

  # Version de NixOS de la première installation : ne plus la changer ensuite.
  system.stateVersion = "26.05";
}
```

Puis l'ajouter au `flake.nix` du dépôt des hosts :

```nix
mavm = shinsaber.nixos.lib.nixosSystem {
  system  = "x86_64-linux";
  modules = [
    shinsaber.nixosModules.general
    shinsaber.nixosModules.server   # si la VM utilise des modules serveur
    ./hosts/mavm.nix
  ];
};
```

Vérifier que la configuration s'évalue avant d'aller plus loin :

```sh
nix eval --raw '.#nixosConfigurations.mavm.config.system.build.toplevel.drvPath'
```

## 2. Créer la VM dans Proxmox

Télécharger l'ISO **minimale** de NixOS dans le stockage ISO de Proxmox, puis créer la VM
(ici en ligne de commande sur le nœud Proxmox ; l'interface web propose les mêmes réglages) :

```sh
qm create 120 --name mavm --ostype l26 \
  --memory 4096 --cores 2 --cpu host \
  --machine q35 --bios ovmf \
  --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=0 \
  --scsihw virtio-scsi-single --scsi0 local-lvm:32,discard=on,iothread=1 \
  --net0 virtio,bridge=vmbr0 \
  --agent enabled=1 \
  --cdrom local:iso/nixos-minimal-26.05-x86_64-linux.iso \
  --boot 'order=scsi0;ide2'
qm start 120
```

En BIOS : retirer `--machine q35 --bios ovmf --efidisk0 …` et mettre `firmware = "bios"`
dans le host.

Le disque doit rester sur **`scsi0`** (valeur par défaut de l'option `device`).
L'ordre de démarrage `scsi0` puis CD permet de démarrer sur l'ISO tant que le disque est
vide, puis directement sur le disque une fois NixOS installé.

> Astuce : créer une fois la même VM sous un VMID dédié (ex. `9000`), **sans la démarrer**,
> puis la convertir en template avec `qm template 9000`. Chaque nouvelle VM se crée ensuite
> avec `qm clone 9000 121 --name autrevm --full` (ajuster disque et mémoire avec `qm set`).

## 3. Ouvrir l'accès SSH à l'installeur

Dans la console Proxmox de la VM (ISO NixOS démarrée) :

```sh
sudo passwd root   # mot de passe temporaire, il disparaît avec l'installation
ip -brief address  # relever l'IP, ex. 192.168.1.50
```

Depuis le poste, copier la clé pour éviter de retaper le mot de passe :

```sh
ssh-copy-id root@192.168.1.50
```

## 4. Installer

### Secrets sops

Si le host utilise `shincraft.system.sops`, sa clé SSH host est sa clé de déchiffrement :
la générer **avant** l'installation, pour que les secrets fonctionnent dès le premier démarrage.

```sh
tmp=$(mktemp -d)
install -d -m 755 "$tmp/etc/ssh"
ssh-keygen -t ed25519 -N "" -C "root@mavm" -f "$tmp/etc/ssh/ssh_host_ed25519_key"
nix shell nixpkgs#ssh-to-age -c ssh-to-age < "$tmp/etc/ssh/ssh_host_ed25519_key.pub"   # → age1…
```

Ajouter la clé `age1…` dans le `.sops.yaml` du dépôt des hosts, puis créer le fichier de
secrets du host (`sops secrets/mavm.yaml`), ou lancer `sops updatekeys` s'il existe déjà
(voir [secrets.md](secrets.md)).

### Lancer l'installation

Depuis le dépôt des hosts, sur le poste :

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#mavm \
  --target-host root@192.168.1.50 \
  --extra-files "$tmp"     # seulement avec sops : dépose la clé host préparée
rm -rf "$tmp"
```

nixos-anywhere partitionne le disque avec disko, construit le système sur le poste, le
copie, l'installe et redémarre la VM. Ensuite, retirer l'ISO de la VM
(`qm set 120 --delete ide2`) et supprimer l'ancienne empreinte SSH, qui a changé :

```sh
ssh-keygen -R 192.168.1.50
```

L'utilisateur n'a pas de mot de passe après l'installation (les modules n'en gèrent pas) :
se connecter en `root` par clé, puis `passwd moi`.

## 5. Mettre à jour

Chaque modification de la configuration se déploie depuis le poste :

```sh
nixos-rebuild switch --flake .#mavm --target-host root@mavm.mondomaine.fr
```

L'évaluation a toujours lieu sur le poste : la VM n'a pas besoin d'accéder au dépôt.
Par défaut, la construction aussi, puis le résultat est copié sur la VM. Deux variantes :

```sh
# Construction sur le poste, mais la VM télécharge elle-même depuis cache.nixos.org
# ce qui s'y trouve : seuls les paquets compilés localement passent par le poste.
nixos-rebuild switch --flake .#mavm --target-host root@mavm.mondomaine.fr --use-substitutes

# Construction sur la VM : seules les recettes (.drv) lui sont envoyées, elle télécharge
# et compile elle-même, et le résultat n'a pas à revenir sur le poste.
nixos-rebuild switch --flake .#mavm \
  --build-host root@mavm.mondomaine.fr --target-host root@mavm.mondomaine.fr
```

| Situation                                       | Options                               |
|-------------------------------------------------|---------------------------------------|
| Poste puissant, bon réseau local                | `--target-host` seul                  |
| Envoi lent depuis le poste (VPN, 4G…)           | `--target-host` + `--use-substitutes` |
| Gros builds, serveur plus puissant que le poste | `--build-host` + `--target-host`      |

## Utiliser le module sur une VM déjà installée

Pas besoin de réinstaller. Remplacer dans le host le bloc commun (agent QEMU, `acpid`,
`sshd`, `boot.loader.grub`, `boot.initrd.availableKernelModules`) par :

```nix
shincraft.system.proxmoxGuest = {
  enable      = true;
  firmware    = "bios";   # le firmware actuel de la VM
  rootSshKeys = [ "ssh-ed25519 AAAAC3Nza... moi@poste" ];
};
```

**Sans `disko`** : les `fileSystems` existants (UUID) restent en place.

Pour le **premier** déploiement à distance, root n'a pas encore la clé. Deux solutions :
- la déposer une fois à la main sur la VM :
  `sudo install -Dm600 /dev/stdin /root/.ssh/authorized_keys <<< "ssh-ed25519 AAAA… moi@poste"` ;
- ou faire ce premier `nixos-rebuild switch` directement sur la VM.

Ensuite, `nixos-rebuild switch --flake .#<host> --target-host root@<host>` fonctionne comme
pour une nouvelle VM.

Un déploiement par un utilisateur non root (`--sudo`) demanderait en plus
`nix.settings.trusted-users`, car le démon Nix refuse les chemins non signés venant d'un
utilisateur non autorisé. Le passage par root avec une clé évite ce réglage.
