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

## Color Definitions

Use `tput` for maximum compatibility. Define colors at the top of scripts that need them:

```bash
# Define colors using tput (portable across terminals)
if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)   # Success messages
    YELLOW=$(tput setaf 3)  # Warnings, prompts, user attention
    BLUE=$(tput setaf 4)    # Section headers, informational
    CYAN=$(tput setaf 6)    # Command output, sub-steps
    RED=$(tput setaf 1)     # Errors, failures
    NC=$(tput sgr0)         # Reset/No Color
else
    # Fallback to ANSI escape codes if tput unavailable
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    RED='\033[0;31m'
    NC='\033[0m'
fi
```

### Color Usage Guidelines

- **GREEN** - Success confirmations, completion messages
- **YELLOW** - Warnings, prompts for user input, items requiring attention
- **BLUE** - Major section headers, high-level operations
- **CYAN** - Command output, sub-operations, detailed progress
- **RED** - Errors, failures, critical issues

## Emoji Standards

Use emojis consistently to provide visual cues:

```bash
# Define emoji constants for consistency
ROCKET="🚀"      # Starting a new process or major operation
WRENCH="🔧"      # Installation, configuration, setup tasks
CHECK="✅"       # Success, completion, verification passed
CROSS="❌"       # Error, failure, verification failed
COMPUTER="💻"    # System-level operations
PARTY="🎉"       # Final completion, celebration
```

### Emoji Usage Examples

```bash
printf "${CYAN}${ROCKET} Starting installation process...${NC}\n"
printf "${YELLOW}${WRENCH} Configuring system settings...${NC}\n"
printf "${GREEN}${CHECK} Installation complete.${NC}\n"
printf "${RED}${CROSS} Error: Configuration failed.${NC}\n"
printf "${BLUE}${COMPUTER} Updating system packages...${NC}\n"
printf "${GREEN}${PARTY} Setup finished successfully!${NC}\n"
```

## Output Formatting Patterns

### Section Headers
Major sections should be visually distinct:
```bash
printf "\n${BLUE}📦 Section Name${NC}\n\n"
```

### Sub-Operations
Indent sub-tasks with 3 spaces and use an arrow:
```bash
echo "   ↳ Downloading configuration file..."
```

### Success Messages
```bash
printf "${GREEN}✅ Operation completed successfully.${NC}\n"
```

### Error Messages
```bash
printf "${RED}❌ Error: Specific description of what failed.${NC}\n"
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
    printf "${RED}${CROSS} Error: required_tool is not installed.${NC}\n"
    exit 1
fi
```

### Command Success Verification
```bash
if ! sudo apt install package-name -y; then
    printf "${RED}${CROSS} Error: Package installation failed.${NC}\n"
    exit 1
fi
printf "${GREEN}${CHECK} Package installed successfully.${NC}\n"
```

### Idempotent Checks
Scripts should be safely re-runnable:
```bash
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ Configuration already exists. Skipping."
else
    echo "⏳ Creating configuration..."
    # Create config
fi
```

## Helper Functions

### Print Functions
Standardize common output patterns:
```bash
# Print a formatted section header
print_header() {
    printf "\n${BLUE}📦 $1${NC}\n\n"
}

# Print a success message
print_success() {
    printf "${GREEN}✅ $1${NC}\n"
}

# Print an error message
print_error() {
    printf "${RED}❌ Error: $1${NC}\n" >&2
}

# Download with status feedback
download_file() {
    local url=$1
    local dest=$2
    local filename=$(basename "$dest")
    
    echo -n "   ↳ Downloading $filename..."
    if wget -q "$url" -O "$dest"; then
        echo -e " ${GREEN}✔${NC}"
    else
        echo -e " ${RED}✖ FAILED${NC}"
        exit 1
    fi
}
```

### Usage Example
```bash
print_header "Installing Dependencies"
echo "   ↳ Updating package lists..."
if sudo apt update; then
    print_success "Package lists updated"
else
    print_error "Failed to update package lists"
    exit 1
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

# --- Color Definitions ---
if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    RED=$(tput setaf 1)
    NC=$(tput sgr0)
else
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    RED='\033[0;31m'
    NC='\033[0m'
fi

# --- Emoji Constants ---
ROCKET="🚀"
WRENCH="🔧"
CHECK="✅"
CROSS="❌"
COMPUTER="💻"
PARTY="🎉"

# --- Main Script ---
printf "${CYAN}${ROCKET} Starting [Package Name] setup...${NC}\n\n"

# 1. Check if already installed
printf "${BLUE}Checking for existing installation...${NC}\n"
if command -v package_name &> /dev/null; then
    printf "${GREEN}${CHECK} Already installed.${NC}\n"
else
    printf "${YELLOW}${WRENCH} Not found. Installing...${NC}\n"
    # Installation steps
fi

# 2. Configuration
printf "\n${BLUE}📦 Configuring [Package Name]...${NC}\n"
# Configuration steps

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
    echo "✅ Configuration already present."
else
    echo "⏳ Adding configuration block..."
    cat >> "$CONFIG_FILE" << 'EOL'
# --- My Tool Configuration ---
export TOOL_PATH="$HOME/.tool"
export PATH="$TOOL_PATH/bin:$PATH"
# --- End My Tool Configuration ---
EOL
    echo "✅ Configuration added."
fi
```

## Testing & Validation

Before committing new scripts:
1. Test on a clean system if possible
2. Verify idempotency (safe to run multiple times)
3. Test with and without required tools installed
4. Ensure error messages are clear and actionable
5. Verify color output in different terminals