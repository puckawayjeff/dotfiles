#!/usr/bin/env bash
# install.sh - Creates symlinks for dotfiles configuration
# Safe to run multiple times (idempotent)

# Don't exit on error for graceful degradation
set +e

# --- Configuration ---
# Get the directory of the script itself
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# --- Load Shared Library ---
if [ -f "$DOTFILES_DIR/lib/utils.sh" ]; then
    source "$DOTFILES_DIR/lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

# --- Main Script ---
log_section "Starting dotfiles installation" "$ROCKET"

# --- 1. Configure git if needed ---
log_section "Git Configuration" "$WRENCH"
if ! git config --global user.name > /dev/null 2>&1; then
    log_info "Setting default git user.name..."
    git config --global user.name "dotfiles-user"
    log_warning "Git user.name set to 'dotfiles-user' - update with: git config --global user.name 'Your Name'"
fi
if ! git config --global user.email > /dev/null 2>&1; then
    log_info "Setting default git user.email..."
    git config --global user.email "dotfiles@change.me"
    log_warning "Git user.email set to 'dotfiles@change.me' - update with: git config --global user.email 'your@email.com'"
fi

# Check if values are still defaults
CURRENT_NAME=$(git config --global user.name)
CURRENT_EMAIL=$(git config --global user.email)
if [ "$CURRENT_NAME" = "dotfiles-user" ] || [ "$CURRENT_EMAIL" = "dotfiles@change.me" ]; then
    log_warning "Using default git credentials - update before committing!"
else
    log_success "Git configured: $CURRENT_NAME <$CURRENT_EMAIL>"
fi

# --- 2. Install core utilities ---
log_section "Core Utilities Installation" "$PACKAGE"

if command -v apt &> /dev/null; then
    # Define core utilities: command:package format
    # When command and package are the same, just use single name
    CORE_UTILS=(
        "batcat:bat"
        "7z:p7zip-full"
        "tree"
        "curl"
        "wget"
        "sudo"
        "unzip"
    )
    
    UTILS_TO_INSTALL=()
    
    for util in "${CORE_UTILS[@]}"; do
        if [[ "$util" == *:* ]]; then
            # Split command:package
            IFS=':' read -r cmd pkg <<< "$util"
        else
            # Command and package are the same
            cmd="$util"
            pkg="$util"
        fi
        
        if ! command -v "$cmd" &> /dev/null; then
            UTILS_TO_INSTALL+=("$pkg")
        fi
    done
    
    if [ ${#UTILS_TO_INSTALL[@]} -gt 0 ]; then
        log_info "Installing: ${UTILS_TO_INSTALL[*]}"
        if sudo apt update > /dev/null 2>&1 && sudo apt install -y "${UTILS_TO_INSTALL[@]}" 2>/dev/null; then
            log_success "Core utilities installed"
        else
            log_warning "Some core utilities failed to install, continuing..."
        fi
    else
        log_success "All core utilities already installed"
    fi
else
    log_warning "apt not available - skipping core utilities installation (Synology environment?)"
fi

# --- 3. Install terminal utilities ---
log_section "Terminal Utilities" "$COMPUTER"
if [ -f "$DOTFILES_DIR/lib/terminal.sh" ]; then
    log_info "Running terminal utilities installer..."
    if source "$DOTFILES_DIR/lib/terminal.sh"; then
        : # Success message handled by terminal.sh
    else
        log_warning "Terminal utilities installation had errors, continuing..."
    fi
else
    log_warning "lib/terminal.sh not found, skipping terminal setup"
fi

# --- 4. Create symlinks ---
log_info "Creating symlinks..."

# Define symlink mappings (source -> target)
# NOTE: SSH config is managed separately (not symlinked from public repo)
declare -A SYMLINKS=(
    ["$DOTFILES_DIR/config/.zshrc"]="$HOME/.zshrc"
    ["$DOTFILES_DIR/config/.zprofile"]="$HOME/.zprofile"
    ["$DOTFILES_DIR/config/starship.toml"]="$HOME/.config/starship.toml"
    ["$DOTFILES_DIR/config/fastfetch.jsonc"]="$HOME/.config/fastfetch/config.jsonc"
    ["$DOTFILES_DIR/config/functions.zsh"]="$HOME/.zsh_functions"
)

CREATED=0
SKIPPED=0

for source in "${!SYMLINKS[@]}"; do
    target="${SYMLINKS[$source]}"
    
    # Check if target already exists and points to correct location
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        log_substep "$(basename "$target") - already linked"
        SKIPPED=$((SKIPPED + 1))
    else
        # Create/update symlink
        ln -sf "$source" "$target"
        log_substep "$(basename "$target") - linked"
        CREATED=$((CREATED + 1))
    fi
done

if [ $CREATED -gt 0 ]; then
    log_success "Created/updated $CREATED symlink(s)."
fi
if [ $SKIPPED -gt 0 ]; then
    log_info "Skipped $SKIPPED existing symlink(s)"
fi

# --- 5. Final instructions ---
log_section "Installation Complete" "$PARTY"
if [ -f "$HOME/.zshrc" ]; then
    log_info "Run 'source ~/.zshrc' or restart your shell to apply changes"
else
    log_warning ".zshrc not found - changes will apply on next login"
fi

# Check if shell needs to be changed
if [ "$(basename "$SHELL")" != "zsh" ] && command -v zsh &> /dev/null; then
    log_warning "Default shell is not zsh - logout/login required for change to take effect"
fi

printf "\n${GREEN}${CHECK} Dotfiles installation complete!${NC}\n"
log_section "Next Steps" "$ROCKET"
printf "${YELLOW}${INFO}${NC} To apply all changes, run:\n"
printf "   ${CYAN}exec zsh${NC}  ${DIM}# Reload current shell${NC}\n"
printf "   ${DIM}OR${NC}\n"
printf "   ${CYAN}exit${NC}      ${DIM}# Start a new session${NC}\n\n"
