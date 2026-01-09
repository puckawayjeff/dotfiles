# Release Notes - v3.0.0 "Puckadots"

This is a major architectural release that transforms the repository into a modular, multi-distro framework.

## 🚨 Breaking Changes

1.  **Private Repo Enforcement**: You **MUST** have a `dotfiles.env` file and a private `sshsync` repo to use this release. Public-only mode is deprecated.
2.  **Path Changes**: All configuration files have moved to subdirectories in `config/`.
3.  **Command Changes**: `add-dotfile` now **only** adds files to your private repo.

## ✨ Highlights

- **Multi-Distro**: Works on Debian, Fedora, Arch, Alpine.
- **Modular Zsh**: Configuration is split for easier maintenance.
- **Fastfetch**: Native integration for "Last Login" info.
- **Clean Root**: Documentation and legacy scripts cleaned up.

## 🛠️ Upgrade Guide

1.  **Backup**: Backup your current `~/dotfiles` and `~/.config`.
2.  **Pull**: Run `git pull` in `~/dotfiles`.
3.  **Sync**: Run `./sync.sh`. This will move your configs and update symlinks.
4.  **Restart**: Run `exec zsh`.
