package permissions

import (
	"fmt"
	"os/exec"
)

/*
#cgo LDFLAGS: -framework CoreGraphics
#include <CoreGraphics/CoreGraphics.h>
*/
import "C"

// HasScreenRecordingPermission checks if the application has screen recording permission.
// It uses CGPreflightScreenCaptureAccess() from the macOS CoreGraphics framework.
// This function works on macOS 10.15+ (all supported macOS versions for this project).
func HasScreenRecordingPermission() bool {
	return bool(C.CGPreflightScreenCaptureAccess())
}

// OpenScreenRecordingSettings opens the macOS System Preferences screen recording settings.
// It uses the x-apple.systempreferences URL scheme to navigate to the Privacy > Screen Recording settings.
func OpenScreenRecordingSettings() error {
	cmd := exec.Command("open", "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("open screen recording settings: %w", err)
	}
	return nil
}
