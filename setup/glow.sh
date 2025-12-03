#!/usr/bin/env bash
# Installs Glow (terminal markdown renderer) on Debian/Ubuntu-based systems.
# This script is idempotent and safe to run multiple times.

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

# --- Define File Paths ---
KEY_FILE="/etc/apt/keyrings/charm.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/charm.list"

# --- Main Script ---
printf "${CYAN}${ROCKET} Starting Glow Setup...${NC}\n\n"

# 1. Check if glow is already installed
printf "${BLUE}Checking for existing installation...${NC}\n"
if command -v glow &> /dev/null; then
    printf "${GREEN}${CHECK} Glow is already installed.${NC}\n"
    printf "${CYAN}   ↳ Version: $(glow --version | head -n1)${NC}\n"
else
    printf "${YELLOW}${WRENCH} Glow not found. Installing...${NC}\n\n"
    
    # 2. Add the Charm repository GPG key
    printf "${BLUE}${WRENCH} Configuring APT repository...${NC}\n"
    echo "   ↳ Checking for Charm GPG key..."
    
    # Create the keyrings directory (idempotent)
    sudo mkdir -p /etc/apt/keyrings
    
    # Check if the key file already exists
    if [ ! -f "$KEY_FILE" ]; then
        echo "   ↳ Key not found. Downloading..."
        if ! curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o "$KEY_FILE"; then
            printf "${RED}${CROSS} Error: Failed to download GPG key.${NC}\n"
            exit 1
        fi
        printf "${GREEN}${CHECK} GPG key downloaded.${NC}\n"
    else
        printf "${GREEN}${CHECK} Keyring file already exists.${NC}\n"
    fi
    
    # 3. Add the Charm APT source
    echo "   ↳ Checking for Charm APT source..."
    
    # Check if the source file already exists
    if [ ! -f "$SOURCE_FILE" ]; then
        echo "   ↳ APT source file not found. Adding..."
        echo "deb [signed-by=$KEY_FILE] https://repo.charm.sh/apt/ * *" | sudo tee "$SOURCE_FILE" > /dev/null
        printf "${GREEN}${CHECK} APT source added.${NC}\n"
    else
        printf "${GREEN}${CHECK} APT source file already exists.${NC}\n"
    fi
    
    # 4. Update and install glow
    printf "\n${BLUE}${COMPUTER} Installing Glow...${NC}\n"
    echo "   ↳ Updating package lists..."
    if ! sudo apt update; then
        printf "${RED}${CROSS} Error: Failed to update package lists.${NC}\n"
        exit 1
    fi
    
    echo "   ↳ Installing Glow package..."
    if ! sudo apt install -y glow; then
        printf "${RED}${CROSS} Error: Glow installation failed.${NC}\n"
        exit 1
    fi
    
    printf "${GREEN}${CHECK} Glow installed successfully.${NC}\n"
fi

# 5. Display completion and usage information
printf "\n${GREEN}${PARTY} Glow setup complete!${NC}\n\n"
printf "${CYAN}Quick Start:${NC}\n"
printf "  ${YELLOW}glow README.md${NC}        - Render a markdown file\n"
printf "  ${YELLOW}glow -p${NC}               - Render with pager enabled\n"
printf "  ${YELLOW}glow -s dark${NC}          - Use dark style\n"
printf "  ${YELLOW}glow -s light${NC}         - Use light style\n"
printf "  ${YELLOW}glow${NC}                  - Browse markdown files in current directory\n"
