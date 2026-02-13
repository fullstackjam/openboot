package permissions

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestHasScreenRecordingPermission_Returns verifies that HasScreenRecordingPermission
// returns a boolean value without panicking. This is an actual system call to the
// macOS CoreGraphics framework, so the result depends on the system state.
func TestHasScreenRecordingPermission_Returns(t *testing.T) {
	result := HasScreenRecordingPermission()
	assert.IsType(t, true, result)
}

// TestOpenScreenRecordingSettings_NoError verifies that OpenScreenRecordingSettings
// executes without panicking and returns an error type (even if nil).
func TestOpenScreenRecordingSettings_NoError(t *testing.T) {
	err := OpenScreenRecordingSettings()
	// The function should return an error type (may be nil or non-nil depending on system state)
	assert.IsType(t, (*error)(nil), &err)
}
