#!/usr/bin/env bash
# lib/motd.sh - Dynamic MOTD script for dotfiles
# Executed by shell configuration on initial login/launch
#
# Purpose: Display system information on terminal login without running on every shell reload

# Exit on error
set -e

# --- Fastfetch Display ---
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch --key-type icon
else
    # Fallback if fastfetch is not installed
    echo " "
fi

# --- Help Functions Reminder ---
# Display helpful tip about available commands
if command -v tput >/dev/null 2>&1; then
    CYAN=$(tput setaf 6)
    YELLOW=$(tput setaf 3)
    NC=$(tput sgr0)
else
    CYAN='\033[0;36m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
fi

echo ""
echo "${CYAN}📚 Quick Help:${NC} ${YELLOW}dothelp${NC} - Show all commands  |  ${YELLOW}dotkeys${NC} - Keyboard shortcuts"
echo ""
