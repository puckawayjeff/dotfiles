#!/usr/bin/env bash
# Installs Syncthing on Debian/Ubuntu-based systems.
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
KEY_FILE="/etc/apt/keyrings/syncthing-archive-keyring.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/syncthing.list"

# --- Main Script ---
printf "${CYAN}${ROCKET} Starting Syncthing Setup...${NC}\n\n"

# 1. Add the release PGP keys
printf "${BLUE}${WRENCH} Configuring APT repository...${NC}\n"
echo "   ↳ Checking for Syncthing PGP key..."

# Create the keyrings directory (idempotent)
sudo mkdir -p /etc/apt/keyrings

# Check if the key file already exists
if [ ! -f "$KEY_FILE" ]; then
    echo "   ↳ Key not found. Downloading..."
    if ! sudo curl -L -o "$KEY_FILE" https://syncthing.net/release-key.gpg; then
        printf "${RED}${CROSS} Error: Failed to download PGP key.${NC}\n"
        exit 1
    fi
    printf "${GREEN}${CHECK} PGP key downloaded.${NC}\n"
else
    printf "${GREEN}${CHECK} Keyring file already exists.${NC}\n"
fi

# 2. Add the "stable-v2" channel to APT sources
echo "   ↳ Checking for Syncthing APT source..."

# Check if the source file already exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "   ↳ APT source file not found. Adding..."
    echo "deb [signed-by=$KEY_FILE] https://apt.syncthing.net/ syncthing stable-v2" | sudo tee "$SOURCE_FILE" > /dev/null
    printf "${GREEN}${CHECK} APT source added.${NC}\n"
else
    printf "${GREEN}${CHECK} APT source file already exists.${NC}\n"
fi

# 3. Update and install syncthing
printf "\n${BLUE}${COMPUTER} Installing Syncthing...${NC}\n"
echo "   ↳ Updating package lists..."
sudo apt update

echo "   ↳ Installing Syncthing package..."
if ! sudo apt install syncthing -y; then
    printf "${RED}${CROSS} Error: Syncthing installation failed.${NC}\n"
    exit 1
fi

printf "\n${GREEN}${PARTY} Syncthing installation complete!${NC}\n"
