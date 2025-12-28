# Dotfiles Management for Linux Hosts

> **Quick Start:** Deploy to a new host with one command:
>
> ```bash
> wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
> ```

## Overview

Symlink-based dotfiles management for consistent shell configuration across Linux hosts (servers, VMs, desktops). Configuration files live in Git and are symlinked to system locations (`~/.zshrc`, `~/.config/`, etc.).

**Two Modes**:
- **Standalone**: Public dotfiles only (works immediately, one-way sync)
- **Enhanced**: Private SSH keys + configs (requires setup, two-way sync)

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system design.

## 🚀 Quick Start

### Standalone Mode (Default)

No setup required - just run the command above!

**What you get**:
- ✅ Modern Zsh with plugins (autosuggestions, syntax highlighting, FZF, zoxide)
- ✅ Starship prompt with Git integration
- ✅ Fastfetch system info display
- ✅ Enhanced tools (eza, tmux, micro, bat)
- ✅ Sensible Git defaults
- ✅ Pull updates from GitHub

**First login**: Type `dothelp` for commands or `dotkeys` for keyboard shortcuts.

### Enhanced Mode (Optional)

For managing multiple machines with SSH keys and private configurations.

**Additional features**:
- ✅ Encrypted SSH keys auto-deployment
- ✅ Private SSH config repository
- ✅ Personal Git credentials
- ✅ Two-way sync commands: `dotpush`, `sshpush`, `sshpull`

**Setup**: See [PRIVATE_SETUP.md](PRIVATE_SETUP.md) for step-by-step guide.

## Essential Commands

```bash
# View all commands
dothelp              # Show command reference
dotkeys              # Show keyboard shortcuts

# Manage dotfiles
dotpull              # Pull latest changes (standalone + enhanced)
dotpush "message"    # Commit and push changes (enhanced only)
add-dotfile <path>   # Add file to repo with symlink

# System maintenance
updatep              # System update in tmux
maintain             # Full maintenance workflow (pull + update)

# Setup optional tools
dotsetup             # List available installers
dotsetup nvm         # Install Node Version Manager
```

See [docs/Functions Reference.md](docs/Functions%20Reference.md) for complete documentation.

## Terminal Features

### Shell Environment
- **Zsh** with Zinit plugin manager
- **Autosuggestions** - Press → to accept grey completions
- **Syntax highlighting** - Instant validation (green=valid, red=invalid)
- **FZF** - Ctrl+R (history), Ctrl+T (files), Alt+C (directories), Tab (fuzzy completion)
- **Zoxide** - Smart directory jumping with `j` command
- **Micro** - Modern terminal editor (default EDITOR)
- **Ripgrep** - Ultra-fast search tool for code

### Visual Tools
- **Starship** - Fast, informative prompt with Git status
- **Eza** - Modern `ls` with icons and Git integration
- **Fastfetch** - System info on terminal login
- **Tmux** - Terminal multiplexer with sensible defaults

### Power Features
- **fcd** - Fuzzy directory change with tree preview
- **fne** - Find text in files and edit at exact line (ripgrep + fzf + micro)
- **git open** - Open current repository in browser
- **1M command history** - Find that command from 6 months ago

### Plugins
- **Oh-My-Zsh**: git, docker, extract, command-not-found, colored-man-pages, copypath, copyfile
- **Core**: completions, multi-word history search, syntax highlighting, autosuggestions
- **FZF-Tab**: Fuzzy tab completion with file/directory previews
- **Git-Open**: Open repositories in browser
- **Additional**: zsh-help, printdocker, zsh-activate-py-environment, zsh-you-should-use

## Adding Your Own Dotfiles

Use the `add-dotfile` command to automate the process:

```bash
# Simple usage (moves to config/ directory)
add-dotfile ~/.gitconfig

# Custom destination
add-dotfile ~/.config/app/config.json config/app-config.json

# Then push changes
dotpush "Add gitconfig"
```

The script:
1. Moves file into the repository
2. Creates symlink at original location
3. Updates `config/symlinks.conf`
4. Stages changes in Git

See [docs/Examples.md](docs/Examples.md) for workflows and patterns.

## Repository Structure

```text
dotfiles/
├── join.sh                    # One-command deployment
├── sync.sh                    # Main sync script
├── test.sh                    # Validation suite
├── VERSION                    # Version tracking
├── ARCHITECTURE.md            # System design documentation
├── PRIVATE_SETUP.md           # Enhanced mode setup guide
├── QUICKSTART.md              # Command reference card
├── config/                    # Configuration files
│   ├── zshrc.conf             # Shell configuration
│   ├── zprofile.conf          # Zsh profile
│   ├── functions.zsh          # Custom functions
│   ├── symlinks.conf          # User-added dotfiles
│   ├── starship.toml          # Prompt configuration
│   ├── fastfetch.jsonc        # System info display
│   ├── tmux.conf              # Terminal multiplexer
│   ├── micro.json             # Text editor settings
│   └── eza-theme.yml          # File listing theme
├── lib/                       # Shared libraries
│   ├── utils.sh               # Colors, logging, helpers
│   ├── terminal.sh            # Core tool installation
│   ├── motd.sh                # Login message
│   └── last-login.sh          # Last login display
├── setup/                     # Optional tool installers
│   ├── foot.sh                # Wayland terminal
│   ├── glow.sh                # Markdown viewer
│   ├── nvm.sh                 # Node Version Manager
│   └── syncthing.sh           # File synchronization
└── docs/                      # Extended documentation
```

## Documentation

### Core Documentation
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design and repository pattern
- **[PRIVATE_SETUP.md](PRIVATE_SETUP.md)** - Enhanced mode setup guide
- **[QUICKSTART.md](QUICKSTART.md)** - Essential commands reference
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

### Guides
- **[Functions Reference](docs/Functions%20Reference.md)** - Complete command documentation
- **[New Host Deployment](docs/New%20Host%20Deployment.md)** - join.sh workflow and recovery
- **[Terminal Font Setup](docs/Terminal%20Font%20Setup.md)** - Nerd Fonts installation
- **[Setup Scripts Reference](docs/Setup%20Scripts%20Reference.md)** - Optional tool installers
- **[Examples](docs/Examples.md)** - Practical workflows and patterns

### Development
- **[Script Development Best Practices](docs/Script%20Development%20Best%20Practices.md)** - Coding standards

## Testing

Validate repository health:

```bash
./test.sh
```

Runs 9 tests checking:
- Core files exist
- Symlink sources valid
- Shell files source correctly
- Setup scripts properly formatted
- Documentation complete
- Git repository valid

## SSH Configuration

**Standalone Mode**: Manual SSH setup required for Git push access.

```bash
# Generate key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github

# Add to GitHub at https://github.com/settings/keys

# Create SSH config
cat >> ~/.ssh/config << 'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes
EOF
```

**Enhanced Mode**: SSH keys automatically deployed from encrypted archive.

## Forking This Repository

To create your own dotfiles:

1. **Fork** this repository on GitHub
2. **Clone** your fork: `git clone git@github.com:yourusername/dotfiles.git`
3. **Customize** configurations in `config/` directory
4. **Update** `join.sh` with your repository URL
5. **Test** with `./test.sh`
6. **Deploy** to your machines

For enhanced mode:
1. Create private `sshsync` repository
2. Package SSH keys with `sshpack` function
3. Host encrypted archive on your web server
4. Create `dotfiles.env` with your credentials

See [PRIVATE_SETUP.md](PRIVATE_SETUP.md) for detailed instructions.

## System Requirements

- **OS**: Debian-based Linux (Debian, Ubuntu, Mint, Pi OS, Proxmox VE)
- **Shell**: Bash 4.0+ (script compatibility)
- **Terminal**: ANSI color and Unicode support
- **Network**: Internet access for package installation
- **Privileges**: User with sudo access

Zsh, Git, and other tools are auto-installed if missing.

## Version

Current version: **1.3.0**

Check installed version:
```bash
dotversion
```

## License

MIT License - See [LICENSE.md](LICENSE.md)

## Contributing

This is a personal dotfiles repository optimized for my workflow. Feel free to:
- Fork for your own use
- Open issues for bugs
- Submit PRs for improvements to the framework

For personal customization, fork the repository and make it your own!

## Support

- **Issues**: Report bugs or ask questions via GitHub Issues
- **Documentation**: Check `docs/` directory for detailed guides
- **Quick Help**: Run `dothelp` in your terminal after installation

---

**Made with ❤️ for efficient terminal workflows**
