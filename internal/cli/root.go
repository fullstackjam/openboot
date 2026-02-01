package cli

import (
	"fmt"
	"os"

	"github.com/fullstackjam/openboot/internal/config"
	"github.com/fullstackjam/openboot/internal/installer"
	"github.com/spf13/cobra"
)

var (
	version = "0.2.0"
	cfg     = &config.Config{}
)

var rootCmd = &cobra.Command{
	Use:   "openboot",
	Short: "One-line macOS development environment setup",
	Long: `OpenBoot bootstraps your Mac development environment in minutes.
Install Homebrew, CLI tools, GUI apps, dotfiles, and Oh-My-Zsh with a single command.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		return installer.Run(cfg)
	},
}

func init() {
	rootCmd.Flags().StringVarP(&cfg.Preset, "preset", "p", "", "Set preset (minimal, standard, full, devops, frontend, data, mobile, ai)")
	rootCmd.Flags().BoolVarP(&cfg.Silent, "silent", "s", false, "Non-interactive mode for CI/automation")
	rootCmd.Flags().BoolVar(&cfg.DryRun, "dry-run", false, "Preview what would be installed without installing")
	rootCmd.Flags().BoolVar(&cfg.Update, "update", false, "Update Homebrew and upgrade all packages")
	rootCmd.Flags().BoolVar(&cfg.Rollback, "rollback", false, "Restore backed up files")
	rootCmd.Flags().StringVar(&cfg.Shell, "shell", "", "Shell framework setup (install, skip)")
	rootCmd.Flags().StringVar(&cfg.Macos, "macos", "", "macOS preferences (configure, skip)")
	rootCmd.Flags().StringVar(&cfg.Dotfiles, "dotfiles", "", "Dotfiles mode (clone, link, skip)")
	rootCmd.Flags().BoolVar(&cfg.Resume, "resume", false, "Resume from last incomplete step")

	rootCmd.AddCommand(versionCmd)
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print version information",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("OpenBoot v%s\n", version)
	},
}

func Execute() error {
	if cfg.Silent {
		if name := os.Getenv("OPENBOOT_GIT_NAME"); name != "" {
			cfg.GitName = name
		}
		if email := os.Getenv("OPENBOOT_GIT_EMAIL"); email != "" {
			cfg.GitEmail = email
		}
		if preset := os.Getenv("OPENBOOT_PRESET"); preset != "" && cfg.Preset == "" {
			cfg.Preset = preset
		}
	}

	return rootCmd.Execute()
}
