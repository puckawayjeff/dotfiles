# New Host Deployment

## Overview

The `new-host.sh` script automates the deployment process for setting up a new Linux host with your dotfiles configuration. It handles dependency installation, repository cloning, and symlink creation.

## Deployment

One-line deployment command:

```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/new-host.sh | bash
```

This command will:

1. Check for and install Git (if needed)
2. Check for and install Zsh (if needed)
3. Clone the dotfiles repository from GitHub
4. Run `install.sh` to create all symlinks

## Script Behavior

### First-Time Setup

When running `new-host.sh` on a host without the dotfiles repository:

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

## Idempotency

The `new-host.sh` script is fully idempotent - safe to run multiple times:

- **Git Installation**: Skips if already installed
- **Zsh Installation**: Skips if already installed  
- **Repository**: Stashes changes and pulls if exists, clones if not
- **Symlinks**: `install.sh` uses `ln -sf` (creates or updates symlinks)

You can safely re-run the script to:

- Update to latest dotfiles
- Fix broken symlinks
- Update Git configuration
