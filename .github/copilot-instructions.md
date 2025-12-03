# Dotfiles Repository Instructions

## Architecture Overview

Symlink-based dotfiles management for Linux hosts. Files live in Git and are symlinked to system locations (`~/.zshrc`, `~/.config/`, etc.). The repository is the single source of truth for shell configs and application configs across multiple hosts.

**Key Components:**
- `install.sh` - Creates all symlinks via SYMLINKS associative array
- `config/functions.zsh` - Common Zsh functions and aliases
- `config/.zshrc` - Main Zsh configuration file
- `lib/utils.sh` - Shared library for colors, icons, and helper functions
- `join.sh` - One-click deployment (installs git/zsh, clones repo, runs `install.sh`)
- `setup/*.sh` - Optional tool installers (fastfetch, foot, nvm, syncthing)

## Critical Workflows

### Adding a New Dotfile
**ALWAYS** use `add-dotfile <path>` function to create a /dotfiles symlink. Never manually move files.

Example:
```bash
add-dotfile ~/.gitconfig
```

The script:
1. Validates source exists and destination available
2. Moves file into repo
3. Creates symlink at original location
4. Adds entry to SYMLINKS array in `install.sh`
5. Stages in git
6. Prints next steps (review with `git diff --staged`, then commit/push)

**Critical**: Preserves portability by replacing literal `$HOME` paths with variable via sed.

### New Host Deployment
Canonical one-liner:
```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

**Prerequisites:** SSH keys must be manually configured before running if wanting to interact with GitHub beyond initial clone.

Flow: Check SSH → Install git/zsh → Configure git user → Clone repo → Run `install.sh`

If repo exists, stashes uncommitted changes before pulling (shows stash command in output).

### Modifying install.sh
Structure to preserve:
1. Create directories (`~/.config/`)
2. Iterate SYMLINKS array with `ln -sf`
3. Source `~/.zshrc` at end

**Variables**:
- `$DOTFILES_DIR` - Resolved via `$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )`
- Source paths use `$DOTFILES_DIR`, target paths use `$HOME`

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

Defined in `lib/utils.sh` and sourced in `.zshrc`


**Idempotency** - All scripts safe to run multiple times. Check existing state before acting:
```bash
if command -v tool &> /dev/null; then
    printf "${GREEN}${CHECK} Already installed.${NC}\n"
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

**`unpackk <archive>`** - Extract archive to directory
- Supports tar.gz, tgz, zip, and 7z formats
- Automatic nested directory handling
- Optional source archive deletion after extraction

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

### Future Enhancements
- **Documentation Polish**: Continue improving documentation clarity
- **Examples**: Add example configurations for common use cases
