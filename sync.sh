#!/usr/bin/env bash
# sync.sh - Sync and configure dotfiles
# Safe to run multiple times (idempotent)
# Usage: sync.sh [--from-join] [--quiet]
#   --from-join: First-time setup (verbose, from join.sh)
#   --quiet:     Suppress verbose output (for cron/auto-updates)

# Don't exit on error for graceful degradation
set +e

# Parse arguments
QUIET_MODE=false
FROM_JOIN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet|-q)
            QUIET_MODE=true
            shift
            ;;
        --from-join)
            FROM_JOIN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: sync.sh [--from-join] [--quiet]"
            exit 1
            ;;
    esac
done

export QUIET_MODE
export FROM_JOIN

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
if [[ "$FROM_JOIN" == "true" ]]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Starting dotfiles sync (first-time setup)" "$ROCKET"
    fi
else
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Syncing dotfiles" "$ROCKET"
    fi
    
    # Pull latest changes from dotfiles
    if [ -d "$DOTFILES_DIR/.git" ]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            log_info "Pulling latest dotfiles changes..."
        fi
        cd "$DOTFILES_DIR"
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            git stash push -m "Auto-stash before sync on $(date '+%Y-%m-%d %H:%M:%S')" &>/dev/null
        fi
        GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull &>/dev/null
        cd - >/dev/null
    fi
    
    # Pull latest changes from sshsync if it exists (enhanced mode)
    if [ -d "$HOME/sshsync/.git" ]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            log_info "Pulling latest sshsync changes..."
        fi
        cd "$HOME/sshsync"
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            git stash push -m "Auto-stash before sync on $(date '+%Y-%m-%d %H:%M:%S')" &>/dev/null
        fi
        GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull &>/dev/null
        cd - >/dev/null
    fi
fi

# Detect enhanced mode
ENHANCED_MODE=false
if [ -d "$HOME/sshsync/.git" ]; then
    ENHANCED_MODE=true
fi

# --- 1. Configure git if needed (only in standalone mode or from join) ---
if [ "$ENHANCED_MODE" = false ] && [ "$FROM_JOIN" = true ]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Git Configuration" "$WRENCH"
    fi
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
fi

# --- 1a. Enhanced mode: Symlink SSH config from sshsync ---
if [ "$ENHANCED_MODE" = true ]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "SSH Configuration" "$WRENCH"
    fi
    
    SSH_CONFIG_SOURCE="$HOME/sshsync/ssh.conf"
    SSH_CONFIG_TARGET="$HOME/.ssh/config"
    
    if [ -f "$SSH_CONFIG_SOURCE" ]; then
        # Check if already symlinked correctly
        if [ -L "$SSH_CONFIG_TARGET" ] && [ "$(readlink "$SSH_CONFIG_TARGET")" = "$SSH_CONFIG_SOURCE" ]; then
            if [[ "$QUIET_MODE" != "true" ]]; then
                log_success "SSH config already linked"
            fi
        else
            # Backup existing config if it's a regular file
            if [ -f "$SSH_CONFIG_TARGET" ] && [ ! -L "$SSH_CONFIG_TARGET" ]; then
                mv "$SSH_CONFIG_TARGET" "$SSH_CONFIG_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
                log_info "Backed up existing SSH config"
            fi
            
            # Create symlink
            ln -sf "$SSH_CONFIG_SOURCE" "$SSH_CONFIG_TARGET"
            log_success "SSH config linked from sshsync"
        fi
    else
        log_warning "sshsync/ssh.conf not found - SSH config not updated"
    fi
fi

# --- 2. Install core utilities ---
if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "Core Utilities Installation" "$PACKAGE"
fi

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
        "rename"
        "rsync"
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
if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "Terminal Utilities" "$COMPUTER"
fi
if [ -f "$DOTFILES_DIR/lib/terminal.sh" ]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_info "Running terminal utilities installer..."
    fi
    if source "$DOTFILES_DIR/lib/terminal.sh"; then
        : # Success message handled by terminal.sh
    else
        log_warning "Terminal utilities installation had errors, continuing..."
    fi
else
    log_warning "lib/terminal.sh not found, skipping terminal setup"
fi

# --- 4. Setup MOTD integration ---
if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "MOTD Setup" "$COMPUTER"
fi

MOTD_DIR="/etc/update-motd.d"
MOTD_SCRIPT="$DOTFILES_DIR/lib/motd.sh"
MOTD_FRAGMENT="$MOTD_DIR/99-dotfiles"

if [ -d "$MOTD_DIR" ]; then
    # Check if MOTD fragment exists and has correct content
    if [ -f "$MOTD_FRAGMENT" ]; then
        if grep -q "exec.*$MOTD_SCRIPT" "$MOTD_FRAGMENT" 2>/dev/null; then
            log_success "MOTD already configured"
        else
            log_info "Updating MOTD fragment..."
            # Create the fragment that execs our script (per man update-motd best practices)
            if sudo tee "$MOTD_FRAGMENT" > /dev/null 2>&1 << EOF
#!/bin/sh
# Dotfiles MOTD fragment - calls external script
# This allows the main script to be updated without modifying this file
exec $MOTD_SCRIPT
EOF
            then
                sudo chmod +x "$MOTD_FRAGMENT" 2>/dev/null
                log_success "MOTD fragment updated at $MOTD_FRAGMENT"
                log_substep "Will display system info on terminal login"
            else
                log_warning "Failed to update MOTD fragment (sudo required), skipping..."
            fi
        fi
    else
        log_info "Setting up MOTD integration..."
        # Create the fragment that execs our script (per man update-motd best practices)
        if sudo tee "$MOTD_FRAGMENT" > /dev/null 2>&1 << EOF
#!/bin/sh
# Dotfiles MOTD fragment - calls external script
# This allows the main script to be updated without modifying this file
exec $MOTD_SCRIPT
EOF
        then
            sudo chmod +x "$MOTD_FRAGMENT" 2>/dev/null
            log_success "MOTD configured at $MOTD_FRAGMENT"
            log_substep "Will display system info on terminal login"
        else
            log_warning "Failed to create MOTD fragment (sudo required), skipping..."
        fi
    fi
else
    log_info "System does not support update-motd (/etc/update-motd.d not found)"
    log_substep "Skipping MOTD setup - fastfetch will run from .zshrc instead"
fi

# --- 5. Create symlinks from config/symlinks.conf ---
# Single source of truth for ALL dotfiles symlinks (core tools + user-added)
# Symlinks are defined in config/symlinks.conf and processed here

if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "Configuration Symlinks" "$WRENCH"
fi

SYMLINKS_CONF="$DOTFILES_DIR/config/symlinks.conf"

if [ -f "$SYMLINKS_CONF" ] && [ -s "$SYMLINKS_CONF" ]; then
    log_info "Processing symlinks from config/symlinks.conf..."
    
    CREATED=0
    SKIPPED=0
    
    # Read symlinks from config file
    while IFS=: read -r source target || [ -n "$source" ]; do
        # Skip empty lines and comments
        [[ -z "$source" || "$source" =~ ^[[:space:]]*# ]] && continue
        
        # Expand variables in paths
        source=$(eval echo "$source")
        target=$(eval echo "$target")
        
        # Create parent directory if needed
        target_dir=$(dirname "$target")
        if [[ ! -d "$target_dir" ]]; then
            mkdir -p "$target_dir"
        fi
        
        # Check if target already exists and points to correct location
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            log_substep "$(basename "$target") - already linked"
            SKIPPED=$((SKIPPED + 1))
        else
            # Backup existing file if present
            if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
                local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
                mv "$target" "$backup"
                log_substep "$(basename "$target") - backed up existing file"
            fi
            
            # Create/update symlink
            ln -sf "$source" "$target"
            log_substep "$(basename "$target") - linked"
            CREATED=$((CREATED + 1))
        fi
    done < "$SYMLINKS_CONF"
    
    if [ $CREATED -gt 0 ]; then
        log_success "Created/updated $CREATED symlink(s)"
    fi
    if [ $SKIPPED -gt 0 ]; then
        log_info "Skipped $SKIPPED existing symlink(s)"
    fi
else
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_warning "No symlinks configured in symlinks.conf"
        log_substep "Use 'add-dotfile <path>' to add configuration files"
    fi
fi

# --- 6. Final instructions ---
if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "Sync Complete" "$PARTY"
    
    if [ "$ENHANCED_MODE" = true ]; then
        log_success "Enhanced mode active"
        log_info "Commands available: dotpush, sshpush, sshpull"
    else
        log_success "Standalone mode active"
        log_info "For enhanced mode, see: PRIVATE_SETUP.md"
    fi
    
    if [ -f "$HOME/.zshrc" ]; then
        log_info "Run 'source ~/.zshrc' or restart your shell to apply changes"
    else
        log_warning ".zshrc not found - changes will apply on next login"
    fi

    # Check if shell needs to be changed
    if [ "$(basename "$SHELL")" != "zsh" ] && command -v zsh &> /dev/null; then
        log_warning "Default shell is not zsh - logout/login required for change to take effect"
    fi

    if [ "$FROM_JOIN" = true ]; then
        log_complete "Dotfiles setup complete!"
        log_section "Next Steps" "$ROCKET"
        log_plain "${YELLOW}${INFO}${NC} To apply all changes, run:"
        log_plain "   ${CYAN}exec zsh${NC}  ${DIM}# Reload current shell${NC}"
        log_plain "   ${DIM}OR${NC}"
        log_plain "   ${CYAN}exit${NC}      ${DIM}# Start a new session${NC}"
        log_plain ""
    else
        log_complete "Dotfiles sync complete!"
    fi
else
    # In quiet mode, show compact summary
    mode_str="standalone"
    if [ "$ENHANCED_MODE" = true ]; then
        mode_str="enhanced"
    fi
    log_success "Dotfiles synced ($mode_str mode)"
fi
