#!/bin/bash

# Core detection module for OpenBoot macOS bootstrap tool
# Detects system architecture, shell, tools, and environment

# Detect system architecture (arm64 or x86_64)
detect_architecture() {
    /usr/bin/uname -m
}

# Detect Homebrew prefix based on architecture
detect_homebrew_prefix() {
    local arch
    arch=$(detect_architecture)
    
    if [[ "$arch" == "arm64" ]]; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

# Detect current shell (zsh, bash, or other)
detect_shell() {
    local shell_name
    shell_name=$(basename "$SHELL")
    echo "$shell_name"
}

# Detect shell profile file path based on shell type
detect_shell_profile() {
    local shell_name
    shell_name=$(detect_shell)
    
    if [[ "$shell_name" == "zsh" ]]; then
        echo "$HOME/.zprofile"
    elif [[ "$shell_name" == "bash" ]]; then
        echo "$HOME/.bash_profile"
    else
        # Fallback for other shells
        echo "$HOME/.profile"
    fi
}

# Detect macOS version
detect_macos_version() {
    /usr/bin/sw_vers -productVersion
}

# Detect if running under Rosetta translation
# Returns 0 if Rosetta, 1 if native
detect_rosetta() {
    local translated
    translated=$(sysctl -n sysctl.proc_translated 2>/dev/null)
    
    if [[ "$translated" == "1" ]]; then
        return 0
    else
        return 1
    fi
}

# Check if Homebrew is already installed
# Returns 0 if installed, 1 if not
detect_existing_homebrew() {
    if command -v brew &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if Xcode Command Line Tools are installed
# Returns 0 if installed, 1 if not
detect_existing_clt() {
    if xcode-select -p &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if running in interactive TTY
# Returns 0 if interactive, 1 if not
is_interactive() {
    if [[ -t 0 ]]; then
        return 0
    else
        return 1
    fi
}
