# PROMPT ORIGINAL
# PROMPT='%{$fg_bold[red]%}➜ %{$fg_bold[green]%} %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}'

# PROMPT 2

# PROMPT='%{$fg_bold[red]%}➜ %F{yellow}%D[{%H:%M:%S}%f] %{$fg_bold[green]%} %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}'

## ORIGINALMENTE É CYAN NA PASTA E BLUE NO GIT; BOTEI RED NA PASTA E CYAN NO GIT
# PROMPT 3 NO ARROWS
# PROMPT='[%D{%H:%M}]%f%{$fg_bold[green]%} %{$fg[red]%}%c %{$fg_bold[cyan]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}'

#PROMPT
setopt PROMPT_SUBST
# PROMPT='[%D{%H:%M}]%f%{$fg_bold[green]%} %{$fg[red]%}%(~.~.${PWD/#$HOME\//}) %{$fg_bold[cyan]%}$(git_prompt_info)%{$reset_color%} '

# PROMPT='%{$fg[cyan]%}[%D{%H:%M}]%f%{$fg[green]%} %{$fg[red]%}$( if [[ $PWD = $HOME ]]; then
#  print -r -- "~"
# elif [[ $PWD == $HOME/* ]]; then
#   print -r -- "${PWD#$HOME/}"
# else
#   print -r -- "$PWD"
# fi ) %{$fg_bold[blue]%}$(git_prompt_info)%{$reset_color%} '


PROMPT='%{$fg[cyan]%}[%D{%H:%M}]%f%{$fg[green]%} %{$fg[red]%}$( if [[ $PWD = $HOME ]]; then
  printf "~"
elif [[ $PWD == $HOME/* ]]; then
  printf "%s" "${PWD#$HOME/}"
else
  printf "%s" "$PWD"
fi ) %{$fg_bold[blue]%}$(git_prompt_info)%{$reset_color%} '
RPROMPT='$(git_prompt_status)%{$reset_color%}'



ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""


ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[cyan]%} ✈"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%} ✭"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} ✗"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[blue]%} ➦"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[magenta]%} ✂"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[grey]%} ✱"
