---
name: nouveau-module
description: Crée un nouveau module NixOS shincraft (serveur ou général) en respectant les conventions du dépôt, puis met à jour imports et README.
argument-hint: "<server|general> <nom> [description]"
---

# Créer un module shincraft

Demande : `$ARGUMENTS`. Si le type (`server` / `general`) ou le nom manque, demande-le.

## Module serveur (`modules/server/<nom>/default.nix`)

Module autonome qui déclare ses propres options. Prendre
`modules/server/romm/default.nix` (conteneurs OCI) ou `modules/server/nextcloud/default.nix`
(service NixOS natif) comme modèle selon le cas.

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.shincraft.server.<nom>;
in
with lib;
with types;
{
  options.shincraft.server.<nom> = {
    enable = mkEnableOption "Install <Nom> in the system";

    port = mkOption {
      type        = ints.u16;
      default     = <port>;
      description = "Port d'écoute du service <Nom>";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # …
    })
  ];
}
```

Puis ajouter `./<nom>` à `imports` dans `modules/server/default.nix`.

Points d'attention :
- Préférer un service NixOS natif (`services.<nom>`) s'il existe dans nixpkgs 26.05 ;
  sinon `virtualisation.oci-containers` avec une **image à version fixe** (jamais `latest`).
- Secrets : option `passwordFile`/`environmentFile` (chemin) plutôt qu'une chaîne en clair.
- Exposition web : ne pas ouvrir le firewall par défaut ; l'utilisateur passera par
  `shincraft.server.nginx.domain`.

## Module général (`modules/general/<catégorie>/…`)

Les options générales sont centralisées :
1. Déclarer l'option dans `modules/general/default.nix`, au bon endroit de l'arbre
   `options.shincraft` (ou dans `userModule` si c'est une option par utilisateur).
2. Implémenter dans le sous-module concerné avec `config = mkMerge [ (mkIf cfg.… { … }) ];`
   (créer un fichier et l'ajouter aux `imports` si nécessaire).
3. Option par utilisateur → implémenter dans `modules/general/users/default.nix`
   (côté `users.users` ou `home-manager.users`).

## Finalisation

- Aligner les `=` comme le reste du fichier ; ne pas lancer de formateur.
- Ajouter l'option dans l'arbre d'options de `README.md` (section correspondante).
- Activer le module dans `tests/server.nix` ou `tests/workstation.nix` avec au moins une
  vérification de son effet (port fermé, secret déclaré, service activé…), puis `nix flake check`.
- Lancer `/verifier` sur un host adapté et préciser que l'option n'étant activée sur aucun
  host, seule la non-régression y est validée : la couverture vient des tests.
