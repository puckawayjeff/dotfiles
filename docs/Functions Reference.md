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

### `updatep()` - Interactive System Update

**Purpose**: Run system updates (`apt update`, `apt full-upgrade`, `apt autoremove`) in an interactive tmux session with colored output and progress indicators.

**Usage**:

```bash
updatep
```

**How It Works**:

1. Checks if tmux is installed (installs it if missing)
2. Creates a new tmux session with a unique name
3. Runs the update commands in sequence with colored output
4. Waits for user keypress before closing the session
5. Shows a summary after the session closes

**Update Commands Executed**:

1. `sudo apt update` - Refresh package lists
2. `sudo apt full-upgrade -y` - Upgrade all packages (including kernel)
3. `sudo apt autoremove -y` - Remove unnecessary packages

**Features**:

- **Auto-install tmux**: Installs tmux automatically if not present
- **Colored output**: Uses tput-based colors for compatibility
- **Interactive review**: Pauses before closing so you can review results
- **Session isolation**: Runs in a separate tmux session
- **Error handling**: Checks each command and reports failures

**Tmux Session Details**:

- Session name: `system-update-<PID>` (e.g., `system-update-12345`)
- Auto-attaches to the session (you see the output live)
- Closes automatically after keypress
- Can be detached with `Ctrl+b d` if needed

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

### `packk()` - Create Archive from Directory

**Purpose**: Create compressed archives (tar.gz, zip, or 7z) from directories with interactive prompts and colored output.

**Usage**:

```bash
packk <directory> [format]
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
packk myapp
# Creates: myapp.tar.gz

# Create zip archive
packk reports zip
# Creates: reports.zip

# Create 7z archive for maximum compression
packk data 7z
# Creates: data.7z

# Archive with absolute path
packk /var/www/html
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
packk .config

# Archive logs before rotation
packk /var/log/application
mv application.tar.gz ~/archives/logs-$(date +%Y%m%d).tar.gz

# Create distribution package
packk ~/projects/release zip

# Maximum compression for large datasets
packk analytics 7z
```

**Error Messages**:

- `Error: No directory specified` - Missing required directory argument
- `Error: Directory 'X' does not exist` - Invalid directory path
- `Error: Directory 'X' is empty` - Cannot archive empty directory
- `Error: 'tool' is not installed` - Required archiver not found
- `Error: Unsupported format 'X'` - Invalid format specified
- `Error: Failed to create archive` - Archiver command failed

---

### `unpackk()` - Extract Archive to Directory

**Purpose**: Extract compressed archives (tar.gz, tgz, zip, or 7z) to directories with automatic nested directory handling, overwrite protection, and optional source deletion.

**Usage**:

```bash
unpackk <archive_file>
```

**How It Works**:

1. Validates archive file exists
2. Determines archive format from extension
3. Checks if required extraction tool is installed
4. Creates target directory (prompts if exists)
5. Extracts archive to target directory
6. Fixes nested directory structure if detected
7. Optionally deletes source archive after extraction

**Examples**:

```bash
# Extract 7z archive
unpackk data.7z
# Creates: data/ directory

# Extract with full path
unpackk ~/downloads/backup.tar.gz
# Creates: backup/ in current directory
```

**Supported Formats**:

- **tar.gz** - Standard Unix compressed tar (uses `tar` command)
- **tgz** - Alternate tar.gz extension (uses `tar` command)
- **zip** - Cross-platform ZIP format (requires `unzip` package)
- **7z** - 7-Zip format (requires `p7zip-full` package)

**Features**:

- **Format detection**: Automatically detects archive type from extension
- **Tool detection**: Verifies required extractor is installed, provides install commands
- **Overwrite protection**: Prompts before overwriting existing directories
- **Nested directory fix**: Automatically flattens single-directory archives
- **Source cleanup**: Optional deletion of archive after extraction
- **Progress feedback**: Color output with emojis for visual status
- **Error handling**: Clear error messages with appropriate exit codes

**Common Use Cases**:

```bash
# Extract downloaded software
cd ~/downloads
unpackk node-v18.tar.gz
cd node-v18

# Restore configuration backup
cd ~
unpackk config-backup.tar.gz

# Extract and cleanup
unpackk archive.zip
# Prompts: "Delete source archive 'archive.zip'? [y/N]:"
# Answer 'y' to delete original zip file

# Extract multiple archives
for archive in *.tar.gz; do
    unpackk "$archive"
done
```

## Command Aliases

### Color-Enabled Grep Aliases

These aliases add color output to grep commands for better readability.

### `ls`/`eza` Conditional Aliases

The repository uses conditional aliases that provide enhanced directory listings when `eza` is installed, with automatic fallback to traditional `ls` commands:

**When `eza` is installed** (modern ls replacement):

```bash
alias ls='eza --color=auto --group-directories-first'
alias ll='eza -lag --group-directories-first --git'
alias la='eza -a --group-directories-first'
alias l='eza -1 --group-directories-first'
alias lt='eza --tree --level=2 --group-directories-first'
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

**Prerequisites**:

```bash
sudo apt install bat
```

**Usage**:

```bash
# View file with syntax highlighting
bat .zshrc

# View file without line numbers
bat --style=plain script.sh

# Compare files
bat file1.txt file2.txt
```

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
