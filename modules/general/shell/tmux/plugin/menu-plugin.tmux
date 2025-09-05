#!/usr/bin/env bash

# Plugin de menu tmux avec navigation hiérarchique
# Auteur: Configuration tmux personnalisée
# Version: 1.1

# === CONFIGURATION PROJETS ===
# Obtenir le chemin absolu de ce script
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# Fichiers de configuration possibles (par ordre de priorité)
CONFIG_FILES="$HOME/.config/tmux/projects.conf"

# ---------------------------------------------
# === FONCTIONS DU MENU PROJETS ===
# ---------------------------------------------

# Charger la configuration des projets
load_projects_config() {
    if [ ! -f "$CONFIG_FILES" ]; then
        return 1
    fi
    
    # Lire le fichier de configuration
    while IFS= read -r line || [ -n "$line" ]; do
        # Ignorer les commentaires et lignes vides
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ "$line" =~ ^[[:space:]]*$ ]]; then
            continue
        fi
        
        # Format attendu: Category/Project:Path
        if [[ "$line" =~ ^([^:]+):(.+)$ ]]; then
            local project_key="${BASH_REMATCH[1]}"
            local project_path="${BASH_REMATCH[2]}"
            
            # Expansion du ~ vers $HOME
            project_path="${project_path/#\~/$HOME}"
            
            # Vérifier que le chemin existe
            if [ -d "$project_path" ]; then
                echo "$project_key:$project_path"
            fi
        fi
    done < "$CONFIG_FILES"
}

# Menu principal des projets
show_projects() {
    show_hierarchy_level
}

# Créer un fichier de configuration exemple
create_config_example() {
    local config_file="${CONFIG_FILES}"
    local config_dir=$(dirname "$config_file")
    
    # Créer le répertoire si nécessaire
    mkdir -p "$config_dir"
    
    cat > "$config_file" << 'EOF'
# Configuration des projets Tmux - Support de profondeur dynamique
# Format: Category/Subcategory/.../Project:Path
# Les chemins peuvent utiliser ~ pour le répertoire home
# Commentaires avec # et lignes vides sont ignorés
# Catégories recommandées (Avec icones):
# Personal 🏠
# Dev      💻
# Work     🏢
# Frontend 🎨
# Backend  ⚙️
# Mobile   📱
# Tools    🔧
# Scripts  📜
# Config   ⚙️
# Docs     📚
# Defaut   📂

# Projets personnels
Personal/Documents:~/Documents
Personal/Downloads:~/Downloads
Personal/Config:~/.config

# Projets de développement - Structure hiérarchique
Dev/NixOS/Hosts:~/Documents/GitHub/nixos-hosts
Dev/NixOS/Modules:~/Documents/GitHub/nixos-modules

# Raccourcis système
System/Logs:/var/log
System/Scripts:/bin

# Ajoutez vos propres projets ici...
# Exemple de structure profonde:
# Company/Department/Team/Project/Component:~/path/to/project
EOF
    tmux display-message "Configuration exemple créée: $config_file"
    sleep 1
    show_projects
}


# Obtenir les éléments d'un niveau donné dans la hiérarchie
get_level_items() {
    local path_prefix="$1"
    
    if [ -z "$path_prefix" ]; then
        # Niveau racine - obtenir les catégories de premier niveau
        load_projects_config | cut -d'/' -f1 | uniq
    else
        # Niveau intermédiaire - obtenir les sous-éléments
        load_projects_config | grep "^${path_prefix}/" | while IFS=':' read -r key path; do
            # Supprimer le préfixe pour obtenir le reste du chemin
            local remaining="${key#${path_prefix}/}"
            
            # Si le reste contient encore des /, c'est un dossier, sinon c'est un projet final
            if [[ "$remaining" == */* ]]; then
                # Obtenir le prochain niveau seulement
                echo "${remaining%%/*}" | head -1
            else
                # C'est un projet final
                echo "PROJECT:$remaining:$path"
            fi
        done | uniq
    fi
}

# Naviguer vers un projet
navigate_to_project() {
    local project_path="$1"
    local project_name="$2"
    
    if [ -z "$project_path" ] || [ ! -d "$project_path" ]; then
        tmux display-message "Erreur: Chemin invalide '$project_path'"
        return
    fi
    
    # Extraire le nom du projet pour la fenêtre
    local window_name="${project_name##*/}"  # Supprimer le préfixe catégorie/
    window_name=$(echo "$window_name" | sed 's/[^a-zA-Z0-9_-]/_/g' | tr '[:upper:]' '[:lower:]')
    
    # Vérifier si on est déjà dans la bonne arborescence
    local current_dir=$(tmux display-message -p '#{pane_current_path}')
    if [[ "$current_dir" == "$project_path"* ]]; then
        tmux display-message "Déjà dans le projet: $project_name"
        return
    fi
    
    # Proposer un menu de choix pour la navigation
    show_navigation_options "$project_path" "$project_name" "$window_name"
}

# Afficher les options de navigation pour un projet
show_navigation_options() {
    local project_path="$1"
    local project_name="$2"
    local window_name="$3"
    local menu_color="fg=#{@thm_green}"
    
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 📂 $project_name " -x C -y 0 \
        "🔙 #[fg=#{@thm_lavender}]Retour" "q" "run-shell '$SCRIPT_PATH show_projects'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "🪟 #[fg=#{@thm_blue}]Nouvelle fenêtre" "n" "run-shell '$SCRIPT_PATH create_project_window \"$project_path\" \"$project_name\" \"$window_name\"'" \
        "📂 #[fg=#{@thm_yellow}]Naviguer ici" "h" "run-shell '$SCRIPT_PATH navigate_current_pane \"$project_path\" \"$project_name\"'" \
        "🔄 #[fg=#{@thm_peach}]Nouvelle session" "s" "run-shell '$SCRIPT_PATH create_project_session \"$project_path\" \"$project_name\" \"$window_name\"'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "⬌ #[fg=#{@thm_mauve}]Panel horizontal" "H" "split-window -h -c \"$project_path\"" \
        "⬍ #[fg=#{@thm_teal}]Panel vertical" "V" "split-window -v -c \"$project_path\"" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "-🗂️ #[fg=#{@thm_subtext_0}]Chemin: $project_path" "" ""
}

# Créer une nouvelle fenêtre pour le projet
create_project_window() {
    local project_path="$1"
    local project_name="$2"
    local window_name="$3"
    
    # Vérifier si une fenêtre avec ce nom existe déjà
    if tmux list-windows -F '#{window_name}' | grep -q "^$window_name$"; then
        # La fenêtre existe, demander si on veut la réutiliser ou en créer une nouvelle
        tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},fg=#{@thm_yellow}] ⚠️ Fenêtre '$window_name' existe " -x C -y 0 \
            "🔙 #[fg=#{@thm_lavender}]Retour#[align=right,fg=#{@thm_subtext_0}]<<<" "q" "run-shell '$SCRIPT_PATH show_navigation_options \"$project_path\" \"$project_name\" \"$window_name\"'" \
            "-#[align=centre,fg=#{@thm_yellow}]──────────" "" "" \
            "🎯 #[fg=#{@thm_green}]Aller à la fenêtre" "g" "run-shell 'tmux select-window -t \"$window_name\"'" \
            "🗑️ #[fg=#{@thm_red}]Remplacer fenêtre" "r" "run-shell 'tmux kill-window -t \"$window_name\" 2>/dev/null; $SCRIPT_PATH create_project_window \"$project_path\" \"$project_name\" \"$window_name\"'"
        return
    fi
    
    # Créer la nouvelle fenêtre et naviguer vers le projet
    tmux new-window -n "$window_name" -c "$project_path"
    tmux display-message "Nouvelle fenêtre créée: $window_name -> $project_path"
}

# Naviguer dans le panneau actuel
navigate_current_pane() {
    local project_path="$1"
    local project_name="$2"
    
    # Changer le répertoire du panneau actuel
    tmux send-keys " cd '$project_path'" Enter
    sleep 0.1
    tmux display-message "Navigation: $project_name -> $project_path"
}

# Créer une nouvelle session pour le projet
create_project_session() {
    local project_path="$1"
    local project_name="$2"
    local session_name="$3"
    
    # Vérifier si une session avec ce nom existe déjà
    if tmux has-session -t "$session_name" 2>/dev/null; then
        # La session existe, demander si on veut la réutiliser ou en créer une nouvelle
        tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},fg=#{@thm_yellow}] ⚠️ Session '$session_name' existe " -x C -y 0 \
            "🔙 #[fg=#{@thm_lavender}]Retour#[align=right,fg=#{@thm_subtext_0}]<<<" "q" "run-shell '$SCRIPT_PATH show_navigation_options \"$project_path\" \"$project_name\" \"$session_name\"'" \
            "-#[align=centre,fg=#{@thm_yellow}]──────────" "" "" \
            "🎯 #[fg=#{@thm_green}]Attacher à la session" "a" "run-shell 'tmux switch-client -t \"$session_name\"'" \
            "🔄 #[fg=#{@thm_blue}]Nouvelle session (suffixe)" "n" "run-shell '$SCRIPT_PATH create_project_session \"$project_path\" \"$project_name\" \"${session_name}_$(date +%s)\"'" \
            "🗑️ #[fg=#{@thm_red}]Remplacer session" "r" "run-shell 'tmux kill-session -t \"$session_name\" 2>/dev/null; $SCRIPT_PATH create_project_session \"$project_path\" \"$project_name\" \"$session_name\"'"
        return
    fi
    
    # Créer la nouvelle session et s'y attacher
    tmux new-session -d -s "$session_name" -c "$project_path"
    tmux switch-client -t "$session_name"
    tmux display-message "Nouvelle session créée: $session_name -> $project_path"
}

# Navigation hiérarchique générique - cœur du système de profondeur dynamique
show_hierarchy_level() {
    local current_path="$1" # Peut être vide pour le niveau racine
    local menu_color="fg=#{@thm_sapphire}"
    
    # Vérifier si la configuration existe
    local has_config=false
    if [ -f "${CONFIG_FILES}" ]; then
        has_config=true
    fi
    
    if [ "$has_config" = false ]; then
        # Aucune configuration trouvée
        tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 📁 Projets " -x C -y 0 \
            "◄ #[fg=#{@thm_lavender}]Retour #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_main'" \
            "-#[align=centre,$menu_color]──────────" "" "" \
            "-⚠️ #[fg=#{@thm_yellow}]Aucune configuration trouvée" "" "" \
            "-#[align=centre,$menu_color]──────────" "" "" \
            "➕ #[fg=#{@thm_green}]Créer config exemple" e "run-shell '$SCRIPT_PATH create_config_example'"
        return
    fi
    
    # Obtenir les éléments du niveau actuel
    local items=$(get_level_items "$current_path")
    local menu_items=""
    local counter=1
    local has_projects=false
    local has_folders=false
    
    if [ ! -z "$items" ]; then
        while IFS= read -r item; do
            if [ ! -z "$item" ]; then
                local shortcut="$counter"
                
                if [[ "$item" == PROJECT:* ]]; then
                    # C'est un projet final
                    has_projects=true
                    local project_info="${item#PROJECT:}"    # Format: ProjectName:Path
                    local project_name="${project_info%%:*}" # Nom du projet
                    local project_path="${project_info#*:}"  # Chemin du projet
                    local project_display=$(echo "$project_name" | cut -c1-25) # Limiter la taille
                    
                    menu_items="$menu_items\"#[fg=#{@thm_green}]$project_display\" \"$shortcut\" \"run-shell '$SCRIPT_PATH navigate_to_project \\\"$project_path\\\" \\\"$project_name\\\"'\" "
                else
                    # C'est un dossier
                    has_folders=true
                    local folder_icon=""
                    local next_path=""
                    
                    if [ -z "$current_path" ]; then
                        next_path="$item"
                    else
                        next_path="$current_path/$item"
                    fi
                    
                    # Icônes selon le nom du dossier
                    case "$item" in
                        "Personal") folder_icon="🏠" ;;
                        "Dev") folder_icon="💻" ;;
                        "Work") folder_icon="🏢" ;;
                        "Frontend") folder_icon="🎨" ;;
                        "Backend") folder_icon="⚙️" ;;
                        "Mobile") folder_icon="📱" ;;
                        "Tools") folder_icon="🔧" ;;
                        "Scripts") folder_icon="📜" ;;
                        "Config") folder_icon="⚙️" ;;
                        "Docs") folder_icon="📚" ;;
                        "IRVE") folder_icon="🔌" ;;
                        "Citeos") folder_icon="🏢" ;;
                        *) folder_icon="📂" ;;
                    esac
                    
                    local item_display=$(echo "$item" | cut -c1-25)
                    
                    # Construire l'action de retour appropriée
                    local return_action=""
                    if [ -z "$current_path" ]; then
                        # Niveau racine vers niveau 1 : retour = show_projects
                        return_action="show_projects"
                    else
                        # Niveau 1+ vers niveau supérieur : retour = show_hierarchy_level avec le niveau parent
                        local parent_path="${current_path%/*}"
                        if [ "$parent_path" = "$current_path" ]; then
                            # current_path ne contient pas de /, donc on est au niveau 1, retour = show_projects
                            return_action="show_projects"
                        else
                            # Niveau 2+, construire le retour vers le niveau parent
                            return_action="show_hierarchy_level $parent_path"
                        fi
                    fi
                    
                    menu_items="$menu_items\"$folder_icon #[fg=#{@thm_blue}]$item_display #[align=right,fg=#{@thm_subtext_0}]>>>\" \"$shortcut\" \"run-shell '$SCRIPT_PATH show_hierarchy_level \\\"$next_path\\\"'\" "
                fi
                counter=$((counter + 1))
            fi
        done <<< "$items"
    fi
    
    # Construire le breadcrumb pour le titre
    local breadcrumb_title="📁 Projets"
    if [ ! -z "$current_path" ]; then
        local breadcrumb=$(echo "$current_path" | sed 's|/| > |g')
        breadcrumb_title="📁 $breadcrumb"
    fi
    
    # Déterminer l'action de retour appropriée
    local back_action=""
    local back_label="Retour"
    
    if [ -z "$current_path" ]; then
        # Niveau racine des projets - retour vers le menu principal
        back_action="show_main"
        back_label="Retour Menu Principal"
        menu_color="fg=#{@thm_sapphire}"
    else
        # Niveau 1+ - calculer le niveau parent
        local parent_path="${current_path%/*}"
        if [ "$parent_path" = "$current_path" ]; then
            # current_path ne contient pas de /, donc on est au niveau 1, retour = show_projects
            back_action="show_projects"
            back_label="Retour Projets"
        else
            # Niveau 2+, retour vers le niveau parent
            back_action="show_hierarchy_level \"$parent_path\""
            back_label="Retour $(echo "${parent_path%%/*}" | head -1)"
        fi
        menu_color="fg=#{@thm_blue}"
    fi
    
    if [ ! -z "$menu_items" ]; then
        local extra_options=""
        
        # Ajouter les options supplémentaires seulement au niveau racine
        if [ -z "$current_path" ]; then
            extra_options="\"-#[align=centre,$menu_color]──────────\" \"\" \"\" \
                \"🗂️ #[fg=#{@thm_peach}]Navigation directe #[align=right,fg=#{@thm_subtext_0}]>>>\" \"d\" \"run-shell '$SCRIPT_PATH show_direct_navigation'\" \
                \"📝 #[fg=#{@thm_yellow}]Éditer config\" \"e\" \"new-window -n 'Config' '$EDITOR ${CONFIG_FILES}'\" \
                \"🔄 #[fg=#{@thm_green}]Actualiser\" \"r\" \"run-shell '$SCRIPT_PATH show_projects'\""
        fi
        
        eval "tmux display-menu -T \"#[align=centre,bg=#{@thm_surface_0},$menu_color] $breadcrumb_title \" -x C -y 0 \
            \"◄ #[fg=#{@thm_lavender}]$back_label #[align=right,fg=#{@thm_subtext_0}]<<<\" \"q\" \"run-shell '$SCRIPT_PATH $back_action'\" \
            \"-#[align=centre,$menu_color]──────────\" \"\" \"\" \
            $menu_items \
            $extra_options"
    else
        tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] $breadcrumb_title " -x C -y 0 \
            "◄ #[fg=#{@thm_lavender}]$back_label #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH $back_action'" \
            "-#[align=centre,$menu_color]──────────" "" "" \
            "⚠️ #[fg=#{@thm_yellow}]Aucun élément dans cette catégorie" "" ""
    fi
}

# Navigation directe (tous les projets dans un seul menu)
show_direct_navigation() {
    local menu_color="fg=#{@thm_peach}"
    
    # Obtenir tous les projets
    local all_projects=$(load_projects_config)
    local menu_items=""
    local counter=1
    
    if [ ! -z "$all_projects" ]; then
        while IFS=':' read -r project_key project_path; do
            if [ ! -z "$project_key" ] && [ ! -z "$project_path" ]; then
                local shortcut="$counter"
                local display_name=$(echo "$project_key" | cut -c1-30)  # Limiter la taille
                
                menu_items="$menu_items\"📁 #[fg=#{@thm_green}]$display_name\" \"$shortcut\" \"run-shell '$SCRIPT_PATH navigate_to_project \\\"$project_path\\\" \\\"$project_key\\\"'\" "
                counter=$((counter + 1))
                
                # Limiter le nombre d'éléments pour éviter un menu trop long
                if [ "$counter" -gt 15 ]; then
                    break
                fi
            fi
        done <<< "$all_projects"
    fi
    
    if [ ! -z "$menu_items" ]; then
        eval "tmux display-menu -T \"#[align=centre,bg=#{@thm_surface_0},$menu_color] 🗂️ Navigation Directe \" -x C -y 0 \
            \"◄ #[fg=#{@thm_sapphire}]Retour Projets #[align=right,fg=#{@thm_subtext_0}]<<<\" \"q\" \"run-shell '$SCRIPT_PATH show_projects'\" \
            \"-#[align=centre,$menu_color]──────────\" \"\" \"\" \
            $menu_items"
    else
        tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 🗂️ Navigation Directe " -x C -y 0 \
            "◄ #[fg=#{@thm_sapphire}]Retour Projets #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_projects'" \
            "-#[align=centre,$menu_color]──────────" "" "" \
            "⚠️ #[fg=#{@thm_yellow}]Aucun projet configuré" "" ""
    fi
}

# Menu principal musique - Liste des players
show_music_players() {
    # Récupérer la liste des players disponibles
    local players_list=$(playerctl -l -i firefox 2>/dev/null || echo "")
    
    if [ -z "$players_list" ]; then
        echo ""
    else
        # Construire dynamiquement le menu avec les players disponibles
        local menu_items=""
        
        local counter=1
        while IFS= read -r player; do
            if [ ! -z "$player" ]; then
                # Raccourci basé sur le numéro du player
                local shortcut="$counter"
                local status=$(playerctl -p "$player" status 2>/dev/null || echo "Unknown")
                # Icônes selon le statut
                local status_icon="⏸"
                case "$status" in
                    "Playing") status_icon="#[fg=#{@thm_green}]▶" ;;
                    "Paused") status_icon="#[fg=#{@thm_peach}]⏸" ;;
                    "Stopped") status_icon="#[fg=#{@thm_red}]⏹"; continue ;;
                esac
                # Extraire le nom du player
                local player_name="${player%%.*}"  # Supprime .0 et ce qui suit
                menu_items="$menu_items\"🎵 $status_icon #[fg=#{@thm_pink}]$player_name #[align=right,fg=#{@thm_subtext_0}]>>>\" \"$shortcut\" \"run-shell '$SCRIPT_PATH show_music_control $player'\" "
                counter=$((counter + 1))
            fi
        done <<< "$players_list"
        # Retourner les éléments du menu
        echo "$menu_items"
    fi
}

# Menu principal
show_main() {
    # Récupérer les informations du lecteur en cours de lecture
    local music_items=$(show_music_players)
    local menu_color="fg=#{@thm_lavender}"
    
    # Construire le menu avec ou sans info musicale
    if [ ! -z "$music_items" ]; then
        eval "tmux display-menu -T \"#[align=centre,bg=#{@thm_surface_0},$menu_color] 󰹯 Menu Principal \" -x C -y 0 \
            \"📁 #[fg=#{@thm_sapphire}]Projets #[align=right,fg=#{@thm_subtext_0}]>>>\" \"j\" \"run-shell '$SCRIPT_PATH show_projects'\" \
            $music_items \
            \"-#[align=centre,$menu_color]──────────\" \"\" \"\" \
            \"🖥️ #[fg=#{@thm_blue}]Sessions #[align=right,fg=#{@thm_subtext_0}]>>>\" \"s\" \"run-shell '$SCRIPT_PATH show_sessions'\" \
            \"🪟 #[fg=#{@thm_green}]Fenêtres #[align=right,fg=#{@thm_subtext_0}]>>>\" \"w\" \"run-shell '$SCRIPT_PATH show_windows'\" \
            \"🔲 #[fg=#{@thm_mauve}]Panneaux #[align=right,fg=#{@thm_subtext_0}]>>>\" \"p\" \"run-shell '$SCRIPT_PATH show_panes'\" \
            \"🧰 #[fg=#{@thm_yellow}]Outils #[align=right,fg=#{@thm_subtext_0}]>>>\" \"t\" \"run-shell '$SCRIPT_PATH show_tools'\" \
            \"-#[align=centre,$menu_color]──────────\" \"\" \"\" \
            \"🆘 #[fg=#{@thm_red}]Aide Raccourcis\" \"?\" \"display-popup -E -w 77 -h 21 '\$tmux_help'\""
    else
        tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 󰹯 Menu Principal " -x C -y 0 \
            "📁 #[fg=#{@thm_sapphire}]Projets #[align=right,fg=#{@thm_subtext_0}]>>>" "j" "run-shell '$SCRIPT_PATH show_projects'" \
            "-#[align=centre,$menu_color]──────────" "" "" \
            "🖥️ #[fg=#{@thm_blue}]Sessions #[align=right,fg=#{@thm_subtext_0}]>>>" "s" "run-shell '$SCRIPT_PATH show_sessions'" \
            "🪟 #[fg=#{@thm_green}]Fenêtres #[align=right,fg=#{@thm_subtext_0}]>>>" "w" "run-shell '$SCRIPT_PATH show_windows'" \
            "🔲 #[fg=#{@thm_mauve}]Panneaux #[align=right,fg=#{@thm_subtext_0}]>>>" "p" "run-shell '$SCRIPT_PATH show_panes'" \
            "🧰 #[fg=#{@thm_yellow}]Outils #[align=right,fg=#{@thm_subtext_0}]>>>" "t" "run-shell '$SCRIPT_PATH show_tools'" \
            "-#[align=centre,$menu_color]──────────" "" "" \
            "🆘 #[fg=#{@thm_red}]Aide Raccourcis" "?" "display-popup -E -w 77 -h 21 '$tmux_help'"
    fi
}

# Menu Sessions
show_sessions() {
    local menu_color="fg=#{@thm_blue}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 🖥️ Gestion Sessions " -x C -y 0 \
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_main'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "➕ #[fg=#{@thm_green}]Nouvelle Session" n "new-session" \
        "📝 #[fg=#{@thm_yellow}]Nouvelle Session Nommée" m "command-prompt -p 'Nom: ' 'new-session -d -s %%'" \
        "📋 #[fg=#{@thm_blue}]Lister Sessions" l "choose-tree -s -O time" \
        "✏️ #[fg=#{@thm_peach}]Renommer Session" r "command-prompt -I '#S' 'rename-session %%'" \
        "🔌 #[fg=#{@thm_teal}]Détacher Session" d "detach-client" \
        "❌ #[fg=#{@thm_red}]Tuer Session" k "confirm-before 'kill-session'"
}

# Menu Fenêtres
show_windows() {
    local menu_color="fg=#{@thm_green}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 🪟 Gestion Fenêtres " -x C -y 0 \
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_main'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "➕ #[fg=#{@thm_green}]Nouvelle Fenêtre" n "new-window -c '#{pane_current_path}'" \
        "📝 #[fg=#{@thm_yellow}]Nouvelle Fenêtre Nommée" m "command-prompt -p 'Nom: ' 'new-window -n %% -c #{pane_current_path}'" \
        "✏️ #[fg=#{@thm_peach}]Renommer Fenêtre" r "command-prompt -I '#W' 'rename-window %%'" \
        "📦 #[fg=#{@thm_blue}]Déplacer Fenêtre" d "command-prompt -p 'Index: ' 'move-window -t %%'" \
        "❌ #[fg=#{@thm_red}]Tuer Fenêtre" k "confirm-before 'kill-window'"
}

# Menu Panneaux
show_panes() {
    local menu_color="fg=#{@thm_mauve}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 🔲 Gestion Panneaux " -x C -y 0 \
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_main'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "󰤼 #[fg=#{@thm_blue}]Split Horizontal" h "split-window -h -c '#{pane_current_path}'" \
        "󰤻 #[fg=#{@thm_blue}]Split Vertical" v "split-window -v -c '#{pane_current_path}'" \
        "📏 #[fg=#{@thm_yellow}]Redimensionner #[align=right,fg=#{@thm_subtext_0}]>>>" r "run-shell '$SCRIPT_PATH show_resize'" \
        "🔄 #[fg=#{@thm_teal}]Échanger #[align=right,fg=#{@thm_subtext_0}]>>>" e "run-shell '$SCRIPT_PATH show_swap'" \
        "📌 #[fg=#{@thm_peach}]Marquer/Démarquer" m "select-pane -m" \
        "#{?#{>:#{window_panes},1},#{?window_zoomed_flag,#[fg=#{@thm_blue}]🔍 Unzoom,#[fg=#{@thm_blue}]🔍 Zoom},}" z "resize-pane -Z" \
        "❌ #[fg=#{@thm_red}]Tuer Panneau" k "confirm-before 'kill-pane'"
}

# Sous-menu Redimensionner
show_resize() {
    local menu_color="fg=#{@thm_yellow}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 📏 Redimensionner Panneau " -x C -y 0 \
        "◄ #[fg=#{@thm_mauve}]Retour Panneaux #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_panes'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "⬅️ #[fg=#{@thm_blue}]Plus Large" t "resize-pane -L 5" \
        "➡️ #[fg=#{@thm_blue}]Plus Étroit" n "resize-pane -R 5" \
        "⬆️ #[fg=#{@thm_green}]Plus Haut" r "resize-pane -U 5" \
        "⬇️ #[fg=#{@thm_green}]Plus Bas" s "resize-pane -D 5"
}

# Sous-menu Échanger
show_swap() {
    local menu_color="fg=#{@thm_teal}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 🔄 Échanger Panneaux " -x C -y 0 \
        "◄ #[fg=#{@thm_mauve}]Retour Panneaux #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_panes'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "⬆️ #[fg=#{@thm_blue}]Vers le Haut" u "swap-pane -U" \
        "⬇️ #[fg=#{@thm_blue}]Vers le Bas" d "swap-pane -D" \
        "📌 #[fg=#{@thm_peach}]Avec Marqué" m "swap-pane"
}

# Menu Outils
show_tools() {
    local menu_color="fg=#{@thm_red}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 🧰 Outils Tmux " -x C -y 0 \
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_main'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "📋 #[fg=#{@thm_blue}]Mode Copie" c "copy-mode" \
        "🕒 #[fg=#{@thm_green}]Horloge" h "clock-mode"
}

# === GESTION MUSICALE ===

# Menu de contrôle pour un player spécifique
show_music_control() {
    local player="$1"
    
    if [ -z "$player" ]; then
        show_main
        return
    fi
    
    # Récupérer les informations du player
    local status=$(playerctl -p "$player" status 2>/dev/null || echo "Unknown")
    local title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "Titre inconnu")
    local artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "Artiste inconnu")
    local position=$(playerctl -p "$player" position --format "{{ duration(position) }}" 2>/dev/null || echo "00:00")
    local length=$(playerctl -p "$player" metadata mpris:length 2>/dev/null)
    local loop_status=$(playerctl -p "$player" loop 2>/dev/null || echo "None")
    
    # Convertir la durée totale si disponible
    local duration="Unknown"
    if [ ! -z "$length" ] && [ "$length" != "0" ]; then
        # Conversion microsecondes vers secondes en bash pur
        duration=$((length / 1000000))
        if [ "$duration" -gt 0 ]; then
            # Convertir les secondes en format MM:SS
            local hours=$((duration / 3600))
            local minutes=$((duration / 60 % 60))
            local seconds=$((duration % 60))
            if [ "$hours" -gt 0 ]; then
                duration=$(printf "%d:%02d:%02d" "$hours" "$minutes" "$seconds")
            else
                duration=$(printf "%d:%02d" "$minutes" "$seconds")
            fi
        else
            duration="Unknown"
        fi
    fi
    
    # Icônes selon le statut
    local status_icon="⏸"
    case "$status" in
        "Playing") status_icon="#[fg=#{@thm_green}]▶" ;;
        "Paused") status_icon="#[fg=#{@thm_peach}]⏸" ;;
        "Stopped") status_icon="#[fg=#{@thm_red}]⏹" ;;
    esac
    
    # Icône et couleur pour le statut de loop
    local loop_icon="🔁"
    local loop_color="#{@thm_overlay1}"
    case "$loop_status" in
        "Track") 
            loop_icon="🔂"
            loop_color="#{@thm_blue}" ;;
        "Playlist") 
            loop_icon="🔁"
            loop_color="#{@thm_green}" ;;
        "None") 
            loop_icon="➡️"
            loop_color="#{@thm_overlay1}" ;;
    esac
    # Construire le titre du menu avec les infos
    local player_name="${player%%.*}"  # Supprime .0 et ce qui suit
    local menu_color="fg=#{@thm_pink}"
    local menu_title="#[align=centre,bg=#{@thm_surface_0},fg=#FCFCFC] ♪ $status_icon #[align=centre,bg=#{@thm_surface_0},$menu_color]$player_name "
    
    tmux display-menu -T "$menu_title" -x C -y 0 \
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '$SCRIPT_PATH show_main'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "-🎵 #[fg=#{@thm_green}]$(echo "$title" | cut -c1-25)" "" "" \
        "-👤 #[fg=#{@thm_yellow}]$(echo "$artist" | cut -c1-25)" "" "" \
        "-⏱  #[fg=#{@thm_teal}]$position / $duration" "" "" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "⏯ #[fg=#{@thm_mauve}]Play/Pause" space "run-shell 'playerctl -p $player play-pause'" \
        "⏮ #[fg=#{@thm_blue}]Précédent" p "run-shell 'playerctl -p $player previous'" \
        "⏭ #[fg=#{@thm_blue}]Suivant" n "run-shell 'playerctl -p $player next'" \
        "⏹ #[fg=#{@thm_red}]Stop" s "run-shell 'playerctl -p $player stop'" \
        "#[fg=$loop_color]$loop_icon#[fg=#{@thm_sapphire}]Loop: $loop_status" l "run-shell '$SCRIPT_PATH cycle_loop $player'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "🔄 #[fg=#{@thm_peach}]Actualiser" r "run-shell '$SCRIPT_PATH show_music_control $player'"
}

# Fonction pour cycler entre les modes de loop
cycle_loop() {
    local player="$1"
    
    if [ -z "$player" ]; then
        return
    fi
    
    local current_loop=$(playerctl -p "$player" loop 2>/dev/null || echo "None")
    
    case "$current_loop" in
        "None")
            playerctl -p "$player" loop Track 2>/dev/null || true
            ;;
        "Track")
            playerctl -p "$player" loop Playlist 2>/dev/null || true
            ;;
        "Playlist")
            playerctl -p "$player" loop None 2>/dev/null || true
            ;;
        *)
            playerctl -p "$player" loop None 2>/dev/null || true
            ;;
    esac
    
    # Actualiser le menu après le changement
    sleep 0.1  # Petit délai pour que le changement soit pris en compte
    show_music_control "$player"
}

# Point d'entrée principal
case "$1" in
    "show_main")
        show_main
        ;;
    "show_sessions")
        show_sessions
        ;;
    "show_windows")
        show_windows
        ;;
    "show_panes")
        show_panes
        ;;
    "show_resize")
        show_resize
        ;;
    "show_swap")
        show_swap
        ;;
    "show_tools")
        show_tools
        ;;
    "show_projects")
        show_projects
        ;;
    "show_hierarchy_level")
        show_hierarchy_level "$2" "$3" "$4"
        ;;
    "show_direct_navigation")
        show_direct_navigation
        ;;
    "navigate_to_project")
        navigate_to_project "$2" "$3"
        ;;
    "show_navigation_options")
        show_navigation_options "$2" "$3" "$4"
        ;;
    "create_project_window")
        create_project_window "$2" "$3" "$4"
        ;;
    "navigate_current_pane")
        navigate_current_pane "$2" "$3"
        ;;
    "create_project_session")
        create_project_session "$2" "$3" "$4"
        ;;
    "create_config_example")
        create_config_example
        ;;
    "show_music_players")
        show_music_players
        ;;
    "show_music_control")
        show_music_control "$2"
        ;;
    "cycle_loop")
        cycle_loop "$2"
        ;;
    *)
        show_main
        ;;
esac
