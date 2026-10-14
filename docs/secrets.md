# Gestion des secrets — besoin d'analyse

Statut : **à analyser** (ouvert le 2026-10-14). Aucune solution n'est retenue.

## Problème

Plusieurs modules reçoivent des secrets sous forme de **chaînes Nix**. Une chaîne utilisée
dans la configuration finit dans `/nix/store`, qui est lisible par tous les utilisateurs de
la machine, et persiste dans les anciennes générations. Le dépôt `nixos-modules` est
public ; les valeurs sont fournies par le dépôt (privé) des hosts.

## Inventaire

| Option                                         | Forme actuelle                 | Où le secret atterrit             |
|------------------------------------------------|--------------------------------|-----------------------------------|
| `shincraft.server.romm.db.password`            | chaîne                         | env du conteneur (unit systemd)   |
| `shincraft.server.romm.db.rootPassword`        | chaîne                         | env du conteneur `romm-db`        |
| `shincraft.server.romm.authSecretKey`          | chaîne                         | env du conteneur `romm`           |
| `shincraft.server.romm.screenscraper.password` | chaîne                         | env du conteneur `romm`           |
| `shincraft.server.romm.retroachievements.apiKey` / `steamgriddb.apiKey` | chaîne | env du conteneur `romm`        |
| `shincraft.server.auth.rootPW`                 | chaîne (hash SSHA), **valeur par défaut en dur dans le dépôt public** | config OpenLDAP |
| `shincraft.server.nextcloud.admin.passwordFile` | chemin de fichier ✅          | hors store                        |

## Questions à trancher

1. **Outil** : comparer au minimum
   - [agenix](https://github.com/ryantm/agenix) / ragenix — chiffrement `age` avec les clés SSH des hosts, un fichier par secret ;
   - [sops-nix](https://github.com/Mic92/sops-nix) — fichiers YAML/JSON chiffrés (age ou GPG), plusieurs secrets par fichier, templates ;
   - fichiers déposés à la main hors store (ex. `/var/lib/secrets`) sans outil.
2. **Où vivent les secrets chiffrés** : dans le dépôt privé des hosts (recommandé, ce dépôt-ci restant
   générique) ou dans un dépôt dédié.
3. **Interface des modules** : passer les options concernées en `…File` / `environmentFile`
   (chemins), indépendamment de l'outil choisi. Pour RomM, `virtualisation.oci-containers`
   supporte `environmentFiles`.
4. **Migration** : garder temporairement les options chaîne (dépréciées via
   `mkRenamedOptionModule` / `warnings`) ou casser l'interface d'un coup.
5. **Bootstrap** : comment une nouvelle machine obtient sa clé de déchiffrement
   (clé SSH de l'hôte, clé age dédiée…).

## Critères

- Aucun secret en clair dans `/nix/store` ni dans un dépôt git.
- Fonctionne pour les postes et les serveurs, en x86_64 comme en aarch64.
- Rotation d'un secret sans reconstruire tout le système à la main.
- Dépendance supplémentaire limitée (un input flake au plus).

## Actions immédiates possibles (sans attendre l'analyse)

- Supprimer la valeur par défaut de `auth.rootPW` (forcer le host à la fournir).
- Ajouter des variantes `…File` aux options RomM.
