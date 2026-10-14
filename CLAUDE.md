@AGENTS.md

## Spécifique à Claude Code

- Répondre en français.
- Le contexte privé (dépôt des hosts, machines) est dans `CLAUDE.local.md`, chargé
  automatiquement et ignoré par git. Ne jamais en recopier le contenu ailleurs.
- Skills du projet : `/verifier` (évalue les hosts avec la copie locale) et
  `/nouveau-module` (crée un module en suivant les conventions).
- Après toute modification d'un `.nix`, lancer `/verifier` sur au moins un host concerné
  avant d'annoncer que c'est terminé.
