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
# Helper Functions
# ============================================================================

# get_packages - Returns package list for a given preset and type
# Usage: get_packages "minimal" "cli"
# Args:
#   $1: preset name (minimal, standard, full)
#   $2: type (cli or cask)
# Returns: space-separated list of packages
get_packages() {
    local preset="$1"
    local type="$2"
    
    # Validate inputs
    if [[ ! "$preset" =~ ^(minimal|standard|full)$ ]]; then
        echo "Error: Invalid preset '$preset'. Must be: minimal, standard, or full" >&2
        return 1
    fi
    
    if [[ ! "$type" =~ ^(cli|cask)$ ]]; then
        echo "Error: Invalid type '$type'. Must be: cli or cask" >&2
        return 1
    fi
    
    # Convert to uppercase for array name
    local array_name
    array_name=$(echo "${preset}_${type}" | tr '[:lower:]' '[:upper:]')
    
    # Use eval to access the appropriate array
    eval "echo \"\${${array_name}[@]}\""
}

# get_all_presets - Returns all available preset names
# Usage: get_all_presets
# Returns: space-separated list of preset names
get_all_presets() {
    echo "minimal standard full"
}
