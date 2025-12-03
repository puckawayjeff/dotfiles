#!/usr/bin/env bash
# setup/eza.sh
# Install and configure eza (modern ls replacement)

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
COMPUTER="💻"
PARTY="🎉"

# --- Start Process ---
printf "${CYAN}${ROCKET} Starting eza installation...${NC}\n"

# --- Check if already installed from official repository ---
if command -v eza &> /dev/null && [ -f /etc/apt/sources.list.d/gierens.list ]; then
    CURRENT_VERSION=$(eza --version | head -n1)
    printf "${GREEN}${CHECK} eza is already installed from official repository: $CURRENT_VERSION${NC}\n"
    printf "${YELLOW}To upgrade, run: sudo apt update && sudo apt install eza -y${NC}\n"
    exit 0
fi

# --- Remove distro eza if present ---
if dpkg -l | grep -q "^ii.*eza"; then
    printf "${YELLOW}${WRENCH} Removing distro-installed eza...${NC}\n"
    echo "   ↳ Uninstalling old version from default repositories..."
    if sudo apt remove -y eza; then
        printf "${GREEN}${CHECK} Old eza version removed.${NC}\n"
    else
        printf "${RED}${CROSS} Warning: Failed to remove old eza version.${NC}\n"
    fi
fi

# --- Update package list ---
printf "${BLUE}${COMPUTER} Updating package list...${NC}\n"
if ! sudo apt update; then
    printf "${RED}${CROSS} Error: Failed to update package list.${NC}\n"
    exit 1
fi

# --- Install gpg if needed ---
if ! command -v gpg &> /dev/null; then
    printf "${BLUE}${WRENCH} Installing gpg...${NC}\n"
    echo "   ↳ Required for repository key verification..."
    if ! sudo apt install -y gpg; then
        printf "${RED}${CROSS} Error: Failed to install gpg.${NC}\n"
        exit 1
    fi
    printf "${GREEN}${CHECK} gpg installed.${NC}\n"
fi

# --- Add official eza repository ---
printf "${BLUE}${WRENCH} Setting up official eza repository...${NC}\n"

# Create keyrings directory
if [ ! -d /etc/apt/keyrings ]; then
    echo "   ↳ Creating keyrings directory..."
    sudo mkdir -p /etc/apt/keyrings
fi

# Add GPG key
if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
    echo "   ↳ Adding repository GPG key..."
    if ! wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg; then
        printf "${RED}${CROSS} Error: Failed to download repository key.${NC}\n"
        exit 1
    fi
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    printf "${GREEN}${CHECK} Repository key added.${NC}\n"
else
    printf "${GREEN}${CHECK} Repository key already exists.${NC}\n"
fi

# Add repository source
if [ ! -f /etc/apt/sources.list.d/gierens.list ]; then
    echo "   ↳ Adding repository source..."
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
    sudo chmod 644 /etc/apt/sources.list.d/gierens.list
    printf "${GREEN}${CHECK} Repository source added.${NC}\n"
else
    printf "${GREEN}${CHECK} Repository source already exists.${NC}\n"
fi

# Update package list with new repository
printf "${BLUE}${COMPUTER} Updating package list with new repository...${NC}\n"
if ! sudo apt update; then
    printf "${RED}${CROSS} Error: Failed to update package list.${NC}\n"
    exit 1
fi

# --- Install eza ---
printf "${BLUE}${WRENCH} Installing eza from official repository...${NC}\n"
echo "   ↳ Installing from deb.gierens.de..."

if sudo apt install -y eza; then
    printf "${GREEN}${CHECK} eza installed successfully.${NC}\n"
else
    printf "${RED}${CROSS} Error: Failed to install eza.${NC}\n"
    exit 1
fi

# --- Verify installation ---
if command -v eza &> /dev/null; then
    VERSION=$(eza --version | head -n1)
    printf "${GREEN}${CHECK} Verified installation: $VERSION${NC}\n"
else
    printf "${RED}${CROSS} Error: eza was installed but is not in PATH.${NC}\n"
    exit 1
fi

# --- Completion ---
printf "${GREEN}${PARTY} eza setup complete!${NC}\n"
printf "\n${CYAN}💡 Usage Tips:${NC}\n"
printf "   ↳ Basic list: ${YELLOW}eza${NC}\n"
printf "   ↳ Long format: ${YELLOW}eza -l${NC}\n"
printf "   ↳ With icons: ${YELLOW}eza --icons${NC}\n"
printf "   ↳ Tree view: ${YELLOW}eza --tree${NC}\n"
printf "   ↳ Git status: ${YELLOW}eza -l --git${NC}\n"
printf "\n${CYAN}Your ls aliases will automatically use eza when available.${NC}\n"
printf "${CYAN}Reload your shell with: ${YELLOW}source ~/.bashrc${NC}\n"
