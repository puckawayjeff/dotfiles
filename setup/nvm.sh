#!/usr/bin/env bash
# Installs NVM (Node Version Manager) and Node.js LTS on Debian-based systems.
# This script is idempotent and safe to run multiple times.
# Automatically configures shell integration for bash.

# Exit immediately if a command exits with a non-zero status
set -e

# Load shared utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found"
    exit 1
fi

# --- Configuration ---
NVM_VERSION="v0.40.1"  # Update this to latest stable version as needed
NVM_DIR="${HOME}/.nvm"
PROFILE_FILE="${HOME}/.zshrc"

# --- Main Script ---
log_section "Starting NVM Setup" "$ROCKET"

# 1. Clean up any system-installed Node.js (optional but recommended)
log_step "Checking for system Node.js installations..." "$WRENCH"
if command -v node &> /dev/null && [[ "$(which node)" != *".nvm"* ]]; then
    log_warning "System Node.js detected. Removing to avoid conflicts..."
    log_substep "This requires sudo and will keep your system clean."
    if sudo apt remove -y nodejs npm 2>/dev/null; then
        sudo apt autoremove -y
        log_success "System Node.js removed."
    else
        log_warning "Could not remove system Node.js (may not be installed via apt)."
    fi
else
    log_success "No conflicting system Node.js found."
fi

# 2. Check if NVM is already installed
printf "\n${BLUE}Checking for existing NVM installation...${NC}\n"
if [ -d "$NVM_DIR" ]; then
    log_success "NVM directory already exists at $NVM_DIR."
    # Load NVM to check version
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command -v nvm &> /dev/null; then
        CURRENT_VERSION=$(nvm --version)
        log_info "${CYAN}Current NVM version: ${CURRENT_VERSION}${NC}"
    fi
else
    # 3. Install NVM
    printf "${YELLOW}${WRENCH} NVM not found. Installing...${NC}\n\n"
    log_action "Downloading NVM ${NVM_VERSION}..."
    
    if curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash; then
        log_success "NVM installed successfully."
    else
        log_error "NVM installation failed."
        exit 1
    fi
fi

# 4. Load NVM into current session
printf "\n${BLUE}📦 Loading NVM into current session...${NC}\n"
export NVM_DIR="$NVM_DIR"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

if ! command -v nvm &> /dev/null; then
    log_error "NVM failed to load."
    exit 1
fi
log_success "NVM loaded."

# 5. Verify shell configuration is present
printf "\n${BLUE}Checking shell configuration...${NC}\n"
NVM_CONFIG_MARKER='# --- NVM Configuration ---'

if grep -Fxq "$NVM_CONFIG_MARKER" "$PROFILE_FILE"; then
    log_success "NVM configuration already present in $PROFILE_FILE."
else
    log_warning "Adding NVM configuration to $PROFILE_FILE..."
    
    # Add NVM configuration block
    cat >> "$PROFILE_FILE" << 'EOL'

# --- NVM Configuration ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# --- End NVM Configuration ---
EOL
    log_success "Configuration added to $PROFILE_FILE."
fi

# 6. Install Node.js LTS if not already installed
printf "\n${BLUE}${COMPUTER} Checking for Node.js installation...${NC}\n"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    log_success "Node.js ${NODE_VERSION} is already installed."
    log_substep "Location: $(which node)"
else
    log_warning "Installing Node.js LTS version..."
    log_substep "This may take a few minutes..."
    
    if nvm install --lts; then
        log_success "Node.js LTS installed successfully."
        
        # Set LTS as default
        echo "   ↳ Setting LTS as default version..."
        nvm alias default 'lts/*'
        log_success "Default version set to LTS."
    else
        log_error "Node.js installation failed."
        exit 1
    fi
fi

# 7. Verify installation
printf "\n${BLUE}Verifying installation...${NC}\n"
NODE_PATH=$(which node)
NPM_PATH=$(which npm)

if [[ "$NODE_PATH" == *".nvm"* ]]; then
    log_success "Node.js location: ${NODE_PATH}"
    log_success "Node.js version: $(node --version)"
    log_success "NPM location: ${NPM_PATH}"
    log_success "NPM version: $(npm --version)"
else
    log_warning "Warning: Node.js not running from NVM directory."
    printf "Expected path to contain '.nvm', got: ${NODE_PATH}\n"
fi

# 8. Display helpful information
log_complete "NVM setup complete!"
log_plain ""
log_info "${CYAN}Quick Start Commands:${NC}"
log_plain "  ${YELLOW}nvm ls${NC}"              - List installed Node versions\n"
log_plain "  ${YELLOW}nvm ls-remote${NC}"       - List available versions online\n"
log_plain "  ${YELLOW}nvm install node${NC}"    - Install latest Node.js\n"
log_plain "  ${YELLOW}nvm install 18${NC}"      - Install specific version (e.g., 18)\n"
log_plain "  ${YELLOW}nvm use 18${NC}"          - Switch to version 18\n"
log_plain "  ${YELLOW}nvm alias default 18${NC}" - Set version 18 as default\n"
printf "\n${CYAN}Current session is ready. New terminals will load NVM automatically.${NC}\n"
