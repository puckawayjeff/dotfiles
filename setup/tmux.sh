#!/usr/bin/env bash
# Installs tmux and sets up a sensible default configuration on Debian-based systems.
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

# --- Configuration ---
TMUX_CONF="${HOME}/.tmux.conf"
DOTFILES_DIR="${HOME}/dotfiles"
TMUX_CONF_SOURCE="${DOTFILES_DIR}/config/tmux.conf"

# --- Main Script ---
printf "${CYAN}${ROCKET} Starting tmux Setup...${NC}\n\n"

# 1. Check if tmux is already installed
printf "${BLUE}${WRENCH} Checking for tmux installation...${NC}\n"
if command -v tmux &> /dev/null; then
    TMUX_VERSION=$(tmux -V)
    printf "${GREEN}${CHECK} tmux is already installed: ${TMUX_VERSION}${NC}\n"
else
    printf "${YELLOW}${WRENCH} tmux not found. Installing...${NC}\n"
    
    # Update package list
    printf "${BLUE}${COMPUTER} Updating package list...${NC}\n"
    if sudo apt update; then
        printf "${GREEN}${CHECK} Package list updated.${NC}\n"
    else
        printf "${RED}${CROSS} Error: Failed to update package list.${NC}\n"
        exit 1
    fi
    
    # Install tmux
    printf "${BLUE}${COMPUTER} Installing tmux...${NC}\n"
    if sudo apt install -y tmux; then
        TMUX_VERSION=$(tmux -V)
        printf "${GREEN}${CHECK} tmux installed successfully: ${TMUX_VERSION}${NC}\n"
    else
        printf "${RED}${CROSS} Error: tmux installation failed.${NC}\n"
        exit 1
    fi
fi

# 2. Check if config file exists (symlink expected)
printf "\n${BLUE}Checking tmux configuration...${NC}\n"

if [[ -L "$TMUX_CONF" ]]; then
    # It's a symlink - check if it points to the right place
    LINK_TARGET=$(readlink -f "$TMUX_CONF")
    EXPECTED_TARGET=$(readlink -f "$TMUX_CONF_SOURCE")
    
    if [[ "$LINK_TARGET" == "$EXPECTED_TARGET" ]]; then
        printf "${GREEN}${CHECK} Configuration already linked correctly.${NC}\n"
        printf "   ↳ ${TMUX_CONF} -> ${TMUX_CONF_SOURCE}\n"
    else
        printf "${YELLOW}⚠️  Symlink exists but points to wrong location.${NC}\n"
        printf "   ↳ Current: ${LINK_TARGET}\n"
        printf "   ↳ Expected: ${EXPECTED_TARGET}\n"
        printf "${YELLOW}${WRENCH} Fixing symlink...${NC}\n"
        rm "$TMUX_CONF"
        ln -s "$TMUX_CONF_SOURCE" "$TMUX_CONF"
        printf "${GREEN}${CHECK} Symlink corrected.${NC}\n"
    fi
elif [[ -f "$TMUX_CONF" ]]; then
    # Regular file exists
    printf "${YELLOW}⚠️  Regular file exists at ${TMUX_CONF}${NC}\n"
    printf "${YELLOW}This will be replaced by a symlink to the dotfiles version.${NC}\n"
    printf "Backup existing file? [Y/n]: "
    read -r RESPONSE
    
    if [[ ! "$RESPONSE" =~ ^[Nn]$ ]]; then
        BACKUP_FILE="${TMUX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$TMUX_CONF" "$BACKUP_FILE"
        printf "${GREEN}${CHECK} Backup created: ${BACKUP_FILE}${NC}\n"
    fi
    
    rm "$TMUX_CONF"
    ln -s "$TMUX_CONF_SOURCE" "$TMUX_CONF"
    printf "${GREEN}${CHECK} Symlink created.${NC}\n"
else
    # No config exists
    if [[ -f "$TMUX_CONF_SOURCE" ]]; then
        printf "${BLUE}${WRENCH} Creating symlink to dotfiles config...${NC}\n"
        ln -s "$TMUX_CONF_SOURCE" "$TMUX_CONF"
        printf "${GREEN}${CHECK} Symlink created.${NC}\n"
    else
        printf "${YELLOW}⚠️  Source config not found: ${TMUX_CONF_SOURCE}${NC}\n"
        printf "${YELLOW}Run 'install.sh' from your dotfiles directory to set up all configs.${NC}\n"
    fi
fi

# 3. Verify installation and config
printf "\n${BLUE}Verifying setup...${NC}\n"

if command -v tmux &> /dev/null; then
    printf "${GREEN}${CHECK} tmux command: $(which tmux)${NC}\n"
    printf "${GREEN}${CHECK} tmux version: $(tmux -V)${NC}\n"
fi

if [[ -L "$TMUX_CONF" ]]; then
    printf "${GREEN}${CHECK} Config file: ${TMUX_CONF} (symlink)${NC}\n"
    printf "   ↳ Points to: $(readlink "$TMUX_CONF")\n"
elif [[ -f "$TMUX_CONF" ]]; then
    printf "${GREEN}${CHECK} Config file: ${TMUX_CONF} (regular file)${NC}\n"
else
    printf "${YELLOW}⚠️  No config file found at ${TMUX_CONF}${NC}\n"
fi

# 4. Test configuration syntax (if tmux is running, this won't work perfectly, but we try)
printf "\n${BLUE}Testing configuration syntax...${NC}\n"
if [[ -f "$TMUX_CONF" ]]; then
    # Start tmux in the background with the config and immediately exit to test parsing
    if tmux -f "$TMUX_CONF" new-session -d -s tmux-config-test 'exit' 2>/dev/null; then
        tmux kill-session -t tmux-config-test 2>/dev/null || true
        printf "${GREEN}${CHECK} Configuration syntax is valid.${NC}\n"
    else
        printf "${YELLOW}⚠️  Could not verify config (tmux may already be running).${NC}\n"
    fi
fi

# 5. Display helpful information
printf "\n${GREEN}${PARTY} tmux setup complete!${NC}\n\n"
printf "${CYAN}Quick Start Commands:${NC}\n"
printf "  ${YELLOW}tmux${NC}                    - Start a new tmux session\n"
printf "  ${YELLOW}tmux new -s <name>${NC}      - Start a new named session\n"
printf "  ${YELLOW}tmux ls${NC}                 - List all sessions\n"
printf "  ${YELLOW}tmux attach -t <name>${NC}   - Attach to a session\n"
printf "  ${YELLOW}tmux kill-session -t <name>${NC} - Kill a session\n"
printf "\n${CYAN}Key Bindings (with our config):${NC}\n"
printf "  ${YELLOW}Ctrl+b${NC} is the prefix key\n"
printf "  ${YELLOW}Prefix + |${NC}              - Split pane vertically\n"
printf "  ${YELLOW}Prefix + -${NC}              - Split pane horizontally\n"
printf "  ${YELLOW}Prefix + h/j/k/l${NC}        - Navigate panes (vim-style)\n"
printf "  ${YELLOW}Prefix + r${NC}              - Reload configuration\n"
printf "  ${YELLOW}Prefix + [${NC}              - Enter copy mode (scroll with arrows/vim keys)\n"
printf "  ${YELLOW}Mouse${NC}                   - Click to select panes, drag to resize, scroll to navigate history\n"
printf "\n${CYAN}Note: This config integrates with the 'updatep' function in your .zshrc${NC}\n"
