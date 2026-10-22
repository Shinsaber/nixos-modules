# AGENTS.md

Instructions pour les assistants IA (Claude Code, Copilot, Codex…) qui travaillent sur ce dépôt.

## Le projet

Flake Nix qui expose des **modules NixOS réutilisables** sous l'espace d'options `shincraft.*`.
Il ne contient **aucune machine** : les hosts sont définis dans un dépôt de configuration
**privé** séparé, qui consomme ce flake.

## ⚠ Ce dépôt est public

Ne jamais écrire dans un fichier suivi par git (code, docs, commits, PR) d'information
venant du dépôt privé des hosts ou de la machine locale : noms de machines, domaines,
adresses IP, chemins locaux, noms d'utilisateurs, contenu des configurations de hosts,
état ou erreurs de ces hosts. Ces informations vont uniquement dans les fichiers locaux
ignorés par git (`CLAUDE.local.md`, `AGENTS.local.md`, `.claude/settings.local.json`).
Les exemples de documentation utilisent des valeurs fictives (`mondomaine.fr`, `192.168.1.10`…).

Sorties du flake ([flake.nix](flake.nix)) :

| Sortie                     | Contenu                                                                 |
|----------------------------|-------------------------------------------------------------------------|
| `nixosModules.general`     | `./packages` (overlay) + `./modules/general` + home-manager, disko, sops-nix |
| `nixosModules.server`      | `./packages` (overlay) + `./modules/server` (toujours combiné à `general`) |
| `packages.x86_64-linux.nixvim` | Neovim configuré via nixvim (`./packages/nvim`)                     |
| `nixos`, `unstable`        | Les nixpkgs réexportés ; les hosts appellent `shinsaber.nixos.lib.nixosSystem` |

Versions : NixOS **26.05** (`nixos`), home-manager `release-26.05`, nixvim `nixos-26.05`,
et `nixos-unstable` disponible dans les modules via l'argument `unstable`.

## Arborescence

```
modules/
  general/
    default.nix        # ⚠ déclare la plupart des options shincraft.* (gui, system, shell, tools, users)
    gui/ system/ shell/ tools/ users/   # implémentations (config = mkIf …)
  server/
    <service>/default.nix   # chaque service déclare SES options + sa config
packages/
  default.nix          # overlay nixpkgs (openjdk7, maven-3-8-4, java7-helper, freelens, jellyfin-web patché)
  nvim/                # module nixvim
```

### Deux styles de déclaration d'options coexistent

- **`modules/general`** : les options sont centralisées dans
  [modules/general/default.nix](modules/general/default.nix) ; les sous-modules ne font que
  `config = mkMerge [ (mkIf cfg.x { … }) ]`. Pour ajouter une option « general », il faut
  donc modifier **deux fichiers** (la déclaration + l'implémentation).
- **`modules/server`** : chaque service est autonome
  (`options.shincraft.server.<service> = { … }; config = mkIf cfg.enable { … };`).
  C'est le style à privilégier pour tout nouveau module serveur
  (exemple de référence : [modules/server/romm/default.nix](modules/server/romm/default.nix)).
  Exception historique : `jellyfin` (et `transmission`, `jellyseerr`) et `nginx` déclarent des
  options directement sous `shincraft.server`.

Tout nouveau dossier doit être ajouté à la liste `imports` du `default.nix` parent.

### Arguments de module spéciaux

Injectés via `_module.args` dans [flake.nix](flake.nix) (uniquement pour `general`) :
- `unstable` : nixpkgs unstable (ex. VSCodium dans `users/vscodium.nix`).
- `packages.nixvim` : le paquet Neovim construit par le flake.

Ils ne sont **pas** disponibles dans les modules `server` s'ils sont importés seuls.

### Utilisateurs (`shincraft.users.<nom>`)

`modules/general/users` génère à la fois `users.users.<nom>` et `home-manager.users.<nom>`
à partir du sous-module `userModule` (options `user-config.*` et `home-config.*`).
Les réglages par utilisateur passent par home-manager (`useGlobalPkgs = true`).

## Conventions de code

- Squelette de module :
  ```nix
  { config, lib, pkgs, ... }:
  let
    cfg = config.shincraft.<chemin>;
  in
  with lib;
  with types;
  {
    options.shincraft.<chemin> = { … };
    config = mkMerge [
      (mkIf cfg.enable { … })
    ];
  }
  ```
- Indentation 2 espaces. Les `=` des blocs d'options sont **alignés en colonnes**
  (`type    = str;`). Conserver cet alignement.
- **Ne pas lancer de formateur** (`nixpkgs-fmt`, `nixfmt`, `alejandra`) sur des fichiers
  entiers : il casserait l'alignement et produirait des diffs énormes.
- Booléens simples : `mkEnableOption "…"`. Autres options : `mkOption` avec `type`,
  `default`, `example` et `description`.
- Langue : les descriptions et commentaires récents sont en **français** ; les libellés de
  `mkEnableOption` sont souvent en anglais. Suivre le style du fichier modifié.
- Valeurs qu'un host doit pouvoir surcharger : `mkDefault`.
- Messages de commit : courts, sans convention imposée (ex. `Add romm`, `Update flake`).

## Vérifier une modification

Ce dépôt n'a ni tests ni CI. La seule validation fiable est d'**évaluer une configuration
de host** du dépôt privé consommateur, en remplaçant son input par la copie locale de ce dépôt :

```sh
cd <DEPOT_HOSTS>
nix eval --no-write-lock-file \
  --override-input <INPUT> path:<CHEMIN_DE_CE_DEPOT> \
  --raw '.#nixosConfigurations."<HOST>".config.system.build.toplevel.drvPath'
```

- Chemin du dépôt, nom de l'input et liste des hosts : voir `CLAUDE.local.md` / `AGENTS.local.md`
  (fichiers locaux). Sans eux, demander à l'utilisateur.
- `--no-write-lock-file` est indispensable : sans lui le `flake.lock` du dépôt des hosts est modifié.
- ~1 minute par host. Pour un module serveur, évaluer un host qui importe `nixosModules.server`.
  Si l'option n'est activée sur aucun host, l'évaluation ne teste pas le nouveau code :
  le signaler plutôt que d'affirmer que c'est validé.
- Vérification rapide de la structure du flake : `nix flake show`.
- Une évaluation qui réussit n'est **pas** un build : ne pas lancer `nixos-rebuild` ni
  `nix build` d'un système complet sans le demander.

## À ne pas faire

- Ne pas lancer `nix flake update` / modifier `flake.lock` sans demande explicite.
- Ne pas modifier le dépôt des hosts sauf demande explicite.
- Ne pas mettre de secrets réels dans ce dépôt (il est public sur GitHub). Pour un nouveau
  secret : option `…File` de type `nullOr str`, `null` par défaut = secret sops nommé
  `<service>/<nom>` (voir [docs/secrets.md](docs/secrets.md) et le module `kanidm`). Jamais de chaîne :
  elle finirait lisible dans `/nix/store`.
- Ne pas toucher aux images de `modules/general/system/splash/src/` (thèmes Plymouth).

## Points connus du code (dette existante)

À connaître pour ne pas être surpris ; ne pas corriger sans demande :
- `shincraft.server.jellyseerr` est déclarée mais sans effet (Seerr est activé avec `jellyfin`).
- `home-config.ssh.listAlias` accepte l'ancien format `matchBlocks` grâce à une conversion
  dans [modules/general/users/default.nix](modules/general/users/default.nix)
  (`sshAliasToSettings`) pour rester compatible avec les configurations existantes.
- `modules/general/system/splash/` contient son propre `flake.nix` (non utilisé par le flake racine).
- Mettre à jour l'arbre d'options du [README.md](README.md) quand on ajoute ou renomme une option.
