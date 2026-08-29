# If you come from bash you might have to change your $PATH.

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Plugins. Standard plugins in $ZSH/plugins/, custom in $ZSH_CUSTOM/plugins/.
# zsh-syntax-highlighting must be installed (e.g. `brew install zsh-syntax-highlighting`
# or clone into $ZSH_CUSTOM/plugins/) for that plugin to work.
plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# ===== User configuration =====

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="$(brew --prefix python)/libexec/bin:$PATH"

alias pihole="ssh pi@raspberrypi.local"

# Force standard 256color terminal for SSH connections
alias ssh="TERM=xterm-256color ssh"
