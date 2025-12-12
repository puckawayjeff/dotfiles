#!/usr/bin/env bash
# Sets up the 'foot' terminal inside the 'cage' compositor
# to automatically launch on login on tty1.

# Exit immediately if a command exits with a non-zero status
set -e

# Load shared utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found"
    exit 1
fi

# --- Main Script ---
log_section "Starting Foot Terminal Setup" "$ROCKET"

# 1. Install packages
log_action "Installing packages..."
echo "   ↳ Updating package lists..."
sudo apt update

echo "   ↳ Installing cage, foot, and emoji support..."
if ! sudo apt install -y cage foot fonts-noto-color-emoji; then
    log_error "Package installation failed."
    exit 1
fi
log_success "Packages installed successfully."

# 2. Create configuration directory
printf "\n${BLUE}📦 Configuring Foot Terminal...${NC}\n"
echo "   ↳ Creating configuration directory..."
mkdir -p ~/.config/foot
log_success "Directory ~/.config/foot created."

# 3. Create the foot.ini configuration file
echo "   ↳ Creating foot.ini with custom font and colors..."
cat > ~/.config/foot/foot.ini << EOL
# ~/.config/foot/foot.ini
# Main configuration for the foot terminal

# Set the font to FiraCode Nerd Font with a size of 12.
# Nerd Fonts include thousands of glyphs for icons, powerline, etc.
font=FiraCode Nerd Font Mono:size=12

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
log_success "foot.ini created successfully."

log_complete "Foot Terminal setup complete!"
log_warning "Next steps:"
printf "   ↳ Restart your cage/foot session for changes to take effect\n"
printf "   ↳ Font configured: FiraCode Nerd Font (with full icon support)\n"
