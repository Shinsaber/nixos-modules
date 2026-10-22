# Nextcloud (`shincraft.server.nextcloud`)

Notes d'usage du module. Valeurs d'exemple : `cloud.mondomaine.fr`, proxy `192.168.1.10`,
VPN `10.8.0.0/24`.

## Exemple de host

```nix
shincraft.server.nextcloud = {
  enable         = true;
  hostName       = "cloud.mondomaine.fr";
  openFirewall   = true;               # port 80, pour le reverse proxy
  trustedProxies = [ "192.168.1.10" ];
  apps           = [ "calendar" "contacts" "tasks" "notes" "memories" "maps" "previewgenerator" ];
};
```

Et sur la VM du reverse proxy :

```nix
shincraft.server.nginx.domain."mondomaine.fr".cloud = {
  host        = "192.168.1.20";
  port        = 80;
  maxBodySize = "16G";                 # aligné sur maxUploadSize
  allowFrom   = [ "10.8.0.0/24" ];     # accès réservé au VPN
};
```

## Compte administrateur

Par défaut, l'installation ne crée **aucun** admin : aucun mot de passe n'a besoin d'exister
sur la VM avant le premier démarrage. Une fois la VM installée :

```sh
nextcloud-occ user:add --group admin --display-name "Moi" moi   # demande le mot de passe
```

`nextcloud-occ` est fourni par NixOS (il s'exécute avec l'utilisateur `nextcloud`).
Le mot de passe se change ensuite dans l'interface ou avec
`nextcloud-occ user:resetpassword moi`.

Pour créer l'admin dès l'installation : `admin.user` + `admin.passwordFile` (fichier déposé
par exemple avec `nixos-anywhere --extra-files`, lu uniquement à l'installation).

## Applications

L'App Store est désactivé : toutes les apps sont installées, activées et mises à jour par Nix
(avec le flake). Deux sources :

- **`apps`** : noms des apps packagées dans nixpkgs. Liste :
  `nix eval --json nixpkgs#nextcloud33.packages.apps --apply builtins.attrNames` ;
- **`extraApps`** : les autres, avec `pkgs.fetchNextcloudApp` (URL de l'archive de release,
  `hash`, `license`). Pour le hash, mettre `lib.fakeHash`, évaluer, et recopier la valeur
  donnée par l'erreur.

Apps utiles :

| Besoin                    | App                                  | Source        |
|---------------------------|--------------------------------------|---------------|
| Galerie photo, timeline   | `memories`                           | nixpkgs       |
| Aperçus des photos RAW    | `camerarawpreviews`                  | `extraApps`   |
| Génération des aperçus    | `previewgenerator`                   | nixpkgs       |
| Traces GPX sur carte      | `maps`                               | nixpkgs       |
| Agenda, contacts, tâches  | `calendar`, `contacts`, `tasks`      | nixpkgs       |
| SSO (OIDC)                | `user_oidc`                          | nixpkgs       |

Memories utilise exiftool et ffmpeg. Les binaires fournis avec l'app ne fonctionnent pas sous
NixOS : pointer vers ceux de nixpkgs.

```nix
shincraft.server.nextcloud.extraSettings = {
  "memories.exiftool"          = lib.getExe pkgs.exiftool;
  "memories.exiftool_no_local" = true;
  "memories.vod.ffmpeg"        = lib.getExe' pkgs.ffmpeg-headless "ffmpeg";
  "memories.vod.ffprobe"       = lib.getExe' pkgs.ffmpeg-headless "ffprobe";
};
```

## Stockage S3 (ex. OVH Object Storage)

```nix
shincraft.server.nextcloud.s3 = {
  enable     = true;
  bucket     = "nextcloud";
  hostname   = "s3.gra.io.cloud.ovh.net";
  region     = "gra";
  key        = "<access key ID>";
  # secretFile non renseigné : clé secrète lue dans le secret sops `nextcloud/s3-secret`
};
```

À savoir avant de l'activer :
- **à décider dès l'installation** : il n'y a pas de migration officielle entre le stockage
  local et S3, dans un sens comme dans l'autre ;
- les fichiers sont stockés sous forme d'objets `urn:oid:<id>` : le bucket n'est pas lisible
  sans la base de données. **Sauvegarder PostgreSQL** est donc indispensable ;
- les aperçus (`appdata`) vont aussi dans le bucket : prévoir leur volume et le nombre de
  requêtes dans le coût ;
- la clé secrète vient de sops (`nextcloud/s3-secret`, voir [secrets.md](secrets.md)) ; un fichier
  déposé à la main reste possible avec `secretFile` (lu par systemd, `root:root 0600` suffit).

## SSO avec Kanidm

```nix
shincraft.server.nextcloud.oidc = {
  enable       = true;
  discoveryUri = "https://idm.mondomaine.fr/oauth2/openid/nextcloud/.well-known/openid-configuration";
};
```

L'app `user_oidc` est ajoutée automatiquement et le fournisseur est déclaré au démarrage
(`nextcloud-oidc-provider.service`), avec le secret sops `oidc/nextcloud`. La connexion locale
reste possible (compte admin créé en CLI). Côté Kanidm : voir [kanidm.md](kanidm.md).

## Édition de documents avec ONLYOFFICE

Deux morceaux : le **Document Server** (`shincraft.server.onlyoffice`, gourmand : prévoir
au moins 2 vCPU et 4 Go de RAM, idéalement sur sa propre VM) et l'app Nextcloud `onlyoffice`.
Ils s'authentifient mutuellement avec un secret JWT partagé, `onlyoffice/jwt-secret`, qui doit
avoir **la même valeur** dans les fichiers sops des deux hosts (`openssl rand -hex 32`).

VM Document Server (ex. `192.168.1.40`) :

```nix
shincraft.server.onlyoffice = {
  enable                = true;
  hostName              = "office.mondomaine.fr";
  openFirewall          = true;
  allowLocalConnections = true;   # si cloud.mondomaine.fr résout vers une IP privée
};
```

Le module active PostgreSQL, RabbitMQ et un vhost nginx local (port 80). Le nonce des liens
sécurisés est généré sur la machine au premier démarrage : pas de secret à gérer pour lui.

VM Nextcloud :

```nix
shincraft.server.nextcloud.onlyoffice = {
  enable            = true;
  documentServerUrl = "https://office.mondomaine.fr/";
};
```

L'app `onlyoffice` est installée, l'URL est écrite dans `config.php` et le secret JWT y est
fusionné au démarrage depuis sops (`services.nextcloud.secretFile`), sans passer par le store.

Reverse proxy :

```nix
shincraft.server.nginx.domain."mondomaine.fr".office = {
  host        = "192.168.1.40";
  port        = 80;
  maxBodySize = "100M";
};
```

### Flux réseau

Le navigateur, Nextcloud et le Document Server se parlent tous par les **URL publiques**,
donc par le reverse proxy :

| De                | Vers                     | Pourquoi                                     |
|-------------------|--------------------------|----------------------------------------------|
| Navigateur        | `office.mondomaine.fr`   | éditeur (WebSocket)                          |
| Nextcloud         | `office.mondomaine.fr`   | vérification du serveur, conversions         |
| Document Server   | `cloud.mondomaine.fr`    | téléchargement du fichier, enregistrement    |

Avec `allowFrom` (accès réservé au VPN) sur ces sous-domaines, **ajouter aussi les IP des
VM Nextcloud et Document Server**, sinon l'ouverture ou l'enregistrement échoue en 403.

Si Nextcloud refuse de joindre le Document Server parce qu'il résout vers une IP privée
(« Error when trying to connect »), ajouter
`extraSettings.allow_local_remote_servers = true;`.

## Sauvegardes

Avec le stockage S3, **la base de données est la seule carte du bucket** : sans elle, les
objets `urn:oid:<id>` sont inexploitables. À activer avant de mettre des données.

Dès que `shincraft.system.backup` est activé sur le host (voir [backup.md](backup.md)), le
module enregistre le job `nextcloud` :
- dump PostgreSQL de la base `nextcloud` ;
- `/var/lib/nextcloud/config` : le `config.php` contient `secret`, `passwordsalt` et
  `instanceid`, indispensables à une restauration.

Secret sops : `backup/nextcloud-password` (mot de passe du dépôt restic).

Versioning conseillé aussi sur le bucket **des fichiers** Nextcloud : une base restaurée peut
référencer des fichiers effacés depuis la sauvegarde.

Sans stockage S3 pour les fichiers, ajouter leur dossier :
`shincraft.system.backup.jobs.nextcloud.paths = [ "/var/lib/nextcloud/data" ];`.

### Vérifier et restaurer

La commande `restic-nextcloud` (installée par le module) a déjà le dépôt, le mot de passe et
les identifiants S3 :

```sh
systemctl start restic-backups-nextcloud      # lancer une sauvegarde maintenant
restic-nextcloud snapshots                    # lister les sauvegardes
restic-nextcloud check                        # vérifier l'intégrité du dépôt
```

Restauration de la base et de la configuration :

```sh
restic-nextcloud restore latest --target /tmp/restore
nextcloud-occ maintenance:mode --on
systemctl stop phpfpm-nextcloud.service nextcloud-cron.timer   # libère les connexions à la base
sudo -u postgres dropdb nextcloud
zstd -dc /tmp/restore/var/backup/postgresql/nextcloud.sql.zst | sudo -u postgres psql
cp -a /tmp/restore/var/lib/nextcloud/config/config.php /var/lib/nextcloud/config/
systemctl start phpfpm-nextcloud.service nextcloud-cron.timer
nextcloud-occ maintenance:mode --off
```

Le dump est fait avec `-C` : il recrée la base `nextcloud`, dont le rôle propriétaire est créé
par le module. **Tester une restauration une fois**, sur une VM de test, avant d'en avoir besoin.
