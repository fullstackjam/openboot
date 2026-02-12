#!/bin/bash
set -euo pipefail

VERSION="${OPENBOOT_VERSION:-latest}"
REPO="openbootdotdev/openboot"
BINARY_NAME="openboot"
INSTALL_DIR="${OPENBOOT_INSTALL_DIR:-$HOME/.openboot/bin}"
DRY_RUN="${OPENBOOT_DRY_RUN:-false}"
SKIP_CHECKSUM="${OPENBOOT_SKIP_CHECKSUM:-false}"

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

    # Manually set PATH instead of using eval for security
    local arch
    arch=$(uname -m)
    case "$arch" in
        arm64)
            if [[ -x "/opt/homebrew/bin/brew" ]]; then
                export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
                export HOMEBREW_PREFIX="/opt/homebrew"
                export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
                export HOMEBREW_REPOSITORY="/opt/homebrew"
            fi
            ;;
        x86_64)
            if [[ -x "/usr/local/bin/brew" ]]; then
                export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
                export HOMEBREW_PREFIX="/usr/local"
                export HOMEBREW_CELLAR="/usr/local/Cellar"
                export HOMEBREW_REPOSITORY="/usr/local/Homebrew"
            fi
            ;;
        *)
            echo "Error: Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac

    echo ""
    echo "Homebrew installed!"
    echo ""
}

check_existing_installation() {
    if ! command -v brew &>/dev/null; then
        return 0
    fi

    if ! brew list openboot &>/dev/null 2>&1; then
        return 0
    fi

    local existing_path
    existing_path=$(command -v openboot 2>/dev/null || true)

    if [[ -z "$existing_path" ]]; then
        return 0
    fi

    if [[ -L "$existing_path" ]]; then
        local link_target
        link_target=$(readlink "$existing_path" 2>/dev/null || true)
        if [[ "$link_target" == *"/Cellar/openboot"* ]] || [[ "$link_target" == *"/opt/homebrew"*"/openboot"* ]]; then
            echo ""
            echo "⚠️  OpenBoot is already installed via Homebrew"
            echo "   Location: $existing_path"
            echo ""
            echo "Choose one:"
            echo "  1. Update via Homebrew:  brew upgrade openboot"
            echo "  2. Switch to curl:       brew uninstall openboot && curl -fsSL https://openboot.dev/install.sh | bash"
            echo ""
            exit 1
        fi
    fi

    echo "Cleaning up stale Homebrew registration..."
    brew uninstall --force openboot &>/dev/null || true
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
        return 0
    fi
    
    local checksum_url
    if [[ "$VERSION" == "latest" ]]; then
        checksum_url="https://github.com/${REPO}/releases/latest/download/checksums.txt"
    else
        checksum_url="https://github.com/${REPO}/releases/download/${VERSION}/checksums.txt"
    fi
    
    local checksums
    if ! checksums=$(curl -fsSL \
        --max-time 30 \
        --retry 3 \
        --retry-delay 2 \
        --proto '=https' \
        --tlsv1.2 \
        "$checksum_url" 2>/dev/null); then
        echo "Warning: Could not download checksums file. Skipping verification."
        return 0
    fi
    
    local expected_checksum
    expected_checksum=$(echo "$checksums" | grep "${BINARY_NAME}-${os}-${arch}" | awk '{print $1}')
    
    if [[ -z "$expected_checksum" ]]; then
        echo "Warning: No checksum found for ${BINARY_NAME}-${os}-${arch}. Skipping verification."
        return 0
    fi
    
    local actual_checksum
    if command -v shasum &>/dev/null; then
        actual_checksum=$(shasum -a 256 "$binary_path" | awk '{print $1}')
    elif command -v sha256sum &>/dev/null; then
        actual_checksum=$(sha256sum "$binary_path" | awk '{print $1}')
    else
        return 0
    fi
    
    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        echo ""
        echo "Error: Downloaded file appears corrupted."
        echo "Expected: $expected_checksum"
        echo "Got:      $actual_checksum"
        echo ""
        echo "Please try again or download manually from:"
        echo "  https://github.com/${REPO}/releases"
        rm -f "$binary_path"
        exit 1
    fi
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
    if command -v openboot &>/dev/null; then
        local existing_path
        existing_path=$(command -v openboot)
        if [[ "$existing_path" != "$INSTALL_DIR/openboot" ]]; then
            echo "OpenBoot already available at: $existing_path"
            echo "Skipping PATH modification to avoid conflicts"
            echo ""
            echo "If you want to use the version at $INSTALL_DIR/openboot instead,"
            echo "remove the existing installation first or adjust your PATH manually."
            return 0
        fi
    fi

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
        check_existing_installation
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

    local temp_binary="${INSTALL_DIR}/.openboot.tmp.$$"
    trap 'rm -f "$temp_binary"' EXIT INT TERM

    if [[ -f "$binary_path" ]]; then
        local backup_path="${binary_path}.backup.$(date +%s)"
        echo "Backing up existing binary to: ${backup_path##*/}"
        mv "$binary_path" "$backup_path"
    fi

    if ! curl -fsSL \
        --max-time 60 \
        --retry 3 \
        --retry-delay 2 \
        --proto '=https' \
        --tlsv1.2 \
        "$url" \
        -o "$temp_binary"; then
        echo ""
        echo "Error: Failed to download OpenBoot"
        echo "URL: $url"
        echo ""
        echo "Please check: https://github.com/${REPO}/releases"
        exit 1
    fi

    local file_size
    if command -v stat &>/dev/null; then
        if stat -f%z "$temp_binary" &>/dev/null 2>&1; then
            file_size=$(stat -f%z "$temp_binary")
        else
            file_size=$(stat -c%s "$temp_binary" 2>/dev/null || echo "0")
        fi
    else
        file_size="0"
    fi

    if [[ "$file_size" -lt 1000000 ]]; then
        echo ""
        echo "Error: Downloaded file is too small (${file_size} bytes)"
        echo "This may indicate a download error or invalid release"
        rm -f "$temp_binary"
        exit 1
    fi

    verify_checksum "$temp_binary" "$os" "$arch"

    chmod 755 "$temp_binary"

    if ! mv "$temp_binary" "$binary_path"; then
        echo ""
        echo "Error: Failed to install binary"
        exit 1
    fi

    add_to_path
    export PATH="$INSTALL_DIR:$PATH"

    echo "OpenBoot installed to $binary_path"
    echo ""

    exec "$binary_path" "$@"
}

main "$@"
