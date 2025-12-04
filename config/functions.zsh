# config/functions.zsh - Custom Zsh functions
# Sourced by .zshrc

# Source shared utilities (colors, emojis, logging functions)
DOTFILES_DIR="${HOME}/dotfiles"
source "${DOTFILES_DIR}/lib/utils.sh"

autoload -U colors && colors

# --- Functions ---

# Update system packages
updatep() {
    log_section "Starting system update process" "$ROCKET"
    
    # Check for tmux
    if ! command -v tmux &> /dev/null; then
        log_warning "${WRENCH} tmux not found. Attempting to install..."
        log_info "Running 'sudo apt update' first..."
        if ! sudo apt update; then
            log_error "'sudo apt update' failed."
            return 1
        fi
        if ! sudo apt install tmux -y; then
            log_error "tmux installation failed."
            return 1
        fi
        log_success "tmux installed successfully."
    else
        log_success "tmux is already installed."
    fi
    
    local LOG_FILE="${HOME}/.cache/updatep.log"
    mkdir -p "${HOME}/.cache"
    
    log_info "${COMPUTER} Running system update..."
    log_info "Output will be logged to: ${LOG_FILE}"
    log_info "${CYAN}Press Ctrl+B then D to detach if needed${NC}\n"
    
    local SESSION_NAME="system-update-$$"
    
    # Create a temporary script file
    local SCRIPT_FILE="/tmp/updatep-${SESSION_NAME}.sh"
    cat > "$SCRIPT_FILE" << 'SCRIPT_EOF'
#!/bin/bash
LOG_FILE="$1"

# Use script command to log everything while displaying to terminal
script -q -c '
    echo "--- Starting System Updates ---"
    echo "Timestamp: $(date "+%Y-%m-%d %H:%M:%S")"
    echo ""
    echo "Running: sudo apt update"
    sudo apt update
    echo ""
    echo "Running: sudo apt full-upgrade -y"
    sudo apt full-upgrade -y
    echo ""
    echo "Running: sudo apt autoremove -y"
    sudo apt autoremove -y
    echo ""
    
    # Update flatpak if available
    if command -v flatpak &> /dev/null; then
        echo "Running: flatpak update -y"
        flatpak update -y
        echo ""
    fi
    
    echo "--- Update Process Finished ---"
    echo "Timestamp: $(date "+%Y-%m-%d %H:%M:%S")"
' "$LOG_FILE"
SCRIPT_EOF
    chmod +x "$SCRIPT_FILE"
    
    if ! tmux new-session -s "$SESSION_NAME" "$SCRIPT_FILE '$LOG_FILE'"; then
         log_error "Failed to create tmux session."
         rm -f "$SCRIPT_FILE"
         return 1
    fi
    
    # Cleanup script file after session ends
    rm -f "$SCRIPT_FILE"
    
    log_section "Process Summary" "$CHECK"
    log_success "System update completed successfully."
    log_info "${CYAN}${PARTY} Log saved to: ${LOG_FILE}${NC}"
    log_warning "View log: cat ${LOG_FILE}\n"
    
    return 0
}

# Create directory and cd into it
mkd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

# Dotfiles git push
dotpush() {
    local ORIGINAL_DIR="$PWD"
    local COMMIT_MSG="$1"
    
    if [[ -z "$COMMIT_MSG" ]]; then
        printf "Enter commit message: "
        read -r COMMIT_MSG
        if [[ -z "$COMMIT_MSG" ]]; then
            log_error "No commit message provided. Aborting."
            return 1
        fi
    fi
    
    cd "$HOME/dotfiles" || {
        log_error "Could not change to ~/dotfiles directory"
        return 1
    }
    
    git add . && \
    git commit -m "$COMMIT_MSG" && \
    git push
    
    local EXIT_CODE=$?
    
    cd "$ORIGINAL_DIR" || {
        log_warning "Could not return to original directory: $ORIGINAL_DIR"
    }
    
    return $EXIT_CODE
}

# Dotfiles git pull (Enhanced)
dotpull() {
    local ORIGINAL_DIR="$PWD"
    local DOTFILES_DIR="$HOME/dotfiles"
    local NO_EXEC=false

    # Parse arguments
    if [[ "$1" == "-n" || "$1" == "--no-exec" ]]; then
        NO_EXEC=true
    fi
    
    cd "$DOTFILES_DIR" || {
        log_error "Could not change to ~/dotfiles directory"
        return 1
    }
    
    # Auto-stash if needed
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_warning "⚠️  Local changes detected. Stashing..."
        git stash push -m "Auto-stash before pull on $(date '+%Y-%m-%d %H:%M:%S')"
        log_substep "Local changes stashed. Use 'git stash pop' to restore them."
    fi
    
    log_info "⬇️  Pulling latest changes..."
    if GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull; then
        log_success "Git pull successful."
        
        # Run install.sh to update symlinks/config
        if [[ -f "./install.sh" ]]; then
            log_info "\n${WRENCH} Running install.sh..."
            ./install.sh --quiet
        fi
        
        if [[ "$NO_EXEC" == "true" ]]; then
            log_success "\nDotfiles updated. Reload skipped (--no-exec)."
        else
            # Reload shell configuration by replacing the process
            log_info "\n🔄 Reloading zsh configuration..."
            exec zsh
        fi
    else
        log_error "Git pull failed."
        cd "$ORIGINAL_DIR"
        return 1
    fi
    
    cd "$ORIGINAL_DIR"
}

# Add a new dotfile to the repo
# Usage: add-dotfile <source_path> [destination_path]
# Examples:
#   add-dotfile ~/.gitconfig
#   add-dotfile ~/.config/tmux/tmux.conf
#   add-dotfile ~/.bashrc config/.bashrc.backup
add-dotfile() {
    local file="$1"
    local custom_dest="$2"
    
    if [[ -z "$file" ]]; then
        log_error "No file path provided."
        log_plain "Usage: add-dotfile <path_to_dotfile> [destination_path]"
        log_plain ""
        log_plain "Examples:"
        log_substep "add-dotfile ~/.gitconfig"
        log_substep "add-dotfile ~/.config/tmux/tmux.conf"
        log_substep "add-dotfile ~/.bashrc config/.bashrc.backup"
        return 1
    fi
    
    # Check if file is already a symlink
    if [[ -L "$file" ]]; then
        local link_target=$(readlink "$file")
        log_error "Source '$file' is already a symlink."
        log_substep "Target: $link_target"
        return 1
    fi
    
    local source_path=$(realpath "$file")
    local basename=$(basename "$source_path")
    local dotfiles_dir="$HOME/dotfiles"
    local install_script="$dotfiles_dir/install.sh"
    
    # Determine destination path
    local dest_path
    if [[ -n "$custom_dest" ]]; then
        # Custom destination provided
        if [[ "$custom_dest" = /* ]]; then
            # Absolute path
            dest_path="$custom_dest"
        else
            # Relative path (relative to dotfiles dir)
            dest_path="$dotfiles_dir/$custom_dest"
        fi
    else
        # Default: config/<basename>
        dest_path="$dotfiles_dir/config/$basename"
    fi
    
    # Get the directory part and filename part
    local dest_dir=$(dirname "$dest_path")
    local dest_filename=$(basename "$dest_path")
    
    # Validation
    if [[ ! -e "$source_path" ]]; then
        log_error "Source '$source_path' does not exist."
        return 1
    fi
    
    # Check if source is a directory
    if [[ -d "$source_path" ]]; then
        log_error "Source '$source_path' is a directory."
        log_plain "This function currently only supports files."
        log_plain "To add a directory, manually move it and create the symlink."
        return 1
    fi
    
    if [[ -e "$dest_path" ]]; then
        log_error "Destination '$dest_path' already exists."
        return 1
    fi
    
    if [[ ! -f "$install_script" ]]; then
        log_error "install.sh not found."
        return 1
    fi
    
    # Create destination directory if needed
    if [[ ! -d "$dest_dir" ]]; then
        log_step "Creating destination directory..." "$FOLDER"
        mkdir -p "$dest_dir"
    fi
    
    # Move file
    log_step "Moving file to repo..." "$WRENCH"
    mv "$source_path" "$dest_path"
    log_success "Moved to $dest_path"
    
    # Symlink back
    log_step "Creating symlink..." "$LINK"
    ln -s "$dest_path" "$source_path"
    log_success "Symlink created"
    
    # Update symlinks.conf
    log_step "Updating symlinks configuration..." "$PENCIL"
    
    local symlinks_conf="$dotfiles_dir/config/symlinks.conf"
    
    # Replace literal home path with $HOME variable
    local install_target_path="${source_path/#$HOME/\$HOME}"
    # Convert dest_path to use $DOTFILES_DIR
    local install_source_path="${dest_path/#$dotfiles_dir/\$DOTFILES_DIR}"
    local new_entry="$install_source_path:$install_target_path"
    
    # Check if entry already exists
    if grep -qF "$new_entry" "$symlinks_conf" 2>/dev/null; then
        log_warning "${WARNING}  Entry already exists in symlinks.conf"
    else
        # Append to config file
        echo "$new_entry" >> "$symlinks_conf"
        log_success "Added to symlinks.conf"
    fi
    
    # Stage changes
    log_step "Staging changes..." "$PACKAGE"
    # Get relative path from dotfiles_dir for git add
    local git_add_path="${dest_path/#$dotfiles_dir\/}"
    git -C "$dotfiles_dir" add "$git_add_path" "config/symlinks.conf"
    
    log_complete "Successfully added '$dest_filename'!"
    log_plain "Next: dotpush 'Add $dest_filename'"
}

# Run dotfiles setup scripts
dotsetup() {
    local SETUP_DIR="$HOME/dotfiles/setup"
    
    if [[ -z "$1" ]]; then
        log_info "${PACKAGE} Available setup scripts:"
        if [[ -d "$SETUP_DIR" ]]; then
            for script in "$SETUP_DIR"/*.sh; do
                if [[ -f "$script" ]]; then
                    local script_name=$(basename "$script" .sh)
                    if [[ ! "$script_name" =~ ^_ ]]; then
                        log_substep "${script_name}"
                    fi
                fi
            done
        else
            log_error "Setup directory not found: $SETUP_DIR"
            return 1
        fi
        return 0
    fi
    
    local SCRIPT_NAME="$1"
    local SCRIPT_PATH="$SETUP_DIR/${SCRIPT_NAME}.sh"
    
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        log_error "Setup script '${SCRIPT_NAME}' not found."
        return 1
    fi
    
    if [[ ! -x "$SCRIPT_PATH" ]]; then
        chmod +x "$SCRIPT_PATH"
    fi
    
    log_section "Running setup script: ${SCRIPT_NAME}" "$ROCKET"
    bash "$SCRIPT_PATH"
}

# Check PATH validity
paths() {
    log_section "Checking PATH entries" "$COMPUTER"
    
    echo $PATH | tr ':' '\n' | while read -r path; do
        if [[ -d "$path" ]]; then
            printf "${GREEN}${CHECK}${NC} $path\n"
        else
            printf "${RED}${CROSS}${NC} $path\n"
            log_warning "PATH entry does not exist: $path" >&2
        fi
    done
}

# Pack directory into archive
packk() {
    if [[ -z "$1" ]]; then
        log_error "No directory specified."
        log_plain "Usage: packk <directory> [format]"
        log_plain "Formats: tar.gz (default), zip, 7z"
        return 1
    fi
    
    local SOURCE_DIR="$1"
    local FORMAT="${2:-tar.gz}"
    
    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_error "Directory '$SOURCE_DIR' does not exist."
        return 1
    fi
    
    if [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
        log_error "Directory '$SOURCE_DIR' is empty."
        return 1
    fi
    
    local DIR_NAME=$(basename "$SOURCE_DIR")
    local ARCHIVE_NAME=""
    
    case "$FORMAT" in
        tar.gz)
            ARCHIVE_NAME="${DIR_NAME}.tar.gz"
            if ! command -v tar &> /dev/null; then
                log_error "'tar' is not installed."
                return 1
            fi
            ;;
        zip)
            ARCHIVE_NAME="${DIR_NAME}.zip"
            if ! command -v zip &> /dev/null; then
                log_error "'zip' is not installed."
                return 1
            fi
            ;;
        7z)
            ARCHIVE_NAME="${DIR_NAME}.7z"
            if ! command -v 7z &> /dev/null; then
                log_error "'7z' is not installed."
                return 1
            fi
            ;;
        *)
            log_error "Unsupported format '$FORMAT'."
            log_plain "Supported formats: tar.gz, zip, 7z"
            return 1
            ;;
    esac
    
    if [[ -f "$ARCHIVE_NAME" ]]; then
        log_warning "⚠️  Archive '$ARCHIVE_NAME' already exists."
        printf "Overwrite? [y/N]: "
        read -r RESPONSE
        if [[ ! "$RESPONSE" =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled."
            return 0
        fi
    fi
    
    log_section "Creating archive" "$ROCKET"
    
    case "$FORMAT" in
        tar.gz)
            if tar -czf "$ARCHIVE_NAME" "$SOURCE_DIR"; then
                log_success "Created: $ARCHIVE_NAME"
            else
                log_error "Failed to create archive."
                return 1
            fi
            ;;
        zip)
            if zip -r "$ARCHIVE_NAME" "$SOURCE_DIR" > /dev/null; then
                log_success "Created: $ARCHIVE_NAME"
            else
                log_error "Failed to create archive."
                return 1
            fi
            ;;
        7z)
            if 7z a "$ARCHIVE_NAME" "$SOURCE_DIR" > /dev/null; then
                log_success "Created: $ARCHIVE_NAME"
            else
                log_error "Failed to create archive."
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Maintenance sequence
maintain() {
    log_section "Starting Maintenance Sequence" "$ROCKET"
    
    # Run dotpull without reloading shell immediately
    # (dotpull already uses --quiet for install.sh)
    dotpull --no-exec
    if [[ $? -ne 0 ]]; then
        log_error "dotpull failed. Stopping."
        return 1
    fi
    
    # Note: install.sh is already run by dotpull (in quiet mode)
    
    log_success "Configuration updated."
    log_info "Launching system updates...\n"
    
    updatep
    
    # Reload shell at the very end
    log_info "\n🔄 Reloading zsh configuration..."
    exec zsh
}

# Display dotfiles version
dotversion() {
    local DOTFILES_DIR="$HOME/dotfiles"
    local VERSION_FILE="$DOTFILES_DIR/VERSION"
    
    if [[ ! -f "$VERSION_FILE" ]]; then
        log_error "VERSION file not found."
        return 1
    fi
    
    local VERSION=$(cat "$VERSION_FILE")
    printf "${CYAN}${PACKAGE} Dotfiles Version:${NC} ${GREEN}v${VERSION}${NC}\n"
    
    # Optional: Show git info if available
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        local COMMIT=$(git -C "$DOTFILES_DIR" rev-parse --short HEAD 2>/dev/null)
        local BRANCH=$(git -C "$DOTFILES_DIR" branch --show-current 2>/dev/null)
        if [[ -n "$COMMIT" ]]; then
            printf "${BLUE}   Branch:${NC} $BRANCH\n"
            printf "${BLUE}   Commit:${NC} $COMMIT\n"
        fi
    fi
}

# ===== SSH Sync Functions (Optional - only loaded if sshsync repo exists) =====
if [[ -d "$HOME/sshsync/.git" ]]; then
    
    # SSH config git push
    sshpush() {
        local ORIGINAL_DIR="$PWD"
        local COMMIT_MSG="$1"
        
        if [[ -z "$COMMIT_MSG" ]]; then
            printf "Enter commit message: "
            read -r COMMIT_MSG
            if [[ -z "$COMMIT_MSG" ]]; then
                log_error "No commit message provided. Aborting."
                return 1
            fi
        fi
        
        cd "$HOME/sshsync" || {
            log_error "Could not change to ~/sshsync directory"
            return 1
        }
        
        # Discard local changes to ssh.conf (will be overwritten by symlink anyway)
        git checkout -- ssh.conf 2>/dev/null || true
        
        git add . && \
        git commit -m "$COMMIT_MSG" && \
        git push
        
        local EXIT_CODE=$?
        
        cd "$ORIGINAL_DIR" || {
            log_warning "Could not return to original directory: $ORIGINAL_DIR"
        }
        
        return $EXIT_CODE
    }
    
    # SSH config git pull
    sshpull() {
        local ORIGINAL_DIR="$PWD"
        local SSHSYNC_DIR="$HOME/sshsync"
        
        cd "$SSHSYNC_DIR" || {
            log_error "Could not change to ~/sshsync directory"
            return 1
        }
        
        # Discard local changes to ssh.conf (will be overwritten by symlink anyway)
        git checkout -- ssh.conf 2>/dev/null || true
        
        log_info "⬇️  Pulling latest SSH config changes..."
        if GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull; then
            log_success "SSH config updated successfully."
        else
            log_error "Git pull failed."
            cd "$ORIGINAL_DIR"
            return 1
        fi
        
        cd "$ORIGINAL_DIR"
    }
    
fi
