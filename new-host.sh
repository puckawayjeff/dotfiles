#!/usr/bin/env bash
# new-host.sh: Set up a new host with dotfiles
# Usage: wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/new-host.sh | bash
# 
# Prerequisites: SSH keys must be configured manually before running this script.
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

# Check if SSH is configured
if [ ! -f "$HOME/.ssh/id_ed25519_github" ]; then
    printf "${YELLOW}${WARNING} SSH keys not found.${NC}\n"
    printf "${YELLOW}   This script requires SSH to be configured manually first.${NC}\n"
    printf "${YELLOW}   Generate keys: ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github${NC}\n"
    printf "${YELLOW}   Add public key to GitHub: https://github.com/settings/keys${NC}\n\n"
fi

print_header "Checking for Git and Zsh"
# Check if Git is installed
if ! command -v git &> /dev/null; then
    printf "${YELLOW}${WRENCH} Git is not installed. Installing...${NC}\n"
    echo "   ↳ Updating package lists..."
    sudo apt update
    echo "   ↳ Installing Git..."
    sudo apt install -y git
    print_success "Git installed successfully."
else
    print_success "Git is already installed."
fi

# Check if Zsh is installed
if ! command -v zsh &> /dev/null; then
    printf "${YELLOW}${WRENCH} Zsh is not installed. Installing...${NC}\n"
    sudo apt install -y zsh
    print_success "Zsh installed successfully."
else
    print_success "Zsh is already installed."
fi

# Set Zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    printf "${YELLOW}${WRENCH} Setting Zsh as default shell...${NC}\n"
    sudo chsh -s "$(which zsh)" "$USER"
    print_success "Default shell changed to Zsh (requires logout)."
fi

# Verify Git installation
echo "   ↳ Git version: $(git --version | cut -d' ' -f3)"

# Configure Git (users should customize these values)
echo "   ↳ Configuring Git settings..."
git config --global pull.rebase false
print_success "Git pull strategy configured."
printf "${YELLOW}   Note: Set your Git identity with:${NC}\\n"
printf "${YELLOW}   git config --global user.name \"Your Name\"${NC}\\n"
printf "${YELLOW}   git config --global user.email \"you@example.com\"${NC}\\n"

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
    printf "${YELLOW}${WRENCH} You may be prompted to accept the host and decrypt your SSH key...${NC}\\n"
    # Clone this repository - modify the URL if you've forked it
    git clone git@github.com:puckawayjeff/dotfiles.git "$HOME/dotfiles"
    print_success "Dotfiles repository cloned."
fi

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
