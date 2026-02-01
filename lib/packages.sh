#!/bin/bash

# OpenBoot Package Definitions Module
# Defines preset package lists for different installation levels
# Presets: minimal (essential), standard (development), full (comprehensive)

# ============================================================================
# MINIMAL PRESET - Essential CLI tools and free GUI apps
# ============================================================================

MINIMAL_CLI=(
  "curl"
  "wget"
  "jq"
  "tree"
  "htop"
  "watch"
  "gh"
  "stow"
  "ssh-copy-id"
  "rsync"
)

MINIMAL_CASK=(
  "warp"           # Free terminal
  "maccy"          # Free clipboard manager
  "scroll-reverser" # Free utility
)

# ============================================================================
# STANDARD PRESET - Development tools (includes minimal)
# ============================================================================

STANDARD_CLI=(
  "${MINIMAL_CLI[@]}"
  "node"
  "tmux"
)

STANDARD_CASK=(
  "${MINIMAL_CASK[@]}"
  "visual-studio-code"
  "google-chrome"
  "orbstack"
  "postman"
  "typora"
)

# ============================================================================
# FULL PRESET - Comprehensive suite (includes standard)
# ============================================================================

FULL_CLI=(
  "${STANDARD_CLI[@]}"
  "kubectl"
  "helm"
  "argocd"
  "awscli"
  "wireguard-tools"
  "wrk"
  "telnet"
  "zola"
)

FULL_CASK=(
  "${STANDARD_CASK[@]}"
  "feishu"
  "wechat"
  "telegram"
  "notion"
  "microsoft-office"
  "microsoft-edge"
  "neteasemusic"
  "betterdisplay"
  "balenaetcher"
  "clash-verge-rev"
)

# ============================================================================
# DEVOPS PRESET - Kubernetes, cloud, infrastructure
# ============================================================================

DEVOPS_CLI=(
  "${MINIMAL_CLI[@]}"
  "kubectl"
  "helm"
  "argocd"
  "k9s"
  "terraform"
  "awscli"
  "azure-cli"
  "kubectx"
  "stern"
  "kustomize"
)

DEVOPS_CASK=(
  "${MINIMAL_CASK[@]}"
  "visual-studio-code"
  "orbstack"
  "lens"
)

# ============================================================================
# FRONTEND PRESET - Web development focused
# ============================================================================

FRONTEND_CLI=(
  "${MINIMAL_CLI[@]}"
  "node"
  "yarn"
  "pnpm"
  "bun"
)

FRONTEND_CASK=(
  "${MINIMAL_CASK[@]}"
  "visual-studio-code"
  "google-chrome"
  "firefox"
  "figma"
  "arc"
)

# ============================================================================
# DATA PRESET - Data science and analytics
# ============================================================================

DATA_CLI=(
  "${MINIMAL_CLI[@]}"
  "python"
  "pipx"
  "uv"
  "postgresql"
  "sqlite"
)

DATA_CASK=(
  "${MINIMAL_CASK[@]}"
  "visual-studio-code"
  "dbeaver-community"
  "db-browser-for-sqlite"
)

# ============================================================================
# Helper Functions
# ============================================================================

get_packages() {
    local preset="$1"
    local type="$2"
    
    if [[ ! "$preset" =~ ^(minimal|standard|full|devops|frontend|data)$ ]]; then
        echo "Error: Invalid preset '$preset'" >&2
        return 1
    fi
    
    if [[ ! "$type" =~ ^(cli|cask)$ ]]; then
        echo "Error: Invalid type '$type'. Must be: cli or cask" >&2
        return 1
    fi
    
    local array_name
    array_name=$(echo "${preset}_${type}" | tr '[:lower:]' '[:upper:]')
    
    eval "echo \"\${${array_name}[@]}\""
}

get_all_presets() {
    echo "minimal standard full devops frontend data"
}
