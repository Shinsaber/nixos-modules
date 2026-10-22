# Gestion des secrets — sops-nix

[sops-nix](https://github.com/Mic92/sops-nix).

Plusieurs secrets par fichier, **templates** (fichiers
d'environnement composés, ex. RomM), redémarrage automatique des services quand un secret
change (`restartUnits`), noms des secrets lisibles dans les diffs.

## Principe

- Les fichiers de secrets sont **chiffrés** (YAML) et vivent dans le dépôt **privé** des hosts.
  Ce dépôt-ci ne contient que les noms des secrets attendus.
- Au build, seul le fichier chiffré entre dans `/nix/store`. Les services reçoivent un
  **chemin** (`/run/secrets/<nom>`).
- À l'activation, sops-nix déchiffre avec la **clé SSH host** de la machine
  (`/etc/ssh/ssh_host_ed25519_key`, convertie en clé age) vers un ramfs : rien en clair sur
  disque ni dans le store.
- Ne **jamais** lire un secret à l'évaluation (`builtins.readFile`, interpolation dans une
  chaîne) : il serait recopié en clair dans le store. Toujours passer le chemin, ou
  `sops.placeholder` dans un `sops.templates`.

## Activation dans un host

```nix
shincraft.system.sops = {
  enable          = true;
  defaultSopsFile = ../secrets/mavm.yaml;
};
```

Les modules serveur déclarent eux-mêmes leurs secrets dans ce fichier, sous des noms fixes.
Chaque option `…File` reste prioritaire : si elle est renseignée, le module utilise ce fichier
au lieu de sops.

## Noms des secrets attendus

| Module                  | Secret sops                      | Quand                                            |
| ----------------------- | -------------------------------- | ------------------------------------------------ |
| `server.nextcloud.s3`   | `nextcloud/s3-secret`            | `s3.enable`, sans `s3.secretFile`                |
| `server.nextcloud.oidc` | `oidc/<clientId>`                | `oidc.enable`, sans `clientSecretFile`           |
| `server.kanidm`         | `kanidm/admin-password`          | sans `adminPasswordFile`                         |
|                         | `kanidm/idm-admin-password`      | sans `idmAdminPasswordFile`                      |
|                         | `oidc/<client>`                  | pour chaque `oauth2.<client>`, sans `secretFile` |
| `server.onlyoffice`     | `onlyoffice/jwt-secret`          | sans `jwtSecretFile` (même valeur côté Nextcloud) |
| `server.nextcloud.onlyoffice` | `onlyoffice/jwt-secret`  | `onlyoffice.enable`                              |
| `system.backup`         | `backup/s3-secret`               | `backup.enable`, s'il y a au moins un job       |
|                         | `backup/<job>-password`          | pour chaque job (`nextcloud`, `kanidm`, `romm`…) |
| `server.romm`           | `romm/db-password`               | toujours                                         |
|                         | `romm/db-root-password`          | toujours                                         |
|                         | `romm/auth-secret-key`           | toujours (`openssl rand -hex 32`)                |
|                         | `romm/screenscraper-password`    | `screenscraper.enable`                           |
|                         | `romm/retroachievements-api-key` | `retroachievements.enable`                       |
|                         | `romm/steamgriddb-api-key`       | `steamgriddb.enable`                             |

Un fichier de secrets prend la forme d'un YAML imbriqué (la clé `nextcloud/s3-secret`
correspond à `nextcloud:` → `s3-secret:`) :

```yaml
nextcloud:
  s3-secret: "…"
oidc:
  nextcloud: "…"
```

## Mise en place (dépôt des hosts)

1. **Clé personnelle** (pour éditer les secrets) : au choix.

   - **Sa clé SSH ed25519** (recommandé, rien à générer) : mettre **directement** la clé
     publique SSH dans `.sops.yaml` (`ssh-ed25519 AAAA…`, contenu de `~/.ssh/id_ed25519.pub`).
     sops lit tout seul `~/.ssh/id_ed25519` pour déchiffrer (autre chemin :
     `SOPS_AGE_SSH_PRIVATE_KEY_FILE`). Si la clé a une passphrase, sops la demande à chaque
     commande : il ne passe pas par `ssh-agent`.
   - **Une clé age dédiée** :

     ```sh
     mkdir -p ~/.config/sops/age
     nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt   # affiche la clé publique age1…
     ```

   ⚠ Pour sa clé SSH personnelle, utiliser la forme `ssh-ed25519 AAAA…` et **pas** sa
   conversion `ssh-to-age` : sops déchiffre avec la clé SSH telle quelle, qui ne correspond
   qu'à un destinataire `ssh-ed25519`. Pour les **hosts**, c'est l'inverse (étape 2) :
   sops-nix convertit la clé SSH host en clé age, donc le destinataire doit être le `age1…`
   donné par `ssh-to-age`.

2. **Clé d'un host** existant (clé publique age dérivée de sa clé SSH host) :

   ```sh
   ssh-keyscan -t ed25519 mavm.mondomaine.fr | nix shell nixpkgs#ssh-to-age -c ssh-to-age
   ```

   Pour une **nouvelle VM**, générer la clé host à l'avance et la déposer à l'installation :
   voir [proxmox.md](proxmox.md#secrets-sops).

3. **`.sops.yaml`** à la racine du dépôt des hosts : qui peut déchiffrer quel fichier.

   ```yaml
   keys:
     - &moi ssh-ed25519 AAAA… # clé personnelle (~/.ssh/id_ed25519.pub, sans le commentaire)
     - &mavm age1bbbb… # clé du host mavm
     - &idm age1cccc… # clé du host idm
   creation_rules:
     - path_regex: secrets/mavm\.yaml$
       key_groups: [{ age: [*moi, *mavm] }]
     - path_regex: secrets/idm\.yaml$
       key_groups: [{ age: [*moi, *idm] }]
   ```

4. **Créer ou éditer** un fichier : `nix shell nixpkgs#sops -c sops secrets/mavm.yaml`.
5. **Après un ajout de destinataire** dans `.sops.yaml` : `sops updatekeys secrets/mavm.yaml`.
6. **Déployer** : `nixos-rebuild switch --target-host …`. Les services concernés redémarrent
   automatiquement.

## Secret partagé entre deux hosts (OIDC)

Le secret d'un client OIDC est connu à la fois du fournisseur (Kanidm) et du service
(Nextcloud), sous le même nom `oidc/<client>`. Deux possibilités :

- mettre **la même valeur** dans le fichier de chaque host ;
- ou un fichier commun `secrets/oidc.yaml` chiffré pour les deux hosts, référencé dans chacun :
  `sops.secrets."oidc/nextcloud".sopsFile = ../secrets/oidc.yaml;`.

Générer la valeur avec `openssl rand -hex 32`.

## À savoir

- **MariaDB (RomM)** ne lit ses mots de passe qu'à la création de la base : en migrant une
  installation existante, reprendre les **mêmes** valeurs dans sops.
- **Rotation** : éditer le fichier avec `sops`, puis déployer.
- La clé SSH host d'une machine **est** sa clé de déchiffrement : la régénérer (réinstallation
  sans la conserver) oblige à mettre à jour `.sops.yaml` puis à lancer `sops updatekeys`.
