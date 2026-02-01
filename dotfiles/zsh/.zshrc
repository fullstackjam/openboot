# OpenBoot default .zshrc
# Keep it simple - no frameworks

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory

# Basic aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Colors
export CLICOLOR=1

# Prompt (simple)
PROMPT='%F{blue}%~%f %# '
