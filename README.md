# Puckadots v3.0

> **Consistent, powerful terminal environment across hosts.**

**Puckadots** is a modular dotfiles framework designed for multi-distro Linux environments (Debian, Fedora, Arch, Alpine, Synology). It separates **public configuration** (tools, aliases, functions) from **private data** (SSH keys, secrets, host-specific configs) using a "Companion Repo" architecture.

## 🚀 Quick Start

**Prerequisite:** You must have your `dotfiles.env` file hosted securely.

Deploy to a new host with one command:

```bash
mkdir -p ~/.config/dotfiles && wget -O ~/.config/dotfiles/dotfiles.env https://your-server.com/dotfiles.env && wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

This will:
1.  Verify `dotfiles.env` exists.
2.  Install `git` (if missing).
3.  Download and decrypt your SSH keys.
4.  Clone your private `sshsync` repo and this public repo.
5.  Install tools (Zsh, Fastfetch, Eza, etc.) and symlink configs.

---

## 🔒 Private Setup Guide (Required)

Puckadots **requires** a private companion repository (`sshsync`) to function. This keeps your secrets safe while keeping your config public.

### 1. Create Private Repository
1.  Create a **Private** GitHub repository named `sshsync`.
2.  Create an `ssh.conf` file inside it (this will become your `~/.ssh/config`).
3.  Clone it locally.

### 2. Package SSH Keys
Use the `sshpack` command (available after installing Puckadots, or manually) to encrypt your keys.

```bash
# Encrypts ~/.ssh/id_* keys into ssh-keys.tar.gz.enc
sshpack "your-strong-password"
```

### 3. Host the Archive
Upload `ssh-keys.tar.gz.enc` to a secure web server (e.g., your VPS, S3, or Dropbox dl link). It must be downloadable via `wget`.

### 4. Create `dotfiles.env`
This file connects the pieces. **Never commit this to a public repo.**

```bash
SSHSYNC_REPO_URL="git@github.com:yourusername/sshsync.git"
SSH_KEYS_ARCHIVE_URL="https://your-server.com/secure/ssh-keys.tar.gz.enc"
SSH_KEYS_ARCHIVE_PASSWORD="your-strong-password"
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="you@example.com"
```

Save this file securely (Password Manager, encrypted USB). You will need to place it at `~/.config/dotfiles/dotfiles.env` on any new machine before running `join.sh`.

---

## ✨ Features

- **Multi-Distro Support**: Auto-detects `apt`, `dnf`, `pacman`, `apk`.
- **Modular Config**: Zsh, Fastfetch, Tmux, Micro, Eza are independently configured in `config/`.
- **Private Sync**: User-specific dotfiles are tracked in your private `sshsync` repo.
- **Power Tools**:
  - **Zsh** + Zinit (Speed optimized)
  - **Starship** (Prompt)
  - **Fastfetch** (System Info)
  - **Eza** (Modern ls)
  - **FZF** & **Zoxide** (Navigation)
  - **Micro** (Editor)

## 📂 Architecture & Structure

```text
dotfiles/
├── config/                    # Public configurations
│   ├── zsh/                   # Modular Zsh configs
│   ├── fastfetch/             # Fastfetch layouts
│   ├── symlinks.conf          # Core symlink definitions
│   └── ...
├── lib/                       # Library functions
│   ├── os.sh                  # OS abstraction layer
│   ├── terminal.sh            # Tool installers
│   └── update-system.sh       # System update script
├── join.sh                    # Bootstrap script
└── sync.sh                    # Configuration applicator
```

**Symlink Logic**:
- **Public**: Mapped via `dotfiles/config/symlinks.conf`.
- **Private**: Mapped via `sshsync/symlinks.conf`.
- `add-dotfile` automatically adds to the **Private** repo.

## 🛠️ Management Commands

- `dotpull`: Update Puckadots and reload configuration.
- `updatep`: Update system packages (multi-distro aware).
- `add-dotfile <file>`: Add a file to your **private** repo and symlink it.
- `dothelp`: Show command reference.
- `dotkeys`: Show keyboard shortcuts.
- `dotversion`: Show current version.

## 📜 License

MIT License.
