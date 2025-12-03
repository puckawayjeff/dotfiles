# Dotfiles Management for Linux Hosts

> **Quick Start:** Deploy to a new host with one command:
>
> ```bash
> wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/new-host.sh | bash
> ```
>
> This installs Git/Zsh, clones the repo, and creates symlinks.

## Overview

This repository provides a symlink-based dotfiles management system for maintaining consistent shell configuration and application config across multiple Linux hosts (servers, VMs, and desktops).

Files are stored in this Git repository and symlinked to their expected system locations (`~/.zshrc`, `~/.config/starship.toml`, etc.). The repository serves as the single source of truth, with version control enabling change tracking, rollbacks, and safe experimentation.

## Key Features

- **One-click deployment** - Automated setup on new hosts
- **Symlink-based** - Live editing without manual copying
- **Version controlled** - Full history and rollback capability
- **Host-aware configs** - Gracefully handles missing software

## Quick Start

### Deploy to a New Host

The `new-host.sh` script automates the setup process:

1. Checks for required dependencies (Git, Zsh)
2. Clones this repository
3. Creates all symlinks via `install.sh`

```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/new-host.sh | bash
```

### Add a New Dotfile

Use the `add-dotfile` function to automate the process:

```bash
add-dotfile /path/to/file
```

This script will:

1. Move the file into the repository
2. Create a symlink at the original location
3. Update `install.sh` with the new symlink command
4. Stage changes in Git, commit, and push.

### Sync Changes to Other Hosts

**Pushing changes:**

```bash
dotpush "Description of changes"
```

The `dotpush` function can be run from any directory. If you don't provide a message, it will prompt you for one.

**Pulling changes on other hosts:**

```bash
dotpull
```

The `dotpull` function can be run from any directory. It automatically handles stashing uncommitted changes before pulling to prevent conflicts. See [Bash Functions Reference](docs/Bash%20Functions%20Reference.md) for details.

The symlinks ensure changes take effect immediately (or after sourcing shell config files).

## Repository Structure

```
dotfiles/
├── new-host.sh             # Initial setup script
├── install.sh              # Creates all symlinks
├── config/                 # Configuration files
│   ├── .zshrc              # Zsh configuration
│   ├── .zprofile           # Zsh profile
│   ├── functions.zsh       # Custom Zsh functions
│   ├── starship.toml       # Starship prompt configuration
│   └── fastfetch.jsonc     # Fastfetch configuration
├── lib/                    # Shared libraries
│   └── utils.sh            # Common functions for scripts
├── setup/                  # Optional software setup scripts
│   ├── foot.sh             # Wayland terminal emulator
│   ├── glow.sh             # Markdown viewer for terminals
│   ├── nvm.sh              # Node Version Manager
│   └── syncthing.sh        # File synchronization (requires web config)
└── docs/                   # Extended documentation
    ├── Automating Dotfile Management.md
    ├── Functions Reference.md
    ├── Git Workflow for Dotfiles.md
    ├── Handling Git Merge Conflicts.md
    ├── New Host Deployment.md
    ├── Script Development Best Practices.md
    ├── Setup Scripts Reference.md
    └── Terminal Font Setup.md
```

## Key Files & Components

### Shell Configuration (`.zshrc`)

Contains custom functions and host-aware setup:

- `dotpush()` - One-command git workflow (add, commit, push) from any directory
- `dotpull()` - Pull latest changes from GitHub with automatic stashing
- `updatep()` - Interactive system update in tmux with colored output
- `mkd()` - Create and enter directory in one command
- `paths()` - Diagnostic tool to verify PATH entries
- `packk()` - Create compressed archives (tar.gz, zip, 7z) from directories
- `unpackk()` - Extract archives with nested directory handling

Conditional blocks prevent errors when optional software isn't installed:

```bash
if [ -d "$HOME/.deno" ]; then
  export DENO_INSTALL="$HOME/.deno"
  export PATH="$DENO_INSTALL/bin:$PATH"
fi
```

### SSH Configuration

SSH configuration is not managed by this repository. You'll need to configure it manually:

1. **Generate SSH keys:**

   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "your-email@example.com"
   ```

2. **Add public key to GitHub:**
   - Copy contents of `~/.ssh/id_ed25519_github.pub`
   - Add at [https://github.com/settings/keys]

3. **Create/Modify SSH config** (`~/.ssh/config`):

   ```bash
   Host github.com
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_ed25519_github
     IdentitiesOnly yes
   ```

### Setup Scripts (`setup/`)

Standardized installation scripts for optional tools. All follow consistent patterns:

- Color output with emojis for visual feedback
- Idempotent (safe to run multiple times)
- Error handling with clear messages
- Progress indicators

Available setup scripts:

- `foot.sh` - Foot terminal with Cage compositor
- `glow.sh` - Terminal-based Markdown viewer
- `nvm.sh` - Node Version Manager with Node.js LTS
- `syncthing.sh` - File synchronization service

Run any setup script using the `dotsetup` helper:
```bash
dotsetup eza
dotsetup nvm

# Or list all available scripts
dotsetup
```

Alternatively, run directly:
```bash
bash ~/dotfiles/setup/eza.sh
```

## Documentation

Detailed guides are available in the `docs/` directory:

### Getting Started
- **[New Host Deployment](docs/New%20Host%20Deployment.md)** - Complete guide to `new-host.sh`, stash behavior, and recovery workflows

### Configuration & Tools
- **[Functions Reference](docs/Functions%20Reference.md)** - Complete documentation of `dotpush`, `dotpull`, `updatep`, `mkd`, `paths`, and all aliases
- **[Setup Scripts Reference](docs/Setup%20Scripts%20Reference.md)** - Installation scripts for foot, glow, NVM, and Syncthing

### Git & Version Control
- **[Git Workflow for Dotfiles](docs/Git%20Workflow%20for%20Dotfiles.md)** - Using `dotpush`, `dotpull`, and manual Git operations for syncing
- **[Handling Git Merge Conflicts](docs/Handling%20Git%20Merge%20Conflicts.md)** - Resolving conflicts between hosts

### Development
- **[Script Development Best Practices](docs/Script%20Development%20Best%20Practices.md)** - Standards for writing consistent shell scripts
