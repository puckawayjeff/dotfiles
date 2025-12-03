#!/bin/bash

# Zsh Setup Script with Zinit Plugin Manager
# Installs zsh, zinit, and configures with powerful plugins
# Idempotent - safe to run multiple times

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

ROCKET="🚀"
WRENCH="🔧"
CHECK="✅"
CROSS="❌"
COMPUTER="💻"
PARTY="🎉"
STAR="⭐"

# --- Start Installation ---
printf "${CYAN}${ROCKET} Starting Zsh installation and configuration...${NC}\n\n"

# --- 1. Install Zsh ---
printf "${BLUE}${COMPUTER} Checking for Zsh...${NC}\n"
if command -v zsh &> /dev/null; then
    ZSH_VERSION=$(zsh --version | head -n1)
    printf "${GREEN}${CHECK} Zsh already installed: ${ZSH_VERSION}${NC}\n"
else
    printf "${YELLOW}${WRENCH} Zsh not found. Installing...${NC}\n"
    printf "   ↳ Updating package lists...\n"
    if ! sudo apt update > /dev/null 2>&1; then
        printf "${RED}${CROSS} Error: apt update failed.${NC}\n"
        exit 1
    fi
    
    printf "   ↳ Installing zsh package...\n"
    if ! sudo apt install -y zsh; then
        printf "${RED}${CROSS} Error: Zsh installation failed.${NC}\n"
        exit 1
    fi
    printf "${GREEN}${CHECK} Zsh installed successfully.${NC}\n"
fi

# --- 2. Install FZF (Fuzzy Finder) ---
printf "\n${BLUE}${COMPUTER} Checking for FZF...${NC}\n"
if command -v fzf &> /dev/null; then
    printf "${GREEN}${CHECK} FZF already installed.${NC}\n"
else
    printf "${YELLOW}${WRENCH} FZF not found. Installing...${NC}\n"
    if sudo apt install -y fzf; then
        printf "${GREEN}${CHECK} FZF installed successfully.${NC}\n"
    else
        printf "${YELLOW}⚠️  Warning: FZF installation failed. Will continue without it.${NC}\n"
    fi
fi

# --- 3. Install Zoxide (Smart cd) ---
printf "\n${BLUE}${COMPUTER} Checking for Zoxide...${NC}\n"
if command -v zoxide &> /dev/null; then
    printf "${GREEN}${CHECK} Zoxide already installed.${NC}\n"
else
    printf "${YELLOW}${WRENCH} Zoxide not found. Installing...${NC}\n"
    
    # Try package manager first
    if sudo apt install -y zoxide 2>/dev/null; then
        printf "${GREEN}${CHECK} Zoxide installed via apt.${NC}\n"
    else
        # Fallback to curl installer
        printf "   ↳ Installing via curl...\n"
        if curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
            printf "${GREEN}${CHECK} Zoxide installed successfully.${NC}\n"
        else
            printf "${YELLOW}⚠️  Warning: Zoxide installation failed. Will continue without it.${NC}\n"
        fi
    fi
fi

# --- 4. Install fd (Fast find alternative) ---
printf "\n${BLUE}${COMPUTER} Checking for fd...${NC}\n"
if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
    printf "${GREEN}${CHECK} fd already installed.${NC}\n"
else
    printf "${YELLOW}${WRENCH} fd not found. Installing...${NC}\n"
    if sudo apt install -y fd-find; then
        # Create symlink if fdfind is installed (Debian naming)
        if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
            mkdir -p ~/.local/bin
            ln -sf $(which fdfind) ~/.local/bin/fd
            export PATH="$HOME/.local/bin:$PATH"
        fi
        printf "${GREEN}${CHECK} fd installed successfully.${NC}\n"
    else
        printf "${YELLOW}⚠️  Warning: fd installation failed. Will continue without it.${NC}\n"
    fi
fi

# --- 5. Install direnv (Directory environment loader) ---
printf "\n${BLUE}${COMPUTER} Checking for direnv...${NC}\n"
if command -v direnv &> /dev/null; then
    printf "${GREEN}${CHECK} direnv already installed.${NC}\n"
else
    printf "${YELLOW}${WRENCH} direnv not found. Installing...${NC}\n"
    if sudo apt install -y direnv; then
        printf "${GREEN}${CHECK} direnv installed successfully.${NC}\n"
    else
        printf "${YELLOW}⚠️  Warning: direnv installation failed. Will continue without it.${NC}\n"
    fi
fi

# --- 6. Verify .zshrc exists in dotfiles ---
DOTFILES_ZSHRC="$HOME/dotfiles/config/.zshrc"
printf "\n${BLUE}📝 Checking for .zshrc configuration...${NC}\n"
if [[ -f "$DOTFILES_ZSHRC" ]]; then
    printf "${GREEN}${CHECK} Found .zshrc in dotfiles: $DOTFILES_ZSHRC${NC}\n"
    printf "   ↳ Configuration will be symlinked by install.sh\n"
else
    printf "${RED}${CROSS} Error: .zshrc not found in dotfiles.${NC}\n"
    printf "   ↳ Expected location: $DOTFILES_ZSHRC\n"
    exit 1
fi

# --- 7. Install Zinit (will happen on first zsh launch via .zshrc) ---
printf "\n${BLUE}📦 Checking for Zinit plugin manager...${NC}\n"
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ -d "$ZINIT_HOME" ]]; then
    printf "${GREEN}${CHECK} Zinit already installed.${NC}\n"
else
    printf "${YELLOW}${WRENCH} Zinit not found. It will be installed on first zsh launch.${NC}\n"
    printf "   ↳ Installation location: $ZINIT_HOME\n"
fi

# --- 8. Install Nerd Font ---
SETUP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
printf "\n"
if bash "$SETUP_DIR/_firacodenerdfont.sh"; then
    : # Success - helper script provides its own output
else
    printf "${YELLOW}   ↳ Font installation failed but continuing anyway.${NC}\n"
fi

# --- 9. Run install.sh to create symlinks ---
printf "\n${BLUE}🔗 Creating symlinks via install.sh...${NC}\n"
if [[ -f "$HOME/dotfiles/install.sh" ]]; then
    if bash "$HOME/dotfiles/install.sh"; then
        printf "${GREEN}${CHECK} Symlinks created/verified.${NC}\n"
    else
        printf "${YELLOW}⚠️  Warning: install.sh had errors but continuing.${NC}\n"
    fi
else
    printf "${YELLOW}⚠️  Warning: install.sh not found. Skipping symlink creation.${NC}\n"
fi

# --- 10. Test zsh configuration ---
printf "\n${BLUE}🧪 Testing Zsh configuration...${NC}\n"
if zsh -c 'exit 0' 2>/dev/null; then
    printf "${GREEN}${CHECK} Zsh configuration is valid.${NC}\n"
else
    printf "${RED}${CROSS} Warning: Zsh configuration has errors.${NC}\n"
    printf "   ↳ You may need to fix syntax errors in .zshrc\n"
fi

# --- 11. Change default shell to zsh ---
CURRENT_SHELL=$(basename "$SHELL")
printf "\n${BLUE}🐚 Checking default shell...${NC}\n"
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    printf "${GREEN}${CHECK} Default shell is already zsh.${NC}\n"
else
    printf "${YELLOW}${WRENCH} Current shell: $CURRENT_SHELL${NC}\n"
    printf "   ↳ Changing default shell to zsh...\n"
    
    ZSH_PATH=$(which zsh)
    
    # Verify zsh is in /etc/shells
    if ! grep -q "^${ZSH_PATH}$" /etc/shells 2>/dev/null; then
        printf "   ↳ Adding zsh to /etc/shells...\n"
        if echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null; then
            printf "${GREEN}${CHECK} Added zsh to /etc/shells.${NC}\n"
        else
            printf "${RED}${CROSS} Error: Failed to add zsh to /etc/shells.${NC}\n"
            exit 1
        fi
    fi
    
    # Change shell
    if chsh -s "$ZSH_PATH"; then
        printf "${GREEN}${CHECK} Default shell changed to zsh.${NC}\n"
        printf "${YELLOW}⚠️  You must log out and log back in for the change to take effect.${NC}\n"
    else
        printf "${RED}${CROSS} Error: Failed to change default shell.${NC}\n"
        printf "   ↳ You can manually change it later with: chsh -s \$(which zsh)\n"
    fi
fi

# --- 12. Completion Message ---
printf "\n${CYAN}═══════════════════════════════════════${NC}\n"
printf "${GREEN}${CHECK} Zsh setup complete!${NC}\n"
printf "${CYAN}═══════════════════════════════════════${NC}\n\n"

printf "${YELLOW}${STAR} Features installed:${NC}\n"
printf "   ✓ Zsh shell with Zinit plugin manager\n"
printf "   ✓ zsh-autosuggestions (Fish-like suggestions)\n"
printf "   ✓ fast-syntax-highlighting (Command validation)\n"
printf "   ✓ zsh-completions (Enhanced tab completion)\n"
printf "   ✓ zsh-history-substring-search (Arrow key history)\n"
printf "   ✓ FZF (Fuzzy finder - Ctrl+R for history)\n"
printf "   ✓ Zoxide (Smart cd replacement - use 'z' command)\n"
printf "   ✓ fd (Fast find alternative)\n"
printf "   ✓ direnv (Auto-load directory environments)\n"
printf "   ✓ Starship prompt (from existing config)\n"
printf "   ✓ FiraCode Nerd Font\n\n"

printf "${YELLOW}Next steps:${NC}\n"
printf "   1. ${CYAN}Log out and log back in${NC} (or reboot) for shell change\n"
printf "   2. Open a new terminal - Zinit will auto-install on first launch\n"
printf "   3. Try these commands:\n"
printf "      • Type a command and press ${CYAN}→${NC} to accept suggestion\n"
printf "      • Press ${CYAN}Ctrl+R${NC} for fuzzy history search (FZF)\n"
printf "      • Use ${CYAN}z <directory>${NC} instead of cd (learns your habits)\n"
printf "      • Press ${CYAN}ESC ESC${NC} to add sudo to current command\n"
printf "   4. Configure your terminal font to ${CYAN}FiraCode Nerd Font${NC}\n"
printf "      See: ${CYAN}docs/Terminal Font Setup.md${NC}\n\n"

printf "${BLUE}${COMPUTER} Your existing bash functions are preserved and work in zsh:${NC}\n"
printf "   • dotpush, dotpull, dotsetup\n"
printf "   • updatep, maintain\n"
printf "   • mkd, paths, packk, unpackk\n\n"

exit 0
