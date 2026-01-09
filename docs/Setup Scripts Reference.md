# Setup Scripts Reference

## Overview

The `setup/` directory contains standardized installation scripts for tools and services. Each script is:

- **Idempotent** - Safe to run multiple times without errors
- **Self-contained** - No arguments required, interactive where needed
- **Consistent** - All follow the same formatting and error handling patterns
- **Well-documented** - Clear output with colored progress indicators

### Tools

These tools may be manually installed via `dotsetup`:

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

### Foot Terminal - Wayland Terminal Emulator

**Script**: `setup/foot.sh` 📦

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

### Glow - Terminal Markdown Renderer

**Script**: `setup/glow.sh` 📦

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

### NVM - Node Version Manager

**Script**: `setup/nvm.sh` 📦

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

### Syncthing - Continuous File Synchronization

**Script**: `setup/syncthing.sh` 📦

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
