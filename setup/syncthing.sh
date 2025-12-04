#!/usr/bin/env bash
# Installs Syncthing on Debian/Ubuntu-based systems.
# This script is idempotent and safe to run multiple times.

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

# --- Define File Paths ---
KEY_FILE="/etc/apt/keyrings/syncthing-archive-keyring.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/syncthing.list"

# --- Main Script ---
log_section "Starting Syncthing Setup" "$ROCKET"

# 1. Add the release PGP keys
log_step "Configuring APT repository..." "$WRENCH"
echo "   ↳ Checking for Syncthing PGP key..."

# Create the keyrings directory (idempotent)
sudo mkdir -p /etc/apt/keyrings

# Check if the key file already exists
if [ ! -f "$KEY_FILE" ]; then
    log_substep "Key not found. Downloading..."
    if ! sudo curl -L -o "$KEY_FILE" https://syncthing.net/release-key.gpg; then
        log_error "Failed to download PGP key."
        exit 1
    fi
    log_success "PGP key downloaded."
else
    log_success "Keyring file already exists."
fi

# 2. Add the "stable-v2" channel to APT sources
echo "   ↳ Checking for Syncthing APT source..."

# Check if the source file already exists
if [ ! -f "$SOURCE_FILE" ]; then
    log_substep "APT source file not found. Adding..."
    echo "deb [signed-by=$KEY_FILE] https://apt.syncthing.net/ syncthing stable-v2" | sudo tee "$SOURCE_FILE" > /dev/null
    log_success "APT source added."
else
    log_success "APT source file already exists."
fi

# 3. Update and install syncthing
printf "\n${BLUE}${COMPUTER} Installing Syncthing...${NC}\n"
echo "   ↳ Updating package lists..."
sudo apt update

echo "   ↳ Installing Syncthing package..."
if ! sudo apt install syncthing -y; then
    log_error "Syncthing installation failed."
    exit 1
fi

log_complete "Syncthing installation complete!"
