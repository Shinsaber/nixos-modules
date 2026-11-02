
# --- Ajout shincraft : notifications propagées au terminal client --------------------
# Ajouté à la fin du plugin par zsh-auto-notify.nix, pour remplacer _auto_notify_message.
#
# - Session locale graphique : notify-send (comme le plugin d'origine).
# - Session SSH ou sans affichage (ex. après `sudo -i`) : séquence d'échappement envoyée
#   au terminal, qui la transmet au poste client à travers SSH (et tmux) :
#     * kitty                       : OSC 99
#     * Ghostty, WezTerm, foot, VTE : OSC 777
#     * Konsole                     : cloche (BEL) -> notification « Sonnerie dans une
#                                     session non visible » de Konsole
#
# Variables :
#   AUTO_NOTIFY_TERMINAL_BELL=0  désactive la cloche (défaut : 1)

[[ -z "$AUTO_NOTIFY_TERMINAL_BELL" ]] &&
    export AUTO_NOTIFY_TERMINAL_BELL=1

# Les sessions SSH ne sont plus ignorées : elles notifient via le terminal
export AUTO_NOTIFY_ENABLE_SSH=1

function _auto_notify_is_local_gui() {
    [[ -z "${SSH_CLIENT}${SSH_CONNECTION}${SSH_TTY}" ]] &&
        [[ -n "${WAYLAND_DISPLAY}${DISPLAY}" ]]
}

# Encapsule une séquence pour tmux (nécessite `allow-passthrough on`)
function _auto_notify_tmux_wrap() {
    if [[ -n "$TMUX" ]]; then
        printf '\ePtmux;%s\e\\' "${1//$'\e'/$'\e\e'}"
    else
        printf '%s' "$1"
    fi
}

function _auto_notify_terminal() {
    # Retire les caractères de contrôle qui casseraient la séquence
    local title="${1//[$'\e\a']/}"
    local body="${2//[$'\e\a']/}"
    body="${body//$'\n'/ - }"

    local term="$TERM"
    if [[ -n "$TMUX" ]]; then
        term="$(tmux display-message -p '#{client_termname}' 2>/dev/null)"
    fi

    if [[ "$term" == "xterm-kitty" ]]; then
        # OSC 99 : titre puis corps, regroupés par l'identifiant i
        local id="auto-notify-$$-$RANDOM"
        _auto_notify_tmux_wrap $'\e]99;'"i=${id}:d=0:p=title;${title}"$'\e\\'
        _auto_notify_tmux_wrap $'\e]99;'"i=${id}:d=1:p=body;${body}"$'\e\\'
    else
        # OSC 777 : le ';' sépare les champs, on le retire du titre
        _auto_notify_tmux_wrap $'\e]777;notify;'"${title//;/,};${body}"$'\a'
        # La cloche traverse tmux nativement, pas besoin de passthrough
        [[ "$AUTO_NOTIFY_TERMINAL_BELL" == "1" ]] && printf '\a'
    fi
}

function _auto_notify_message() {
    local command="$1"
    local elapsed="$2"
    local exit_code="$3"

    if [[ "$exit_code" -eq 130 ]] && [[ "${AUTO_NOTIFY_CANCEL_ON_SIGINT}" -eq 1 ]]; then
        return
    fi

    local DEFAULT_TITLE="\"%command\" Completed"
    local DEFAULT_BODY="$(echo -e "Total time: %elapsed seconds\nExit code: %exit_code")"
    local title="$(_auto_notify_format "${AUTO_NOTIFY_TITLE:-$DEFAULT_TITLE}" "$command" "$elapsed" "$exit_code")"
    local body="$(_auto_notify_format "${AUTO_NOTIFY_BODY:-$DEFAULT_BODY}" "$command" "$elapsed" "$exit_code")"

    if _auto_notify_is_local_gui; then
        local urgency="normal"
        local icon="${AUTO_NOTIFY_ICON_SUCCESS:-}"
        if [[ "$exit_code" -ne 0 ]]; then
            urgency="critical"
            icon="${AUTO_NOTIFY_ICON_FAILURE:-}"
        fi
        local arguments=("$title" "$body" "--app-name=zsh" "--urgency=$urgency"
            "--hint=int:transient:$AUTO_NOTIFY_ENABLE_TRANSIENT"
            "--expire-time=$AUTO_NOTIFY_EXPIRE_TIME")
        [[ -n "$icon" ]] && arguments+=("--icon=$icon")

        # Pas de démon de notification joignable : repli sur le terminal
        notify-send "${arguments[@]}" 2>/dev/null || _auto_notify_terminal "$title" "$body"
    else
        _auto_notify_terminal "$title" "$body"
    fi
}
