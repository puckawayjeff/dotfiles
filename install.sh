#!/usr/bin/env bash
# install.sh - Creates symlinks for dotfiles configuration
# Safe to run multiple times (idempotent)

# Exit on error
set -e

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
log_section "Starting dotfiles installation"

# 1. Ensure required directories exist
log_section "Ensuring directories exist" "$WRENCH"
mkdir -p "$HOME/.config/fastfetch"
log_success "Directories ready."

# 2. Create symlinks
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
    log_info "Skipped $SKIPPED existing symlink(s)."
fi

# 3. Apply changes to current session
log_info "Applying changes to current session..."
if [ -f "$HOME/.zshrc" ]; then
    log_info "Note: Run 'source ~/.zshrc' or restart your shell to apply changes."
else
    log_warning "Note: .zshrc not found. Changes will apply on next login."
fi

printf "\n${GREEN}${PARTY} Dotfiles installation complete!${NC}\n"
