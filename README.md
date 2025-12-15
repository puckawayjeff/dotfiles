# Dotfiles Management for Linux Hosts

> **Quick Start:** Deploy to a new host with one command:
>
> ```bash
> wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
> ```
>
> This installs Git, core utilities (bat, p7zip-full, tree), runs automated setup (zsh, eza, fastfetch, starship), clones the repo, and creates symlinks.

## Overview

This repository provides a symlink-based dotfiles management system for maintaining consistent shell configuration and application config across multiple Linux hosts (servers, VMs, and desktops).

Files are stored in this Git repository and symlinked to their expected system locations (`~/.zshrc`, `~/.config/starship.toml`, etc.). The repository serves as the single source of truth, with version control enabling change tracking, rollbacks, and safe experimentation.

## Key Features

- **One-click deployment** - Automated setup on new hosts
- **Symlink-based** - Live editing without manual copying
- **Version controlled** - Full history and rollback capability
- **Host-aware configs** - Gracefully handles missing software

## Terminal Environment

The automated setup configures a modern, powerful shell environment with intelligent completions, fuzzy finding, and visual enhancements:

### Zsh - Modern Shell with Plugins

**Why Zsh?** Modern shell with intelligent completions, command history, and syntax validation. Autosuggestions save hundreds of keystrokes per day. FZF and zoxide revolutionize navigation. Fully compatible with existing bash scripts.

**Automatic Installation:**

- Zsh 5.9+ as default shell
- [Zinit](https://github.com/zdharma-continuum/zinit) plugin manager
- 8 power-user plugins:
  - **zsh-autosuggestions** - Fish-like inline suggestions from history
  - **fast-syntax-highlighting** - Real-time command syntax validation
  - **zsh-completions** - Additional completion definitions
  - **zsh-history-substring-search** - Arrow key history filtering
  - **FZF** - Fuzzy finder for files, history, processes
  - **zoxide** - Smarter cd with frecency algorithm
  - **fd** - Modern, faster find replacement
  - **direnv** - Automatic environment loading per directory
- FiraCode Nerd Font for icon display

**First Use:** Log out and back in after installation. On first zsh session, Zinit auto-installs all plugins (~30 seconds, one-time only).

**Key Features:**

- **Autosuggestions** - Type partial command, press → to accept grey suggestion
- **Syntax Highlighting** - Green = valid, Red = invalid, instantly as you type
- **FZF** - Ctrl+R (history), Ctrl+T (files), Alt+C (directories)
- **Zoxide** - `z dotfiles` jumps intelligently based on frecency
- **History Substring** - Up/Down arrows filter history by typed prefix
- **Fast Startup** - Plugins lazy-load in background (~0.1s prompt)

### Eza - Modern ls Replacement

**Why Eza?** Better defaults, git integration, and icon support. Shows more information at a glance while remaining familiar.

**Automatic Installation:**

- Replaces `ls` with enhanced version via aliases
- Git status integration (modified/staged indicators)
- File type icons with Nerd Fonts
- Directories listed before files
- Tree view for hierarchies
- Written in Rust for performance

**Conditional Aliases:** Automatically used when available, gracefully falls back to standard `ls` on systems without eza.

### Starship - Cross-Shell Prompt

**Why Starship?** Fast, informative prompt with git status, language versions, and context-aware modules.

**Automatic Installation:**

- Cross-shell prompt with Nerd Font support
- Git branch and status indicators
- Language version detection (Node, Python, Rust, etc.)
- Command duration for long-running tasks
- Exit status indicators
- Customizable via `config/starship.toml`

### Fastfetch - System Information

**Why Fastfetch?** Fast neofetch alternative written in C, shows system info with distro logo on terminal login.

**Automatic Installation:**

- Displays on terminal login via MOTD (not on every shell reload)
- System info, distro logo, hardware details
- Compatibility aliases for `neofetch` and `screenfetch`
- Customizable via `config/fastfetch.jsonc`
- See [MOTD Integration](docs/MOTD%20Integration.md) for details

### Terminal Font Setup

For proper icon display in prompts and eza output, configure your terminal to use **FiraCode Nerd Font** (auto-installed by setup). See [Terminal Font Setup](docs/Terminal%20Font%20Setup.md) for terminal-specific configuration instructions.

## Quick Start

### Deploy to a New Host

The `join.sh` script automates the complete setup process:

1. Updates package lists
2. Installs Git (if needed)
3. Installs core utilities: `bat`, `p7zip-full`, `tree`
4. Clones this repository
5. Runs core setup scripts automatically:
   - **zsh** - Modern shell with Zinit, autosuggestions, syntax highlighting, FZF, zoxide
   - **eza** - Modern ls replacement with git integration
   - **fastfetch** - Fast system information display
   - **starship** - Cross-shell prompt with Nerd Font support
6. Creates all symlinks via `install.sh`

```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

**Note**: You'll need to log out and log back in for Zsh to become your default shell.

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

```text
dotfiles/
├── join.sh                 # Initial setup script (auto-installs core tools)
├── install.sh              # Creates all symlinks
├── config/                 # Configuration files
│   ├── .zshrc              # Zsh configuration
│   ├── .zprofile           # Zsh profile
│   ├── functions.zsh       # Custom Zsh functions
│   ├── starship.toml       # Starship prompt configuration
│   └── fastfetch.jsonc     # Fastfetch configuration
├── lib/                    # Shared libraries
│   └── utils.sh            # Common functions for scripts
├── setup/                  # Software setup scripts
│   ├── foot.sh             # 📦 Wayland terminal emulator
│   ├── glow.sh             # 📦 Markdown viewer
│   ├── nvm.sh              # 📦 Node Version Manager
│   └── syncthing.sh        # 📦 File synchronization
└── docs/                   # Extended documentation
    ├── Functions Reference.md
    ├── New Host Deployment.md
    ├── Script Development Best Practices.md
    ├── Setup Scripts Reference.md
    └── Terminal Font Setup.md
```

## Key Files & Components

### Shell Configuration (`.zshrc`)

Modern shell configuration using **Zinit** plugin manager with curated plugins:

**Core Zinit Plugins:**
- `zsh-completions` - Additional completion definitions
- `zsh-autosuggestions` - Fish-like command suggestions
- `zsh-history-substring-search` - Filter history with arrow keys
- `fast-syntax-highlighting` - Real-time command validation

**Oh-My-Zsh Plugins (via Zinit snippets):**
- `git` - Comprehensive git aliases (`gst`, `gco`, `gp`, `gl`, etc.)
- `docker` - Docker shortcuts and completions
- `sudo` - Press ESC twice to prepend sudo
- `extract` - Universal archive extraction
- `command-not-found` - Suggests package installations
- `colored-man-pages` - Syntax-highlighted documentation
- `copypath` / `copyfile` - Clipboard utilities

**Custom Functions:**
- `dotpush()` - One-command git workflow (add, commit, push) from any directory
- `dotpull()` - Pull latest changes from GitHub with automatic stashing
- `dothelp()` - Show all available commands and functions (colorful reference)
- `dotkeys()` - Display keyboard shortcuts quick reference
- `updatep()` - Interactive system update in tmux with colored output
- `mkd()` - Create and enter directory in one command
- `paths()` - Diagnostic tool to verify PATH entries
- `packk()` - Create compressed archives (tar.gz, zip, 7z) from directories
- `maintain()` - Quick `dotpull` and `updatep` combo

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

Standardized installation scripts for system tools. All follow consistent patterns:

- Color output with emojis for visual feedback
- Idempotent (safe to run multiple times)
- Error handling with clear messages
- Progress indicators

**Available Scripts**:

- `foot.sh` - Foot terminal with Cage compositor (Wayland only)
- `glow.sh` - Terminal-based Markdown viewer
- `nvm.sh` - Node Version Manager with Node.js LTS
- `syncthing.sh` - File synchronization service

Run optional setup scripts using the `dotsetup` helper:

```bash
dotsetup glow
dotsetup nvm

# Or list all available scripts
dotsetup
```

Alternatively, run directly:

```bash
bash ~/dotfiles/setup/glow.sh
```

## Documentation

Detailed guides are available in the `docs/` directory:

### Getting Started

- **[New Host Deployment](docs/New%20Host%20Deployment.md)** - Complete guide to `join.sh`, stash behavior, and recovery workflows
- **[Terminal Font Setup](docs/Terminal%20Font%20Setup.md)** - Nerd Font setup instructions

### Configuration & Tools

- **[Functions Reference](docs/Functions%20Reference.md)** - Complete documentation of `dotpush`, `dotpull`, `updatep`, `mkd`, `paths`, and all aliases
- **[Setup Scripts Reference](docs/Setup%20Scripts%20Reference.md)** - Installation scripts for foot, glow, NVM, and Syncthing

### Development

- **[Script Development Best Practices](docs/Script%20Development%20Best%20Practices.md)** - Standards for writing consistent shell scripts