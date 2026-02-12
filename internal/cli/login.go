package cli

import (
	"fmt"
	"os"

	"github.com/openbootdotdev/openboot/internal/auth"
	"github.com/openbootdotdev/openboot/internal/ui"
	"github.com/spf13/cobra"
)

var loginCmd = &cobra.Command{
	Use:   "login",
	Short: "Authenticate with openboot.dev",
	Long:  `Log in to your openboot.dev account via browser. Required for installing private configs and uploading snapshots.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if auth.IsAuthenticated() {
			stored, _ := auth.LoadToken()
			if stored != nil {
				ui.Success(fmt.Sprintf("Already logged in as %s", stored.Username))
				fmt.Fprintf(os.Stderr, "  Run 'openboot logout' to log out first.\n")
				return nil
			}
		}

		apiBase := auth.GetAPIBase()
		if _, err := auth.LoginInteractive(apiBase); err != nil {
			return fmt.Errorf("login failed: %w", err)
		}

		return nil
	},
}

var logoutCmd = &cobra.Command{
	Use:   "logout",
	Short: "Log out of openboot.dev",
	Long:  `Remove the stored authentication token from this machine.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if !auth.IsAuthenticated() {
			ui.Info("Not logged in.")
			return nil
		}

		stored, _ := auth.LoadToken()
		if err := auth.DeleteToken(); err != nil {
			return fmt.Errorf("logout failed: %w", err)
		}

		if stored != nil {
			ui.Success(fmt.Sprintf("Logged out of %s", stored.Username))
		} else {
			ui.Success("Logged out")
		}
		return nil
	},
}
