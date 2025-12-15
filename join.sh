#!/usr/bin/env bash
# join.sh: Set up a new host with dotfiles
# Usage: wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
# 
# Prerequisites: SSH keys must be configured manually before running this script to enable git operations.
# This script is idempotent and safe to re-run.

# Exit immediately if a command exits with a non-zero status
set -e

# --- Color Definitions ---
# Define colors using tput (portable across terminals)
if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)   # Success messages
    YELLOW=$(tput setaf 3)  # Warnings, prompts, user attention
    BLUE=$(tput setaf 4)    # Section headers, informational
    CYAN=$(tput setaf 6)    # Command output, sub-steps
    RED=$(tput setaf 1)     # Errors, failures
    NC=$(tput sgr0)         # Reset/No Color
else
    # Fallback to ANSI escape codes if tput unavailable
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
WARNING="⚠️"
PACKAGE="📦"

# --- Helper Functions (matching utils.sh) ---

# Print a section header
log_section() {
    local title="$1"
    local icon="${2:-$PACKAGE}"
    printf "\n${CYAN}${icon} ${title}...${NC}\n"
}

# Print a success message
log_success() {
    printf "${GREEN}${CHECK} $1${NC}\n"
}

# Print an error message
log_error() {
    printf "${RED}${CROSS} Error: $1${NC}\n" >&2
}

# Print an info message
log_info() {
    printf "${BLUE}$1${NC}\n"
}

# Print a warning message
log_warning() {
    printf "${YELLOW}$1${NC}\n"
}

# Print a sub-step
log_substep() {
    echo "   ↳ $1"
}

# --- Main Script ---

# Determine if we need sudo (root doesn't need it)
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

log_section "Starting dotfiles setup (public version)" "$ROCKET"

log_section "Installing Base Utilities" "$PACKAGE"
if ! command -v apt &> /dev/null; then
    log_error "Cannot update packages without apt package manager."
else
    log_warning "Updating package lists..."
    $SUDO apt update &> /dev/null
    log_success "Package lists updated"
fi
# Check if Git is installed
if ! command -v git &> /dev/null; then
    # Git not installed - check if apt is available
    if ! command -v apt &> /dev/null; then
        log_error "Git is not installed and apt package manager is not available"
        log_error "This script requires Debian-based systems (Debian, Ubuntu, Mint, etc.)"
        exit 1
    fi
    
    log_warning "Git is not installed. Installing..."
    $SUDO apt install -y git
    log_success "Git installed successfully"
else
    log_success "Git is already installed"
fi

# Verify Git installation
log_substep "Git version: $(git --version | cut -d' ' -f3)"

log_section "Cloning dotfiles repository" "$ROCKET"
if [ -d "$HOME/dotfiles/.git" ]; then
    log_warning "Dotfiles repository already exists"
    cd "$HOME/dotfiles"
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_substep "Stashing local changes..."
        git stash push -m "Auto-stash before pull on $(date '+%Y-%m-%d %H:%M:%S')"
        log_info "   ↳ Local changes stashed. Use 'git stash pop' to restore them."
    fi
    
    log_substep "Pulling latest changes..."
    GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull
    log_success "Dotfiles repository updated"
else
    # Check for SSH key to determine clone method
    if [ -f "$HOME/.ssh/id_ed25519_github" ]; then
        log_substep "SSH key found - cloning via SSH..."
        git clone git@github.com:puckawayjeff/dotfiles.git "$HOME/dotfiles"
    else
        log_substep "No SSH key - cloning via HTTPS..."
        git clone https://github.com/puckawayjeff/dotfiles.git "$HOME/dotfiles"
    fi
    log_success "Dotfiles repository cloned"
fi

log_section "Running dotfiles install script" "$WRENCH"
bash "$HOME/dotfiles/install.sh"
log_success "Install script finished"

log_section "Finalizing setup" "$PARTY"
# Check if default shell was changed 
if [ "$(basename "$SHELL")" != "zsh" ] && command -v zsh &> /dev/null; then
    log_substep "Default shell changed to zsh"
    log_substep "Logout and login to activate zsh"
fi

# Check if git config is using defaults
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
if [ "$CURRENT_EMAIL" = "dotfiles@change.me" ]; then
    log_warning "Git is using default credentials"
    log_substep "Update with: git config --global user.name 'Your Name'"
    log_substep "Update with: git config --global user.email 'your@email.com'"
fi

printf "\n${GREEN}${PARTY} New host setup complete!${NC}\n"
log_info "Start a new shell with: zsh"
log_info ""
log_info "${CYAN}📚 Quick Help:${NC}"
log_substep "dothelp - Show all available commands"
log_substep "dotkeys - Show keyboard shortcuts"
