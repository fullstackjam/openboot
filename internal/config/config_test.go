package config

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetPreset(t *testing.T) {
	tests := []struct {
		name      string
		presetKey string
		found     bool
		hasName   bool
	}{
		{
			name:      "valid preset minimal",
			presetKey: "minimal",
			found:     true,
			hasName:   true,
		},
		{
			name:      "valid preset developer",
			presetKey: "developer",
			found:     true,
			hasName:   true,
		},
		{
			name:      "valid preset full",
			presetKey: "full",
			found:     true,
			hasName:   true,
		},
		{
			name:      "invalid preset",
			presetKey: "nonexistent",
			found:     false,
			hasName:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			preset, found := GetPreset(tt.presetKey)
			assert.Equal(t, tt.found, found)
			if tt.hasName {
				assert.Equal(t, tt.presetKey, preset.Name)
			}
		})
	}
}

func TestGetPresetNames(t *testing.T) {
	names := GetPresetNames()

	assert.Equal(t, 3, len(names))
	assert.Equal(t, "minimal", names[0])
	assert.Equal(t, "developer", names[1])
	assert.Equal(t, "full", names[2])
}
