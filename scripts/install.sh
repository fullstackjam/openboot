#!/bin/bash
set -euo pipefail

VERSION="${OPENBOOT_VERSION:-latest}"
REPO="openbootdotdev/openboot"
BINARY_NAME="openboot"
INSTALL_DIR="${OPENBOOT_INSTALL_DIR:-$HOME/.openboot/bin}"
DRY_RUN="${OPENBOOT_DRY_RUN:-false}"
SKIP_CHECKSUM="${OPENBOOT_SKIP_CHECKSUM:-false}"

print_security_info() {
    echo "🔒 OpenBoot Security Information"
    echo "================================"
    echo ""
    echo "This script will:"
    echo "  1. Download openboot binary from GitHub releases"
    echo "  2. Install to: $INSTALL_DIR"
    echo "  3. Add to PATH via shell rc file"
    echo ""
    echo "Repository: https://github.com/$REPO"
    echo "Version: $VERSION"
    echo ""
    echo "To audit before running:"
    echo "  curl -fsSL https://openboot.dev/install.sh | less"
    echo ""
    echo "To see what will happen without installing:"
    echo "  OPENBOOT_DRY_RUN=true bash <(curl -fsSL https://openboot.dev/install.sh)"
    echo ""
}

install_xcode_clt() {
    if xcode-select -p &>/dev/null; then
        return 0
    fi

    echo "Installing Xcode Command Line Tools..."
    echo "(A dialog may appear - please click 'Install')"
    echo ""

    xcode-select --install 2>/dev/null || true

    echo "Waiting for Xcode Command Line Tools installation..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    echo "Xcode Command Line Tools installed!"
    echo ""
}

install_homebrew() {
    if command -v brew &>/dev/null; then
        return 0
    fi

    echo "Installing Homebrew..."
    echo ""

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo ""
    echo "Homebrew installed!"
    echo ""
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "amd64" ;;
        arm64)   echo "arm64" ;;
        aarch64) echo "arm64" ;;
        *)       echo "unsupported: $arch" >&2; exit 1 ;;
    esac
}

detect_os() {
    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        darwin) echo "darwin" ;;
        *)      echo "Error: OpenBoot only supports macOS" >&2; exit 1 ;;
    esac
}

get_download_url() {
    local os="$1"
    local arch="$2"

    if [[ "$VERSION" == "latest" ]]; then
        echo "https://github.com/${REPO}/releases/latest/download/${BINARY_NAME}-${os}-${arch}"
    else
        echo "https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}-${os}-${arch}"
    fi
}

verify_checksum() {
    local binary_path="$1"
    local os="$2"
    local arch="$3"
    
    if [[ "$SKIP_CHECKSUM" == "true" ]]; then
        echo "Skipping checksum verification (OPENBOOT_SKIP_CHECKSUM=true)"
        return 0
    fi
    
    local checksum_url
    if [[ "$VERSION" == "latest" ]]; then
        checksum_url="https://github.com/${REPO}/releases/latest/download/checksums.txt"
    else
        checksum_url="https://github.com/${REPO}/releases/download/${VERSION}/checksums.txt"
    fi
    
    echo "Verifying checksum..."
    
    local checksums
    if ! checksums=$(curl -fsSL "$checksum_url" 2>/dev/null); then
        echo "⚠️  Warning: Could not download checksums file"
        echo "   Continuing without verification (use OPENBOOT_SKIP_CHECKSUM=true to skip this warning)"
        return 0
    fi
    
    local expected_checksum
    expected_checksum=$(echo "$checksums" | grep "${BINARY_NAME}-${os}-${arch}" | awk '{print $1}')
    
    if [[ -z "$expected_checksum" ]]; then
        echo "⚠️  Warning: No checksum found for ${os}/${arch}"
        return 0
    fi
    
    local actual_checksum
    if command -v shasum &>/dev/null; then
        actual_checksum=$(shasum -a 256 "$binary_path" | awk '{print $1}')
    elif command -v sha256sum &>/dev/null; then
        actual_checksum=$(sha256sum "$binary_path" | awk '{print $1}')
    else
        echo "⚠️  Warning: No checksum tool found (shasum or sha256sum)"
        return 0
    fi
    
    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        echo ""
        echo "❌ Error: Checksum verification failed!"
        echo "   Expected: $expected_checksum"
        echo "   Got:      $actual_checksum"
        echo ""
        echo "This could indicate a corrupted download or security issue."
        echo "Please report this at: https://github.com/${REPO}/issues"
        exit 1
    fi
    
    echo "✓ Checksum verified"
}

detect_shell() {
    local current_shell="${SHELL:-/bin/zsh}"
    case "$current_shell" in
        */zsh)  echo "zsh" ;;
        */bash) echo "bash" ;;
        */fish) echo "fish" ;;
        *)      echo "zsh" ;;
    esac
}

get_shell_rc_file() {
    local shell_type="$1"
    case "$shell_type" in
        zsh)  echo "$HOME/.zshrc" ;;
        bash)
            if [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.zshrc" ;;
    esac
}

create_env_file() {
    local env_file="$HOME/.openboot/env.sh"
    
    if [[ -f "$env_file" ]]; then
        return 0
    fi
    
    cat > "$env_file" << 'EOF'
# OpenBoot environment setup
export PATH="$HOME/.openboot/bin:$PATH"
EOF
    
    echo "Created $env_file"
}

add_to_path() {
    local shell_type
    shell_type=$(detect_shell)
    local rc_file
    rc_file=$(get_shell_rc_file "$shell_type")
    
    if [[ -f "$rc_file" ]] && grep -qF '.openboot/bin' "$rc_file"; then
        echo "Already configured in $rc_file"
        return 0
    fi
    
    if [[ "$shell_type" == "fish" ]]; then
        mkdir -p "$(dirname "$rc_file")"
        echo "" >> "$rc_file"
        echo "# OpenBoot" >> "$rc_file"
        echo 'set -gx PATH "$HOME/.openboot/bin" $PATH' >> "$rc_file"
    else
        create_env_file
        local source_line='[ -f "$HOME/.openboot/env.sh" ] && source "$HOME/.openboot/env.sh"'
        echo "" >> "$rc_file"
        echo "# OpenBoot" >> "$rc_file"
        echo "$source_line" >> "$rc_file"
    fi
    
    echo "Added to PATH in $rc_file"
    
    if [[ -d "$HOME/dotfiles" ]] || [[ -d "$HOME/.dotfiles" ]]; then
        echo ""
        echo "⚠️  Dotfiles detected!"
        echo "If your dotfiles overwrite $rc_file, add this line:"
        if [[ "$shell_type" == "fish" ]]; then
            echo '  set -gx PATH "$HOME/.openboot/bin" $PATH'
        else
            echo '  [ -f "$HOME/.openboot/env.sh" ] && source "$HOME/.openboot/env.sh"'
        fi
        echo ""
    fi
}

main() {
    local snapshot_mode=false
    if [[ "${1:-}" == "snapshot" ]]; then
        snapshot_mode=true
    fi

    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        print_security_info
        exit 0
    fi

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "🔍 DRY RUN MODE - No changes will be made"
        echo "========================================"
    elif [[ "$snapshot_mode" == true ]]; then
        echo "OpenBoot Snapshot"
        echo "================="
    else
        echo "OpenBoot Installer"
        echo "=================="
    fi
    echo ""

    local os arch url binary_path
    os=$(detect_os)
    arch=$(detect_arch)

    if [[ "$os" == "darwin" && "$snapshot_mode" == false ]]; then
        install_xcode_clt
        install_homebrew
    fi

    url=$(get_download_url "$os" "$arch")
    binary_path="${INSTALL_DIR}/${BINARY_NAME}"

    echo "Detected: ${os}/${arch}"
    echo "Download URL: $url"
    echo "Install location: $binary_path"
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would perform:"
        echo "  1. mkdir -p $INSTALL_DIR"
        echo "  2. Download $url -> $binary_path"
        echo "  3. chmod +x $binary_path"
        echo "  4. Add to PATH via shell rc file"
        echo ""
        echo "To actually install, run without OPENBOOT_DRY_RUN:"
        echo "  curl -fsSL https://openboot.dev/install.sh | bash"
        echo ""
        exit 0
    fi

    echo "Downloading OpenBoot..."
    mkdir -p "$INSTALL_DIR"

    if ! curl -fsSL "$url" -o "$binary_path"; then
        echo ""
        echo "Error: Failed to download OpenBoot"
        echo "URL: $url"
        echo ""
        echo "Please check: https://github.com/${REPO}/releases"
        exit 1
    fi

    verify_checksum "$binary_path" "$os" "$arch"

    chmod +x "$binary_path"

    add_to_path
    export PATH="$INSTALL_DIR:$PATH"

    echo "OpenBoot installed to $binary_path"
    echo ""

    exec "$binary_path" "$@"
}

main "$@"
