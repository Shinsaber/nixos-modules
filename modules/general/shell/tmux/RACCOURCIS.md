# 🎯 Guide des Raccourcis Tmux

> Configuration tmux personnalisée avec intégration NeoVim et menu contextuel intelligent

## 🎨 Légende

| Symbole | Signification                                                           |
| ------- | ----------------------------------------------------------------------- |
| 🔄      | **Adaptatif Vim** - Le comportement change selon que vim/nvim est actif |
| 🖱️      | **Compatible Souris** - Fonctionne aussi avec la souris                 |
| ⚡      | **Raccourci Global** - Fonctionne sans préfixe Leader                   |
| 🎯      | **Contextuel** - Apparaît seulement dans certaines situations           |

## 🚀 Navigation NeoVim

> Intégration intelligente avec NeoVim pour une navigation fluide

### Détection automatique

- La configuration détecte automatiquement si NeoVim/Vim est actif
- Les raccourcis s'adaptent selon le contexte

## 📖 Table des matières

- [Préfixe et Base](#préfixe-et-base)
- [Sessions](#sessions)
- [Fenêtres](#fenêtres)
- [Panneaux](#panneaux)
- [Navigation NeoVim](#navigation-neovim)
- [Mode Copie](#mode-copie)
- [Souris et Menu Contextuel](#souris-et-menu-contextuel)
- [Aide](#aide)

---

## 🔑 Préfixe et Base

| Raccourci     | Action      | Description                         |
| ------------- | ----------- | ----------------------------------- |
| `Ctrl+Espace` | **Préfixe** | Préfixe principal (remplace Ctrl+B) |

---

## 🖥️ Sessions

### Création et Gestion

| Raccourci      | Action                  | Description                                   |
| -------------- | ----------------------- | --------------------------------------------- |
| `Leader + C-c` | Nouvelle session        | Crée une nouvelle session tmux                |
| `Leader + C-s` | Nouvelle session nommée | Demande un nom pour la nouvelle session       |
| `Leader + $`   | Renommer session        | Renomme la session courante                   |
| `Leader + Q`   | Tuer session            | Ferme la session courante (avec confirmation) |

### Navigation

| Raccourci       | Action             | Description                                    |
| --------------- | ------------------ | ---------------------------------------------- |
| `Leader + C-l`  | Liste sessions     | Interface interactive pour choisir une session |
| `Leader + C-w`  | Vue complète       | Sessions + fenêtres + panneaux dans une vue    |
| `Leader + BTab` | Dernière session   | Bascule vers la dernière session active        |
| `Leader + C-p`  | Session précédente | Va à la session précédente                     |
| `Leader + C-n`  | Session suivante   | Va à la session suivante                       |

### Commandes depuis le terminal

```bash
tmux ls                   # Lister toutes les sessions
tmux new -s nom           # Créer session nommée
tmux attach -t nom        # Se connecter à une session
tmux kill-session -t nom  # Tuer une session
```

---

## 🪟 Fenêtres

### Création et Gestion

| Raccourci    | Action                  | Description                                   |
| ------------ | ----------------------- | --------------------------------------------- |
| `Leader + c` | Nouvelle fenêtre        | Crée une fenêtre dans le répertoire courant   |
| `Leader + C` | Nouvelle fenêtre nommée | Demande un nom pour la nouvelle fenêtre       |
| `Leader + ,` | Renommer fenêtre        | Renomme la fenêtre courante                   |
| `Leader + M` | Renommage manuel        | Désactive le renommage auto et renomme        |
| `Leader + X` | Tuer fenêtre            | Ferme la fenêtre courante (avec confirmation) |

### Navigation

| Raccourci      | Action             | Description                             |
| -------------- | ------------------ | --------------------------------------- |
| `Leader + C-t` | Fenêtre précédente | Va à la fenêtre précédente              |
| `Leader + C-n` | Fenêtre suivante   | Va à la fenêtre suivante                |
| `Leader + Tab` | Dernière fenêtre   | Bascule vers la dernière fenêtre active |
| `Leader + 1-9` | Fenêtre par numéro | Accès direct aux fenêtres 1 à 9         |

---

## 🔲 Panneaux

### Création et Division

| Raccourci       | Action               | Description                                  |
| --------------- | -------------------- | -------------------------------------------- |
| `Leader + s` 🔄 | Division horizontale | Si vim: `:split`, sinon: tmux split          |
| `Leader + v` 🔄 | Division verticale   | Si vim: `:vsplit`, sinon: tmux split         |
| `Leader + x` 🖱️ | Tuer panneau         | Ferme le panneau courant (avec confirmation) |

### Navigation

| Raccourci  | Action         | Description                        |
| ---------- | -------------- | ---------------------------------- |
| `C-t` ⚡🔄 | Panneau gauche | Va au panneau à gauche (vim-aware) |
| `C-s` ⚡🔄 | Panneau bas    | Va au panneau du bas (vim-aware)   |
| `C-r` ⚡🔄 | Panneau haut   | Va au panneau du haut (vim-aware)  |
| `C-n` ⚡🔄 | Panneau droit  | Va au panneau à droite (vim-aware) |

### Manipulation

| Raccourci       | Action              | Description                       |
| --------------- | ------------------- | --------------------------------- |
| `Leader + >` 🖱️ | Échanger suivant    | Échange avec le panneau suivant   |
| `Leader + <` 🖱️ | Échanger précédent  | Échange avec le panneau précédent |
| `Leader + +` 🖱️ | Maximiser/Restaurer | Bascule le zoom du panneau        |

### Redimensionnement

| Raccourci    | Action            | Description                     |
| ------------ | ----------------- | ------------------------------- |
| `Leader + T` | Réduire largeur   | Réduit la largeur de 2 unités   |
| `Leader + S` | Augmenter hauteur | Augmente la hauteur de 2 unités |
| `Leader + R` | Réduire hauteur   | Réduit la hauteur de 2 unités   |
| `Leader + N` | Augmenter largeur | Augmente la largeur de 2 unités |

---

## 📋 Mode Copie

### Activation

| Raccourci        | Action     | Description                    |
| ---------------- | ---------- | ------------------------------ |
| `Leader + Enter` | Mode copie | Entre en mode copie (style vi) |

### Navigation en mode copie

| Raccourci  | Action         | Description                                 |
| ---------- | -------------- | ------------------------------------------- |
| `C-t` ⚡🔄 | Panneau gauche | Va au panneau à gauche (même en mode copie) |
| `C-s` ⚡🔄 | Panneau bas    | Va au panneau du bas (même en mode copie)   |
| `C-r` ⚡🔄 | Panneau haut   | Va au panneau du haut (même en mode copie)  |
| `C-n` ⚡🔄 | Panneau droit  | Va au panneau à droite (même en mode copie) |

### Sélection et copie (style vi)

| Raccourci | Action                  | Description                          |
| --------- | ----------------------- | ------------------------------------ |
| `v`       | Commencer sélection     | Mode sélection visuelle              |
| `C-v`     | Sélection rectangulaire | Bascule en sélection bloc            |
| `y`       | Copier et quitter       | Copie la sélection et quitte le mode |
| `Escape`  | Annuler                 | Annule et quitte le mode copie       |
| `T`       | Début de ligne          | Va au début de la ligne              |
| `N`       | Fin de ligne            | Va à la fin de la ligne              |
| `/`       | Recherche avant         | Recherche vers l'avant               |
| `?`       | Recherche arrière       | Recherche vers l'arrière             |

### Tampons

| Raccourci    | Action         | Description                       |
| ------------ | -------------- | --------------------------------- |
| `Leader + b` | Lister tampons | Affiche tous les tampons de copie |
| `Leader + p` | Coller         | Colle depuis le tampon principal  |
| `Leader + P` | Choisir tampon | Interface pour choisir le tampon  |

---

## 🖱️ Souris et Menu Contextuel

### Support souris

- **Activation** : `set -g mouse on`
- **Défilement** : Molette de la souris
- **Sélection** : Clic et glisser
- **Redimensionnement** : Glisser les bordures

### Menu contextuel intelligent

#### Activation

| Action              | Résultat                                       |
| ------------------- | ---------------------------------------------- |
| **Clic droit** 🖱️🔄 | Affiche le menu contextuel adaptatif selon vim |

#### Menu Standard

- **Titre** : `[Numéro panneau] (ID panneau)`
- **Options** : Actions tmux standard

#### Menu Vim (quand NeoVim/Vim détecté)

- **Titre** : `[Numéro panneau] (ID panneau) [VIM]` 🔄
- **Options vim** 🎯 :
  - `w` : Vim Save (`:w`)
  - `q` : Vim Save & Quit (`:wq`)
  - `Q` : Vim Quit (`:q!`)
  - `H` : Vim Split Horizontal (`:split`)
  - `V` : Vim Split Vertical (`:vsplit`)
  - `t` : Vim New Tab (`:tabnew`)

#### Actions contextuelles (les deux menus)

| Contexte                   | Actions disponibles                            |
| -------------------------- | ---------------------------------------------- |
| **Mode copie** 🎯          | Go To Top `<`, Go To Bottom `>`                |
| **Mot sous souris** 🎯🖱️   | Search For, Type, Copy                         |
| **Ligne sous souris** 🎯🖱️ | Copy Line                                      |
| **Lien sous souris** 🎯🖱️  | Type hyperlink, Copy hyperlink                 |
| **Panneaux tmux** 🖱️       | Split Horizontal `h`, Split Vertical `v`       |
| **Gestion** 🖱️             | Swap Up/Down/Marked, Kill, Respawn, Mark, Zoom |

---

## 🆘 Aide

### Raccourcis d'aide

| Raccourci    | Action                    | Description                      |
| ------------ | ------------------------- | -------------------------------- |
| `Leader + h` | Aide interactive          | Popup avec résumé des raccourcis |
| `Leader + m` | Activer/désactiver souris | Bascule le support souris        |

### Écran et historique

| Raccourci | Action        | Description                               |
| --------- | ------------- | ----------------------------------------- |
| `C-l` ⚡  | Effacer écran | Efface l'écran (garde l'historique)       |
| `C-k` ⚡  | Effacer tout  | Efface l'écran + supprime l'historique    |
| `C-f` ⚡  | Recherche zsh | Active la recherche dans l'historique zsh |

---

## 🔧 Configuration avancée

### Variables importantes

```bash
# Détection NeoVim/Vim
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^S (n?vim?x?)(-wrapped)?(diff)?$'"

# Préfixe personnalisé
set-option -g prefix C-Space
```

### Intégration système

- **Wayland** : Copie vers `wl-copy`
- **X11** : Copie vers `xclip`
- **UTF-8** : Support complet
- **Couleurs** : True color (24-bit)

### Optimisations

- **Temps d'échappement** : 10ms (plus rapide)
- **Délai de répétition** : 600ms
- **Historique** : 10,000 lignes
- **Rafraîchissement status** : 10 secondes

---

## 💡 Conseils d'utilisation

1. **Apprentissage progressif** : Commencez par les raccourcis de base
2. **Menu contextuel** : Utilisez le clic droit pour découvrir les options
3. **Aide intégrée** : `Leader + h` pour un rappel rapide
4. **Vim intégration** : Les raccourcis s'adaptent automatiquement
5. **Souris** : Activée par défaut pour faciliter la transition

---

_Configuration créée pour une expérience tmux moderne et intuitive_ ✨
