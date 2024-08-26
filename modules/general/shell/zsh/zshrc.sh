#setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.
ZLE_RPROMPT_INDENT=0             # Cut Extra space without background on the right side of right prompt

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

export EDITOR='vim'
export CITY='Nanterre'

mkcd () { mkdir -p "$1" && cd "$1" }
color () { for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done }

alias -g G="| grep"
alias -g H='| head'
alias -g T='| tail'
alias -g L="| less"

alias -g N="2>/dev/null"
alias -g NN=">/dev/null 2>&1"

_editor_fts=(cpp cxx cc c hh h inl asc txt TXT tex)
for ft in $_editor_fts; do alias -s $ft=$EDITOR; done
_media_fts=(ape avi flv m4a mkv mp4 mov mp3 mpeg mpg ogg ogm rm wav webm)
for ft in $_media_fts; do alias -s $ft=mpv; done

# Add docker to list of ignored commands
AUTO_NOTIFY_IGNORE+=(
  "docker"
  "ga"
)

#auto_notify_ignore+=(
#  'ga'
#  'glo'
#  'cat'
#)