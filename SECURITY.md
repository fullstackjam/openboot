# Security Policy

## 🔒 Security Features

OpenBoot takes security seriously. Here's how we protect you:

### 1. Transparent Installation

**Before Installing:**
```bash
# Preview what the script will do (no changes)
OPENBOOT_DRY_RUN=true bash <(curl -fsSL https://openboot.dev/install.sh)

# Audit the installation script
curl -fsSL https://openboot.dev/install.sh | less

# View security information
curl -fsSL https://openboot.dev/install.sh | bash -s -- --help
```

### 2. Binary Verification

All binaries are automatically verified with SHA-256 checksums:

```bash
# Checksums are downloaded and verified automatically
curl -fsSL https://openboot.dev/install.sh | bash

# Skip verification (not recommended)
OPENBOOT_SKIP_CHECKSUM=true bash <(curl -fsSL https://openboot.dev/install.sh)
```

**Manual Verification:**
```bash
# Download binary
curl -LO https://github.com/openbootdotdev/openboot/releases/latest/download/openboot-darwin-arm64

# Download checksums
curl -LO https://github.com/openbootdotdev/openboot/releases/latest/download/checksums.txt

# Verify
shasum -a 256 -c checksums.txt --ignore-missing
```

### 3. Minimal Permissions

OpenBoot **never** requires `sudo` during installation:
- Installs to `~/.openboot/bin` (user directory)
- Only modifies user shell rc files
- Homebrew may prompt for password (handled by Homebrew itself)

### 4. Isolated Configuration

- Uses `~/.openboot/env.sh` for PATH configuration
- Separate from other tools
- Easy to uninstall: `rm -rf ~/.openboot`

### 5. Source Code Transparency

- All code is open source on GitHub
- Installation script: https://github.com/openbootdotdev/openboot/blob/main/scripts/install.sh
- Review before running: https://openboot.dev/install.sh

## 🚨 Reporting Security Issues

If you discover a security vulnerability, please:

1. **DO NOT** open a public issue
2. Email: security@openboot.dev (or open a private security advisory)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We'll respond within 48 hours and work with you to address the issue.

## 🛡️ Security Best Practices

### For Users

1. **Always review installation scripts** before running
2. **Verify checksums** for manual downloads
3. **Use latest version** for security updates
4. **Report suspicious behavior** immediately

### For Contributors

1. **Never commit secrets** (API keys, passwords, tokens)
2. **Validate all user input**
3. **Use secure defaults**
4. **Follow principle of least privilege**

## 📋 Security Audit Checklist

- [ ] Installation script reviewed
- [ ] Binary checksum verified
- [ ] No sudo required during install
- [ ] Source code audited
- [ ] Only modifies user-owned files
- [ ] No network requests to untrusted domains
- [ ] All dependencies from official sources

## 🔐 What OpenBoot Does NOT Do

- ❌ Collect telemetry or analytics
- ❌ Phone home or track usage
- ❌ Modify system-level configurations
- ❌ Require sudo for installation
- ❌ Access sensitive data
- ❌ Install unsigned binaries (all releases are checksummed)

## 📚 Security Resources

- **Installation Script**: https://github.com/openbootdotdev/openboot/blob/main/scripts/install.sh
- **Release Process**: https://github.com/openbootdotdev/openboot/blob/main/.github/workflows/release.yml
- **Source Code**: https://github.com/openbootdotdev/openboot

## 🕒 Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| < 0.13  | :x:                |

We support the latest release. Please upgrade to the latest version for security updates.

## 🔄 Update Notifications

To check for updates:
```bash
openboot update --self
```

---

**Last Updated**: 2026-02-10  
**Contact**: security@openboot.dev
