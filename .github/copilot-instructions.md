# Dotfiles Repository Instructions

## Architecture Overview

Symlink-based dotfiles management for Linux hosts. Files live in Git and are symlinked to system locations (`~/.zshrc`, `~/.config/`, etc.). The repository is the single source of truth for shell configs and application configs across multiple hosts.

**Key Components:**
- `install.sh` - Orchestrates installation and manages user-defined symlinks
- `config/symlinks.conf` - User-added dotfiles symlink registry (managed by add-dotfile)
- `config/functions.zsh` - Common Zsh functions and aliases
- `config/.zshrc` - Main Zsh configuration file
- `lib/utils.sh` - Shared library for colors, icons, and helper functions
- `lib/terminal.sh` - Core terminal utilities installer + configuration management (zsh, starship, fastfetch, tmux)
- `join.sh` - One-click deployment (installs git/zsh, clones repo, runs `install.sh`)
- `setup/*.sh` - Optional tool installers (foot, glow, nvm, syncthing)

## Critical Workflows

### Adding a New Dotfile
**ALWAYS** use `add-dotfile <path>` function to add user files to dotfiles. Never manually move files.

Example:
```bash
add-dotfile ~/.gitconfig
```

The script:
1. Validates source exists and destination available
2. Moves file into repo (default: `config/<basename>`)
3. Creates symlink at original location
4. Adds entry to `config/symlinks.conf` (not install.sh)
5. Stages files in git
6. Prints next steps (review with `git diff --staged`, then commit/push)

**Critical**: 
- Preserves portability by using `$HOME` and `$DOTFILES_DIR` variables
- Writes to `config/symlinks.conf` in format: `source:target`
- Core tool configs (zsh, starship, fastfetch, tmux) are managed by `lib/terminal.sh`, not via add-dotfile

### New Host Deployment
Canonical one-liner:
```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

**Prerequisites:** SSH keys must be manually configured before running if wanting to interact with GitHub beyond initial clone.

Flow: Check SSH → Install git/zsh → Configure git user → Clone repo → Run `install.sh`

If repo exists, stashes uncommitted changes before pulling (shows stash command in output).

### Symlink Management Architecture

**Core Tool Configs** (managed by `lib/terminal.sh`):
- `.zshrc`, `.zprofile`, `functions.zsh` - Zsh configuration
- `starship.toml` - Starship prompt
- `fastfetch.jsonc` - Fastfetch system info
- `tmux.conf` - Tmux multiplexer

These are automatically symlinked during `terminal.sh` execution via `setup_config_symlinks()`.

**User-Added Configs** (managed by `config/symlinks.conf`):
- Format: `$DOTFILES_DIR/path/to/file:$HOME/target/path`
- Read by `install.sh` during step 5
- Added via `add-dotfile` function (never edit manually)
- Supports comments (lines starting with `#`)

**Variables**:
- `$DOTFILES_DIR` - Resolved via `$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )`
- Source paths use `$DOTFILES_DIR`, target paths use `$HOME`
- Variables are expanded at runtime via `eval echo`

## Git Workflow (Single-User)

This is a personal sync repository, not collaborative development. All work on `main` branch.

**Preferred workflow** (from any directory):
```bash
dotpush "description"
```

The `dotpush` function (defined in `.zshrc`):
- Changes to `~/dotfiles`
- Runs `git add . && git commit -m "$1" && git push`
- Prompts for message if none provided
- Returns to original directory
- Returns exit code for scripting

Testing happens live. No branches. Changes sync immediately via symlinks.

## Script Development Standards

### Environment Assumptions
- **OS**: Debian-based (Debian, Ubuntu, Mint, Pi OS, Proxmox VE) - `apt` package manager
- **Shell**: Zsh (installed if missing)
- **Privileges**: User with `sudo` access
- **Network**: Internet access for package installation and git operations
- **Display**: Works with/without GUI
- **Fonts**: Nerd Fonts for emoji/glyphs
- **Terminal**: ANSI colors + Unicode support

### Required Patterns

**Colors, Emoji constants, and Output format**:

Defined in `lib/utils.sh` and sourced in `.zshrc`. **CRITICAL**: Always use `log_*` helper functions for output, never raw `printf` or `echo` with color codes.

**Available log_* functions**:
- `log_section "Title" "Optional Icon"` - Section headers (cyan, always shown)
- `log_success "Message"` - Success messages (green with ✅)
- `log_error "Message"` - Error messages (red with ❌, always shown)
- `log_info "Message"` - Info messages (blue)
- `log_warning "Message"` - Warnings (yellow, always shown)
- `log_step "Message" "Optional Icon"` - Step descriptions (blue with 🔧)
- `log_action "Message" "Optional Icon"` - Actions in progress (cyan with 💻)
- `log_complete "Message"` - Completion messages (green with 🎉)
- `log_data "Icon" "Color" "Message"` - Data display with custom icon/color
- `log_substep "Message"` - Sub-step indented text
- `log_plain "Message"` - Plain text without formatting

**Example usage**:
```bash
log_section "Installing Package"
log_step "Downloading dependencies"
log_data "$COMPUTER" "${CYAN}${BOLD}" "hostname"
log_data "$CLOCK" "$YELLOW" "Thu Dec 4, 2025 at 3:02 PM"
log_success "Installation complete"
```

**Idempotency** - All scripts safe to run multiple times. Check existing state before acting:
```bash
if command -v tool &> /dev/null; then
    log_success "Already installed"
else
    # Install logic
fi
```

**Configuration markers** (for `.zshrc` additions):
```bash
MARKER_START="# --- Tool Configuration ---"
if grep -Fxq "$MARKER_START" "$CONFIG_FILE"; then
    echo "Already configured"
else
    cat >> "$CONFIG_FILE" << 'EOL'
# --- Tool Configuration ---
# Configuration here
# --- End Tool Configuration ---
EOL
fi
```

### Host-Aware .zshrc Pattern
Prevent errors when optional tools aren't installed:
```bash
if [ -d "$HOME/.deno" ]; then
  export DENO_INSTALL="$HOME/.deno"
  export PATH="$DENO_INSTALL/bin:$PATH"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
```

Apply to all optional tools: Deno, dotnet, NVM, etc.

## Key Shell Functions (`.zshrc`)

**`dotpush [message]`** - One-command git workflow
- Saves current directory, changes to `~/dotfiles`
- Prompts for message if not provided
- Runs `git add . && git commit && git push`
- Returns to original directory

**`dotpull()`** - Pull latest dotfiles changes
- Saves current directory, changes to `~/dotfiles`
- Automatically stashes uncommitted changes
- Pulls from GitHub and reports status
- Returns to original directory

**`updatep()`** - Interactive system update in tmux
- Auto-installs tmux if missing
- Runs `apt update && apt full-upgrade -y && apt autoremove -y`
- Colored output with progress indicators
- Waits for keypress before closing session
- Session name: `system-update-$$` (unique per invocation)

**`mkd <dir>`** - Create directory and cd into it
- Equivalent to `mkdir -p "$1" && cd "$1"`

**`paths()`** - Diagnostic for PATH validity
- Splits `$PATH` by `:`, checks each entry
- Prints ✔ (green) for existing directories
- Prints ✘ (red) + warning to stderr for missing

**`packk <directory> [format]`** - Create archive from directory
- Supports tar.gz (default), zip, and 7z formats
- Interactive overwrite protection
- Validates directory exists and is not empty

**`extract <archive>`** - Extract any archive format (oh-my-zsh plugin)
- Universal extractor for all common archive types
- Automatic format detection
- No configuration needed

**`dothelp()`** - Display custom functions quick reference
- Colorful multi-column reference of all commands
- Categorized by type (Dotfiles, System, Plugins, Navigation)
- Includes custom functions and oh-my-zsh plugin commands
- Optimized for IDE terminal windows

**`dotkeys()`** - Display keyboard shortcuts quick reference
- Shows all available keybindings and shortcuts
- Color-coded categories (Shell, Tmux, Plugins)
- Multi-column layout for space efficiency
- Quick lookup for frequently-used shortcuts

## Oh-My-Zsh Plugins (via Zinit)

The repository uses Zinit to load oh-my-zsh plugins without the full framework overhead:

**Loaded plugins:**
- **git** - Git aliases (`gst`, `gco`, `gp`, `gl`, `gcmsg`, etc.)
- **docker** - Docker shortcuts (`dps`, `dex`, `dlog`, `dstop`)
- **sudo** - ESC ESC to prepend sudo
- **extract** - Universal archive extraction
- **command-not-found** - Package suggestions
- **colored-man-pages** - Syntax highlighting for man pages
- **copypath** - Copy current directory path
- **copyfile** - Copy file contents to clipboard

## SSH Key Management

SSH keys and configuration are NOT managed by this repository. Users must configure SSH manually to enable git operations.

Example SSH setup:
- Generate keys: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github`
- Add public key to GitHub: https://github.com/settings/keys
- Create `~/.ssh/config` with host aliases as needed

## Common Operations

**Add new setup script**:
1. Create in `setup/` following standard format (see `setup/nvm.sh` for reference)
2. Must be idempotent with marker-based config additions
3. Use consistent colors/emojis/output format
4. Add to `dotpush "Add <tool> setup script"`

**Modify existing function in .zshrc**:
1. Edit `config/.zshrc` directly (already symlinked)
2. Changes take effect immediately (or `source ~/.zshrc`)
3. Run `dotpush "Update <function> description"`

## Documentation Structure

`docs/` contains detailed guides (markdown files):
- **Functions Reference.md** - All functions and aliases documented
- **New Host Deployment.md** - `join.sh` guide, stash behavior, recovery
- **Script Development Best Practices.md** - Conventions documented here
- **Setup Scripts Reference.md** - Installation scripts for tools
- **Terminal Font Setup.md** - Nerd Fonts installation guide

## Project Roadmap (December 2025)

### Completed (December 2025)
- ✅ **Test Suite**: Created `test.sh` validation script
- ✅ **Examples Documentation**: Added comprehensive `docs/Examples.md`
- ✅ **Enhanced add-dotfile**: Support for custom paths, symlink detection, better error handling
- ✅ **Changelog**: Created `CHANGELOG.md` for tracking changes
- ✅ **Quick Start Guide**: Created `QUICKSTART.md` reference card
- ✅ **Tmux Configuration**: Complete tmux setup with sensible defaults
  - Mouse support enabled
  - Vim-style keybindings for pane navigation
  - Intuitive split commands (`|` and `-`)
  - Customized status bar with session info, date, and time
  - Integration with `updatep` function
  - Automated installation via `lib/terminal.sh`
  - Symlinked configuration at `~/.tmux.conf`
  - Comprehensive documentation added

### Future Enhancements

**High Priority:**
- None currently - all high priority items completed!

**Medium Priority:**
- **Host-Specific Overrides**: Support per-host customization
  - `config/hosts/<hostname>/` directory structure
  - Load optional `~/.zshrc.local` for host-specific settings
  - Document patterns in best practices
  - Allow host-specific aliases and environment variables

**Low Priority:**
- **Backup/Restore Functions**: Add safety net for major changes
  - `dotbackup` function for timestamped backups
  - `dotrestore` function to rollback to previous state
- **Extended Validation**: Enhance `test.sh` with additional checks
  - Verify plugin installations
  - Check for common configuration errors
  - Performance benchmarks for shell startup time
