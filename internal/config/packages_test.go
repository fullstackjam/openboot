package config

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetPackagesForPreset(t *testing.T) {
	tests := []struct {
		name      string
		preset    string
		minCount  int
		shouldHas []string
	}{
		{
			name:      "minimal preset",
			preset:    "minimal",
			minCount:  20,
			shouldHas: []string{"curl", "wget", "jq", "warp"},
		},
		{
			name:      "developer preset",
			preset:    "developer",
			minCount:  30,
			shouldHas: []string{"curl", "node", "typescript", "visual-studio-code"},
		},
		{
			name:      "full preset",
			preset:    "full",
			minCount:  50,
			shouldHas: []string{"curl", "python", "docker", "typescript", "wrangler"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			packages := GetPackagesForPreset(tt.preset)
			assert.GreaterOrEqual(t, len(packages), tt.minCount)
			for _, pkg := range tt.shouldHas {
				assert.True(t, packages[pkg], "package %s should be in %s preset", pkg, tt.preset)
			}
		})
	}
}

func TestIsNpmPackage(t *testing.T) {
	tests := []struct {
		name     string
		pkgName  string
		expected bool
	}{
		{
			name:     "known npm package",
			pkgName:  "typescript",
			expected: true,
		},
		{
			name:     "non-npm package",
			pkgName:  "curl",
			expected: false,
		},
		{
			name:     "empty string",
			pkgName:  "",
			expected: false,
		},
		{
			name:     "non-existent package",
			pkgName:  "nonexistentpkg123",
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := IsNpmPackage(tt.pkgName)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestIsCaskPackage(t *testing.T) {
	tests := []struct {
		name     string
		pkgName  string
		expected bool
	}{
		{
			name:     "known cask package",
			pkgName:  "visual-studio-code",
			expected: true,
		},
		{
			name:     "non-cask package",
			pkgName:  "curl",
			expected: false,
		},
		{
			name:     "empty string",
			pkgName:  "",
			expected: false,
		},
		{
			name:     "non-existent package",
			pkgName:  "nonexistentpkg123",
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := IsCaskPackage(tt.pkgName)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestIsTapPackage(t *testing.T) {
	tests := []struct {
		name     string
		pkgName  string
		expected bool
	}{
		{
			name:     "valid tap with 2 slashes",
			pkgName:  "homebrew/core/package",
			expected: true,
		},
		{
			name:     "valid tap with 2 slashes different names",
			pkgName:  "user/repo/formula",
			expected: true,
		},
		{
			name:     "single slash",
			pkgName:  "homebrew/core",
			expected: false,
		},
		{
			name:     "no slashes",
			pkgName:  "package",
			expected: false,
		},
		{
			name:     "empty string",
			pkgName:  "",
			expected: false,
		},
		{
			name:     "three slashes",
			pkgName:  "a/b/c/d",
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := IsTapPackage(tt.pkgName)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestGetAllPackageNames(t *testing.T) {
	names := GetAllPackageNames()

	assert.Greater(t, len(names), 0)
	assert.Contains(t, names, "curl")
	assert.Contains(t, names, "node")
	assert.Contains(t, names, "typescript")
	assert.Contains(t, names, "visual-studio-code")
}
