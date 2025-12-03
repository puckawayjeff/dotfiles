#!/usr/bin/env bash
# Installs NVM (Node Version Manager) and Node.js LTS on Debian-based systems.
# This script is idempotent and safe to run multiple times.
# Automatically configures shell integration for bash.

# Exit immediately if a command exits with a non-zero status
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

# --- Configuration ---
NVM_VERSION="v0.40.1"  # Update this to latest stable version as needed
NVM_DIR="${HOME}/.nvm"
PROFILE_FILE="${HOME}/.bashrc"

# --- Main Script ---
printf "${CYAN}${ROCKET} Starting NVM Setup...${NC}\n\n"

# 1. Clean up any system-installed Node.js (optional but recommended)
printf "${BLUE}${WRENCH} Checking for system Node.js installations...${NC}\n"
if command -v node &> /dev/null && [[ "$(which node)" != *".nvm"* ]]; then
    printf "${YELLOW}System Node.js detected. Removing to avoid conflicts...${NC}\n"
    echo "   ↳ This requires sudo and will keep your system clean."
    if sudo apt remove -y nodejs npm 2>/dev/null; then
        sudo apt autoremove -y
        printf "${GREEN}${CHECK} System Node.js removed.${NC}\n"
    else
        printf "${YELLOW}Could not remove system Node.js (may not be installed via apt).${NC}\n"
    fi
else
    printf "${GREEN}${CHECK} No conflicting system Node.js found.${NC}\n"
fi

# 2. Check if NVM is already installed
printf "\n${BLUE}Checking for existing NVM installation...${NC}\n"
if [ -d "$NVM_DIR" ]; then
    printf "${GREEN}${CHECK} NVM directory already exists at $NVM_DIR.${NC}\n"
    # Load NVM to check version
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command -v nvm &> /dev/null; then
        CURRENT_VERSION=$(nvm --version)
        printf "${CYAN}Current NVM version: ${CURRENT_VERSION}${NC}\n"
    fi
else
    # 3. Install NVM
    printf "${YELLOW}${WRENCH} NVM not found. Installing...${NC}\n\n"
    printf "${BLUE}${COMPUTER} Downloading NVM ${NVM_VERSION}...${NC}\n"
    
    if curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash; then
        printf "${GREEN}${CHECK} NVM installed successfully.${NC}\n"
    else
        printf "${RED}${CROSS} Error: NVM installation failed.${NC}\n"
        exit 1
    fi
fi

# 4. Load NVM into current session
printf "\n${BLUE}📦 Loading NVM into current session...${NC}\n"
export NVM_DIR="$NVM_DIR"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

if ! command -v nvm &> /dev/null; then
    printf "${RED}${CROSS} Error: NVM failed to load.${NC}\n"
    exit 1
fi
printf "${GREEN}${CHECK} NVM loaded.${NC}\n"

# 5. Verify shell configuration is present
printf "\n${BLUE}Checking shell configuration...${NC}\n"
NVM_CONFIG_MARKER='# --- NVM Configuration ---'

if grep -Fxq "$NVM_CONFIG_MARKER" "$PROFILE_FILE"; then
    printf "${GREEN}${CHECK} NVM configuration already present in $PROFILE_FILE.${NC}\n"
else
    printf "${YELLOW}${WRENCH} Adding NVM configuration to $PROFILE_FILE...${NC}\n"
    
    # Add NVM configuration block
    cat >> "$PROFILE_FILE" << 'EOL'

# --- NVM Configuration ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# --- End NVM Configuration ---
EOL
    printf "${GREEN}${CHECK} Configuration added to $PROFILE_FILE.${NC}\n"
fi

# 6. Install Node.js LTS if not already installed
printf "\n${BLUE}${COMPUTER} Checking for Node.js installation...${NC}\n"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    printf "${GREEN}${CHECK} Node.js ${NODE_VERSION} is already installed.${NC}\n"
    echo "   ↳ Location: $(which node)"
else
    printf "${YELLOW}${WRENCH} Installing Node.js LTS version...${NC}\n"
    echo "   ↳ This may take a few minutes..."
    
    if nvm install --lts; then
        printf "${GREEN}${CHECK} Node.js LTS installed successfully.${NC}\n"
        
        # Set LTS as default
        echo "   ↳ Setting LTS as default version..."
        nvm alias default 'lts/*'
        printf "${GREEN}${CHECK} Default version set to LTS.${NC}\n"
    else
        printf "${RED}${CROSS} Error: Node.js installation failed.${NC}\n"
        exit 1
    fi
fi

# 7. Verify installation
printf "\n${BLUE}Verifying installation...${NC}\n"
NODE_PATH=$(which node)
NPM_PATH=$(which npm)

if [[ "$NODE_PATH" == *".nvm"* ]]; then
    printf "${GREEN}${CHECK} Node.js location: ${NODE_PATH}${NC}\n"
    printf "${GREEN}${CHECK} Node.js version: $(node --version)${NC}\n"
    printf "${GREEN}${CHECK} NPM location: ${NPM_PATH}${NC}\n"
    printf "${GREEN}${CHECK} NPM version: $(npm --version)${NC}\n"
else
    printf "${YELLOW}Warning: Node.js not running from NVM directory.${NC}\n"
    printf "Expected path to contain '.nvm', got: ${NODE_PATH}\n"
fi

# 8. Display helpful information
printf "\n${GREEN}${PARTY} NVM setup complete!${NC}\n\n"
printf "${CYAN}Quick Start Commands:${NC}\n"
printf "  ${YELLOW}nvm ls${NC}              - List installed Node versions\n"
printf "  ${YELLOW}nvm ls-remote${NC}       - List available versions online\n"
printf "  ${YELLOW}nvm install node${NC}    - Install latest Node.js\n"
printf "  ${YELLOW}nvm install 18${NC}      - Install specific version (e.g., 18)\n"
printf "  ${YELLOW}nvm use 18${NC}          - Switch to version 18\n"
printf "  ${YELLOW}nvm alias default 18${NC} - Set version 18 as default\n"
printf "\n${CYAN}Current session is ready. New terminals will load NVM automatically.${NC}\n"
