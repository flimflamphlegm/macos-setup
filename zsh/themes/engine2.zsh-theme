# engine2 — two-line prompt: blank line, folder (%1~) + git info, then green arrow.
PROMPT='
%{$fg_bold[cyan]%}%1~%{$reset_color%} $(git_prompt_info)
%{$fg_bold[green]%}➜%{$reset_color%} '

# git_prompt_info formatting (copied from robbyrussell so the git segment is identical).
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}%1{✗%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
