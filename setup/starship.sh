#!/bin/bash

# Starship Prompt Setup Script
# Installs Starship cross-shell prompt with Nerd Font support
# Idempotent - safe to run multiple times

# --- Define Colors and Emojis ---
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

ROCKET="🚀"
WRENCH="🔧"
CHECK="✅"
CROSS="❌"
STAR="⭐"
COMPUTER="💻"

# --- Start Installation ---
printf "${CYAN}${ROCKET} Starting Starship installation...${NC}\n\n"

# --- 1. Check if Starship is already installed ---
printf "${BLUE}${COMPUTER} Checking for existing installation...${NC}\n"
if command -v starship &> /dev/null; then
    CURRENT_VERSION=$(starship --version | head -n1)
    printf "${GREEN}${CHECK} Starship already installed: ${CURRENT_VERSION}${NC}\n"
    printf "${YELLOW}   Checking for updates...${NC}\n"
else
    printf "${YELLOW}${WRENCH} Starship not found. Installing...${NC}\n"
fi

# --- 2. Download and install Starship ---
printf "\n${BLUE}📦 Installing Starship via official installer...${NC}\n"
if curl -sS https://starship.rs/install.sh | sh -s -- --yes; then
    printf "${GREEN}${CHECK} Starship installed successfully.${NC}\n"
else
    printf "${RED}${CROSS} Error: Starship installation failed.${NC}\n"
    exit 1
fi

# --- 3. Verify installation ---
printf "\n${BLUE}${COMPUTER} Verifying installation...${NC}\n"
if command -v starship &> /dev/null; then
    INSTALLED_VERSION=$(starship --version | head -n1)
    printf "${GREEN}${CHECK} Verified: ${INSTALLED_VERSION}${NC}\n"
else
    printf "${RED}${CROSS} Error: Starship command not found after installation.${NC}\n"
    exit 1
fi

# --- 4. Check for starship.toml in dotfiles ---
DOTFILES_TOML="$HOME/dotfiles/starship.toml"
printf "\n${BLUE}📝 Checking for configuration file...${NC}\n"
if [ -f "$DOTFILES_TOML" ]; then
    printf "${GREEN}${CHECK} Found configuration: $DOTFILES_TOML${NC}\n"
    printf "   ↳ Configuration will be symlinked by install.sh\n"
else
    printf "${YELLOW}⚠️  Warning: starship.toml not found in dotfiles.${NC}\n"
    printf "   ↳ Starship will use default configuration\n"
fi

# --- 5. Check .bashrc configuration ---
BASHRC="$HOME/.bashrc"
MARKER_START="# Only sets up starship if it's installed."
printf "\n${BLUE}🔧 Checking .bashrc integration...${NC}\n"

if [ -f "$BASHRC" ] && grep -Fxq "$MARKER_START" "$BASHRC"; then
    printf "${GREEN}${CHECK} Starship already configured in .bashrc${NC}\n"
else
    printf "${YELLOW}${WRENCH} Adding Starship initialization to .bashrc...${NC}\n"
    cat >> "$BASHRC" << 'EOL'

# Only sets up starship if it's installed.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
EOL
    printf "${GREEN}${CHECK} Starship initialization added to .bashrc${NC}\n"
fi

# --- 6. Install FiraCode Nerd Font ---
SETUP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
printf "\n"
if bash "$SETUP_DIR/_firacodenerdfont.sh"; then
    : # Success - helper script provides its own output
else
    printf "${YELLOW}   ↳ Font installation failed but continuing anyway.${NC}\n"
fi

# Install emoji support
printf "\n${BLUE}📦 Installing emoji font support...${NC}\n"
if dpkg -l | grep -q fonts-noto-color-emoji; then
    printf "${GREEN}${CHECK} Emoji fonts already installed.${NC}\n"
else
    printf "   ↳ Installing fonts-noto-color-emoji...\n"
    if sudo apt install -y fonts-noto-color-emoji > /dev/null 2>&1; then
        printf "${GREEN}${CHECK} Emoji fonts installed.${NC}\n"
        fc-cache -fv > /dev/null 2>&1
    else
        printf "${YELLOW}   ↳ Could not install emoji fonts (may require manual installation).${NC}\n"
    fi
fi

# --- 7. Completion ---
printf "\n${CYAN}═══════════════════════════════════════${NC}\n"
printf "${GREEN}${CHECK} Starship setup complete!${NC}\n"
printf "${CYAN}═══════════════════════════════════════${NC}\n\n"

printf "${YELLOW}Next steps:${NC}\n"
printf "   1. Reload your shell: ${CYAN}source ~/.bashrc${NC}\n"
printf "   2. Ensure starship.toml is symlinked: ${CYAN}./install.sh${NC}\n"
printf "   3. Configure your terminal to use 'FiraCode Nerd Font'\n"
printf "      See: ${CYAN}docs/Terminal Font Setup.md${NC} for instructions\n\n"

exit 0
