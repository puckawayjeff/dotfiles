#!/usr/bin/env bash
# Sets up the 'foot' terminal inside the 'cage' compositor
# to automatically launch on login on tty1.

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

# --- Main Script ---
printf "${CYAN}${ROCKET} Starting Foot Terminal Setup...${NC}\n\n"

# 1. Install packages
printf "${BLUE}${COMPUTER} Installing packages...${NC}\n"
echo "   ↳ Updating package lists..."
sudo apt update

echo "   ↳ Installing cage, foot, and emoji support..."
if ! sudo apt install -y cage foot fonts-noto-color-emoji; then
    printf "${RED}${CROSS} Error: Package installation failed.${NC}\n"
    exit 1
fi
printf "${GREEN}${CHECK} Packages installed successfully.${NC}\n"

# 1b. Install FiraCode Nerd Font
SETUP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
printf "\n"
if ! bash "$SETUP_DIR/_firacodenerdfont.sh"; then
    printf "${RED}${CROSS} Error: Font installation failed.${NC}\n"
    exit 1
fi

# 2. Create configuration directory
printf "\n${BLUE}📦 Configuring Foot Terminal...${NC}\n"
echo "   ↳ Creating configuration directory..."
mkdir -p ~/.config/foot
printf "${GREEN}${CHECK} Directory ~/.config/foot created.${NC}\n"

# 3. Create the foot.ini configuration file
echo "   ↳ Creating foot.ini with custom font and colors..."
cat > ~/.config/foot/foot.ini << EOL
# ~/.config/foot/foot.ini
# Main configuration for the foot terminal

# Set the font to FiraCode Nerd Font with a size of 12.
# Nerd Fonts include thousands of glyphs for icons, powerline, etc.
font=FiraCode Nerd Font:size=12

# Example color scheme (Dracula-like)
[colors]
foreground=d8d8d8
background=181818
regular0=282828
regular1=ff5555
regular2=50fa7b
regular3=f1fa8c
regular4=bd93f9
regular5=ff79c6
regular6=8be9fd
regular7=f8f8f2
bright0=6272a4
bright1=ff6e6e
bright2=69ff94
bright3=ffffa5
bright4=d6acff
bright5=ff92df
bright6=a4ffff
bright7=ffffff
EOL
printf "${GREEN}${CHECK} foot.ini created successfully.${NC}\n"

printf "\n${GREEN}${PARTY} Foot Terminal setup complete!${NC}\n"
printf "${YELLOW}Next steps:${NC}\n"
printf "   ↳ Restart your cage/foot session for changes to take effect\n"
printf "   ↳ Font configured: FiraCode Nerd Font (with full icon support)\n"
