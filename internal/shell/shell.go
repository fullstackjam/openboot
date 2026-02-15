package shell

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/openbootdotdev/openboot/internal/system"
)

func IsOhMyZshInstalled() bool {
	home, err := os.UserHomeDir()
	if err != nil {
		return false
	}
	_, err = os.Stat(filepath.Join(home, ".oh-my-zsh"))
	return err == nil
}

func InstallOhMyZsh(dryRun bool) error {
	if IsOhMyZshInstalled() {
		return nil
	}

	if dryRun {
		fmt.Println("[DRY-RUN] Would install Oh-My-Zsh")
		return nil
	}

	script := `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended`
	cmd := exec.Command("bash", "-c", script)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return err
	}

	home, err := system.HomeDir()
	if err != nil {
		return err
	}
	zshrcPath := filepath.Join(home, ".zshrc")
	os.Remove(zshrcPath)

	return nil
}

func ConfigureZshrc(dryRun bool) error {
	home, err := system.HomeDir()
	if err != nil {
		return err
	}
	zshrcPath := filepath.Join(home, ".zshrc")

	additions := `
# OpenBoot additions
# Homebrew (must come before /usr/bin)
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
export PATH="$HOME/.openboot/bin:$HOME/.local/bin:$PATH"

# Modern CLI aliases
alias ls="eza --icons"
alias ll="eza -la --icons"
alias cat="bat"
alias find="fd"
alias grep="rg"
alias top="btop"

# Git aliases
alias gs="git status"
alias gd="git diff"
alias gl="lazygit"

# Zoxide (smart cd)
eval "$(zoxide init zsh)"

# fzf integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
`

	if dryRun {
		fmt.Println("[DRY-RUN] Would add to .zshrc:")
		fmt.Println(additions)
		return nil
	}

	f, err := os.OpenFile(zshrcPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open .zshrc: %w", err)
	}
	defer f.Close()

	if _, err := f.WriteString(additions); err != nil {
		return fmt.Errorf("failed to write to .zshrc: %w", err)
	}

	return nil
}

func SetDefaultShell(dryRun bool) error {
	zshPath := "/bin/zsh"
	if _, err := os.Stat(zshPath); os.IsNotExist(err) {
		zshPath = "/usr/bin/zsh"
	}

	if dryRun {
		fmt.Printf("[DRY-RUN] Would set default shell to %s\n", zshPath)
		return nil
	}

	cmd := exec.Command("chsh", "-s", zshPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

func RestoreFromSnapshot(ohMyZsh bool, theme string, plugins []string, dryRun bool) error {
	if !ohMyZsh {
		return nil
	}

	if !IsOhMyZshInstalled() {
		if dryRun {
			fmt.Println("[DRY-RUN] Would install Oh-My-Zsh")
		} else {
			if err := InstallOhMyZsh(dryRun); err != nil {
				return fmt.Errorf("failed to install Oh-My-Zsh: %w", err)
			}
		}
	}

	home, err := system.HomeDir()
	if err != nil {
		return err
	}
	zshrcPath := filepath.Join(home, ".zshrc")

	if _, err := os.Stat(zshrcPath); os.IsNotExist(err) {
		if dryRun {
			fmt.Printf("[DRY-RUN] Would create %s\n", zshrcPath)
			return nil
		}
		template := fmt.Sprintf(`export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="%s"
plugins=(%s)
source $ZSH/oh-my-zsh.sh
`, theme, strings.Join(plugins, " "))
		if err := os.WriteFile(zshrcPath, []byte(template), 0644); err != nil {
			return fmt.Errorf("failed to create .zshrc: %w", err)
		}
		return nil
	}

	if dryRun {
		if theme != "" {
			fmt.Printf("[DRY-RUN] Would set ZSH_THEME=\"%s\"\n", theme)
		}
		if len(plugins) > 0 {
			fmt.Printf("[DRY-RUN] Would set plugins=(%s)\n", strings.Join(plugins, " "))
		}
		return nil
	}

	content, err := os.ReadFile(zshrcPath)
	if err != nil {
		return fmt.Errorf("failed to read .zshrc: %w", err)
	}

	updated := string(content)

	if theme != "" {
		themeRe := regexp.MustCompile(`ZSH_THEME="[^"]*"`)
		newTheme := fmt.Sprintf(`ZSH_THEME="%s"`, theme)
		if themeRe.MatchString(updated) {
			updated = themeRe.ReplaceAllString(updated, newTheme)
		} else {
			updated = newTheme + "\n" + updated
		}
	}

	if len(plugins) > 0 {
		pluginsRe := regexp.MustCompile(`plugins=\([^)]*\)`)
		newPlugins := fmt.Sprintf("plugins=(%s)", strings.Join(plugins, " "))
		if pluginsRe.MatchString(updated) {
			updated = pluginsRe.ReplaceAllString(updated, newPlugins)
		} else {
			updated = newPlugins + "\n" + updated
		}
	}

	if err := os.WriteFile(zshrcPath, []byte(updated), 0644); err != nil {
		return fmt.Errorf("failed to write .zshrc: %w", err)
	}

	return nil
}
