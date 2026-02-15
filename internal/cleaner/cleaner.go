package cleaner

import (
	"fmt"

	"github.com/openbootdotdev/openboot/internal/brew"
	"github.com/openbootdotdev/openboot/internal/npm"
	"github.com/openbootdotdev/openboot/internal/snapshot"
	"github.com/openbootdotdev/openboot/internal/ui"
)

type CleanResult struct {
	ExtraFormulae []string
	ExtraCasks    []string
	ExtraNpm      []string
}

func (r *CleanResult) TotalExtra() int {
	return len(r.ExtraFormulae) + len(r.ExtraCasks) + len(r.ExtraNpm)
}

func DiffFromSnapshot(snap *snapshot.Snapshot) (*CleanResult, error) {
	desiredFormulae := toSet(snap.Packages.Formulae)
	desiredCasks := toSet(snap.Packages.Casks)
	desiredNpm := toSet(snap.Packages.Npm)

	return diff(desiredFormulae, desiredCasks, desiredNpm)
}

func DiffFromLists(formulae, casks, npmPkgs []string) (*CleanResult, error) {
	return diff(toSet(formulae), toSet(casks), toSet(npmPkgs))
}

func diff(desiredFormulae, desiredCasks, desiredNpm map[string]bool) (*CleanResult, error) {
	result := &CleanResult{}

	installedFormulae, installedCasks, err := brew.GetInstalledPackages()
	if err != nil {
		return nil, fmt.Errorf("failed to get installed brew packages: %w", err)
	}

	for pkg := range installedFormulae {
		if !desiredFormulae[pkg] {
			result.ExtraFormulae = append(result.ExtraFormulae, pkg)
		}
	}

	for pkg := range installedCasks {
		if !desiredCasks[pkg] {
			result.ExtraCasks = append(result.ExtraCasks, pkg)
		}
	}

	if npm.IsAvailable() {
		installedNpm, err := npm.GetInstalledPackages()
		if err != nil {
			ui.Warn(fmt.Sprintf("Failed to check npm packages: %v", err))
		} else {
			for pkg := range installedNpm {
				if !desiredNpm[pkg] {
					result.ExtraNpm = append(result.ExtraNpm, pkg)
				}
			}
		}
	}

	return result, nil
}

func Execute(result *CleanResult, dryRun bool) error {
	type uninstallOp struct {
		label     string
		pkgs      []string
		uninstall func([]string, bool) error
	}

	ops := []uninstallOp{
		{
			label:     "Removing extra formulae",
			pkgs:      result.ExtraFormulae,
			uninstall: brew.Uninstall,
		},
		{
			label:     "Removing extra casks",
			pkgs:      result.ExtraCasks,
			uninstall: brew.UninstallCask,
		},
		{
			label:     "Removing extra npm packages",
			pkgs:      result.ExtraNpm,
			uninstall: npm.Uninstall,
		},
	}

	var errs []error
	for _, op := range ops {
		if len(op.pkgs) > 0 {
			fmt.Println()
			ui.Header(op.label)
			fmt.Println()
			if err := op.uninstall(op.pkgs, dryRun); err != nil {
				errs = append(errs, fmt.Errorf("%s: %w", op.label, err))
			}
		}
	}

	if len(errs) > 0 {
		return fmt.Errorf("%d cleanup steps had failures", len(errs))
	}
	return nil
}

func toSet(items []string) map[string]bool {
	s := make(map[string]bool, len(items))
	for _, item := range items {
		s[item] = true
	}
	return s
}
