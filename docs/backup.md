# Sauvegardes (`shincraft.system.backup`)

Sauvegardes [restic](https://restic.net) vers un bucket S3 (ex. OVH Object Storage).
Chaque service a **son propre dépôt restic** et **sa propre clé de chiffrement** : la fuite du
mot de passe d'un service ne donne pas accès aux sauvegardes des autres.

## Activation dans un host

```nix
shincraft.system.sops.enable = true;   # obligatoire : les secrets passent par sops

shincraft.system.backup = {
  enable   = true;
  bucket   = "backups";
  hostname = "s3.gra.io.cloud.ovh.net";
  region   = "gra";
  key      = "<access key ID>";
};
```

Les modules serveur s'enregistrent tout seuls dans `backup.jobs` : il n'y a rien d'autre à
déclarer. Un job par service, déposé dans `s3:https://<hostname>/<bucket>/<host>/<job>` :

| Job         | Contenu                                                                  |
|-------------|--------------------------------------------------------------------------|
| `nextcloud` | dump PostgreSQL de `nextcloud` + `/var/lib/nextcloud/config` (`config.php`) |
| `kanidm`    | exports nocturnes de Kanidm (`online_backup`, 02:00, 7 versions locales)  |
| `romm`      | dump MariaDB (`mariadb-dump` dans le conteneur `romm-db`), sans la bibliothèque |

Déroulement (03:00 par défaut, rattrapé au démarrage si la machine était éteinte) :
1. les bases déclarées dans `postgresDatabases` sont dumpées (`pg_dump`, zstd) dans
   `/var/backup/postgresql/<base>.sql.zst` ;
2. `prepareCommand` est exécuté s'il est défini ;
3. restic chiffre, déduplique et envoie les chemins, puis applique la rétention
   (7 quotidiennes, 4 hebdomadaires, 6 mensuelles par défaut).

## Secrets sops

| Secret                   | Rôle                                                                        |
|--------------------------|-----------------------------------------------------------------------------|
| `backup/s3-secret`       | Clé secrète S3, commune aux dépôts du host                                  |
| `backup/<job>-password`  | Mot de passe du dépôt restic du job. **Sans lui, ce dépôt est illisible.**  |

Générer chaque mot de passe avec `openssl rand -hex 32`. Comme ils sont dans le fichier sops du
dépôt des hosts, ils survivent à la perte de la machine.

## Ajuster les jobs depuis le host

```nix
shincraft.system.backup.jobs = {
  nextcloud.paths     = [ "/var/lib/nextcloud/data" ];   # fichiers, si Nextcloud n'est pas sur S3
  kanidm.pruneOpts    = [ "--keep-daily 30" ];           # rétention propre à un job
  romm.enable         = false;                           # désactiver un job

  # job libre
  documents = {
    paths          = [ "/srv/documents" ];
    prepareCommand = "systemctl stop mon-service";
  };
};
```

## Bucket et clés

- **Bucket dédié aux sauvegardes**, distinct de celui des fichiers Nextcloud : une suppression
  dans l'un n'atteint pas l'autre.
- **Clé S3 dédiée**, limitée à ce bucket : la clé de Nextcloud ne peut alors pas effacer les
  sauvegardes. La clé de sauvegarde, elle, peut effacer tous les dépôts du bucket (elle doit
  écrire et appliquer la rétention).
- Activer le **versioning** (voire l'Object Lock) sur le bucket : protège contre un effacement
  par la machine elle-même.
- Même fournisseur = même point de défaillance : pour une vraie règle 3-2-1, ajouter plus tard
  une seconde copie (`restic copy` vers un autre dépôt, autre région, disque local).

## Commandes utiles

Le module restic installe une commande `restic-<job>` par job, avec le dépôt, le mot de passe
et les identifiants S3 déjà configurés :

```sh
systemctl start restic-backups-nextcloud     # lancer une sauvegarde maintenant
restic-nextcloud snapshots                   # lister les sauvegardes
restic-nextcloud check                       # vérifier l'intégrité du dépôt
restic-nextcloud restore latest --target /tmp/restore
```

Procédures de restauration : [Nextcloud](nextcloud.md#vérifier-et-restaurer),
[Kanidm](kanidm.md#sauvegarde-et-restauration), [RomM](#restaurer-romm). **En tester une** sur une VM de test avant
d'en avoir besoin.

## Restaurer RomM

Le job `romm` ne contient que la base (collections, utilisateurs, métadonnées, progression).
La bibliothèque et les assets (`rommDataPath` : ROMs, sauvegardes de jeux, captures) n'y sont
pas : les ajouter si besoin avec `shincraft.system.backup.jobs.romm.paths`.

```sh
restic-romm restore latest --target /tmp/restore
systemctl stop podman-romm.service                 # la base reste démarrée
zstd -dc /tmp/restore/var/backup/romm/romm.sql.zst \
  | podman exec -i romm-db sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot'
systemctl start podman-romm.service
```

Le dump contient `CREATE DATABASE` et recrée les tables : il remplace le contenu actuel de la base.
