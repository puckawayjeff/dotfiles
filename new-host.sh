#!/usr/bin/env bash
# new-host.sh: Set up a new host with dotfiles
# Usage: wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/new-host.sh | bash
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

# --- Helper Functions ---

# Print a formatted section header
print_header() {
    printf "\n${BLUE}📦 $1${NC}\n\n"
}

# Print a success message
print_success() {
    printf "${GREEN}${CHECK} $1${NC}\n"
}

# Print an error message
print_error() {
    printf "${RED}${CROSS} Error: $1${NC}\n" >&2
}

# --- Main Script ---

printf "${CYAN}${ROCKET} Starting dotfiles setup (public version)...${NC}\n"

print_header "Installing Base Utilities"
# Update package lists first
printf "${YELLOW}${WRENCH} Updating package lists...${NC}\n"
sudo apt update

# Check if Git is installed
if ! command -v git &> /dev/null; then
    printf "${YELLOW}${WRENCH} Git is not installed. Installing...${NC}\n"
    sudo apt install -y git
    print_success "Git installed successfully."
else
    print_success "Git is already installed."
fi

# Verify Git installation
echo "   ↳ Git version: $(git --version | cut -d' ' -f3)"

# Install core utilities (bat, p7zip-full, tree)
printf "${YELLOW}${WRENCH} Installing core utilities (bat, p7zip-full, tree)...${NC}\n"
UTILS_TO_INSTALL=()

if ! command -v batcat &> /dev/null; then
    UTILS_TO_INSTALL+=(bat)
fi

if ! command -v 7z &> /dev/null; then
    UTILS_TO_INSTALL+=(p7zip-full)
fi

if ! command -v tree &> /dev/null; then
    UTILS_TO_INSTALL+=(tree)
fi

if [ ${#UTILS_TO_INSTALL[@]} -gt 0 ]; then
    echo "   ↳ Installing: ${UTILS_TO_INSTALL[*]}"
    sudo apt install -y "${UTILS_TO_INSTALL[@]}"
    print_success "Core utilities installed successfully."
else
    print_success "All core utilities already installed."
fi

print_header "Cloning dotfiles repository"
if [ -d "$HOME/dotfiles/.git" ]; then
    printf "${YELLOW}⚠️  Dotfiles repository already exists.${NC}\n"
    cd "$HOME/dotfiles"
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "   ↳ Stashing local changes..."
        git stash push -m "Auto-stash before pull on $(date '+%Y-%m-%d %H:%M:%S')"
        printf "${CYAN}   ↳ Local changes stashed. Use 'git stash pop' to restore them.${NC}\n"
    fi
    
    echo "   ↳ Pulling latest changes..."
    git pull
    print_success "Dotfiles repository updated."
else
    # Clone this repository - modify the URL if you've forked it
    git clone git@github.com:puckawayjeff/dotfiles.git "$HOME/dotfiles"
    print_success "Dotfiles repository cloned."
fi

print_header "Running core setup scripts"
# Run setup scripts in order: zsh must be first, others can follow
SETUP_SCRIPTS=("zsh" "eza" "fastfetch" "starship")

for script in "${SETUP_SCRIPTS[@]}"; do
    if [ -f "$HOME/dotfiles/setup/${script}.sh" ]; then
        printf "${CYAN}${WRENCH} Running ${script} setup...${NC}\n"
        if bash "$HOME/dotfiles/setup/${script}.sh"; then
            print_success "${script} setup completed."
        else
            printf "${RED}${CROSS} Warning: ${script} setup failed but continuing...${NC}\n"
        fi
        echo ""
    else
        printf "${YELLOW}${WARNING} Warning: ${script}.sh not found, skipping...${NC}\n"
    fi
done

print_header "Running dotfiles install script"
bash "$HOME/dotfiles/install.sh"
print_success "Install script finished."

print_header "Finalizing setup"
# Source the .zshrc to apply changes immediately
echo "   ↳ Sourcing .zshrc to apply changes..."
if [ -f "$HOME/.zshrc" ]; then
    # We can't source zshrc in bash, so we just inform the user
    printf "${CYAN}   Note: Please restart your shell or run 'zsh' to enter your new environment.${NC}\n"
fi
printf "\n${GREEN}${PARTY} Setup complete!${NC}\n"
