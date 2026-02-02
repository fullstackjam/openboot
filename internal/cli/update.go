package cli

import (
	"fmt"

	"github.com/openbootdotdev/openboot/internal/brew"
	"github.com/openbootdotdev/openboot/internal/ui"
	"github.com/spf13/cobra"
)

var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update Homebrew and upgrade all packages",
	Long: `Update Homebrew package definitions and upgrade all installed packages.

This command will:
1. Show currently outdated packages
2. Update Homebrew itself
3. Upgrade all outdated packages
4. Clean up old versions`,
	RunE: func(cmd *cobra.Command, args []string) error {
		return runUpdateCommand()
	},
}

func init() {
	updateCmd.Flags().BoolVar(&cfg.DryRun, "dry-run", false, "Preview what would be updated without updating")
}

func runUpdateCommand() error {
	fmt.Println()
	ui.Header("OpenBoot Update")
	fmt.Println()

	if cfg.DryRun {
		ui.Muted("[DRY-RUN MODE - No changes will be made]")
		fmt.Println()
	}

	if !brew.IsInstalled() {
		ui.Error("Homebrew is not installed. Run 'openboot' to install it first.")
		return fmt.Errorf("homebrew not installed")
	}

	ui.Info("Checking for outdated packages...")
	outdated, err := brew.ListOutdated()
	if err != nil {
		ui.Error(fmt.Sprintf("Failed to check outdated packages: %v", err))
	} else if len(outdated) == 0 {
		ui.Success("All packages are up to date!")
		fmt.Println()
		return nil
	} else {
		fmt.Println()
		ui.Info(fmt.Sprintf("Found %d outdated packages:", len(outdated)))
		for _, pkg := range outdated {
			fmt.Printf("  %s: %s -> %s\n", pkg.Name, pkg.Current, pkg.Latest)
		}
		fmt.Println()
	}

	if cfg.DryRun {
		ui.Info("Would run: brew update && brew upgrade && brew cleanup")
		return nil
	}

	if err := brew.Update(false); err != nil {
		return err
	}

	brew.Cleanup()

	fmt.Println()
	ui.Success("Update complete!")
	fmt.Println()
	return nil
}
