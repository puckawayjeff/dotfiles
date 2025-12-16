# Architecture Overview

This document explains the design philosophy and architecture of the dotfiles system, including the two-repository pattern for public and private data separation.

## Core Principles

1. **Symlink-Based Management**: Configuration files live in Git, symlinked to their expected locations
2. **Idempotent Operations**: All scripts can be run multiple times safely
3. **Mode Detection**: Automatically switches between standalone and enhanced modes
4. **Common Libraries**: Shared utilities prevent code duplication
5. **Graceful Degradation**: Missing tools don't break the system

## Repository Structure

### Public Repository (This Repo)

**Purpose**: Terminal configuration and universal application settings that work on any machine.

**Contains**:
- Shell configuration (`.zshrc`, functions)
- Terminal tool configs (starship, fastfetch, tmux, micro)
- Core utilities and setup scripts
- Common libraries (`lib/utils.sh`, `lib/terminal.sh`)
- Public documentation

**Key Files**:
```
dotfiles/
├── sync.sh              # Main sync script (reads config/symlinks.conf)
├── join.sh              # One-command deployment
├── config/              # Configuration files
│   ├── .zshrc           # Shell configuration
│   ├── functions.zsh    # Custom functions
│   ├── symlinks.conf    # User-added dotfiles registry
│   └── [tool configs]   # starship.toml, tmux.conf, etc.
├── lib/                 # Shared libraries
│   ├── utils.sh         # Colors, logging, helpers
│   ├── terminal.sh      # Core tool installation
│   ├── motd.sh          # Login message display
│   └── last-login.sh    # Custom last login
└── setup/               # Optional tool installers
```

### Private Repository (Optional: sshsync)

**Purpose**: Personal SSH keys, private configurations, and sensitive data.

**Contains**:
- SSH configuration with private hosts
- Encrypted SSH keys (stored on web server, not in Git)
- Personal Git credentials
- Future: encrypted secrets, API keys

**Key Files**:
```
sshsync/
├── ssh.conf            # SSH config (symlinked to ~/.ssh/config)
├── dotfiles.env        # Environment configuration (optional storage)
└── README.md           # Private setup documentation
```

**Why Separate?**
- Security: SSH keys never in public repository
- Flexibility: Public repo works standalone
- Privacy: Host configurations remain private
- Portability: Fork public repo without exposing private data

## Two Modes of Operation

### Standalone Mode (Default)

**Trigger**: No `~/.config/dotfiles/dotfiles.env` file exists

**What Happens**:
1. `join.sh` clones public dotfiles via HTTPS
2. Sets default Git credentials (user must update)
3. Installs core terminal tools
4. Creates symlinks from `config/`
5. One-way sync (pull only from GitHub)

**Available Commands**:
- `dotpull` - Pull latest changes
- `dotsetup` - Run optional installers
- `updatep` - System updates
- `dothelp` / `dotkeys` - Quick reference

**Limitations**:
- Cannot push changes to GitHub (no SSH keys)
- No private SSH configuration
- Default Git credentials need manual update

### Enhanced Mode

**Trigger**: Valid `~/.config/dotfiles/dotfiles.env` file exists

**What Happens**:
1. Downloads encrypted SSH keys from your web server
2. Decrypts and installs keys with proper permissions
3. Configures Git with your personal credentials
4. Clones both dotfiles AND sshsync via SSH
5. Symlinks SSH config from sshsync
6. Two-way sync (push and pull)

**Additional Commands**:
- `dotpush` - Commit and push dotfiles changes
- `sshpush` - Commit and push SSH config changes
- `sshpull` - Pull latest SSH configuration

**Requirements**:
- `dotfiles.env` file with credentials
- Encrypted SSH keys on web server
- Private sshsync repository on GitHub

## Environment Configuration (dotfiles.env)

Located at: `~/.config/dotfiles/dotfiles.env`

**Purpose**: Enable enhanced mode by providing private repository access.

**Required Variables**:
```bash
SSHSYNC_REPO_URL="git@github.com:username/sshsync.git"
SSH_KEYS_ARCHIVE_URL="https://example.com/secure/ssh-keys.tar.gz.enc"
SSH_KEYS_ARCHIVE_PASSWORD="your-secure-password"
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"
```

**Security**:
- Never commit to public repository
- Store in password manager or private repo
- Archive uses AES-256-CBC encryption (PBKDF2, 100k iterations)
- Password should be 16+ characters

**Setup Process**:
1. Create private sshsync repository
2. Package SSH keys with `sshpack` function
3. Upload encrypted archive to web server
4. Create `dotfiles.env` with credentials
5. Run `join.sh` - it auto-detects enhanced mode

See [PRIVATE_SETUP.md](PRIVATE_SETUP.md) for detailed setup guide.

## Symlink Management

### Core Tool Configurations

Managed by `lib/terminal.sh` during installation:
- `.zshrc`, `.zprofile`, `functions.zsh`
- `starship.toml`
- `fastfetch.jsonc`
- `tmux.conf`
- `micro.json` (settings.json)

These are automatically symlinked when their tools are installed.

### User-Added Configurations

Managed by `config/symlinks.conf`:
- Files added via `add-dotfile` command
- Format: `$DOTFILES_DIR/source/path:$HOME/target/path`
- Read by `sync.sh` during symlink creation
- Supports comments (lines starting with `#`)

**Example**:
```bash
add-dotfile ~/.gitconfig
# Moves ~/.gitconfig to ~/dotfiles/config/.gitconfig
# Creates symlink: ~/.gitconfig → ~/dotfiles/config/.gitconfig
# Adds entry to config/symlinks.conf
```

## Library Architecture

### lib/utils.sh (Core Utilities)

**Purpose**: Shared colors, emojis, and logging functions

**Provides**:
- Color constants (GREEN, YELLOW, BLUE, RED, CYAN, MAGENTA)
- Emoji constants (ROCKET, CHECK, CROSS, WARNING, etc.)
- Logging functions (log_section, log_success, log_error, log_info, etc.)
- Terminal utilities (get_hr for horizontal rules)
- QUIET_MODE support for silent operations

**Used By**: All scripts (sync.sh, join.sh, setup scripts, functions.zsh)

### lib/terminal.sh (Tool Installation)

**Purpose**: Install and configure core terminal tools

**Responsibilities**:
- Zsh shell installation and configuration
- Starship prompt setup
- Fastfetch system info display
- Eza (modern ls replacement)
- Tmux terminal multiplexer
- Micro text editor
- Symlink creation for tool configs

**Called By**: sync.sh during initial setup and updates

### lib/motd.sh (Message of the Day)

**Purpose**: Display system information on terminal login

**Responsibilities**:
- Runs fastfetch for system info
- Custom last login display
- Executes in user context (not root)
- Integrated with `/etc/update-motd.d/99-dotfiles`

### lib/last-login.sh (Last Login Display)

**Purpose**: Custom last login message (replaces SSH default)

**Responsibilities**:
- Displays last login timestamp
- IP to hostname mapping
- Cleaner formatting than system default
- Only shows during SSH sessions

## Workflow Architecture

### Initial Deployment (join.sh)

1. **Mode Detection**: Check for `dotfiles.env`
2. **Enhanced Mode Setup** (if applicable):
   - Download encrypted SSH keys
   - Decrypt with password from env file
   - Extract to `~/.ssh/` with proper permissions
   - Configure Git with personal credentials
   - Clone sshsync via SSH
3. **Base Setup**:
   - Install Git if missing
   - Configure Git (enhanced: personal, standalone: defaults)
   - Clone dotfiles repository
4. **Run sync.sh**: Complete system configuration
5. **Final Steps**: Display commands, suggest shell reload

### Regular Sync (sync.sh)

1. **Pull Updates** (unless first run):
   - Pull dotfiles from GitHub
   - Pull sshsync if enhanced mode
   - Auto-stash local changes
2. **Git Configuration**: Set defaults if standalone first-run
3. **SSH Config**: Symlink from sshsync if enhanced mode
4. **Core Utilities**: Install missing packages (bat, 7z, tree, etc.)
5. **Terminal Tools**: Run `lib/terminal.sh`
6. **MOTD Setup**: Configure system login message
7. **User Symlinks**: Process `config/symlinks.conf`
8. **Display Status**: Show mode and next steps

### Adding Dotfiles (add-dotfile)

1. **Validate**: Check source exists, not already symlinked
2. **Move**: Relocate file to repository
3. **Symlink**: Create symlink at original location
4. **Register**: Add entry to `config/symlinks.conf`
5. **Stage**: Git add both file and config
6. **Prompt**: Suggest `dotpush` command

## Git Workflow

### Standalone Mode
- **Pull**: `dotpull` (auto-stash local changes)
- **Push**: Not available (no SSH keys)
- **Remote**: HTTPS clone (read-only)

### Enhanced Mode
- **Pull**: `dotpull` (auto-stash, then `sync.sh --quiet`)
- **Push**: `dotpush "message"` (add, commit, push)
- **SSH Pull**: `sshpull` (update SSH config)
- **SSH Push**: `sshpush "message"` (push SSH changes)
- **Remote**: SSH clone (read-write)

**Conventions**:
- All work on `main` branch (single-user)
- Functions preserve current directory
- Auto-stash before pulls (safe to run anytime)
- Manual reloading or auto-exec after pull

## Security Model

### Public Repository
- No secrets ever committed
- Application configs are public-safe
- SSH config template (no real hosts)
- Default Git credentials are placeholders

### Private Repository (sshsync)
- Private GitHub repository
- SSH keys stored externally (encrypted)
- Real SSH hosts and configurations
- Git credentials in env file (not in repo)

### Encrypted SSH Keys
- AES-256-CBC with PBKDF2 (100k iterations)
- Stored on user's web server
- Downloaded during enhanced mode setup
- Password in `dotfiles.env` (never in Git)

### Defense in Depth
1. Private repository (access control)
2. Encrypted archive (protection at rest)
3. Strong password (encryption key strength)
4. HTTPS transport (protection in transit)
5. Optional HTTP auth on web server

## Extension Points

### Adding New Tools

1. Create installer in `setup/` directory
2. Follow idempotent pattern (check before install)
3. Source `lib/utils.sh` for consistent output
4. Add configuration to `config/` if needed
5. Update `lib/terminal.sh` if core tool
6. Document in Setup Scripts Reference

### Adding New Functions

1. Define in `config/functions.zsh`
2. Use `lib/utils.sh` for logging
3. Preserve current directory
4. Support QUIET_MODE if appropriate
5. Document in Functions Reference
6. Add to `dothelp()` output

### Host-Specific Overrides

Future feature - planned architecture:
```bash
# In .zshrc
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi
```

## Testing Strategy

### test.sh Validation
- Core files exist
- Symlink sources valid
- Shell files source without errors
- Setup scripts have shebangs
- Documentation complete
- Git repository valid
- Library functions defined

### Manual Testing
- Standalone mode deployment (join.sh)
- Enhanced mode deployment (with dotfiles.env)
- Add dotfile workflow
- Pull/push workflows
- Optional tool installers

## Common Patterns

### Error Handling
```bash
if ! command; then
    log_error "Operation failed"
    return 1
fi
```

### Idempotency
```bash
if command -v tool &> /dev/null; then
    log_success "Already installed"
else
    # Install logic
fi
```

### Directory Preservation
```bash
function my_function() {
    local ORIGINAL_DIR="$PWD"
    cd "$HOME/dotfiles" || return 1
    # Do work
    cd "$ORIGINAL_DIR" || true
}
```

### Configuration Markers
```bash
MARKER="# --- Tool Config ---"
if grep -qF "$MARKER" "$CONFIG_FILE"; then
    log_info "Already configured"
else
    echo "$MARKER" >> "$CONFIG_FILE"
    # Add configuration
fi
```

## Future Enhancements

See [CHANGELOG.md](CHANGELOG.md) roadmap section for planned features:
- Host-specific configuration overrides
- Backup/restore functions
- Extended validation in test.sh
- Password manager integration
- Tailscale auto-configuration

---

**For Users**: See [README.md](README.md) for quick start and [PRIVATE_SETUP.md](PRIVATE_SETUP.md) for enhanced mode.

**For Developers**: See [docs/Script Development Best Practices.md](docs/Script%20Development%20Best%20Practices.md) for coding standards.
