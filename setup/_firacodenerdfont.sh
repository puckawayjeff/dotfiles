#!/bin/bash

# _firacodenerdfont.sh - Helper script to install FiraCode Nerd Font
# This is a shared utility called by other setup scripts
# DO NOT call directly - prefix with _ indicates internal use only

# Exit on error
set -e

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

CHECK="✅"
CROSS="❌"

# --- Configuration ---
NERD_FONT_VERSION="v3.3.0"
FONT_NAME="FiraCode"
FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
TEMP_DIR="/tmp/nerd-font-install"

# --- Main Installation ---
printf "${BLUE}📦 Installing FiraCode Nerd Font...${NC}\n"

# Check if already installed
if fc-list | grep -q "FiraCode Nerd Font"; then
    printf "${GREEN}${CHECK} FiraCode Nerd Font already installed.${NC}\n"
    exit 0
fi

# Check for unzip and zip, install if missing
if ! command -v unzip &> /dev/null || ! command -v zip &> /dev/null; then
    printf "   ↳ Installing unzip and zip...\n"
    if ! sudo apt update > /dev/null 2>&1 || ! sudo apt install -y unzip zip > /dev/null 2>&1; then
        printf "${RED}${CROSS} Error: Failed to install unzip/zip.${NC}\n"
        exit 1
    fi
    printf "${GREEN}${CHECK} Installed unzip and zip.${NC}\n"
fi

printf "   ↳ Creating font directory...\n"
mkdir -p "$FONT_DIR"
mkdir -p "$TEMP_DIR"

printf "   ↳ Downloading FiraCode Nerd Font ${NERD_FONT_VERSION}...\n"
if ! curl -fLo "$TEMP_DIR/${FONT_NAME}.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/${FONT_NAME}.zip"; then
    printf "${RED}${CROSS} Error: Failed to download Nerd Font.${NC}\n"
    exit 1
fi

printf "   ↳ Extracting fonts...\n"
if ! unzip -q -o "$TEMP_DIR/${FONT_NAME}.zip" -d "$FONT_DIR"; then
    printf "${RED}${CROSS} Error: Failed to extract fonts.${NC}\n"
    rm -rf "$TEMP_DIR"
    exit 1
fi

printf "   ↳ Cleaning up...\n"
rm -rf "$TEMP_DIR"

printf "   ↳ Updating font cache...\n"
fc-cache -fv > /dev/null 2>&1

printf "${GREEN}${CHECK} FiraCode Nerd Font installed successfully.${NC}\n"
exit 0
