# Kanidm (`shincraft.server.kanidm`)

Fournisseur d'identité : comptes, groupes, **OIDC** pour les applications, **TOTP** et
**passkeys**. Chaque utilisateur gère lui-même son mot de passe, son OTP et ses passkeys
depuis le portail Kanidm.

Valeurs d'exemple : Kanidm sur `idm.mondomaine.fr` (VM `192.168.1.30`), Nextcloud sur
`cloud.mondomaine.fr`, reverse proxy `192.168.1.10`.

## Host Kanidm

```nix
shincraft.system.sops = { enable = true; defaultSopsFile = ../secrets/idm.yaml; };

shincraft.server.kanidm = {
  enable       = true;
  domain       = "idm.mondomaine.fr";
  openFirewall = true;
  oauth2.nextcloud = {
    displayName   = "Nextcloud";
    originUrl     = "https://cloud.mondomaine.fr/apps/user_oidc/code";
    originLanding = "https://cloud.mondomaine.fr";
  };
};
```

Secrets attendus dans `secrets/idm.yaml` (générer avec `openssl rand -hex 32`) :

```yaml
kanidm:
  admin-password: "…"
  idm-admin-password: "…"
oidc:
  nextcloud: "…"
```

Ce que fait le module :
- serveur Kanidm en HTTPS sur le port 8443, avec un **certificat auto-signé** généré au
  premier démarrage dans `/var/lib/kanidm-tls`. Le certificat public est celui du reverse
  proxy ; `tls.chainFile` / `tls.keyFile` permettent d'en fournir un autre ;
- mots de passe de `admin` et `idm_admin` fixés depuis sops ;
- pour chaque `oauth2.<client>` : le client OIDC, son secret (sops `oidc/<client>`) et un
  groupe d'accès `<client>_users`. Les **membres** du groupe se gèrent dans Kanidm : Nix ne
  les écrase pas.

⚠ `domain` est l'identité de tous les comptes : le changer plus tard invalide les passkeys.

## Reverse proxy

Kanidm n'écoute qu'en HTTPS : le proxy s'y connecte en `https` (certificat non vérifié).

```nix
shincraft.server.nginx.domain."mondomaine.fr".idm = {
  host     = "192.168.1.30";
  port     = 8443;
  protocol = "https";
};
```

## Gérer les comptes

Depuis la VM Kanidm (la commande `kanidm` est installée et pointe sur `https://<domain>`) :

```sh
kanidm login -D idm_admin                    # mot de passe : sops kanidm/idm-admin-password
kanidm person create alice "Alice"
kanidm person update alice --mail alice@mondomaine.fr
kanidm group add-members nextcloud_users alice
kanidm person credential create-reset-token alice
```

La dernière commande donne un lien (et un QR code) à transmettre à l'utilisateur : il y
définit son mot de passe, son TOTP et/ou une passkey. Ensuite, il gère lui-même ses
identifiants depuis `https://idm.mondomaine.fr`. Aucun serveur mail n'est nécessaire.

Les comptes peuvent aussi être déclarés en Nix (`services.kanidm.provision.persons`), mais ce
n'est pas obligatoire : les deux modes coexistent.

## Côté Nextcloud

```nix
shincraft.server.nextcloud.oidc = {
  enable       = true;
  discoveryUri = "https://idm.mondomaine.fr/oauth2/openid/nextcloud/.well-known/openid-configuration";
};
```

Le module installe l'app `user_oidc` et déclare le fournisseur au démarrage
(`nextcloud-oidc-provider.service`). Le secret `oidc/nextcloud` doit avoir **la même valeur**
dans les fichiers sops des deux hosts : voir [secrets.md](secrets.md#secret-partagé-entre-deux-hosts-oidc).

Kanidm impose PKCE et des jetons signés en ES256 : `user_oidc` gère les deux. L'identifiant
Nextcloud de l'utilisateur est son nom court Kanidm (`alice`).

## Sauvegarde et restauration

Le module active l'export intégré de Kanidm (`online_backup`) : chaque nuit à 02:00, un export
cohérent de la base est écrit dans `/var/lib/kanidm/backups` (7 versions gardées). Il contient
tout : comptes, groupes, mots de passe, TOTP, passkeys, clés de signature OIDC.

Avec `shincraft.system.backup` activé sur le host (voir [backup.md](backup.md)), le job
`kanidm` envoie ces exports sur S3 à 03:00, dans son propre dépôt restic (secret sops
`backup/kanidm-password`).

Restauration (serveur **arrêté**, la commande `restore` travaille hors ligne) :

```sh
restic-kanidm restore latest --target /tmp/restore
ls /tmp/restore/var/lib/kanidm/backups/                      # choisir l'export voulu
systemctl stop kanidm
install -o kanidm -g kanidm -m 0600 /tmp/restore/var/lib/kanidm/backups/<export>.json /var/lib/kanidm/backups/
config=$(systemctl cat kanidm | grep -o '/nix/store/[^ ]*server.toml' | head -1)
sudo -u kanidm kanidmd database restore -c "$config" /var/lib/kanidm/backups/<export>.json
systemctl start kanidm
```

Le `domain` de la configuration doit être le même que celui de la sauvegarde.
