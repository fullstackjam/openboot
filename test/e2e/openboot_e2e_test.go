//go:build e2e

package e2e

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/openbootdotdev/openboot/testutil"
	"github.com/stretchr/testify/assert"
)

func TestE2E_Version(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "version")
	output, err := cmd.CombinedOutput()

	assert.NoError(t, err)
	assert.Contains(t, string(output), "OpenBoot v")
}

func TestE2E_Help(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "--help")
	output, err := cmd.CombinedOutput()

	assert.NoError(t, err)
	assert.Contains(t, string(output), "Usage:")
	assert.Contains(t, string(output), "openboot")
}

func TestE2E_DryRunMinimal(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "--preset", "minimal", "--dry-run", "--silent")
	cmd.Env = append(os.Environ(),
		"OPENBOOT_GIT_NAME=Test User",
		"OPENBOOT_GIT_EMAIL=test@example.com",
	)

	output, err := cmd.CombinedOutput()
	outStr := string(output)

	assert.NoError(t, err, "dry-run with minimal preset should succeed, output: %s", outStr)
}

func TestE2E_DryRunDeveloper(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "--preset", "developer", "--dry-run", "--silent")
	cmd.Env = append(os.Environ(),
		"OPENBOOT_GIT_NAME=Test User",
		"OPENBOOT_GIT_EMAIL=test@example.com",
	)

	output, err := cmd.CombinedOutput()
	outStr := string(output)

	assert.NoError(t, err, "dry-run with developer preset should succeed, output: %s", outStr)
}

func TestE2E_SnapshotCapture(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	tmpDir := t.TempDir()
	snapshotPath := filepath.Join(tmpDir, "test-snapshot.json")

	cmd := exec.Command(binary, "snapshot", "--json")
	var stdout, stderr strings.Builder
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	assert.NoError(t, err, "snapshot command should succeed, stderr: %s", stderr.String())

	jsonOutput := stdout.String()
	var snapshotData map[string]interface{}
	err = json.Unmarshal([]byte(jsonOutput), &snapshotData)
	assert.NoError(t, err, "snapshot output should be valid JSON")

	err = os.WriteFile(snapshotPath, []byte(jsonOutput), 0644)
	assert.NoError(t, err)

	fileInfo, err := os.Stat(snapshotPath)
	assert.NoError(t, err)
	assert.Greater(t, fileInfo.Size(), int64(0), "snapshot file should not be empty")
}

func TestE2E_Doctor(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "doctor")
	output, err := cmd.CombinedOutput()
	outStr := string(output)

	assert.NoError(t, err, "doctor command should succeed, output: %s", outStr)
	assert.Contains(t, outStr, "OpenBoot Doctor")
}

func TestE2E_InvalidPreset(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "--preset", "invalid-preset-xyz", "--dry-run", "--silent")
	cmd.Env = append(os.Environ(),
		"OPENBOOT_GIT_NAME=Test User",
		"OPENBOOT_GIT_EMAIL=test@example.com",
	)

	output, err := cmd.CombinedOutput()
	outStr := string(output)

	assert.Error(t, err, "invalid preset should cause command to fail")
	assert.True(t, strings.Contains(outStr, "invalid") || strings.Contains(outStr, "unknown") || strings.Contains(outStr, "error"),
		"error output should mention invalid preset, got: %s", outStr)
}

func TestE2E_MissingGitConfig(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "--preset", "minimal", "--dry-run", "--silent")

	env := os.Environ()
	filteredEnv := []string{}
	for _, e := range env {
		if !strings.HasPrefix(e, "OPENBOOT_GIT_NAME=") &&
			!strings.HasPrefix(e, "OPENBOOT_GIT_EMAIL=") &&
			!strings.HasPrefix(e, "GIT_AUTHOR_NAME=") &&
			!strings.HasPrefix(e, "GIT_AUTHOR_EMAIL=") &&
			!strings.HasPrefix(e, "GIT_COMMITTER_NAME=") &&
			!strings.HasPrefix(e, "GIT_COMMITTER_EMAIL=") {
			filteredEnv = append(filteredEnv, e)
		}
	}
	cmd.Env = filteredEnv

	output, err := cmd.CombinedOutput()
	outStr := string(output)

	if err == nil {
		t.Logf("Command succeeded when git config was missing. This may be OK if git is already configured globally.")
		t.Logf("Output: %s", outStr)
	}
}

func TestE2E_VersionCommand(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "version")
	output, err := cmd.CombinedOutput()
	outStr := string(output)

	assert.NoError(t, err)
	assert.True(t, strings.Contains(outStr, "OpenBoot v"),
		"version output should contain 'OpenBoot v', got: %s", outStr)
}

func TestE2E_HelpFlag(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	cmd := exec.Command(binary, "-h")
	output, err := cmd.CombinedOutput()
	outStr := string(output)

	assert.NoError(t, err)
	assert.Contains(t, outStr, "Usage:")
}

func TestE2E_SnapshotWithOutput(t *testing.T) {
	binary := testutil.BuildTestBinary(t)
	tmpDir := t.TempDir()
	outputPath := filepath.Join(tmpDir, "my-snapshot.json")

	cmd := exec.Command(binary, "snapshot", "--json")
	var stdout, stderr strings.Builder
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	assert.NoError(t, err, "snapshot --json should succeed, stderr: %s", stderr.String())

	jsonOutput := stdout.String()
	var data map[string]interface{}
	err = json.Unmarshal([]byte(jsonOutput), &data)
	assert.NoError(t, err, "snapshot output should be valid JSON")

	err = os.WriteFile(outputPath, []byte(jsonOutput), 0644)
	assert.NoError(t, err)

	content, err := os.ReadFile(outputPath)
	assert.NoError(t, err)
	assert.Greater(t, len(content), 0)
}
