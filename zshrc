# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Plugins. Standard plugins in $ZSH/plugins/, custom in $ZSH_CUSTOM/plugins/.
# fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting must be installed
# (run `bash install.sh zsh` from terminal-setup, which clones them + fzf).
plugins=(
  fzf
  fzf-tab
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# --- Startup speed tweaks -------------------------------------------
# Update oh-my-zsh in the BACKGROUND (non-blocking).
zstyle ':omz:update' mode background
zstyle ':omz:update' frequency 13
# Skip oh-my-zsh's slow completion-security audit (compaudit) on startup.
# Safe on a single-user machine. This lets OMZ run `compinit -C` (cached),
# which skips the ~90ms compdump/compaudit work when the dump is fresh.
ZSH_DISABLE_COMPFIX="true"

# NOTE: Do NOT run a manual `compinit` here. Oh My Zsh runs compinit itself
# in oh-my-zsh.sh and honors ZSH_DISABLE_COMPFIX above. A second compinit
# here just doubled startup time (~220ms) and created a competing
# ~/.zcompdump file. `skip_global_compinit` is a Prezto var and is ignored
# by OMZ, so it did nothing. Let OMZ own completions.

source $ZSH/oh-my-zsh.sh

# ===== User configuration =====

# Two-line prompt: blank line, current folder (%1~) + git info, then green arrow.
PROMPT='
%{$fg_bold[cyan]%}%1~%{$reset_color%} $(git_prompt_info)
%{$fg_bold[green]%}➜%{$reset_color%} '

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="$(brew --prefix python)/libexec/bin:$PATH"

alias pihole="ssh pi@raspberrypi.local"

# Force standard 256color terminal for SSH connections
alias ssh="TERM=xterm-256color ssh"

# --- kitty: fall back to xterm-256color if the kitty terminfo isn't present
if [ "$TERM" = "xterm-kitty" ]; then
    if ! infocmp xterm-kitty >/dev/null 2>&1; then
        export TERM=xterm-256color
    fi
fi

# ===== zsh-syntax-highlighting — MUST be sourced last =====
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# tmux shortcuts — optional session name, defaults to "main"
tsn() { tmux new -s "${1:-main}"; }      # tsn        -> new "main";  tsn foo -> new "foo"
tsa() { tmux attach -t "${1:-main}"; }   # tsa        -> attach main; tsa foo -> attach "foo"
