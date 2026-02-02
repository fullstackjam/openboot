package brew

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"sync"

	"github.com/openbootdotdev/openboot/internal/ui"
)

const maxWorkers = 4

type OutdatedPackage struct {
	Name    string
	Current string
	Latest  string
}

func IsInstalled() bool {
	_, err := exec.LookPath("brew")
	return err == nil
}

func ListOutdated() ([]OutdatedPackage, error) {
	cmd := exec.Command("brew", "outdated", "--json")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	var result struct {
		Formulae []struct {
			Name              string   `json:"name"`
			InstalledVersions []string `json:"installed_versions"`
			CurrentVersion    string   `json:"current_version"`
		} `json:"formulae"`
		Casks []struct {
			Name              string   `json:"name"`
			InstalledVersions []string `json:"installed_versions"`
			CurrentVersion    string   `json:"current_version"`
		} `json:"casks"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, err
	}

	var outdated []OutdatedPackage
	for _, f := range result.Formulae {
		current := ""
		if len(f.InstalledVersions) > 0 {
			current = f.InstalledVersions[0]
		}
		outdated = append(outdated, OutdatedPackage{
			Name:    f.Name,
			Current: current,
			Latest:  f.CurrentVersion,
		})
	}
	for _, c := range result.Casks {
		current := ""
		if len(c.InstalledVersions) > 0 {
			current = c.InstalledVersions[0]
		}
		outdated = append(outdated, OutdatedPackage{
			Name:    c.Name + " (cask)",
			Current: current,
			Latest:  c.CurrentVersion,
		})
	}

	return outdated, nil
}

func Install(packages []string, dryRun bool) error {
	if len(packages) == 0 {
		return nil
	}

	if dryRun {
		ui.Info("Would install CLI packages:")
		for _, p := range packages {
			fmt.Printf("    brew install %s\n", p)
		}
		return nil
	}

	ui.Info(fmt.Sprintf("Installing %d CLI packages...", len(packages)))

	args := append([]string{"install"}, packages...)
	cmd := exec.Command("brew", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func InstallCask(packages []string, dryRun bool) error {
	if len(packages) == 0 {
		return nil
	}

	if dryRun {
		ui.Info("Would install GUI applications:")
		for _, p := range packages {
			fmt.Printf("    brew install --cask %s\n", p)
		}
		return nil
	}

	ui.Info(fmt.Sprintf("Installing %d GUI applications...", len(packages)))

	args := append([]string{"install", "--cask"}, packages...)
	cmd := exec.Command("brew", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

type installJob struct {
	name   string
	isCask bool
}

type installResult struct {
	name   string
	failed bool
	isCask bool
	errMsg string
}

func InstallWithProgress(cliPkgs, caskPkgs []string, dryRun bool) error {
	total := len(cliPkgs) + len(caskPkgs)
	if total == 0 {
		return nil
	}

	if dryRun {
		ui.Info("Would install packages:")
		for _, p := range cliPkgs {
			fmt.Printf("    brew install %s\n", p)
		}
		for _, p := range caskPkgs {
			fmt.Printf("    brew install --cask %s\n", p)
		}
		return nil
	}

	allJobs := make([]installJob, 0, total)
	for _, pkg := range cliPkgs {
		allJobs = append(allJobs, installJob{name: pkg, isCask: false})
	}
	for _, pkg := range caskPkgs {
		allJobs = append(allJobs, installJob{name: pkg, isCask: true})
	}

	failed := runParallelInstall(allJobs, total)

	if len(failed) > 0 {
		fmt.Println()
		ui.Error(fmt.Sprintf("%d packages failed to install:", len(failed)))
		for _, f := range failed {
			if f.errMsg != "" {
				fmt.Printf("    - %s (%s)\n", f.name, f.errMsg)
			} else {
				fmt.Printf("    - %s\n", f.name)
			}
		}
		fmt.Println()

		retryJobs := make([]installJob, len(failed))
		for i, f := range failed {
			retryJobs[i] = f.installJob
		}

		retry, _ := ui.Confirm(fmt.Sprintf("Retry %d failed packages?", len(failed)), true)
		if retry {
			ui.Info("Retrying failed packages...")
			stillFailed := runParallelInstall(retryJobs, len(retryJobs))
			if len(stillFailed) > 0 {
				fmt.Println()
				ui.Muted(fmt.Sprintf("Skipped %d packages that couldn't be installed:", len(stillFailed)))
				for _, f := range stillFailed {
					if f.errMsg != "" {
						fmt.Printf("    - %s (%s)\n", f.name, f.errMsg)
					} else {
						fmt.Printf("    - %s\n", f.name)
					}
				}
			} else {
				ui.Success("All packages installed successfully on retry!")
			}
		} else {
			ui.Muted("Skipping failed packages")
		}
	}

	return nil
}

type failedJob struct {
	installJob
	errMsg string
}

func runParallelInstall(jobs []installJob, total int) []failedJob {
	if len(jobs) == 0 {
		return nil
	}

	progress := ui.NewProgressTracker(total)

	jobChan := make(chan installJob, len(jobs))
	results := make(chan installResult, len(jobs))

	var wg sync.WaitGroup
	workers := maxWorkers
	if len(jobs) < workers {
		workers = len(jobs)
	}

	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for job := range jobChan {
				progress.SetCurrent(job.name)
				errMsg := ""
				if job.isCask {
					errMsg = installSmartCaskWithError(job.name)
				} else {
					errMsg = installFormulaWithError(job.name)
				}
				results <- installResult{name: job.name, failed: errMsg != "", isCask: job.isCask, errMsg: errMsg}
				progress.Complete(job.name)
			}
		}()
	}

	go func() {
		for _, job := range jobs {
			jobChan <- job
		}
		close(jobChan)
	}()

	go func() {
		wg.Wait()
		close(results)
	}()

	var failed []failedJob
	for result := range results {
		if result.failed {
			failed = append(failed, failedJob{
				installJob: installJob{name: result.name, isCask: result.isCask},
				errMsg:     result.errMsg,
			})
		}
	}

	progress.Finish()
	return failed
}

func installFormulaWithError(pkg string) string {
	cmd := exec.Command("brew", "install", pkg)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return parseBrewError(string(output))
	}
	return ""
}

func installSmartCaskWithError(pkg string) string {
	cmd := exec.Command("brew", "install", "--cask", pkg)
	output, err := cmd.CombinedOutput()
	if err != nil {
		cmd2 := exec.Command("brew", "install", pkg)
		output2, err2 := cmd2.CombinedOutput()
		if err2 != nil {
			errMsg := parseBrewError(string(output))
			if errMsg == "unknown error" {
				errMsg = parseBrewError(string(output2))
			}
			return errMsg
		}
	}
	return ""
}

func parseBrewError(output string) string {
	lowerOutput := strings.ToLower(output)
	
	switch {
	case strings.Contains(lowerOutput, "no available formula"):
		return "package not found"
	case strings.Contains(lowerOutput, "already installed"):
		return ""
	case strings.Contains(lowerOutput, "no internet"):
		return "no internet connection"
	case strings.Contains(lowerOutput, "connection refused"):
		return "connection refused"
	case strings.Contains(lowerOutput, "timed out"):
		return "connection timed out"
	case strings.Contains(lowerOutput, "permission denied"):
		return "permission denied"
	case strings.Contains(lowerOutput, "disk full") || strings.Contains(lowerOutput, "no space"):
		return "disk full"
	case strings.Contains(lowerOutput, "sha256 mismatch"):
		return "download corrupted"
	case strings.Contains(lowerOutput, "depends on"):
		return "dependency error"
	default:
		lines := strings.Split(output, "\n")
		for _, line := range lines {
			if strings.Contains(strings.ToLower(line), "error") {
				if len(line) > 60 {
					return line[:57] + "..."
				}
				return line
			}
		}
		return "unknown error"
	}
}

func installSmartCask(pkg string) error {
	cmd := exec.Command("brew", "install", "--cask", pkg)
	cmd.Stdout = nil
	cmd.Stderr = nil
	if err := cmd.Run(); err != nil {
		cmd2 := exec.Command("brew", "install", pkg)
		cmd2.Stdout = nil
		cmd2.Stderr = nil
		return cmd2.Run()
	}
	return nil
}

func Update(dryRun bool) error {
	if dryRun {
		ui.Info("Would run: brew update && brew upgrade")
		return nil
	}

	ui.Info("Updating Homebrew...")
	if err := exec.Command("brew", "update").Run(); err != nil {
		return err
	}

	ui.Info("Upgrading packages...")
	cmd := exec.Command("brew", "upgrade")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func Cleanup() error {
	ui.Info("Cleaning up old versions...")
	return exec.Command("brew", "cleanup").Run()
}
