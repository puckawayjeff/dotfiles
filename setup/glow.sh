#!/usr/bin/env bash
# Installs Glow (terminal markdown renderer) on Debian/Ubuntu-based systems.
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
KEY_FILE="/etc/apt/keyrings/charm.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/charm.list"

# --- Main Script ---
log_section "Starting Glow Setup" "$ROCKET"

# 1. Check if glow is already installed
log_info "Checking for existing installation..."
if command -v glow &> /dev/null; then
    log_success "Glow is already installed."
    log_info "${CYAN}   ↳ Version: $(glow --version | head -n1)${NC}"
else
    printf "${YELLOW}${WRENCH} Glow not found. Installing...${NC}\n\n"
    
    # 2. Add the Charm repository GPG key
    log_step "Configuring APT repository..." "$WRENCH"
    log_substep "Checking for Charm GPG key..."
    
    # Create the keyrings directory (idempotent)
    sudo mkdir -p /etc/apt/keyrings
    
    # Check if the key file already exists
    if [ ! -f "$KEY_FILE" ]; then
        echo "   ↳ Key not found. Downloading..."
        if ! curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o "$KEY_FILE"; then
            log_error "Failed to download GPG key."
            exit 1
        fi
        log_success "GPG key downloaded."
    else
        log_success "Keyring file already exists."
    fi
    
    # 3. Add the Charm APT source
    log_substep "Checking for Charm APT source..."
    
    # Check if the source file already exists
    if [ ! -f "$SOURCE_FILE" ]; then
        echo "   ↳ APT source file not found. Adding..."
        echo "deb [signed-by=$KEY_FILE] https://repo.charm.sh/apt/ * *" | sudo tee "$SOURCE_FILE" > /dev/null
        log_success "APT source added."
    else
        log_success "APT source file already exists."
    fi
    
    # 4. Update and install glow
    printf "\n${BLUE}${COMPUTER} Installing Glow...${NC}\n"
    log_substep "Updating package lists..."
    if ! sudo apt update; then
        log_error "Failed to update package lists."
        exit 1
    fi
    
    log_substep "Installing Glow package..."
    if ! sudo apt install -y glow; then
        log_error "Glow installation failed."
        exit 1
    fi
    
    log_success "Glow installed successfully."
fi

# 5. Display completion and usage information
log_complete "Glow setup complete!"
log_plain ""
log_info "${CYAN}Quick Start:${NC}"
log_plain "  ${YELLOW}glow README.md${NC}        - Render a markdown file"
log_plain "  ${YELLOW}glow -p${NC}               - Render with pager enabled"
log_plain "  ${YELLOW}glow -s dark${NC}          - Use dark style"
log_plain "  ${YELLOW}glow -s light${NC}         - Use light style"
log_plain "  ${YELLOW}glow${NC}                  - Browse markdown files in current directory"
