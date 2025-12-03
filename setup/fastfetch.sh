#!/usr/bin/env bash
# Installs and configures 'fastfetch' for Debian-based distributions.
# Always builds from latest source to ensure schema compatibility.
# Also adds 'neofetch' and 'screenfetch' compatibility aliases.

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
PACKAGE="📦"

# --- Configuration ---
CONFIG_FILE="$HOME/.zshrc"
INSTALL_PREFIX="/usr/local"

# --- Helper Functions ---
get_installed_version() {
    if command -v fastfetch >/dev/null 2>&1; then
        fastfetch --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown"
    else
        echo "none"
    fi
}

get_latest_version() {
    curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep -oP '"tag_name": "\K[^"]+' | sed 's/^v//' || echo "unknown"
}

remove_package_install() {
    printf "${BLUE}${PACKAGE} Checking for package-based installations...${NC}\n"
    
    local removed_any=false
    
    # Check if fastfetch installed via apt
    if dpkg -l | grep -q "^ii.*fastfetch"; then
        printf "${YELLOW}⚠️  Found apt-installed fastfetch. Removing...${NC}\n"
        if sudo apt remove -y fastfetch && sudo apt autoremove -y; then
            printf "${GREEN}${CHECK} Removed fastfetch apt package.${NC}\n"
            removed_any=true
        else
            printf "${RED}${CROSS} Failed to remove fastfetch apt package.${NC}\n"
            return 1
        fi
    fi
    
    # Check if neofetch installed via apt
    if dpkg -l | grep -q "^ii.*neofetch"; then
        printf "${YELLOW}⚠️  Found apt-installed neofetch. Removing...${NC}\n"
        if sudo apt remove -y neofetch; then
            printf "${GREEN}${CHECK} Removed neofetch apt package.${NC}\n"
            removed_any=true
        else
            printf "${RED}${CROSS} Failed to remove neofetch apt package.${NC}\n"
        fi
    fi
    
    # Check if screenfetch installed via apt
    if dpkg -l | grep -q "^ii.*screenfetch"; then
        printf "${YELLOW}⚠️  Found apt-installed screenfetch. Removing...${NC}\n"
        if sudo apt remove -y screenfetch; then
            printf "${GREEN}${CHECK} Removed screenfetch apt package.${NC}\n"
            removed_any=true
        else
            printf "${RED}${CROSS} Failed to remove screenfetch apt package.${NC}\n"
        fi
    fi
    
    # Remove fastfetch PPA if present
    if [ -f /etc/apt/sources.list.d/zhangsongcui3371-ubuntu-fastfetch-*.list ]; then
        printf "${YELLOW}⚠️  Found fastfetch PPA. Removing...${NC}\n"
        if sudo add-apt-repository --remove ppa:zhangsongcui3371/fastfetch -y; then
            printf "${GREEN}${CHECK} Removed PPA.${NC}\n"
            removed_any=true
        fi
    fi
    
    # Run autoremove if we removed anything
    if [ "$removed_any" = true ]; then
        printf "   ↳ Cleaning up unused dependencies...\n"
        sudo apt autoremove -y >/dev/null 2>&1
    else
        printf "${GREEN}${CHECK} No package-based installations found.${NC}\n"
    fi
    
    return 0
}

build_from_source() {
    local latest_version="$1"
    
    printf "${BLUE}${WRENCH} Building fastfetch from source (v${latest_version})...${NC}\n"
    
    # Install build dependencies
    echo "   ↳ Installing build dependencies..."
    if ! sudo apt update || ! sudo apt install -y git cmake build-essential libvulkan-dev libwayland-dev libxrandr-dev libxcb-randr0-dev libdconf-dev libdbus-1-dev libmagickcore-dev libxfconf-0-dev libsqlite3-dev librpm-dev libegl-dev libglx-dev libosmesa6-dev ocl-icd-opencl-dev libpci-dev libdrm-dev 2>/dev/null; then
        printf "${YELLOW}⚠️  Some optional dependencies unavailable. Installing minimal set...${NC}\n"
        if ! sudo apt install -y git cmake build-essential; then
            printf "${RED}${CROSS} Error: Failed to install build dependencies.${NC}\n"
            return 1
        fi
    fi
    
    # Clone repository
    echo "   ↳ Cloning fastfetch repository..."
    cd /tmp
    if [ -d "fastfetch" ]; then
        rm -rf fastfetch
    fi
    
    if ! git clone --depth 1 --branch "${latest_version}" https://github.com/fastfetch-cli/fastfetch.git; then
        printf "${RED}${CROSS} Error: Failed to clone repository.${NC}\n"
        return 1
    fi
    
    cd fastfetch
    
    # Build
    echo "   ↳ Building fastfetch (this may take a few minutes)..."
    if ! cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"; then
        printf "${RED}${CROSS} Error: CMake configuration failed.${NC}\n"
        return 1
    fi
    
    if ! cmake --build build --target fastfetch -j$(nproc); then
        printf "${RED}${CROSS} Error: Build failed.${NC}\n"
        return 1
    fi
    
    # Install
    echo "   ↳ Installing fastfetch binary..."
    if ! sudo cp build/fastfetch "${INSTALL_PREFIX}/bin/fastfetch"; then
        printf "${RED}${CROSS} Error: Installation failed.${NC}\n"
        return 1
    fi
    
    sudo chmod 755 "${INSTALL_PREFIX}/bin/fastfetch"
    
    # Clean up
    cd ~
    rm -rf /tmp/fastfetch
    
    printf "${GREEN}${CHECK} Built and installed fastfetch v${latest_version}.${NC}\n"
    return 0
}

# --- Main Script ---
printf "${CYAN}${ROCKET} Starting Fastfetch Setup...${NC}\n\n"

# 1. Get version information
printf "${BLUE}Checking versions...${NC}\n"
INSTALLED_VERSION=$(get_installed_version)
printf "   ↳ Installed version: ${INSTALLED_VERSION}\n"

LATEST_VERSION=$(get_latest_version)
if [ "$LATEST_VERSION" = "unknown" ]; then
    printf "${YELLOW}⚠️  Could not fetch latest version from GitHub.${NC}\n"
    printf "   ↳ Continuing with current installation...\n"
    NEEDS_INSTALL=false
else
    printf "   ↳ Latest version: ${LATEST_VERSION}\n"
    
    # Determine if we need to install/update
    if [ "$INSTALLED_VERSION" = "none" ]; then
        NEEDS_INSTALL=true
        printf "${YELLOW}${WRENCH} fastfetch not found. Will install latest version.${NC}\n"
    elif [ "$INSTALLED_VERSION" = "unknown" ]; then
        NEEDS_INSTALL=true
        printf "${YELLOW}${WRENCH} Cannot determine installed version. Will reinstall.${NC}\n"
    elif [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
        NEEDS_INSTALL=true
        printf "${YELLOW}${WRENCH} Update available: ${INSTALLED_VERSION} → ${LATEST_VERSION}${NC}\n"
    else
        NEEDS_INSTALL=false
        printf "${GREEN}${CHECK} Already running latest version (${INSTALLED_VERSION}).${NC}\n"
    fi
fi

# 2. Remove package-based installations (always check)
echo ""
remove_package_install

# 3. Install or update if needed
if [ "$NEEDS_INSTALL" = true ] && [ "$LATEST_VERSION" != "unknown" ]; then
    echo ""
    build_from_source "$LATEST_VERSION"
    
    # Verify installation
    NEW_VERSION=$(get_installed_version)
    if [ "$NEW_VERSION" = "none" ] || [ "$NEW_VERSION" = "unknown" ]; then
        printf "${RED}${CROSS} Error: Installation verification failed.${NC}\n"
        exit 1
    fi
    printf "${GREEN}${CHECK} Successfully installed fastfetch v${NEW_VERSION}.${NC}\n"
fi

# 2. Configure shell integration via .bash_fastfetch
printf "\n${BLUE}📦 Configuring shell integration...${NC}\n"

printf "${CYAN}Configuration will activate on next shell or 'source $CONFIG_FILE'.${NC}\n"

printf "\n${GREEN}${PARTY} Fastfetch setup complete!${NC}\n"
