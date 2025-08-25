#!/usr/bin/env bash

# Plugin de menu tmux avec navigation hiérarchique
# Auteur: Configuration tmux personnalisée
# Version: 1.0

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
                menu_items="$menu_items\"🎵 $status_icon #[fg=#{@thm_pink}]$player_name #[align=right,fg=#{@thm_subtext_0}]>>>\" \"$shortcut\" \"run-shell '${BASH_SOURCE} show_music_control $player'\" "
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
            $music_items \
            \"-#[align=centre,$menu_color]──────────\" \"\" \"\" \
            \"🖥️ #[fg=#{@thm_blue}]Sessions #[align=right,fg=#{@thm_subtext_0}]>>>\" \"s\" \"run-shell '${BASH_SOURCE} show_sessions'\" \
            \"🪟 #[fg=#{@thm_green}]Fenêtres #[align=right,fg=#{@thm_subtext_0}]>>>\" \"w\" \"run-shell '${BASH_SOURCE} show_windows'\" \
            \"🔲 #[fg=#{@thm_mauve}]Panneaux #[align=right,fg=#{@thm_subtext_0}]>>>\" \"p\" \"run-shell '${BASH_SOURCE} show_panes'\" \
            \"🧰 #[fg=#{@thm_yellow}]Outils #[align=right,fg=#{@thm_subtext_0}]>>>\" \"t\" \"run-shell '${BASH_SOURCE} show_tools'\" \
            \"-#[align=centre,$menu_color]──────────\" \"\" \"\" \
            \"🆘 #[fg=#{@thm_red}]Aide Raccourcis\" \"?\" \"display-popup -E -w 77 -h 21 '\$tmux_help'\""
    else
        tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 󰹯 Menu Principal " -x C -y 0 \
            "🖥️ #[fg=#{@thm_blue}]Sessions #[align=right,fg=#{@thm_subtext_0}]>>>" "s" "run-shell '${BASH_SOURCE} show_sessions'" \
            "🪟 #[fg=#{@thm_green}]Fenêtres #[align=right,fg=#{@thm_subtext_0}]>>>" "w" "run-shell '${BASH_SOURCE} show_windows'" \
            "🔲 #[fg=#{@thm_mauve}]Panneaux #[align=right,fg=#{@thm_subtext_0}]>>>" "p" "run-shell '${BASH_SOURCE} show_panes'" \
            "🧰 #[fg=#{@thm_yellow}]Outils #[align=right,fg=#{@thm_subtext_0}]>>>" "t" "run-shell '${BASH_SOURCE} show_tools'" \
            "-#[align=centre,$menu_color]──────────" "" "" \
            "🆘 #[fg=#{@thm_red}]Aide Raccourcis" "?" "display-popup -E -w 77 -h 21 '$tmux_help'"
    fi
}

# Menu Sessions
show_sessions() {
    local menu_color="fg=#{@thm_blue}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 🖥️ Gestion Sessions " -x C -y 0 \
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '${BASH_SOURCE} show_main'" \
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
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '${BASH_SOURCE} show_main'" \
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
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '${BASH_SOURCE} show_main'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "󰤼 #[fg=#{@thm_blue}]Split Horizontal" h "split-window -h -c '#{pane_current_path}'" \
        "󰤻 #[fg=#{@thm_blue}]Split Vertical" v "split-window -v -c '#{pane_current_path}'" \
        "📏 #[fg=#{@thm_yellow}]Redimensionner #[align=right,fg=#{@thm_subtext_0}]>>>" r "run-shell '${BASH_SOURCE} show_resize'" \
        "🔄 #[fg=#{@thm_teal}]Échanger #[align=right,fg=#{@thm_subtext_0}]>>>" e "run-shell '${BASH_SOURCE} show_swap'" \
        "📌 #[fg=#{@thm_peach}]Marquer/Démarquer" m "select-pane -m" \
        "#{?#{>:#{window_panes},1},#{?window_zoomed_flag,#[fg=#{@thm_blue}]🔍 Unzoom,#[fg=#{@thm_blue}]🔍 Zoom},}" z "resize-pane -Z" \
        "❌ #[fg=#{@thm_red}]Tuer Panneau" k "confirm-before 'kill-pane'"
}

# Sous-menu Redimensionner
show_resize() {
    local menu_color="fg=#{@thm_yellow}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 📏 Redimensionner Panneau " -x C -y 0 \
        "◄ #[fg=#{@thm_mauve}]Retour Panneaux #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '${BASH_SOURCE} show_panes'" \
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
        "◄ #[fg=#{@thm_mauve}]Retour Panneaux #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '${BASH_SOURCE} show_panes'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "⬆️ #[fg=#{@thm_blue}]Vers le Haut" u "swap-pane -U" \
        "⬇️ #[fg=#{@thm_blue}]Vers le Bas" d "swap-pane -D" \
        "📌 #[fg=#{@thm_peach}]Avec Marqué" m "swap-pane"
}

# Menu Outils
show_tools() {
    local menu_color="fg=#{@thm_red}"
    tmux display-menu -T "#[align=centre,bg=#{@thm_surface_0},$menu_color] 🧰 Outils Tmux " -x C -y 0 \
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '${BASH_SOURCE} show_main'" \
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
        "◄ #[fg=#{@thm_lavender}]Retour Menu Principal #[align=right,fg=#{@thm_subtext_0}]<<<" q "run-shell '${BASH_SOURCE} show_main'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "-🎵 #[fg=#{@thm_green}]$(echo "$title" | cut -c1-25)" "" "" \
        "-👤 #[fg=#{@thm_yellow}]$(echo "$artist" | cut -c1-25)" "" "" \
        "-⏱  #[fg=#{@thm_teal}]$position / $duration" "" "" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "⏯ #[fg=#{@thm_mauve}]Play/Pause" space "run-shell 'playerctl -p $player play-pause'" \
        "⏮ #[fg=#{@thm_blue}]Précédent" p "run-shell 'playerctl -p $player previous'" \
        "⏭ #[fg=#{@thm_blue}]Suivant" n "run-shell 'playerctl -p $player next'" \
        "⏹ #[fg=#{@thm_red}]Stop" s "run-shell 'playerctl -p $player stop'" \
        "#[fg=$loop_color]$loop_icon#[fg=#{@thm_sapphire}]Loop: $loop_status" l "run-shell '${BASH_SOURCE} cycle_loop $player'" \
        "-#[align=centre,$menu_color]──────────" "" "" \
        "🔄 #[fg=#{@thm_peach}]Actualiser" r "run-shell '${BASH_SOURCE} show_music_control $player'"
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
