---
name: verifier
description: Évalue les configurations NixOS du dépôt privé des hosts avec la copie locale de ces modules pour valider une modification. À utiliser après toute modification d'un fichier .nix.
argument-hint: "[host…|all]"
allowed-tools: Bash(nix eval:*), Bash(nix flake check:*), Bash(nix flake show:*), Bash(git diff:*), Bash(git status:*), Bash(git add:*)
---

# Vérifier les modules sur les hosts

Ce dépôt est public : les informations sur les hosts (chemin du dépôt, nom de l'input,
noms de machines, erreurs connues) sont dans `CLAUDE.local.md`, jamais dans ce fichier.
Si `CLAUDE.local.md` n'existe pas, demande le chemin du dépôt des hosts et le nom de
l'input, puis propose de créer `CLAUDE.local.md` (il est ignoré par git).

Ne recopie aucune de ces informations dans un fichier suivi par git.

## Étapes

0. **Tests du dépôt** : dans ce dépôt, `nix flake check` (les fichiers nouveaux doivent être
   suivis par git : `git add -N <fichier>` suffit). En cas d'échec d'un cas, relancer
   `nix eval .#checks.x86_64-linux.<cas> --show-trace`. Si la modification ajoute, renomme ou
   retire une option, mettre à jour `tests/workstation.nix` ou `tests/server.nix` (activation +
   vérification) avant de passer aux hosts.
1. **Lister les hosts** (ne pas se fier à une liste figée) :
   ```sh
   cd <DEPOT_HOSTS> && nix eval --no-write-lock-file \
     --override-input <INPUT> path:<CHEMIN_DE_CE_DEPOT> \
     '.#nixosConfigurations' --apply builtins.attrNames
   ```
2. **Choisir les hosts** :
   - Si `$ARGUMENTS` contient des noms de hosts, utiliser ceux-là ; `all` = tous.
   - Sinon, déduire depuis `git diff --stat` : changement dans `modules/server/` → les hosts
     qui importent `nixosModules.server` ; dans `modules/general/`, `packages/` ou
     `flake.nix` → un host « general » + un host « server ».
3. **Évaluer chaque host** (en parallèle si plusieurs, ~1 min chacun) :
   ```sh
   cd <DEPOT_HOSTS> && nix eval --no-write-lock-file \
     --override-input <INPUT> path:<CHEMIN_DE_CE_DEPOT> \
     --raw '.#nixosConfigurations."<HOST>".config.system.build.toplevel.drvPath'
   ```
   Ne jamais omettre `--no-write-lock-file`. En cas d'erreur, relancer avec `--show-trace`.
4. **Vérifier la couverture** : regarder dans la configuration du host si l'option modifiée
   y est réellement activée. Sinon, dire clairement que le nouveau code n'a pas été évalué
   (le `mkIf` est resté faux).
5. **Rapport** (dans la conversation uniquement) : pour chaque host, ✅ ou ❌ avec l'erreur
   résumée. Signaler les `evaluation warning`. Distinguer les erreurs causées par la
   modification de celles préexistantes (voir « État connu » dans `CLAUDE.local.md`) ;
   en cas de doute, réévaluer après `git stash`.

Ne lance pas de build ni de `nixos-rebuild`, ne modifie pas le dépôt des hosts et ne lis pas
ses secrets.
