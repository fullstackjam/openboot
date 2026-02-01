#!/usr/bin/env bash
# Shell framework installation (Oh-My-Zsh, plugins)

OMZ_DIR="$HOME/.oh-my-zsh"
OMZ_CUSTOM="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

shell_is_omz_installed() {
    [[ -d "$OMZ_DIR" ]]
}

shell_install_omz() {
    if shell_is_omz_installed; then
        echo "Oh-My-Zsh already installed at $OMZ_DIR"
        return 0
    fi
    
    echo "Installing Oh-My-Zsh..."
    
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        echo "Failed to install Oh-My-Zsh"
        return 1
    }
    
    echo "Oh-My-Zsh installed successfully"
}

shell_install_omz_plugins() {
    if ! shell_is_omz_installed; then
        echo "Oh-My-Zsh not installed, skipping plugins"
        return 1
    fi
    
    local plugins_dir="$OMZ_CUSTOM/plugins"
    mkdir -p "$plugins_dir"
    
    echo "Installing Oh-My-Zsh plugins..."
    
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions" 2>/dev/null || true
    fi
    
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting" 2>/dev/null || true
    fi
    
    if [[ ! -d "$plugins_dir/fast-syntax-highlighting" ]]; then
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$plugins_dir/fast-syntax-highlighting" 2>/dev/null || true
    fi
    
    if [[ ! -d "$plugins_dir/zsh-autocomplete" ]]; then
        git clone https://github.com/marlonrichert/zsh-autocomplete "$plugins_dir/zsh-autocomplete" 2>/dev/null || true
    fi
    
    echo "Plugins installed to $plugins_dir"
}

shell_configure_omz_zshrc() {
    local zshrc="$HOME/.zshrc"
    
    if [[ ! -f "$zshrc" ]]; then
        echo "No .zshrc found, skipping configuration"
        return 1
    fi
    
    if grep -q "source \$ZSH/oh-my-zsh.sh" "$zshrc" 2>/dev/null; then
        echo ".zshrc already configured for Oh-My-Zsh"
        return 0
    fi
    
    echo "Configuring .zshrc for Oh-My-Zsh..."
    
    cat > "$zshrc" << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
    git
    kubectl
    helm
    zsh-autosuggestions
    zsh-syntax-highlighting
    fast-syntax-highlighting
    zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh

export PATH="$HOME/.local/bin:$PATH"
EOF
    
    echo ".zshrc configured"
}

shell_setup_omz() {
    shell_install_omz || return 1
    shell_install_omz_plugins
    shell_configure_omz_zshrc
    
    echo ""
    echo "Oh-My-Zsh setup complete!"
    echo "Restart your terminal or run: source ~/.zshrc"
}
