# New Host Deployment

## Overview

The `join.sh` script automates the deployment process for setting up a new Linux host with your dotfiles configuration. It handles dependency installation, repository cloning, and symlink creation.

## Deployment

One-line deployment command:

```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

This command will:

1. Update package lists
2. Install Git (if needed)
3. Install core utilities: `bat`, `p7zip-full`, `tree`
4. Clone the dotfiles repository from GitHub
5. Run core setup scripts automatically:
   - **zsh** - Modern shell with plugins (Zinit, autosuggestions, syntax highlighting, FZF, zoxide)
   - **eza** - Modern ls replacement with git integration and icons
   - **fastfetch** - Fast system information tool
   - **starship** - Cross-shell prompt with Nerd Font support
6. Run `install.sh` to create all symlinks
7. Apply configuration changes

## Script Behavior

### First-Time Setup

When running `join.sh` on a host without the dotfiles repository:

1. **Git Installation** - If Git is not installed, the script will:
   - Run `sudo apt update`
   - Install Git via `sudo apt install -y git`
   - Configure global user name and email

2. **Repository Cloning** - Clone from GitHub:

   ```bash
   git clone git@github.com:puckawayjeff/dotfiles.git ~/dotfiles
   ```

3. **Installation** - Runs `install.sh` to create all symlinks and applies changes to the current session.

### Updates on Existing Hosts

When running on a host that already has the dotfiles repository:

1. **Change Detection** - The script checks if there are uncommitted local changes:

   ```bash
   git diff-index --quiet HEAD -- 2>/dev/null
   ```

2. **Automatic Stashing** - If uncommitted changes exist, they are automatically stashed:

   ```bash
   git stash push -m "Auto-stash before pull on 2025-11-18 14:30:45"
   ```

   The script will display:

   ```text
   ⚠️  Dotfiles repository already exists.
      ↳ Stashing local changes...
      ↳ Local changes stashed. Use 'git stash pop' to restore them.
   ```

3. **Pull Latest Changes** - After stashing (or if no changes exist), the script pulls:

   ```bash
   git pull
   ```

   **Note**: After initial setup, you can use the `dotpull` function (documented in [Functions Reference](Functions%20Reference.md)) which provides the same automatic stashing behavior from any directory.

4. **Re-run Installation** - Runs `install.sh` to update any new symlinks.

## Core vs Optional Tools

### Automatically Installed (Core)

These tools are installed automatically by `join.sh`:

- **bat** - Cat clone with syntax highlighting (Debian package: `bat`, command: `batcat`)
- **p7zip-full** - 7-Zip compression tool (required by `packk` function)
- **tree** - Directory tree visualization
- **zsh** - Modern shell with Zinit plugin manager and 8 power-user plugins
- **eza** - Modern ls replacement with git integration
- **fastfetch** - Fast system information display
- **starship** - Cross-shell prompt with Nerd Font support

### Optional (Manual Installation)

These tools can be installed manually using `dotsetup`:

- **foot** - Lightweight Wayland terminal emulator (requires Wayland)
- **glow** - Beautiful terminal markdown renderer
- **nvm** - Node.js version manager
- **syncthing** - Continuous file synchronization

To install optional tools:

```bash
# List available setup scripts
dotsetup

# Install a specific tool
dotsetup glow
dotsetup nvm
```

## Idempotency

The `join.sh` script is fully idempotent - safe to run multiple times:

- **Git Installation**: Skips if already installed
- **Core Utilities**: Only installs missing packages
- **Repository**: Stashes changes and pulls if exists, clones if not
- **Setup Scripts**: Each script is idempotent and checks existing installations
- **Symlinks**: `install.sh` uses `ln -sf` (creates or updates symlinks)

You can safely re-run the script to:

- Update to latest dotfiles
- Re-run setup scripts to update tools
- Fix broken symlinks
- Ensure all core utilities are installed
