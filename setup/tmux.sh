#!/usr/bin/env bash
# Installs tmux and sets up a sensible default configuration on Debian-based systems.
# This script is idempotent and safe to run multiple times.

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

# --- Configuration ---
TMUX_CONF="${HOME}/.tmux.conf"
DOTFILES_DIR="${HOME}/dotfiles"
TMUX_CONF_SOURCE="${DOTFILES_DIR}/config/tmux.conf"

# --- Main Script ---
log_section "Starting tmux Setup" "$ROCKET"

# 1. Check if tmux is already installed
log_step "Checking for tmux installation..." "$WRENCH"
if command -v tmux &> /dev/null; then
    TMUX_VERSION=$(tmux -V)
    log_success "tmux is already installed: ${TMUX_VERSION}"
else
    log_warning "tmux not found. Installing..."
    
    # Update package list
    log_action "Updating package list..."
    if sudo apt update; then
        log_success "Package list updated."
    else
        log_error "Failed to update package list."
        exit 1
    fi
    
    # Install tmux
    log_action "Installing tmux..."
    if sudo apt install -y tmux; then
        TMUX_VERSION=$(tmux -V)
        log_success "tmux installed successfully: ${TMUX_VERSION}"
    else
        log_error "tmux installation failed."
        exit 1
    fi
fi

# 2. Check if config file exists (symlink expected)
log_info "\nChecking tmux configuration..."

if [[ -L "$TMUX_CONF" ]]; then
    # It's a symlink - check if it points to the right place
    LINK_TARGET=$(readlink -f "$TMUX_CONF")
    EXPECTED_TARGET=$(readlink -f "$TMUX_CONF_SOURCE")
    
    if [[ "$LINK_TARGET" == "$EXPECTED_TARGET" ]]; then
        log_success "Configuration already linked correctly."
        log_substep "${TMUX_CONF} -> ${TMUX_CONF_SOURCE}"
    else
        log_warning "${WARNING}  Symlink exists but points to wrong location."
        log_substep "Current: ${LINK_TARGET}"
        log_substep "Expected: ${EXPECTED_TARGET}"
        log_step "Fixing symlink..." "$WRENCH"
        rm "$TMUX_CONF"
        ln -s "$TMUX_CONF_SOURCE" "$TMUX_CONF"
        log_success "Symlink corrected."
    fi
elif [[ -f "$TMUX_CONF" ]]; then
    # Regular file exists
    log_warning "${WARNING}  Regular file exists at ${TMUX_CONF}"
    log_warning "This will be replaced by a symlink to the dotfiles version."
    printf "Backup existing file? [Y/n]: "
    read -r RESPONSE
    
    if [[ ! "$RESPONSE" =~ ^[Nn]$ ]]; then
        BACKUP_FILE="${TMUX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$TMUX_CONF" "$BACKUP_FILE"
        log_success "Backup created: ${BACKUP_FILE}"
    fi
    
    rm "$TMUX_CONF"
    ln -s "$TMUX_CONF_SOURCE" "$TMUX_CONF"
    log_success "Symlink created."
else
    # No config exists
    if [[ -f "$TMUX_CONF_SOURCE" ]]; then
        log_step "Creating symlink to dotfiles config..." "$WRENCH"
        ln -s "$TMUX_CONF_SOURCE" "$TMUX_CONF"
        log_success "Symlink created."
    else
        log_warning "${WARNING}  Source config not found: ${TMUX_CONF_SOURCE}"
        log_warning "Run 'install.sh' from your dotfiles directory to set up all configs."
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
    log_warning "${WARNING}  No config file found at ${TMUX_CONF}"
fi

# 4. Test configuration syntax (if tmux is running, this won't work perfectly, but we try)
log_info "\nTesting configuration syntax..."
if [[ -f "$TMUX_CONF" ]]; then
    # Start tmux in the background with the config and immediately exit to test parsing
    if tmux -f "$TMUX_CONF" new-session -d -s tmux-config-test 'exit' 2>/dev/null; then
        tmux kill-session -t tmux-config-test 2>/dev/null || true
        log_success "Configuration syntax is valid."
    else
        log_warning "${WARNING}  Could not verify config (tmux may already be running)."
    fi
fi

# 5. Display helpful information
log_complete "tmux setup complete!"
log_plain ""
log_info "${CYAN}Quick Start Commands:${NC}"
log_plain "  ${YELLOW}tmux${NC}                    - Start a new tmux session"
log_plain "  ${YELLOW}tmux new -s <name>${NC}      - Start a new named session"
log_plain "  ${YELLOW}tmux ls${NC}                 - List all sessions"
log_plain "  ${YELLOW}tmux attach -t <name>${NC}   - Attach to a session"
log_plain "  ${YELLOW}tmux kill-session -t <name>${NC} - Kill a session"
log_plain ""
log_info "${CYAN}Key Bindings (with our config):${NC}"
log_plain "  ${YELLOW}Ctrl+b${NC} is the prefix key"
log_plain "  ${YELLOW}Prefix + |${NC}              - Split pane vertically"
log_plain "  ${YELLOW}Prefix + -${NC}              - Split pane horizontally"
log_plain "  ${YELLOW}Prefix + h/j/k/l${NC}        - Navigate panes (vim-style)"
log_plain "  ${YELLOW}Prefix + r${NC}              - Reload configuration"
log_plain "  ${YELLOW}Prefix + [${NC}              - Enter copy mode (scroll with arrows/vim keys)"
log_plain "  ${YELLOW}Mouse${NC}                   - Click to select panes, drag to resize, scroll to navigate history"
log_plain ""
log_info "${CYAN}Note: This config integrates with the 'updatep' function in your .zshrc${NC}"
