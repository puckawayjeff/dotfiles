#!/usr/bin/env bash

set +e

QUIET_MODE=false
FROM_JOIN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet|-q) QUIET_MODE=true; shift ;;
        --from-join) FROM_JOIN=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

export QUIET_MODE
export FROM_JOIN

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DOTFILES_DIR
export SSHSYNC_DIR="$HOME/sshsync"

if [ -f "$DOTFILES_DIR/lib/utils.sh" ]; then
    source "$DOTFILES_DIR/lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

if [ -f "$DOTFILES_DIR/lib/os.sh" ]; then
    source "$DOTFILES_DIR/lib/os.sh"
else
    echo "Error: lib/os.sh not found."
    exit 1
fi

if [[ "$FROM_JOIN" == "true" ]]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Starting dotfiles sync (first-time setup)" "$ROCKET"
    fi
else
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Syncing dotfiles" "$ROCKET"
    fi
    
    if [ -d "$DOTFILES_DIR/.git" ]; then
        [[ "$QUIET_MODE" != "true" ]] && log_info "Pulling latest dotfiles changes..."
        cd "$DOTFILES_DIR"
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            git stash push -m "Auto-stash before sync on $(date '+%Y-%m-%d %H:%M:%S')" &>/dev/null
        fi
        GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull &>/dev/null
        cd - >/dev/null
    fi
    
    if [ -d "$SSHSYNC_DIR/.git" ]; then
        [[ "$QUIET_MODE" != "true" ]] && log_info "Pulling latest sshsync changes..."
        cd "$SSHSYNC_DIR"
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            git stash push -m "Auto-stash before sync on $(date '+%Y-%m-%d %H:%M:%S')" &>/dev/null
        fi
        GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull &>/dev/null
        cd - >/dev/null
    fi
fi

ENHANCED_MODE=false
if [ -d "$SSHSYNC_DIR/.git" ]; then
    ENHANCED_MODE=true
fi

if [ "$ENHANCED_MODE" = false ] && [ "$FROM_JOIN" = true ]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Git Configuration" "$WRENCH"
    fi
    if ! git config --global user.name > /dev/null 2>&1; then
        log_info "Setting default git user.name..."
        git config --global user.name "dotfiles-user"
    fi
    if ! git config --global user.email > /dev/null 2>&1; then
        log_info "Setting default git user.email..."
        git config --global user.email "dotfiles@change.me"
    fi
fi

if [ "$ENHANCED_MODE" = true ]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "SSH Configuration" "$WRENCH"
    fi
    
    SSH_CONFIG_SOURCE="$SSHSYNC_DIR/ssh.conf"
    SSH_CONFIG_TARGET="$HOME/.ssh/config"
    
    if [ -f "$SSH_CONFIG_SOURCE" ]; then
        if [ -L "$SSH_CONFIG_TARGET" ] && [ "$(readlink "$SSH_CONFIG_TARGET")" = "$SSH_CONFIG_SOURCE" ]; then
            [[ "$QUIET_MODE" != "true" ]] && log_success "SSH config already linked"
        else
            if [ -f "$SSH_CONFIG_TARGET" ] && [ ! -L "$SSH_CONFIG_TARGET" ]; then
                mv "$SSH_CONFIG_TARGET" "$SSH_CONFIG_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
                log_info "Backed up existing SSH config"
            fi
            ln -sf "$SSH_CONFIG_SOURCE" "$SSH_CONFIG_TARGET"
            log_success "SSH config linked from sshsync"
        fi
    else
        log_warning "sshsync/ssh.conf not found - SSH config not updated"
    fi
fi

if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "Core Utilities Installation" "$PACKAGE"
fi

pkg_update

CORE_UTILS=(
    "curl"
    "wget"
    "git"
    "sudo"
    "unzip"
    "rsync"
    "tree"
)

case "$PKG_MANAGER" in
    apt)
        CORE_UTILS+=("bat" "p7zip-full" "rename") 
        ;;
    dnf)
        CORE_UTILS+=("bat" "p7zip" "prename")
        ;;
    pacman)
        CORE_UTILS+=("bat" "p7zip" "perl-rename")
        ;;
    apk)
        CORE_UTILS+=("bat" "7zip" "util-linux")
        ;;
esac

pkg_install "${CORE_UTILS[@]}"

if [ "$PKG_MANAGER" = "apt" ]; then
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf $(which batcat) ~/.local/bin/bat
    fi
fi

if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "Terminal Utilities" "$COMPUTER"
fi
if [ -f "$DOTFILES_DIR/lib/terminal.sh" ]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_info "Running terminal utilities installer..."
    fi
    bash "$DOTFILES_DIR/lib/terminal.sh"
else
    log_warning "lib/terminal.sh not found, skipping terminal setup"
fi

if [ -f "/etc/update-motd.d/99-dotfiles" ]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_info "Removing legacy MOTD script..."
    fi
    sudo rm -f "/etc/update-motd.d/99-dotfiles" 2>/dev/null
fi

process_symlinks() {
    local config_file="$1"
    local config_name="$2"
    
    if [ -f "$config_file" ] && [ -s "$config_file" ]; then
        log_info "Processing $config_name symlinks..."
        
        local created=0
        local skipped=0
        
        while IFS=: read -r source target || [ -n "$source" ]; do
            [[ -z "$source" || "$source" =~ ^[[:space:]]*# ]] && continue
            
            source=$(eval echo "$source")
            target=$(eval echo "$target")
            
            local target_dir=$(dirname "$target")
            if [[ ! -d "$target_dir" ]]; then
                mkdir -p "$target_dir"
            fi
            
            if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
                log_substep "$(basename "$target") - already linked"
                skipped=$((skipped + 1))
            else
                if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
                    local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
                    mv "$target" "$backup"
                    log_substep "$(basename "$target") - backed up existing file"
                fi
                
                ln -sf "$source" "$target"
                log_substep "$(basename "$target") - linked"
                created=$((created + 1))
            fi
        done < "$config_file"
        
        if [ $created -gt 0 ]; then
            log_success "Created/updated $created symlink(s)"
        fi
    fi
}

if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "Configuration Symlinks" "$WRENCH"
fi

process_symlinks "$DOTFILES_DIR/config/symlinks.conf" "Public"
process_symlinks "$SSHSYNC_DIR/symlinks.conf" "Private"

if [[ "$QUIET_MODE" != "true" ]]; then
    log_section "Sync Complete" "$PARTY"
    
    if [ "$ENHANCED_MODE" = true ]; then
        log_success "Enhanced mode active"
    else
        log_success "Standalone mode active"
    fi
    
    if [ -f "$HOME/.zshrc" ]; then
        log_info "Run 'source ~/.zshrc' or restart your shell to apply changes"
    else
        log_warning ".zshrc not found - changes will apply on next login"
    fi

    if [ "$(basename "$SHELL")" != "zsh" ] && command -v zsh &> /dev/null; then
        log_warning "Default shell is not zsh - logout/login required for change to take effect"
    fi

    if [ "$FROM_JOIN" = true ]; then
        log_complete "Puckadots setup complete!"
        log_section "Next Steps" "$ROCKET"
        log_plain "${YELLOW}${INFO}${NC} To apply all changes, run:"
        log_plain "   ${CYAN}exec zsh${NC}  ${DIM}# Reload current shell${NC}"
        log_plain "   ${DIM}OR${NC}"
        log_plain "   ${CYAN}exit${NC}      ${DIM}# Start a new session${NC}"
        log_plain ""
    else
        log_complete "Puckadots sync complete!"
    fi
else
    mode_str="standalone"
    if [ "$ENHANCED_MODE" = true ]; then
        mode_str="enhanced"
    fi
    log_success "Puckadots synced ($mode_str mode)"
fi
