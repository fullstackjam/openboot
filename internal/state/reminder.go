package state

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// ReminderState represents the persisted state for screen recording permission reminder.
type ReminderState struct {
	Dismissed bool `json:"dismissed"`
	Skipped   bool `json:"skipped"`
}

// DefaultStatePath returns the path to the reminder state file (~/.openboot/state.json).
func DefaultStatePath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, ".openboot", "state.json")
}

// LoadState reads and unmarshals the reminder state from disk.
// If the file does not exist, returns a default state with no error.
// If the file exists but contains invalid JSON, logs a warning to stderr and returns default state.
func LoadState(path string) (*ReminderState, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return &ReminderState{Dismissed: false, Skipped: false}, nil
		}
		return nil, fmt.Errorf("failed to read state file: %w", err)
	}

	var state ReminderState
	if err := json.Unmarshal(data, &state); err != nil {
		// Log warning to stderr for corrupted JSON, but return default state gracefully
		fmt.Fprintf(os.Stderr, "warning: failed to parse state file, using defaults: %v\n", err)
		return &ReminderState{Dismissed: false, Skipped: false}, nil
	}

	return &state, nil
}

// SaveState persists the reminder state to disk with atomic write semantics.
// Creates parent directory if missing and writes with indented JSON for readability.
func SaveState(path string, s *ReminderState) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create state directory: %w", err)
	}

	data, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal state data: %w", err)
	}

	// Atomic write: write to temp file, then rename
	tmpFile := path + ".tmp"
	if err := os.WriteFile(tmpFile, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary state file: %w", err)
	}

	if err := os.Rename(tmpFile, path); err != nil {
		// Clean up temp file if rename fails
		_ = os.Remove(tmpFile)
		return fmt.Errorf("failed to rename state file: %w", err)
	}

	return nil
}

// ShouldShowReminder returns true if the reminder should be shown.
// Returns false if the reminder has been dismissed.
func ShouldShowReminder(s *ReminderState) bool {
	return !s.Dismissed
}

// MarkDismissed sets the Dismissed flag to true.
func MarkDismissed(s *ReminderState) {
	s.Dismissed = true
}

// MarkSkipped sets the Skipped flag to true.
func MarkSkipped(s *ReminderState) {
	s.Skipped = true
}
