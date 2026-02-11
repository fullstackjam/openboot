# OpenBoot

> One command. Your Mac is ready to code.

<p align="center">
  <img src="demo.gif" alt="OpenBoot Demo" width="800" />
</p>

Setting up a new Mac still wastes hours. You manually install tools one by one, search for that dotfiles repo link, configure macOS defaults, set up your shell... and somehow it's 3pm.

**OpenBoot does it all in one command:**

```bash
curl -fsSL openboot.dev/install | bash
```

**What you get:**
- ✨ **5 minutes, not 5 hours** — Interactive TUI guides you through everything
- 🎯 **Pick what you need** — 70+ curated dev tools across 13 categories (Node, Docker, VS Code, Warp...)
- 💾 **Remember your setup** — Snapshot your current Mac, restore it anywhere, or share with your team
- 🚀 **Install fast** — CLI tools install 4× in parallel, GUI apps handle password prompts smoothly
- 🔒 **Your data stays yours** — Zero telemetry, zero tracking, fully open source

<p align="center">
  <a href="https://github.com/openbootdotdev/openboot/releases"><img src="https://img.shields.io/github/v/release/openbootdotdev/openboot" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/openbootdotdev/openboot" alt="License"></a>
  <a href="https://codecov.io/gh/openbootdotdev/openboot"><img src="https://codecov.io/gh/openbootdotdev/openboot/branch/main/graph/badge.svg" alt="codecov"></a>
</p>

## Quick Start

Run the command above and OpenBoot will guide you through an interactive setup:
1. Choose a preset (minimal, developer, or full)
2. Customize your package selection in a searchable TUI
3. Sit back while everything installs

**Done.** Your shell, dotfiles, and macOS preferences are configured.

<details>
<summary><strong>📸 Already have a Mac set up? Snapshot it</strong></summary>

```bash
curl -fsSL openboot.dev/install | bash -s -- snapshot
```

Captures your Homebrew packages, macOS preferences, shell config, and git settings. Save locally with `--local` or upload to share.

</details>

<details>
<summary><strong>👥 Team onboarding? Share a config</strong></summary>

Create a config at [openboot.dev/dashboard](https://openboot.dev/dashboard), then have your team run:

```bash
curl -fsSL openboot.dev/YOUR_USERNAME | bash
```

Import from an existing Brewfile, pick packages from the catalog, or duplicate an existing config.

</details>

## Choose Your Preset

Start with a curated preset, then customize it in the TUI:

| Preset | Best For | Includes |
|--------|----------|----------|
| **minimal** | CLI essentials | ripgrep, fd, bat, fzf, lazygit, gh, Warp, Raycast |
| **developer** | Full-stack devs | + Node, Go, Docker, VS Code, Chrome, OrbStack |
| **full** | Power users | + Python, Rust, kubectl, Terraform, Ollama, Cursor, Figma |

Not sure? Pick **developer** and toggle what you don't need.

## What's Included

OpenBoot handles everything a traditional Mac setup requires:

- ✅ **Homebrew packages & GUI apps** — Docker, VS Code, Chrome, Warp, etc.
- ✅ **Dotfiles** — Clone your repo, deploy with GNU Stow, or skip
- ✅ **Shell setup** — Oh-My-Zsh with sensible aliases
- ✅ **macOS preferences** — Developer-friendly defaults (Dock, Finder, etc.)
- ✅ **Git identity** — Configure name/email during setup
- ✅ **Smart installs** — Skips already-installed tools, no wasted time

<details>
<summary><strong>🤔 Why not Brewfile / chezmoi / nix-darwin?</strong></summary>

| | OpenBoot | Brewfile | Strap | chezmoi | nix-darwin |
|---|:---:|:---:|:---:|:---:|:---:|
| Interactive TUI | ✅ | — | — | — | — |
| Web dashboard | ✅ | — | — | — | — |
| Team config sharing | ✅ | — | — | — | — |
| One-command setup | ✅ | — | ✅ | ✅ | — |
| Learning curve | Low | Low | Low | High | Very High |

OpenBoot combines the simplicity of Brewfile with the power of dotfiles managers, plus team sharing built in.

</details>

---

## Advanced Usage

<details>
<summary><strong>🤖 CI / Automation</strong></summary>

```bash
OPENBOOT_GIT_NAME="Your Name" \
OPENBOOT_GIT_EMAIL="you@example.com" \
curl -fsSL openboot.dev/install | bash -s -- --preset developer --silent
```

</details>

<details>
<summary><strong>⚙️ Commands</strong></summary>

```bash
openboot                 # Interactive setup
openboot doctor          # Check system health
openboot update          # Update Homebrew and packages
openboot update --dry-run  # Preview updates
openboot version         # Print version
```

</details>

<details>
<summary><strong>🎛️ CLI Options</strong></summary>

```
-p, --preset NAME   Set preset (minimal, developer, full)
-u, --user NAME     Use remote config from openboot.dev
-s, --silent        Non-interactive mode (requires env vars)
    --dry-run       Preview what would be installed
    --update        Update Homebrew and packages
    --rollback      Restore backed up files
    --resume        Resume incomplete installation
    --shell MODE    Shell setup: install, skip
    --macos MODE    macOS prefs: configure, skip
    --dotfiles MODE Dotfiles: clone, link, skip
```

</details>

<details>
<summary><strong>🔑 Environment Variables</strong></summary>

| Variable | Description |
|----------|-------------|
| `OPENBOOT_GIT_NAME` | Git user name (required in silent mode) |
| `OPENBOOT_GIT_EMAIL` | Git user email (required in silent mode) |
| `OPENBOOT_PRESET` | Default preset |
| `OPENBOOT_USER` | Remote config username |

</details>

---

## FAQ

**Do I need anything installed first?**  
Just macOS 12.0+ and an internet connection. OpenBoot installs Homebrew for you if needed.

**What if I already have some tools installed?**  
OpenBoot detects them and skips reinstalling. You only get what's new.

**Can I see what will be installed before running?**  
Yes. Add `--dry-run` to preview everything, or use the interactive TUI to toggle individual packages.

**Is my data tracked?**  
No. Zero telemetry, zero analytics. Fully open source (MIT license).

---

## Contributing

Found a bug or want to add a feature? [Open an issue](https://github.com/openbootdotdev/openboot/issues) or submit a PR.

<details>
<summary><strong>🛠️ Development Setup</strong></summary>

```bash
git clone https://github.com/openbootdotdev/openboot.git
cd openboot
go build -o openboot ./cmd/openboot
./openboot --dry-run
```

</details>

---

**Related:**  
[openboot.dev](https://openboot.dev) · [Dotfiles template](https://github.com/openbootdotdev/dotfiles)

**License:** MIT
