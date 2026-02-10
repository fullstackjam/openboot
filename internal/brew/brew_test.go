package brew

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestParseBrewError(t *testing.T) {
	tests := []struct {
		name     string
		output   string
		expected string
	}{
		{
			name:     "package not found",
			output:   "Error: No available formula with the name \"nonexistent\"",
			expected: "package not found",
		},
		{
			name:     "already installed",
			output:   "Warning: curl 7.85.0 is already installed and up-to-date",
			expected: "",
		},
		{
			name:     "no internet connection",
			output:   "Error: No internet connection available",
			expected: "no internet connection",
		},
		{
			name:     "connection refused",
			output:   "Error: Connection refused when trying to reach github.com",
			expected: "connection refused",
		},
		{
			name:     "connection timed out",
			output:   "Error: The request timed out",
			expected: "connection timed out",
		},
		{
			name:     "permission denied",
			output:   "Error: Permission denied when writing to /usr/local/bin",
			expected: "permission denied",
		},
		{
			name:     "disk full",
			output:   "Error: Disk full - no space left on device",
			expected: "disk full",
		},
		{
			name:     "disk full alternative",
			output:   "Error: No space left on device",
			expected: "disk full",
		},
		{
			name:     "sha256 mismatch",
			output:   "Error: SHA256 mismatch for downloaded file",
			expected: "download corrupted",
		},
		{
			name:     "dependency error",
			output:   "Error: Package depends on missing dependency",
			expected: "dependency error",
		},
		{
			name:     "unknown error with error line",
			output:   "Some output\nError: Something went wrong\nMore output",
			expected: "Error: Something went wrong",
		},
		{
			name:     "unknown error no error line",
			output:   "Some random output\nNo problem found",
			expected: "unknown error",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := parseBrewError(tt.output)
			assert.Equal(t, tt.expected, result)
		})
	}
}
