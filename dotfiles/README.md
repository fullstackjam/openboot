# Dotfiles Template

A minimal, stow-compatible dotfiles template for quick system setup.

## Structure

```
dotfiles/
├── git/
│   └── .gitconfig       # Git configuration with user placeholders
├── zsh/
│   ├── .zprofile        # Shell initialization (Homebrew PATH setup)
│   └── .zshrc           # Interactive shell configuration
└── README.md            # This file
```

## Installation

### Prerequisites

- `stow` installed (`brew install stow`)
- Zsh shell (default on macOS 10.15+)

### Deploy

Deploy all modules:
```bash
stow -v -d dotfiles -t ~ git zsh
```

Deploy specific modules:
```bash
stow -v -d dotfiles -t ~ git    # Git config only
stow -v -d dotfiles -t ~ zsh    # Zsh config only
```

### Customize

Before deploying, edit the files to customize:

1. **`.gitconfig`** - Replace `{{NAME}}` and `{{EMAIL}}` with your details
2. **`.zshrc`** - Add aliases, functions, or environment variables as needed
3. **`.zprofile`** - Add additional PATH setup if required

## What's Included

### Git Configuration
- User name and email (placeholders: `{{NAME}}`, `{{EMAIL}}`)
- Sensible defaults: vim editor, main as default branch, rebase on pull
- Auto-setup remote tracking on push

### Zsh Configuration
- **`.zprofile`** - Runs on login shells, sets up Homebrew PATH for both arm64 and x86_64
- **`.zshrc`** - Runs on interactive shells, includes:
  - History settings (10,000 entries, shared across sessions)
  - Basic aliases (`ll`, `la`, `l`)
  - Color support
  - Simple blue prompt showing current directory

## Philosophy

- **Minimal** - No shell frameworks (Oh-My-Zsh, etc.)
- **Portable** - Works across different machines
- **Stow-friendly** - Proper directory structure for GNU Stow
- **Customizable** - Easy to extend with your own configs

## Removing Dotfiles

To remove symlinks created by stow:
```bash
stow -D -v -d dotfiles -t ~ git zsh
```

## Notes

- Stow creates symlinks, not copies. Edit files in `dotfiles/` directly.
- The `.zprofile` handles both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) Macs.
- No SSH, editor, or machine-specific configs included - keep it focused.
