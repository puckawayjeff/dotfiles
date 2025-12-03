# Setup Scripts Reference

## Overview

The `setup/` directory contains standardized installation scripts for tools and services. Each script is:

- **Idempotent** - Safe to run multiple times without errors
- **Self-contained** - No arguments required, interactive where needed
- **Consistent** - All follow the same formatting and error handling patterns
- **Well-documented** - Clear output with colored progress indicators

### Core vs Optional Tools

**Core Tools (Automatically Installed)**:

These tools are automatically installed by `new-host.sh`:

- **zsh** - Installed first to provide the shell environment
- **eza** - Modern ls replacement
- **fastfetch** - System information display
- **starship** - Cross-shell prompt

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

### Eza - Modern ls Replacement

**Script**: `setup/eza.sh` ⚙️ **Automatically Installed**

**Project**: [eza](https://github.com/eza-community/eza) - Modern replacement for `ls` with better defaults, git integration, and icon support. Provides more information at a glance while remaining familiar. The repository's conditional aliases mean you get enhanced features when available but still work on systems without eza.

**Note**: This tool is automatically installed by `new-host.sh` during initial setup.

**What It Does**:

- Installs `eza` package from system repositories
- Provides enhanced directory listings with colors, icons, and git integration
- Automatically used by `ls` aliases when available (see `.zshrc` conditional aliases)

**Key Features**:

- **Git integration** - Shows modified/staged status next to files
- **Icons** - File type icons with Nerd Fonts
- **Colors** - Enhanced, readable color scheme
- **Group directories** - Directories listed before files
- **Tree view** - Visual directory hierarchy
- **Fast** - Written in Rust for performance

**Project Repository**: [eza-community/eza](https://github.com/eza-community/eza)

---

### Fastfetch - System Information Tool

**Script**: `setup/fastfetch.sh` ⚙️ **Automatically Installed**

**Project**: [fastfetch](https://github.com/fastfetch-cli/fastfetch) - Fast neofetch-like system information tool written in C

**Note**: This tool is automatically installed by `new-host.sh` during initial setup.

**What It Does**:

- Adds the official Fastfetch PPA
- Installs the fastfetch package
- Configures compatibility aliases for `neofetch` and `screenfetch`
- Sets fastfetch to run automatically on interactive shell startup

**Configuration**: Symlinked config file `config/fastfetch.jsonc`.

**Why Use This**: Faster than neofetch and screenfetch, with more accurate information and better customization options. Shows system info, distro logo, and hardware details in a visually appealing format.

---

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

### Zsh - Modern Shell with Plugins

**Script**: `setup/zsh.sh` ⚙️ **Automatically Installed**

**Project**: [Zsh](https://www.zsh.org/) with [Zinit](https://github.com/zdharma-continuum/zinit) plugin manager. Modern shell with intelligent completions, command history, and syntax validation. Autosuggestions alone save hundreds of keystrokes per day. FZF and zoxide revolutionize navigation. Fully compatible with existing bash scripts and dotfiles structure.

**Note**: This is the first script run by `new-host.sh` to establish the shell environment. Zsh will be set as your default shell automatically.

**What It Does**:

- Installs Zsh shell (5.9+)
- Installs 8 power-user plugins via Zinit:
  - **zsh-autosuggestions** - Fish-like inline command suggestions
  - **fast-syntax-highlighting** - Real-time command syntax validation
  - **zsh-completions** - Additional completion definitions
  - **zsh-history-substring-search** - Arrow key history filtering
  - **FZF** - Fuzzy finder for files, history, processes
  - **zoxide** - Smarter cd with frecency algorithm
  - **fd** - Modern, faster find replacement
  - **direnv** - Automatic environment loading per directory
- Installs FiraCode Nerd Font for proper icon display
- Creates symlinked `.zshrc` configuration
- Changes default shell from bash to zsh automatically

**Installation Process**:

1. Checks if zsh is already installed
2. Installs zsh package via apt
3. Installs power tools: fzf, zoxide, fd-find, direnv
4. Calls `_firacodenerdfont.sh` helper for Nerd Font installation
5. Runs `install.sh` to create `.zshrc` symlink
6. Validates zsh configuration for syntax errors
7. Changes default shell using `chsh -s $(which zsh)`
8. Adds zsh to `/etc/shells` if needed

**First Launch Setup**:

On your first interactive zsh session (after logging out/back in), Zinit will auto-install:

- Takes approximately 30 seconds
- Downloads and configures all 8 plugins
- Compiles optimized versions for faster loading
- Only happens once per host

**Usage After Installation**:

**CRITICAL**: You MUST log out and log back in (or reboot) for the shell change to take effect.

After logging back in, test your new features:

```bash
# Test autosuggestions - type a partial command then press → to accept
cd ~/dotf  # Press → to autocomplete to "cd ~/dotfiles"

# Test FZF fuzzy history search
# Press Ctrl+R, then type any part of a previous command

# Test zoxide smart cd
z dotfiles  # Jumps to ~/dotfiles (learns from your cd history)

# Test syntax highlighting
ls        # Green = valid command
lss       # Red = invalid command

# Test completions - press Tab for enhanced suggestions
git <Tab>
docker <Tab>

# Test history substring search
cd        # Press Up arrow to cycle through all cd commands
apt       # Press Up arrow to cycle through all apt commands

# Test FZF file finder
# Ctrl+T to fuzzy find files in current directory
vim <Ctrl+T>

# Test direnv (if you have .envrc files)
cd project-with-envrc  # Automatically loads environment variables

# Verify all custom bash functions work in zsh
dotsetup   # Should list all setup scripts
dotpush    # Git workflow function
updatep    # System update in tmux
mkd test   # Create and cd into directory
```

**Configuration Files**:

- `~/.zshrc` - Main configuration (symlinked to `~/dotfiles/config/.zshrc`)
- `~/.zinit/` - Zinit and plugin installation directory (auto-created)
- `~/.local/share/fonts/NerdFonts/` - FiraCode Nerd Font installation

**Key Features Explained**:

- **Autosuggestions**: Type any command, see grey suggestion based on your history, press → to accept
- **Syntax Highlighting**: Green = valid, Red = invalid, instantly as you type
- **FZF**: Fuzzy finder with preview windows, works with Ctrl+R (history), Ctrl+T (files), Alt+C (directories)
- **Zoxide**: Tracks your most-used directories, `z` command jumps intelligently
- **History Substring**: Up/Down arrows filter history based on what you've typed
- **Direnv**: Auto-loads `.envrc` files when entering directories (useful for project-specific env vars)

**Performance Notes**:

Zinit uses lazy-loading (turbo mode) to maintain fast shell startup:

- Initial prompt appears in ~0.1 seconds
- Plugins load in background within 1 second
- Subsequent shells start instantly

**Terminal Font Configuration**:

For proper icon display in Starship prompt and eza output, configure your terminal to use "FiraCode Nerd Font". See [Terminal Font Setup](Terminal Font Setup.md) for detailed instructions for your specific terminal.

**Switching Back to Bash**:

If you need to temporarily use bash:

```bash
bash  # Start bash session
```

To permanently switch back:

```bash
chsh -s /bin/bash
```

**Project Repositories**:

- [Zsh](https://www.zsh.org/)
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)

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
