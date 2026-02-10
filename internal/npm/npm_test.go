package npm

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestParseNpmError(t *testing.T) {
	tests := []struct {
		name     string
		output   string
		expected string
	}{
		{
			name:     "404 not found error",
			output:   "npm ERR! 404 Not Found - GET https://registry.npmjs.org/nonexistent",
			expected: "package not found",
		},
		{
			name:     "EACCES permission denied",
			output:   "npm ERR! code EACCES\nnpm ERR! syscall open\nnpm ERR! path /usr/local/lib/node_modules",
			expected: "permission denied",
		},
		{
			name:     "ENETWORK network error",
			output:   "npm ERR! code ENETWORK\nnpm ERR! network request failed",
			expected: "network error",
		},
		{
			name:     "ENOTFOUND network error",
			output:   "npm ERR! code ENOTFOUND\nnpm ERR! network request failed",
			expected: "network error",
		},
		{
			name:     "ENOSPC disk full",
			output:   "npm ERR! code ENOSPC\nnpm ERR! syscall write\nnpm ERR! No space left on device",
			expected: "disk full",
		},
		{
			name:     "unknown error with short last line",
			output:   "npm ERR! some error occurred\nnpm ERR! install failed",
			expected: "npm ERR! install failed",
		},
		{
			name:     "empty output",
			output:   "",
			expected: "install failed",
		},
		{
			name:     "long output line",
			output:   "npm ERR! " + string(make([]byte, 150)),
			expected: "install failed",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := parseNpmError(tt.output)
			assert.Equal(t, tt.expected, result)
		})
	}
}
