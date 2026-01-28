# Release Notes - v3.1.0

This release adds a new setup script for managing passwordless sudo configuration.

## ✨ What's New

### Passwordless Sudo Toggle

A new setup script that enables or disables passwordless sudo for your user account:

```bash
# Enable passwordless sudo
sudo dotsetup passwordless-sudo

# Disable (restore password requirement)
sudo dotsetup passwordless-sudo --disable
```

**Why?** Useful for development environments, personal machines, VMs, or automation scenarios where frequently entering your password is inconvenient.

**Safe by design:**
- Uses `/etc/sudoers.d/` drop-in pattern (no editing main sudoers file)
- Validates syntax with `visudo` before activation
- Fully reversible with a single command
- Idempotent (safe to run multiple times)

## 🛠️ Upgrade Guide

1. **Pull**: Run `dotpull` or `git pull` in `~/dotfiles`
2. **Optional**: Enable passwordless sudo with `sudo dotsetup passwordless-sudo`

## ⚠️ Security Note

Passwordless sudo should only be used on trusted machines you control. It is not recommended for production servers or shared systems.
