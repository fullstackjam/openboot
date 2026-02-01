# OpenBoot

> One-line macOS development environment setup

## Quick Start

```bash
curl -fsSL openboot.dev/install | bash
```

## Prerequisites

- macOS 12.0 (Monterey) or later
- Internet connection
- Admin privileges (for Homebrew)

## Usage

### Interactive Mode
Simply run the quick start command. OpenBoot will guide you through:
1. Git identity configuration
2. Preset selection (Minimal, Standard, Full)
3. Package customization
4. Dotfiles setup

```bash
curl -fsSL openboot.dev/install | bash
```

### Non-Interactive Mode (CI/Automation)
Use environment variables and the `--silent` flag to run OpenBoot without user input.

```bash
OPENBOOT_GIT_NAME="Your Name" \
OPENBOOT_GIT_EMAIL="you@example.com" \
curl -fsSL openboot.dev/install | bash -s -- --preset minimal --silent
```

## Presets

| Preset | Focus | CLI Tools | GUI Apps |
|--------|-------|-----------|----------|
| **minimal** | Essential | curl, wget, jq, tree, htop, gh, stow | Warp, Maccy |
| **standard** | Development | + node, tmux | + VS Code, Chrome, OrbStack |
| **full** | Comprehensive | + kubectl, helm, awscli, zola | + Notion, MS Office, Telegram |
| **devops** | Infrastructure | kubectl, helm, terraform, k9s, awscli | VS Code, OrbStack, Lens |
| **frontend** | Web Dev | node, yarn, pnpm, bun | VS Code, Chrome, Firefox, Figma |
| **data** | Data Science | python, pipx, uv, postgresql | VS Code, DBeaver |

## Options

- `--help`: Show help message
- `--preset NAME`: Set preset (minimal, standard, full, devops, frontend, data)
- `--silent`: Non-interactive mode (requires env vars)
- `--shell MODE`: Install shell framework (install, skip)
- `--dotfiles MODE`: Set dotfiles mode (clone, link, skip)
- `--dry-run`: Show what would be installed without installing
- `--resume`: Resume from last incomplete step
- `--rollback`: Restore backed up files to their original state
- `--update`: Update Homebrew and upgrade all packages

## Environment Variables

- `OPENBOOT_GIT_NAME`: Git user name (required in silent mode)
- `OPENBOOT_GIT_EMAIL`: Git user email (required in silent mode)
- `OPENBOOT_PRESET`: Default preset if `--preset` not specified
- `OPENBOOT_DOTFILES`: Dotfiles repository URL

## Rollback

If something goes wrong, OpenBoot automatically backs up your original files before making changes. To restore:

```bash
./install.sh --rollback
```

Backups are stored in `~/.openboot/backup/` with timestamps. The rollback command will show available backups and let you choose which to restore.

## Troubleshooting

### Installation fails with "interactive terminal" error
If you are running in a non-interactive environment (like a script or CI), ensure you use the `--silent` flag and provide the required environment variables.

### Homebrew installation fails
OpenBoot requires Homebrew. If Homebrew installation fails, ensure you have an active internet connection and admin privileges. You can try installing Homebrew manually first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## License

MIT
