# Puckadots v3.0

> **Consistent, powerful terminal environment across hosts.**

**Puckadots** is a modular dotfiles framework designed for multi-distro Linux environments (Debian, Fedora, Arch, Alpine, Synology). It separates **public configuration** (tools, aliases, functions) from **private data** (SSH keys, secrets, host-specific configs).

## 🚀 Quick Start

Deploy to a new host with one command:

```bash
mkdir -p ~/.config/dotfiles && wget -O ~/.config/dotfiles/dotfiles.env https://your-server.com/dotfiles.env && wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

**Requirements:**
- A private `sshsync` repository (for keys/secrets).
- A `dotfiles.env` file hosted securely (or placed manually).

## ✨ Features

- **Multi-Distro Support**: Auto-detects `apt`, `dnf`, `pacman`, `apk`.
- **Modular Config**: Zsh, Fastfetch, Tmux, Micro, Eza are independently configured.
- **Private Sync**: User-specific dotfiles are tracked in your private `sshsync` repo, not the public one.
- **Power Tools**:
  - **Zsh** + Zinit (Speed optimized)
  - **Starship** (Prompt)
  - **Fastfetch** (System Info)
  - **Eza** (Modern ls)
  - **FZF** & **Zoxide** (Navigation)
  - **Micro** (Editor)

## 📂 Repository Structure

```text
dotfiles/
├── bin/                       # System scripts (update-system)
├── config/                    # Public configurations
│   ├── zsh/                   # Modular Zsh configs
│   ├── fastfetch/             # Fastfetch layouts
│   ├── symlinks.conf          # Core symlink definitions
│   └── ...
├── lib/                       # Library functions
│   ├── os.sh                  # OS abstraction layer
│   └── terminal.sh            # Tool installers
├── join.sh                    # Bootstrap script
└── sync.sh                    # Configuration applicator
```

## 🛠️ Management

- `dotpull`: Update Puckadots and reload configuration.
- `updatep`: Update system packages (multi-distro aware).
- `add-dotfile <file>`: Add a file to your **private** repo and symlink it.
- `dothelp`: Show command reference.
- `dotkeys`: Show keyboard shortcuts.

## 🔒 Private Setup

Puckadots requires a "Companion Repo" pattern:
1. **Public Repo** (This one): The engine.
2. **Private Repo** (`sshsync`): Your keys, secrets, and extra dotfiles.

See `PRIVATE_SETUP.md` for details on creating your `sshsync` repo and `dotfiles.env`.

## 📜 License

MIT License.
