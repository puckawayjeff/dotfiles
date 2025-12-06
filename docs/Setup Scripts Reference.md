# Setup Scripts Reference

## Overview

The `setup/` directory contains standardized installation scripts for tools and services. Each script is:

- **Idempotent** - Safe to run multiple times without errors
- **Self-contained** - No arguments required, interactive where needed
- **Consistent** - All follow the same formatting and error handling patterns
- **Well-documented** - Clear output with colored progress indicators

### Core vs Optional Tools

**Core Tools (Automatically Installed)**:

These tools are automatically installed by `join.sh`:

- **zsh** - Installed first to provide the shell environment
- **eza** - Modern ls replacement
- **fastfetch** - System information display
- **starship** - Cross-shell prompt
- **micro** - Terminal text editor with intuitive keybindings

**Optional Tools (Manual Installation)**:

These tools require manual installation via `dotsetup`:

- **foot** - Wayland terminal emulator
- **glow** - Markdown renderer
- **nvm** - Node.js version manager
- **syncthing** - File synchronization

## General Usage

All setup scripts follow the same invocation pattern:

```bash
dotsetup <script-name>
```

## Available Setup Scripts

### Glow - Terminal Markdown Renderer

**Script**: `setup/glow.sh` 📦 **Optional**

**Project**: [Glow](https://github.com/charmbracelet/glow) - Beautifully renders markdown files directly in the terminal with syntax highlighting, styled headers, and proper formatting. Perfect for reading documentation, READMEs, and notes without leaving the command line. Includes a built-in pager and file browser.

**Installation**: Run `dotsetup glow` to install this optional tool.

**What It Does**:

- Adds the official Charm APT repository and GPG key
- Installs the glow package
- Provides beautiful markdown rendering in the terminal

**Installation Process**:

1. Checks if glow is already installed
2. If not present:
   - Creates `/etc/apt/keyrings/` directory
   - Downloads Charm GPG key to `/etc/apt/keyrings/charm.gpg`
   - Adds Charm APT source at `/etc/apt/sources.list.d/charm.list`
   - Updates package lists
   - Installs glow

**Usage After Installation**:

```bash
# Render a markdown file
glow README.md

# Render with pager enabled
glow -p file.md

# Use dark style (default)
glow -s dark file.md

# Use light style
glow -s light file.md

# Browse markdown files in current directory
glow
```

**Project Repository**: [charmbracelet/glow](https://github.com/charmbracelet/glow)

---

### Foot Terminal - Wayland Terminal Emulator

**Script**: `setup/foot.sh` 📦 **Optional**

**Project**: [foot](https://codeberg.org/dnkl/foot) - Extremely fast and lightweight terminal designed for Wayland. Ideal for minimalist setups, older hardware, or dedicated terminal servers. Cage allows running a single application in fullscreen kiosk mode. Good for local monitor output on servers.

**Installation**: Run `dotsetup foot` to install this optional tool.

**Note**: Requires Wayland compositor. Not suitable for X11-only systems.

**What It Does**:

- Installs `foot` terminal emulator
- Installs `cage` (Wayland compositor for single-application mode)
- Installs `fonts-firacode` for programming ligatures
- Creates foot configuration at `~/.config/foot/foot.ini`

**Installation Process**:

1. Updates package lists
2. Installs: `cage`, `foot`, `fonts-firacode`
3. Creates `~/.config/foot/` directory
4. Creates `foot.ini` configuration file with:
   - Fira Code font at size 12
   - Dracula-inspired color scheme
   - Fallback fonts for missing glyphs

---

### NVM - Node Version Manager

**Script**: `setup/nvm.sh` 📦 **Optional**

**Project**: [nvm](https://github.com/nvm-sh/nvm) - Allows managing multiple Node.js versions without conflicts. Essential for projects requiring different Node.js versions. Prevents permission issues with global package installations.

**Installation**: Run `dotsetup nvm` to install this optional tool.

**What It Does**:

- Removes conflicting system-installed Node.js (if present)
- Downloads and installs NVM
- Installs Node.js LTS (Long Term Support) version
- Configures bash integration for automatic loading
- Sets LTS as the default Node.js version

**Installation Process**:

1. Checks for system-installed Node.js and offers to remove it
2. Downloads NVM installation script from GitHub
3. Installs NVM to `~/.nvm`
4. Loads NVM into the current session
5. Adds NVM configuration block to `~/.zshrc`:

   ```bash
   export NVM_DIR="$HOME/.nvm"
   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
   [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
   ```

6. Installs Node.js LTS version
7. Sets LTS as default version

**NVM Version Installed**: v0.40.1 (configurable in script)

**Important Note on Duplicate Configuration**: The script checks for existing NVM configuration using `grep -Fxq` to search for the marker comment. If you run the script multiple times, it should detect the existing configuration and skip adding it. However, if the NVM installer itself (from nvm-sh) adds its own configuration block without using the same marker format, you may end up with duplicates. Always check `~/.zshrc` after running NVM setup and manually remove any duplicate blocks if present.

**Verification Commands**:

```bash
# Check Node.js location (should contain .nvm)
which node

# Check versions
node --version
npm --version

# Verify NVM is loaded
command -v nvm
```

**Project Repository**: [nvm-sh/nvm](https://github.com/nvm-sh/nvm)

---

### Tmux - Terminal Multiplexer

**Script**: Automatically installed via `lib/terminal.sh` ✅ **Core Tool**

**Project**: [tmux](https://github.com/tmux/tmux) - Terminal multiplexer that allows multiple terminal sessions within a single window. Essential for long-running processes, remote server management, and productivity workflows. Integrates with the `updatep` function for safe system updates.

**Installation**: Automatically installed when running `install.sh`.

**What It Does**:

- Installs tmux from system repositories
- Creates symlink to dotfiles-managed configuration at `~/.tmux.conf`
- Provides sensible defaults with modern keybindings

**Configuration Features**:

- **Mouse Support** - Click panes, drag to resize, scroll through history
- **Vim-style Navigation** - `h/j/k/l` for pane movement
- **Intuitive Splits** - `|` for vertical, `-` for horizontal
- **Modern Status Bar** - Shows session name, date, and time
- **Enhanced Scrollback** - 10,000 line history buffer
- **256 Color Support** - Full color terminal support
- **Copy Mode** - Vim keybindings for text selection

**Key Bindings** (Prefix: `Ctrl+b`):

```bash
# Pane Management
Prefix + |              # Split vertically
Prefix + -              # Split horizontally
Prefix + h/j/k/l        # Navigate panes (vim-style)
Prefix + H/J/K/L        # Resize panes (vim-style)

# Window Management
Prefix + c              # New window (in current path)
Prefix + number         # Switch to window by number

# Utilities
Prefix + r              # Reload configuration
Prefix + [              # Enter copy mode (scroll/search)
Prefix + ?              # List all key bindings
```

**Usage After Installation**:

```bash
# Start a new session
tmux

# Named session
tmux new -s mysession

# List sessions
tmux ls

# Attach to session
tmux attach -t mysession

# Detach from session (inside tmux)
Ctrl+b d

# Kill session
tmux kill-session -t mysession
```

**Integration with updatep**:

The `updatep` function automatically:

- Detects if tmux is installed
- Installs tmux if missing
- Runs system updates in a new tmux session
- Prevents SSH disconnections from interrupting updates

**Project Repository**: [tmux/tmux](https://github.com/tmux/tmux)

---

### Micro - Terminal Text Editor

**Script**: Automatically installed via `lib/terminal.sh` ✅ **Core Tool**

**Project**: [micro](https://micro-editor.github.io/) - Modern and intuitive terminal-based text editor. Designed to be easy to use while providing the capabilities of traditional Unix text editors. Features familiar keyboard shortcuts (Ctrl+S to save, Ctrl+Q to quit), syntax highlighting, and mouse support.

**Installation**: Automatically installed when running `install.sh`.

**What It Does**:

- Installs micro from system repositories
- Creates symlink to dotfiles-managed configuration at `~/.config/micro/settings.json`
- Provides sensible defaults with a Dracula color scheme

**Configuration Features**:

- **Dracula Color Scheme** - Dark theme matching the dotfiles aesthetic
- **Mouse Support** - Click to position cursor, select text
- **Syntax Highlighting** - Automatic detection for most languages
- **Diff Gutter** - Shows git changes in the margin
- **Trailing Whitespace Removal** - Automatically removes on save
- **Tab to Spaces** - Converts tabs to 4 spaces
- **Cursor Line Highlighting** - Easy line tracking
- **External Clipboard** - Integration with system clipboard

**Key Bindings** (familiar shortcuts):

```bash
# File Operations
Ctrl+S              # Save file
Ctrl+Q              # Quit
Ctrl+O              # Open file

# Editing
Ctrl+Z              # Undo
Ctrl+Y              # Redo
Ctrl+C              # Copy
Ctrl+X              # Cut
Ctrl+V              # Paste
Ctrl+A              # Select all

# Navigation
Ctrl+F              # Find
Ctrl+N              # Find next
Ctrl+G              # Go to line

# Help
Alt+G               # Toggle keybinding help
Ctrl+E              # Command bar
```

**Usage After Installation**:

```bash
# Open a file
micro filename.txt

# Open multiple files
micro file1.txt file2.txt

# Create new file
micro newfile.md
```

**Configuration Location**:

The micro settings are managed at `~/.config/micro/settings.json` which is symlinked to `config/micro.json` in the dotfiles repository.

**Customization**:

To customize micro, edit the settings file in the dotfiles repo:

```bash
micro ~/dotfiles/config/micro.json
```

Or use micro's built-in settings command:

```bash
# Inside micro, press Ctrl+E then type:
set colorscheme monokai
set tabsize 2
```

**Project Homepage**: [micro-editor.github.io](https://micro-editor.github.io/)

**Project Repository**: [zyedidia/micro](https://github.com/zyedidia/micro)

---

### Syncthing - Continuous File Synchronization

**Script**: `setup/syncthing.sh` 📦 **Optional**

**Project**: [Syncthing](https://syncthing.net/) - Provides Dropbox-like functionality without trusting a third party. Perfect for homelab environments where you control all endpoints. Faster than cloud sync for LAN transfers.

**Installation**: Run `dotsetup syncthing` to install this optional tool.

**What It Does**:

- Adds the official Syncthing APT repository
- Installs the GPG signing key for package verification
- Installs Syncthing from the stable channel

**Installation Process**:

1. Creates `/etc/apt/keyrings/` directory (if needed)
2. Downloads Syncthing release PGP key:

   ```bash
   sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg \
       https://syncthing.net/release-key.gpg
   ```

3. Adds APT source file at `/etc/apt/sources.list.d/syncthing.list`:

   ```text
   deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] \
       https://apt.syncthing.net/ syncthing stable-v2
   ```

4. Updates package lists
5. Installs Syncthing package

**Usage After Installation**:

```bash
# Start Syncthing for current user
syncthing

# Access web UI (opens automatically)
# Default: http://127.0.0.1:8384

# Run as background service
systemctl --user enable syncthing.service
systemctl --user start syncthing.service

# Check service status
systemctl --user status syncthing.service
```

**Initial Setup**:

1. Run `syncthing` command
2. Access web UI at `http://127.0.0.1:8384`
3. Configure folders to sync
4. Add remote devices by device ID
5. Configure ignore patterns and file versioning

**Key Features**:

- **Peer-to-peer** - No central server required
- **Encrypted** - All data encrypted in transit (TLS)
- **Private** - Your data stays on your devices
- **Cross-platform** - Linux, Windows, macOS, Android, iOS
- **Open source** - Fully auditable code

**Use Cases**:

- Sync dotfiles across multiple machines
- Backup photos from phone to server
- Share files between devices without cloud services
- Collaborative document editing
- Keepass database synchronization

**Project Homepage**: [syncthing.net](https://syncthing.net/)

**Project Repository**: [syncthing/syncthing](https://github.com/syncthing/syncthing)

---

### Last Login - Custom SSH Login Display

**Location**: `lib/terminal.sh` (automatic configuration) and `lib/last-login.sh` (display script)

**Type**: 🚀 **Core Feature** (automatically configured during initial setup)

**Purpose**: Replaces the default SSH lastlog message with a custom, styled version that includes IP-to-hostname mapping and cleaner timestamp formatting.

**Installation**: Automatically configured by `lib/terminal.sh` during initial setup. Can also be manually re-run with `sudo ~/dotfiles/lib/terminal.sh`.

**What It Does**:

1. Creates a backup of `/etc/pam.d/sshd` configuration
2. Disables the default `pam_lastlog.so` module
3. Verifies the configuration changes
4. Provides instructions for customizing IP-to-hostname mappings

**How It Works**:

The custom last-login system consists of three components:

1. **`lib/last-login.sh`** - Core script that displays the styled message
2. **`.zshrc` integration** - Sources the script automatically during SSH sessions
3. **PAM configuration** - Disables the default lastlog message to prevent duplication

**Default Output**:

```
Last login: from 100.100.166.103 on Thu Dec 4, 2025 at 1:43 PM
```

**Custom Output (with hostname mapping)**:

```
Last login: from krang on Thu Dec 4, 2025 at 1:43 PM
```

**Customizing IP-to-Hostname Mappings**:

Edit `lib/last-login.sh` and modify the `IP_HOSTNAMES` array:

```bash
declare -A IP_HOSTNAMES=(
    ["100.100.166.103"]="krang"
    ["192.168.1.100"]="server1"
    ["10.0.0.50"]="workstation"
)
```

**Features**:

- **Styled output** - Uses colors and formatting from `lib/utils.sh`
- **IP resolution** - Maps known IPs to friendly hostnames
- **Cleaner timestamps** - Formats dates as "Thu Dec 4, 2025 at 1:43 PM"
- **Smart detection** - Only displays during SSH sessions
- **Fallback support** - Shows IP address if hostname not in mapping table
- **Multiple sources** - Reads from both `wtmp` and `lastlog` for reliability

**Manual Activation (if skipped during setup)**:

If you need to manually configure or re-configure:

1. Run terminal.sh with sudo: `sudo ~/dotfiles/lib/terminal.sh`
2. This will disable `PrintLastLog` in `/etc/ssh/sshd_config`
3. SSH service will be automatically restarted

The display script is integrated into `.zshrc` and runs automatically during SSH sessions.

**Reverting to Default**:

To restore SSH's original lastlog:

```bash
# Restore from backup
sudo cp /etc/ssh/sshd_config.dotfiles-backup /etc/ssh/sshd_config
sudo systemctl restart ssh

# Or manually edit /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config
# Change: PrintLastLog no  →  PrintLastLog yes (or comment it out)
# Then: sudo systemctl restart ssh
```

**Testing**:

To test the display without SSHing:

```bash
SSH_CONNECTION='test' bash ~/dotfiles/lib/last-login.sh
```
