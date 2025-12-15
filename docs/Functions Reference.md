# Functions Reference

## Overview

This document provides comprehensive documentation for all custom functions and aliases defined in the dotfiles repository. These are primarily defined in `.zshrc` and `config/functions.zsh`.

## Custom Functions (`.zshrc`)

### `dotpush()` - Simplified Git Workflow

**Purpose**: All-in-one command to stage, commit, and push dotfiles changes from any directory.

**Usage**:

```bash
# With commit message
dotpush "Updated shell configuration"

# Without message (will prompt)
dotpush
```

**How It Works**:

1. Saves your current directory
2. Changes to `~/dotfiles`
3. Stages all changes (`git add .`)
4. Commits with your provided message
5. Pushes to GitHub (`git push`)
6. Returns to your original directory

**Error Handling**:

- Returns error code 1 if no commit message provided (after prompt)
- Returns error code 1 if `~/dotfiles` directory doesn't exist
- Warns but continues if return to original directory fails
- Propagates git command exit codes

---

### `dotpull()` - Pull Latest Dotfiles Changes

**Purpose**: Pull the latest changes from the dotfiles repository on GitHub. Automatically stashes uncommitted local changes before pulling to prevent conflicts.

**Usage**:

```bash
dotpull
```

**How It Works**:

1. Saves your current directory
2. Changes to `~/dotfiles`
3. Checks for uncommitted local changes
4. Stashes local changes if any are found
5. Pulls latest changes from GitHub (`git pull`)
6. Reports success or failure
7. Returns to your original directory

**Features**:

- **Automatic stashing**: Uncommitted changes are safely stashed before pulling
- **Timestamped stash messages**: Easy to identify when stash was created
- **Error handling**: Checks for git errors and reports them
- **Directory restoration**: Returns to your original directory after completion
- **Exit code propagation**: Returns git's exit code for scripting

**When to Use**:

- After making changes on another host and pushing with `dotpush`
- When working across multiple machines (laptop, desktop, servers)
- Before making local changes (to ensure you have latest version)
- As part of automated sync scripts

**Error Handling**:

- Returns error code 1 if `~/dotfiles` directory doesn't exist
- Warns but continues if return to original directory fails
- Propagates git pull exit codes for script integration
- Automatically handles merge conflicts (will report them)

---

### `dotsetup()` - Run Setup Scripts

**Purpose**: Convenient wrapper to run setup scripts from the `~/dotfiles/setup/` directory without typing full paths. Lists available scripts when called without arguments.

**Usage**:

```bash
# List available setup scripts
dotsetup

# Run a specific setup script
dotsetup <script-name>
```

**How It Works**:

1. If no argument provided, lists all `.sh` files in `~/dotfiles/setup/`
2. If script name provided:
   - Validates that `<script-name>.sh` exists
   - Makes it executable if needed
   - Runs the script with zsh
3. Returns the script's exit code for error handling

---

### `updatep()` - Background System Update

**Purpose**: Run system updates (`apt update`, `apt full-upgrade`, `apt autoremove`) in a background tmux session with all output logged to a file.

**Usage**:

```bash
updatep
```

**How It Works**:

1. Checks if tmux is installed (installs it if missing)
2. Creates a temporary script with update commands
3. Launches a detached tmux session to run the script
4. Waits for the session to complete
5. Logs all output to `~/.cache/updatep.log` (overwrites previous run)
6. Auto-closes when finished (no user input required)
7. Shows a summary with log file location

**Update Commands Executed**:

1. `sudo apt update` - Refresh package lists
2. `sudo apt full-upgrade -y` - Upgrade all packages (including kernel)
3. `sudo apt autoremove -y` - Remove unnecessary packages

**Features**:

- **Background execution**: Runs in detached tmux session (non-blocking)
- **Automatic logging**: All output saved to `~/.cache/updatep.log`
- **Auto-install tmux**: Installs tmux automatically if not present
- **Auto-close**: No user interaction required, completes automatically
- **No delays**: Starts immediately and finishes as soon as updates complete
- **Review capability**: Check log file anytime with `cat ~/.cache/updatep.log`

**Log File Details**:

- Location: `~/.cache/updatep.log`
- Format: Plain text with timestamps
- Behavior: Overwrites previous run (non-cumulative)
- Includes: All command output and error messages

**Tmux Session Details**:

- Session name: `system-update-<PID>` (e.g., `system-update-12345`)
- Runs detached (in background)
- Auto-closes when complete
- Temporary script cleaned up after execution

---

### `mkd()` - Make and Enter Directory

**Purpose**: Create a directory and immediately change into it with a single command.

**Usage**:

```bash
mkd /path/to/new/directory
```

---

### `paths()` - Verify PATH Entries

**Purpose**: Diagnostic tool that checks each directory in your `$PATH` and reports which exist (valid) and which are missing (invalid).

**Usage**:

```bash
paths
```

**Output Example**:

```text
Checking PATH entries...
✔ /usr/local/sbin
✔ /usr/local/bin
✔ /usr/sbin
✔ /usr/bin
✔ /sbin
✔ /bin
✔ /home/jeff/.deno/bin
✘ /home/jeff/.cargo/bin
Warning: PATH entry does not exist: /home/jeff/.cargo/bin
✔ /home/jeff/.local/bin
```

**How It Works**:

1. Splits `$PATH` by colon (`:`) delimiter
2. Checks each entry with `[ -d "$path" ]`
3. Prints green ✔ for existing directories
4. Prints red ✘ for missing directories
5. Outputs warnings to stderr for missing entries

---

### `maintain()` - Complete Maintenance Workflow

**Purpose**: All-in-one maintenance command that updates dotfiles, reinstalls configuration, updates system packages, and reloads the shell in a single streamlined workflow.

**Usage**:

```bash
maintain
```

**How It Works**:

1. Saves your current directory
2. Runs `dotpull --no-exec` to get latest dotfiles (auto-stashes local changes)
3. Runs `install.sh` in quiet mode (symlinks are already handled by dotpull)
4. Launches `updatep` to update system packages in background tmux session
5. Returns to original directory
6. Reloads zsh configuration with `exec zsh`

**What Gets Updated**:

- **Dotfiles**: Latest changes from GitHub
- **Symlinks**: Configuration links verified/created
- **System packages**: `apt update`, `apt full-upgrade`, `apt autoremove`
- **Flatpak apps**: If flatpak is installed
- **Shell environment**: Fresh zsh session with updated configs

**Typical Output**:

```text
Starting Maintenance Sequence...
⬇️  Pulling latest changes...
✅ Git pull successful.
🔧 Running install.sh...
✅ Configuration updated.
Launching system updates...

Starting system update process...
✅ tmux is already installed.
💻 Running system update...
Output will be logged to: /home/jeff/.cache/updatep.log
Press Ctrl+B then D to detach if needed

🔄 Reloading zsh configuration...
```

**When to Use**:

- Regular maintenance routine (weekly/monthly)
- After making changes on another host
- Before starting important work (ensure everything is current)
- After system updates to sync environment

**Error Handling**:

- Stops if `dotpull` fails (reports git errors)
- Continues even if system updates fail (logs errors)
- Always attempts to return to original directory
- Always reloads shell (even if updates fail)

**Time to Complete**: 1-5 minutes depending on updates available

**Related Functions**: `dotpull`, `updatep`, `dotpush`

---

### `dotversion()` - Display Dotfiles Version

**Purpose**: Shows the current version of your dotfiles repository along with git branch and commit information.

**Usage**:

```bash
dotversion
```

**Example Output**:

```text
📦 Dotfiles Version: v1.2.0
   Branch: main
   Commit: 8a1cbbd
```

**How It Works**:

1. Reads version from `~/dotfiles/VERSION` file
2. Queries git for current branch name
3. Queries git for latest commit hash (short form)
4. Displays formatted output with colors and emojis

**When to Use**:

- Checking which version is deployed on a host
- Debugging configuration issues (version mismatches)
- Confirming successful updates after `dotpull`
- System information gathering

**Integration**:

This version is also displayed in:
- Fastfetch system information (custom module)
- MOTD on terminal login

**Error Handling**:

- Returns error if `VERSION` file not found
- Gracefully handles missing git information
- Works even if not in a git repository

---

### `dotpack()` - Create Archive from Directory

**Purpose**: Create compressed archives (tar.gz, zip, or 7z) from directories with interactive prompts and colored output.

**Usage**:

```bash
dotpack <directory> [format]
```

**Parameters**:

- `<directory>` - Path to directory to archive (required)
- `[format]` - Archive format: `tar.gz` (default), `zip`, or `7z` (optional)

**How It Works**:

1. Validates directory exists and is not empty
2. Checks if required archiver tool is installed
3. Determines archive name from directory basename
4. Prompts if archive already exists (with overwrite option)
5. Creates archive with appropriate compression in current directory
6. Reports success or failure with colored output

**Examples**:

```bash
# Create tar.gz archive (default)
dotpack myapp
# Creates: myapp.tar.gz

# Create zip archive
dotpack reports zip
# Creates: reports.zip

# Create 7z archive for maximum compression
dotpack data 7z
# Creates: data.7z

# Archive with absolute path
dotpack /var/www/html
# Creates: html.tar.gz in current directory
```

**Supported Formats**:

- **tar.gz** - Standard Unix compressed tar (uses `tar` command)
- **zip** - Cross-platform ZIP format (requires `zip` package)
- **7z** - High compression 7-Zip format (requires `p7zip-full` package)

**Features**:

- **Validation**: Checks directory exists and is not empty before archiving
- **Tool detection**: Verifies required archiver is installed, provides install commands
- **Overwrite protection**: Prompts before overwriting existing archives
- **Progress feedback**: Colored output with emojis for visual status
- **Error handling**: Clear error messages with appropriate exit codes

**Common Use Cases**:

```bash
# Backup configuration directory
dotpack .config

# Archive logs before rotation
dotpack /var/log/application
mv application.tar.gz ~/archives/logs-$(date +%Y%m%d).tar.gz

# Create distribution package
dotpack ~/projects/release zip

# Maximum compression for large datasets
dotpack analytics 7z
```

**Error Messages**:

- `Error: No directory specified` - Missing required directory argument
- `Error: Directory 'X' does not exist` - Invalid directory path
- `Error: Directory 'X' is empty` - Cannot archive empty directory
- `Error: 'tool' is not installed` - Required archiver not found
- `Error: Unsupported format 'X'` - Invalid format specified
- `Error: Failed to create archive` - Archiver command failed

---

### `extract()` - Universal Archive Extraction (oh-my-zsh plugin)

**Purpose**: Universal archive extraction supporting all common archive formats with automatic format detection.

**Usage**:

```bash
extract <archive_file> [archive_file2 ...]
```

**Supported Formats**:
- tar.gz, tgz, tar.bz2, tbz2, tar.xz, txz, tar.lz, tar.zst
- zip, rar, 7z
- gz, bz2, xz, lz, zst
- deb, rpm
- jar, war, ear
- And many more...

**Examples**:

```bash
# Extract single archive
extract data.tar.gz

# Extract multiple archives
extract file1.zip file2.tar.gz file3.7z

# Works with any supported format
extract backup.tar.xz
extract software.rar
```

**Features**:
- Automatic format detection from file extension
- No configuration needed
- Handles nested archives
- Simple, memorable command name

---

### `dotkeys()` - Keyboard Shortcuts Quick Reference

**Purpose**: Display colorful, organized reference of available keyboard shortcuts and keybindings.

**Usage**:

```bash
dotkeys
```

**Features**:
- Multi-column layout optimized for IDE terminal windows (140x20)
- Color-coded categories (Shell, Tmux, Plugins)
- Emoji icons for visual clarity
- Quick lookup for frequently-forgotten shortcuts

**Example Output**:

Shows shortcuts for:
- Shell completion and history navigation
- Tmux multiplexer commands
- Plugin-provided keybindings (sudo, FZF)

---

### `dothelp()` - Custom Functions Quick Reference

**Purpose**: Display comprehensive reference of all custom functions and plugin commands.

**Usage**:

```bash
dothelp
```

**Features**:
- Categorized by function type (Dotfiles, System, Plugins, Navigation)
- Multi-column format for space efficiency
- Color-coded sections with emoji icons
- Includes both custom functions and oh-my-zsh plugin commands

**Categories**:
- **Dotfiles Management**: dotpush, dotpull, add-dotfile, dotsetup, dotversion, maintain
- **System Utilities**: updatep, paths, mkd, dotpack
- **Plugin Commands**: extract, copypath, copyfile, git aliases, docker shortcuts
- **Navigation & Search**: zoxide (j/z), eza listings, fastfetch

---

## Command Aliases

### Color-Enabled Grep Aliases

These aliases add color output to grep commands for better readability.

### `ls`/`eza` Conditional Aliases

The repository uses conditional aliases that provide enhanced directory listings when `eza` is installed, with automatic fallback to traditional `ls` commands:

**When `eza` is installed** (modern ls replacement):

```bash
alias ls='eza --color=auto --group-directories-first'
alias ll='eza --icons -lag --group-directories-first --git'
alias la='eza --icons -a --group-directories-first'
alias l='eza --icons -1 --group-directories-first'
alias lt='eza --icons --tree --level=2 --group-directories-first'
```

**When `eza` is NOT installed** (fallback):

```bash
alias ls='ls --color=auto'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'
```

**Features**:

- **Automatic detection**: Checks if `eza` is installed at shell startup
- **Seamless fallback**: Works on hosts with or without `eza`
- **Enhanced when available**: Git status, icons support, better formatting
- **Consistent interface**: Same commands work everywhere

**Eza Enhancements** (when installed):

- **Git integration** (`ll`) - Shows git status alongside files
- **Icons support** - Compatible with Nerd Fonts for file type icons
- **Group directories first** - Directories always listed before files
- **Tree view** (`lt`) - Visual directory hierarchy (2 levels deep)
- **Better colors** - More readable color scheme

**Format Details**:

- `ll` - Long format with all files, git status (eza), permissions/owner/size/date
- `la` - All files including hidden (except `.` and `..`)
- `l` - Single column (eza) or columnar with type indicators (ls)
- `lt` - Tree view 2 levels deep (eza only)

### `bat` Alias

```bash
alias bat='batcat --color=auto'
```

**Purpose**: Maps `bat` command to `batcat` (the package name on Debian/Ubuntu) with automatic color detection.

**Why This Alias**:
On Debian-based systems, the `bat` package (a different tool) conflicts with the name, so the Rust-based `bat` (cat clone with syntax highlighting) is installed as `batcat`. This alias restores the expected `bat` command.

## Function Usage Tips

### Chaining Functions

Functions can be combined with standard zsh operators:

```bash
# Create directory and immediately create file in it
mkd ~/new-project && touch main.py

# Update system and reboot if successful
updatep && sudo reboot

# Check paths and save output to file
paths > path-check.txt 2>&1
```

### Error Handling

All functions properly propagate exit codes:

```bash
# Check if dotpush succeeded
if dotpush "Update configuration"; then
    echo "Successfully pushed changes"
else
    echo "Push failed, check git status"
fi

# Use in scripts
dotpush "Automated backup" || {
    echo "Backup push failed at $(date)" >> /var/log/backup.log
    exit 1
}
```

### Function Discovery

List all custom functions defined in your shell:

```bash
# Show all functions
declare -F

# Show specific function definition
declare -f dotpush

# Search for functions containing keyword
declare -F | grep update
```

---

## Library Scripts (`lib/`)

### `lib/last-login.sh` - Custom Last Login Display

**Purpose**: Replaces the default PAM lastlog message with a styled version that includes IP-to-hostname mapping and cleaner timestamp formatting. Automatically runs during SSH sessions.

**Invocation**: Automatically sourced by `.zshrc` when `$SSH_CONNECTION` is set (SSH session detected).

**Manual Testing**:

```bash
# Test the display without SSH
SSH_CONNECTION='test' bash ~/dotfiles/lib/last-login.sh
```

**Output Examples**:

```bash
# With hostname mapping configured
Last login: from krang on Thu Dec 4, 2025 at 1:43 PM

# Without hostname mapping (fallback to IP)
Last login: from 100.100.166.103 on Thu Dec 4, 2025 at 1:43 PM

# Local login (no SSH)
Last login: locally on Thu Dec 4, 2025 at 1:43 PM
```

**Customization**:

Edit the `IP_HOSTNAMES` associative array in `lib/last-login.sh`:

```bash
declare -A IP_HOSTNAMES=(
    ["100.100.166.103"]="krang"
    ["192.168.1.100"]="server1"
    ["10.0.0.50"]="workstation"
)
```

**Features**:

- **Styled output** using `lib/utils.sh` colors (green, cyan, yellow)
- **IP-to-hostname resolution** from custom mapping table
- **Fallback to IP** if hostname not found in mapping
- **Cleaner date formatting** (e.g., "Thu Dec 4, 2025 at 1:43 PM")
- **Multiple data sources** - reads from `last` command (wtmp) and `lastlog`
- **SSH-only display** - prevents duplicate messages on local terminals

**Dependencies**:

- `lib/utils.sh` - Color definitions and styling
- PAM lastlog disabled - Use `setup/last-login.sh` to configure

**How It Works**:

1. Checks if running in SSH session (`$SSH_CONNECTION`)
2. Queries `last` command for recent login history
3. Falls back to `lastlog` if `last` fails
4. Resolves IP address to hostname using mapping table
5. Formats timestamp into human-friendly format
6. Displays styled output with colors

**Related Configuration**:

- Installation: `sudo setup/last-login.sh`
- Documentation: See "Setup Scripts Reference.md"
- PAM config: `/etc/pam.d/sshd` (pam_lastlog disabled)

---

## SSH Sync Functions (Optional)

These functions are conditionally loaded only when a companion private repository exists at `~/sshsync/.git`. They provide git workflow commands for managing SSH configuration separately from the main dotfiles repository.

### `sshpush()` - Push SSH Config Changes

**Purpose**: Simplified git workflow for committing and pushing SSH configuration changes from the companion sshsync repository.

**Availability**: Only loaded when `~/sshsync/.git` exists

**Usage**:

```bash
# With commit message
sshpush "Add new server configuration"

# Without message (will prompt)
sshpush
```

**How It Works**:

1. Saves your current directory
2. Changes to `~/sshsync`
3. Stages all changes (`git add .`)
4. Commits with your provided message
5. Pushes to remote repository (`git push`)
6. Returns to your original directory

**The ssh.conf File**:

The `~/sshsync/ssh.conf` file is the actual SSH configuration file. A symlink at `~/.ssh/config` points to it. Changes made to SSH configuration are committed and pushed as part of the normal git workflow.

**Error Handling**:

- Returns error code 1 if no commit message provided (after prompt)
- Returns error code 1 if `~/sshsync` directory doesn't exist
- Warns but continues if return to original directory fails
- Propagates git command exit codes

---

### `sshpull()` - Pull SSH Config Updates

**Purpose**: Pull the latest SSH configuration changes from the companion sshsync repository.

**Availability**: Only loaded when `~/sshsync/.git` exists

**Usage**:

```bash
sshpull
```

**How It Works**:

1. Saves your current directory
2. Changes to `~/sshsync`
3. Pulls latest changes from remote (`git pull`)
4. Reports success or failure
5. Returns to your original directory

**Features**:

- **Quiet SSH**: Uses `LogLevel=ERROR` to suppress verbose SSH output
- **Error reporting**: Clear success/failure messages
- **Directory restoration**: Returns to original directory after completion

**When to Use**:

- After making SSH config changes on another host
- Before adding new SSH configurations (to get latest version)
- As part of system maintenance routine

**Error Handling**:

- Returns error code 1 if `~/sshsync` directory doesn't exist
- Propagates git pull exit codes for script integration
- Returns to original directory even if pull fails

---

**Note**: These functions follow the same pattern as `dotpush` and `dotpull` but operate on the separate sshsync repository. They are designed to work alongside the main dotfiles workflow without interfering with it.
