# Script Development Best Practices

This guide establishes conventions for creating and maintaining bash scripts in the dotfiles repository. Following these patterns ensures consistency, readability, and maintainability across all scripts.

## Environment & Assumptions

All scripts should be written with these assumptions:

- **Target OS**: Debian-based Linux (Debian, Ubuntu, Mint, Pi OS, Proxmox)
- **Shell**: Zsh or Bash
- **Display**: May or may not have GUI (scripts should work in headless environments)
- **Fonts**: Nerd Fonts available (emoji and glyphs can be used freely)
- **Terminal**: ANSI color codes and Unicode fully supported

## Script Header

Every script should start with a clear header:

```bash
#!/usr/bin/env bash
# Brief description of what the script does
# Usage: ./script-name.sh [arguments]
```

Add `set -e` for scripts where any failure should stop execution:

```bash
set -e  # Exit immediately if a command exits with a non-zero status
```

## Shared Library Usage

**Always source `lib/utils.sh`** to access standardized colors, icons, and helper functions:

```bash
# Source the shared library (adjust path as needed)
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DOTFILES_DIR/lib/utils.sh"
```

This provides:

- **Colors**: `$GREEN`, `$YELLOW`, `$BLUE`, `$CYAN`, `$RED`, `$NC` (portable via tput)
- **Icons**: `$ROCKET`, `$WRENCH`, `$CHECK`, `$CROSS`, `$COMPUTER`, `$PARTY`, `$PACKAGE`
- **Helpers**: `log_section()`, `log_success()`, `log_error()`, `log_warning()`, `log_info()`, `log_substep()`

### When to Define Colors Manually

Only define colors inline for **standalone scripts** that must work outside the dotfiles repository. For all scripts within the dotfiles structure, use `lib/utils.sh`.

## Color Usage Guidelines (from lib/utils.sh)

- **GREEN** - Success confirmations, completion messages
- **YELLOW** - Warnings, prompts for user input, items requiring attention
- **BLUE** - Major section headers, high-level operations
- **CYAN** - Command output, sub-operations, detailed progress
- **RED** - Errors, failures, critical issues

## Using Helper Functions

Prefer helper functions from `lib/utils.sh` over manual printf/echo commands:

```bash
# Use helper functions for standard messages
log_section "Installing Dependencies"             # Section header with icon
log_substep "Downloading configuration file..."   # Indented sub-step
log_success "Installation complete"               # Success message
log_error "Configuration failed"                  # Error message
log_warning "Please review the settings"          # Warning message
log_info "Processing 3 files"                     # Info message

# For custom formatted output, icons are available:
printf "${CYAN}${ROCKET} Starting installation process...${NC}\n"
printf "${GREEN}${PARTY} Setup finished successfully!${NC}\n"
```

## Output Formatting Patterns

### Section Headers

Use the `log_section` helper function:

```bash
log_section "Section Name"          # Uses default rocket icon
log_section "Installing" "$WRENCH"  # Custom icon
```

### Sub-Operations

Use the `log_substep` helper function:

```bash
log_substep "Downloading configuration file..."
log_substep "Extracting archive..."
```

### Success Messages

Use the `log_success` helper function:

```bash
log_success "Operation completed successfully"
```

### Error Messages

Use the `log_error` helper function:

```bash
log_error "Specific description of what failed"
```

### Warning Messages

Use the `log_warning` helper function:

```bash
log_warning "Configuration needs review"
```

### Info Messages

Use the `log_info` helper function:

```bash
log_info "Processing batch 2 of 5"
```

### Progress Updates

```bash
echo "[1/4] First step description..."
echo "[2/4] Second step description..."
```

## Error Handling

### Basic Error Checking

```bash
if ! command -v required_tool &> /dev/null; then
    log_error "required_tool is not installed"
    exit 1
fi
```

### Command Success Verification

```bash
if ! sudo apt install package-name -y; then
    log_error "Package installation failed"
    exit 1
fi
log_success "Package installed successfully"
```

### Idempotent Checks

Scripts should be safely re-runnable:

```bash
if [ -f "$CONFIG_FILE" ]; then
    log_success "Configuration already exists. Skipping"
else
    log_substep "Creating configuration..."
    # Create config
fi
```

## Path Variables

Always use variables for paths, never hardcode:

```bash
# Get script's directory
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Use $HOME instead of hardcoded paths
CONFIG_FILE="$HOME/.zshrc"
TARGET_DIR="$HOME/.config/app"
```

## Setup Script Structure

For `setup/*.sh` scripts, follow this template:

```bash
#!/usr/bin/env bash
# Brief description of what this sets up
# Prerequisites: List any requirements

# Exit on error
set -e

# Source shared library
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$DOTFILES_DIR/lib/utils.sh"

# --- Main Script ---
printf "${CYAN}${ROCKET} Starting [Package Name] setup...${NC}\n\n"

# 1. Check if already installed
log_section "Checking Installation"
if command -v package_name &> /dev/null; then
    log_success "Already installed"
else
    log_warning "Not found. Installing..."
    log_substep "Downloading package..."
    # Installation steps
    log_success "Installation complete"
fi

# 2. Configuration
log_section "Configuring [Package Name]" "$WRENCH"
log_substep "Creating config directory..."
log_substep "Writing configuration file..."
# Configuration steps
log_success "Configuration complete"

# 3. Final verification
printf "\n${GREEN}${PARTY} Setup complete!${NC}\n"
```

## Configuration Management

When adding configuration blocks to files like `.zshrc`:

```bash
CONFIG_FILE="$HOME/.zshrc"
MARKER="# --- My Tool Configuration ---"

# Check for existing configuration
if grep -Fxq "$MARKER" "$CONFIG_FILE"; then
    log_success "Configuration already present"
else
    log_substep "Adding configuration block..."
    cat >> "$CONFIG_FILE" << 'EOL'
# --- My Tool Configuration ---
export TOOL_PATH="$HOME/.tool"
export PATH="$TOOL_PATH/bin:$PATH"
# --- End My Tool Configuration ---
EOL
    log_success "Configuration added"
fi
```

## Standalone Scripts (Outside Dotfiles)

If creating a script that must work independently of the dotfiles repository, define colors inline:

```bash
# Define colors using tput (portable across terminals)
if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    RED=$(tput setaf 1)
    NC=$(tput sgr0)
else
    # Fallback to ANSI escape codes
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    RED='\033[0;31m'
    NC='\033[0m'
fi

# Define icons
ROCKET="🚀"
CHECK="✅"
CROSS="❌"
WRENCH="🔧"
```

For all other scripts within the dotfiles repository, use `lib/utils.sh`.

## Testing & Validation

Before committing new scripts:

1. Test on a clean system if possible
2. Verify idempotency (safe to run multiple times)
3. Test with and without required tools installed
4. Ensure error messages are clear and actionable
5. Verify color output in different terminals
6. Confirm `lib/utils.sh` is sourced correctly (for dotfiles scripts)
