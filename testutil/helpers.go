package testutil

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

func BuildTestBinary(t *testing.T) string {
	tmpDir, err := os.MkdirTemp("", "openboot-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}

	binaryPath := filepath.Join(tmpDir, "openboot")
	cmd := exec.Command("go", "build", "-o", binaryPath, "./cmd/openboot")

	projectRoot := findProjectRoot(t)
	cmd.Dir = projectRoot

	if err := cmd.Run(); err != nil {
		t.Fatalf("failed to build test binary: %v", err)
	}

	return binaryPath
}

func findProjectRoot(t *testing.T) string {
	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("failed to get working directory: %v", err)
	}

	for {
		if _, err := os.Stat(filepath.Join(wd, "go.mod")); err == nil {
			return wd
		}
		parent := filepath.Dir(wd)
		if parent == wd {
			t.Fatalf("could not find project root (go.mod)")
		}
		wd = parent
	}
}

type MockExecCommand struct {
	Called bool
	Args   []string
	Err    error
}

func NewMockExecCommand() *MockExecCommand {
	return &MockExecCommand{
		Called: false,
		Args:   []string{},
		Err:    nil,
	}
}

type CommandResult struct {
	ExitCode int
	Stdout   string
	Stderr   string
	Err      error
}

func AssertCommandSuccess(t *testing.T, result CommandResult) {
	if result.Err != nil {
		t.Errorf("expected command to succeed, got error: %v", result.Err)
	}
	if result.ExitCode != 0 {
		t.Errorf("expected exit code 0, got %d", result.ExitCode)
	}
}

func AssertCommandFailure(t *testing.T, result CommandResult) {
	if result.ExitCode == 0 {
		t.Errorf("expected command to fail, but exit code was 0")
	}
}
