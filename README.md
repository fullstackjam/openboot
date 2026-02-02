# OpenBoot

> One-line macOS development environment setup

[![Release](https://img.shields.io/github/v/release/openbootdotdev/openboot)](https://github.com/openbootdotdev/openboot/releases)
[![License](https://img.shields.io/github/license/openbootdotdev/openboot)](LICENSE)

## Quick Start

```bash
curl -fsSL openboot.dev/install | bash
```

## What is OpenBoot?

OpenBoot is a CLI tool that bootstraps your Mac development environment in minutes. It provides:

- **Interactive TUI** for selecting packages
- **Curated presets** for different development workflows
- **Custom configurations** via [openboot.dev](https://openboot.dev)
- **Dotfiles integration** with GNU Stow

## Prerequisites

- macOS 12.0 (Monterey) or later
- Internet connection
- Admin privileges (for Homebrew)

## Usage

### Interactive Mode

```bash
curl -fsSL openboot.dev/install | bash
```

OpenBoot will guide you through:
1. Git identity configuration
2. Preset selection
3. Package customization
4. Dotfiles setup (optional)
5. Oh-My-Zsh installation (optional)

### Custom Configuration

Create your own config at [openboot.dev/dashboard](https://openboot.dev/dashboard), then:

```bash
curl -fsSL openboot.dev/YOUR_USERNAME | bash
```

### Non-Interactive Mode (CI/Automation)

```bash
OPENBOOT_GIT_NAME="Your Name" \
OPENBOOT_GIT_EMAIL="you@example.com" \
curl -fsSL openboot.dev/install | bash -s -- --preset minimal --silent
```

## Presets

| Preset | Focus | Key Tools |
|--------|-------|-----------|
| **minimal** | Essential CLI tools | ripgrep, fd, bat, fzf, lazygit, gh |
| **developer** | General development | Node, Go, Docker, VS Code, OrbStack |
| **full** | Complete setup | kubectl, terraform, Python, Cursor |

## CLI Options

```
--preset NAME     Set preset (minimal, developer, full)
--user USERNAME   Use remote config from openboot.dev
--silent          Non-interactive mode (requires env vars)
--dry-run         Preview what would be installed
--update          Update Homebrew and upgrade all packages
--rollback        Restore backed up files
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENBOOT_GIT_NAME` | Git user name (required in silent mode) |
| `OPENBOOT_GIT_EMAIL` | Git user email (required in silent mode) |
| `OPENBOOT_PRESET` | Default preset |
| `OPENBOOT_USER` | Remote config username |

## Development

```bash
# Clone
git clone https://github.com/openbootdotdev/openboot.git
cd openboot

# Build
make build

# Run locally
./openboot --dry-run

# Run tests
make test
```

## Project Structure

```
openbootdotdev/
├── openboot        # This repo - CLI tool (Go)
├── openboot.dev    # Website & API (SvelteKit + Cloudflare)
└── dotfiles        # Dotfiles template (GNU Stow)
```

## Related

- [openboot.dev](https://github.com/openbootdotdev/openboot.dev) - Website & dashboard
- [dotfiles](https://github.com/openbootdotdev/dotfiles) - Dotfiles template

## License

MIT
