# OpenBoot default .zshrc
# Works standalone, compatible with Oh-My-Zsh if installed later

# ============================================================
# Oh-My-Zsh (uncomment after installing: sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)")
# ============================================================
# export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="robbyrussell"
# plugins=(git kubectl helm zsh-autosuggestions zsh-syntax-highlighting)
# source $ZSH/oh-my-zsh.sh

# ============================================================
# Standalone Configuration (works without Oh-My-Zsh)
# ============================================================

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_space

# Navigation
setopt autocd
setopt autopushd
setopt pushdminus
setopt pushdsilent

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colors
export CLICOLOR=1
autoload -Uz colors && colors

# Prompt (simple, shows git branch if in repo)
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'
setopt prompt_subst
PROMPT='%F{blue}%~%f${vcs_info_msg_0_} %# '

# ============================================================
# Aliases
# ============================================================

# ls
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# git (mirrors .gitconfig aliases)
alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gbr='git branch'
alias glg='git log --oneline --decorate --graph --all'

# safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ============================================================
# PATH
# ============================================================
export PATH="$HOME/.local/bin:$PATH"

# ============================================================
# Custom (add your own below)
# ============================================================

