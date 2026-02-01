#!/bin/bash
set -euo pipefail

VERSION="0.1.0"
DRY_RUN=false
OPENBOOT_INSTALL_URL="${OPENBOOT_INSTALL_URL:-https://raw.githubusercontent.com/fullstackjam/openboot/main/install.sh}"

# -----------------------------------------------------------------------------
# Help & Usage
# -----------------------------------------------------------------------------
show_help() {
    cat <<EOF
OpenBoot - Bootstrap your Mac development environment

Usage: curl -fsSL openboot.dev/install | bash
       bash <(curl -fsSL openboot.dev/install)
       ./boot.sh [OPTIONS]

Options:
    --help      Show this help message
    --version   Show version information
    --dry-run   Show what would be installed without executing

Description:
    OpenBoot bootstraps essential development dependencies:
    - Xcode Command Line Tools
    - Homebrew package manager
    - gum (for interactive TUI)
    
    After bootstrapping, it downloads and runs the main installer.

Environment Variables:
    OPENBOOT_INSTALL_URL   Override the install.sh download URL

EOF
    exit 0
}

show_version() {
    echo "OpenBoot v${VERSION}"
    exit 0
}

# -----------------------------------------------------------------------------
# Parse flags FIRST (before any interactive operations)
# -----------------------------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            show_help
            ;;
        --version|-v)
            show_version
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Dry-run mode: show what would happen and exit
# -----------------------------------------------------------------------------
if $DRY_RUN; then
    echo "OpenBoot v${VERSION} - Dry Run Mode"
    echo "=================================="
    echo ""
    echo "The following would be installed/configured:"
    echo ""
    
    # Check CLT
    if xcode-select -p &>/dev/null; then
        echo "[OK] Xcode Command Line Tools - already installed"
    else
        echo "[INSTALL] Xcode Command Line Tools"
    fi
    
    # Check Homebrew
    if command -v brew &>/dev/null; then
        echo "[OK] Homebrew - already installed"
    else
        echo "[INSTALL] Homebrew package manager"
    fi
    
    # Check gum
    if command -v gum &>/dev/null; then
        echo "[OK] gum - already installed"
    else
        echo "[INSTALL] gum (via Homebrew)"
    fi
    
    echo ""
    echo "[DOWNLOAD] install.sh from: ${OPENBOOT_INSTALL_URL}"
    echo ""
    echo "Run without --dry-run to proceed with installation."
    exit 0
fi

# -----------------------------------------------------------------------------
# Fix stdin for curl | bash pattern (CRITICAL)
# -----------------------------------------------------------------------------
exec </dev/tty 2>/dev/null || {
    echo "Error: This installer requires an interactive terminal"
    echo ""
    echo "Try one of these alternatives:"
    echo "  bash <(curl -fsSL openboot.dev/install)"
    echo "  curl -fsSL openboot.dev/install -o boot.sh && bash boot.sh"
    exit 1
}

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------
log_step() {
    echo ""
    echo "==> $1"
}

log_info() {
    echo "    $1"
}

log_success() {
    echo "[OK] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# -----------------------------------------------------------------------------
# Install Xcode Command Line Tools
# -----------------------------------------------------------------------------
install_clt() {
    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools already installed"
        return 0
    fi
    
    log_step "Installing Xcode Command Line Tools..."
    
    # Trigger the installation dialog
    xcode-select --install 2>/dev/null || true
    
    echo ""
    echo "    A dialog should have appeared asking to install the Command Line Tools."
    echo "    Please click 'Install' and wait for it to complete."
    echo ""
    read -rp "    Press Enter after the installation completes... "
    
    # Verify installation
    if ! xcode-select -p &>/dev/null; then
        log_error "Xcode Command Line Tools installation failed or was cancelled."
        echo ""
        echo "Please try again by running:"
        echo "  xcode-select --install"
        echo ""
        echo "Then re-run this installer."
        exit 1
    fi
    
    log_success "Xcode Command Line Tools installed"
}

# -----------------------------------------------------------------------------
# Install Homebrew
# -----------------------------------------------------------------------------
install_homebrew() {
    if command -v brew &>/dev/null; then
        log_success "Homebrew already installed"
        return 0
    fi
    
    log_step "Installing Homebrew..."
    log_info "This may take a few minutes..."
    
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Configure PATH based on architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        # Apple Silicon
        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        # Intel
        if [[ -x /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Verify installation
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew installation failed."
        echo ""
        echo "Please check the output above for errors and try again."
        exit 1
    fi
    
    log_success "Homebrew installed"
}

# -----------------------------------------------------------------------------
# Install gum
# -----------------------------------------------------------------------------
install_gum() {
    if command -v gum &>/dev/null; then
        log_success "gum already installed"
        return 0
    fi
    
    log_step "Installing gum..."
    brew install gum
    
    if ! command -v gum &>/dev/null; then
        log_error "gum installation failed."
        exit 1
    fi
    
    log_success "gum installed"
}

# -----------------------------------------------------------------------------
# Download and run install.sh
# -----------------------------------------------------------------------------
run_installer() {
    log_step "Downloading OpenBoot installer..."
    
    # Create temp file for installer
    local installer_script
    installer_script=$(mktemp)
    trap 'rm -f "$installer_script"' EXIT
    
    if ! curl -fsSL "$OPENBOOT_INSTALL_URL" -o "$installer_script"; then
        log_error "Failed to download installer from: ${OPENBOOT_INSTALL_URL}"
        exit 1
    fi
    
    log_info "Running install.sh..."
    echo ""
    
    # Source the installer so it runs in the same shell context
    # shellcheck disable=SC1090
    source "$installer_script"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "OpenBoot v${VERSION}"
    echo "===================="
    echo "Bootstrapping your Mac development environment..."
    
    install_clt
    install_homebrew
    install_gum
    run_installer
}

main
