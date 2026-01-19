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

    local UPDATE_SCRIPT="${DOTFILES_DIR}/lib/update-system.sh"

    if [[ ! -x "$UPDATE_SCRIPT" ]]; then
        log_error "Update script not found or not executable: $UPDATE_SCRIPT"
        return 1
    fi

    local LOG_FILE="${HOME}/.cache/updatep.log"
    mkdir -p "${HOME}/.cache"

    log_info "${COMPUTER} Running system update..."
    log_info "Output will be logged to: ${LOG_FILE}"
    log_info "${CYAN}Press Ctrl+B then D to detach if needed${NC}\n"

    local SESSION_NAME="system-update-$$"

    # Run the update script inside tmux, logging to file
    if ! tmux new-session -s "$SESSION_NAME" "$UPDATE_SCRIPT | tee $LOG_FILE"; then
         log_error "Failed to create tmux session. Is tmux installed?"
         return 1
    fi

    log_section "Process Summary" "$CHECK"
    log_success "System update process finished."
    log_info "${CYAN}${PARTY} Log saved to: ${LOG_FILE}${NC}"
    log_warning "View log: cat ${LOG_FILE}\n"

    return 0
}

if (( $+commands[yazi] )); then
	# cd to yazi selection
	y() {
		local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
		yazi "$@" --cwd-file="$tmp"
		if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
			builtin cd -- "$cwd"
		fi
		rm -f -- "$tmp"
	}
fi

if (( $+commands[pandoc] )); then
	# Opens rendered markdown as a temporary HTML file in the default browser
	mdv() {
		local input_file="$1"
		local output_file="/tmp/$(basename "$input_file").html"
		local css_file="${DOTFILES_DIR}/config/pandoc/github-dark.css"
		pandoc --standalone --embed-resources --css="$css_file" "$input_file" -o "$output_file"
		xdg-open "$output_file"
	}

	# Convert markdown to HTML in the same directory
	mdh() {
		local input_file="$1"
		local output_file="${input_file%.*}.html"
		local css_file="${DOTFILES_DIR}/config/pandoc/github-dark.css"
		pandoc --standalone --embed-resources --css="$css_file" "$input_file" -o "$output_file"
		echo "Converted $input_file to $output_file"
	}
fi

# Create directory and cd into it
mkd() {
    if [[ -d "$1" ]]; then
        echo "Directory '$1' already exists, navigating there..."
        builtin cd "$1"
    else
        mkdir -p "$1" && builtin cd "$1"
    fi
}

# Smart cd with zoxide fallback
cd() {
    # Go to home without arguments
    [ -z "$*" ] && builtin cd && return
    # If directory exists, change to it
    [ -d "$*" ] && builtin cd "$*" && return
    [ "$*" = "-" ] && builtin cd "$*" && return
    # Catch cd . and cd ..
    case "$*" in
        ..) builtin cd ..; return;;
        .) builtin cd .; return;;
    esac
    # Finally, call zoxide (using 'j' command as configured)
    j "$*" || builtin cd "$*"
}

# Dotfiles git push
dotpush() {
    # Check if enhanced mode is active (sshsync exists)
    if [[ ! -d "$HOME/sshsync/.git" ]]; then
        log_error "Enhanced mode not configured"
        log_info "dotpush requires SSH access to push changes"
        log_info ""
        log_info "To enable enhanced mode:"
        log_info "  1. Create ~/.config/dotfiles/dotfiles.env"
        log_info "  2. See: https://github.com/puckawayjeff/dotfiles/blob/main/PRIVATE_SETUP.md"
        return 1
    fi

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

        # Run sync.sh to update symlinks/config
        if [[ -f "./sync.sh" ]]; then
            log_info "\n${WRENCH} Running sync.sh..."
            ./sync.sh --quiet
        fi

        if [[ "$NO_EXEC" == "true" ]]; then
            log_success "\nDotfiles updated. Reload skipped (--no-exec)."
            cd "$ORIGINAL_DIR"
        else
            # Return to original directory before reloading shell
            cd "$ORIGINAL_DIR" || true
            # Reload shell configuration by replacing the process
            log_info "\n🔄 Reloading zsh configuration..."
            exec zsh
        fi
    else
        log_error "Git pull failed."
        cd "$ORIGINAL_DIR"
        return 1
    fi
}

# Add a new dotfile to the repo
# Usage: add-dotfile <source_path> [destination_path]
add-dotfile() {
    local file="$1"
    local custom_dest="$2"

    local sshsync_dir="$HOME/sshsync"
    local symlinks_conf="$sshsync_dir/symlinks.conf"

    if [[ ! -d "$sshsync_dir/.git" ]]; then
        log_error "Private sshsync repo not found at $sshsync_dir"
        log_info "add-dotfile requires a private repository for storage."
        return 1
    fi

    if [[ -z "$file" ]]; then
        log_error "No file path provided."
        log_plain "Usage: add-dotfile <path_to_dotfile> [destination_path]"
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

    # Determine destination path inside sshsync
    local dest_path
    if [[ -n "$custom_dest" ]]; then
        # Custom destination provided
        dest_path="$sshsync_dir/$custom_dest"
    else
        # Default: config/<basename>
        dest_path="$sshsync_dir/config/$basename"
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
        log_error "Destination '$dest_path' already exists in sshsync."
        return 1
    fi

    # Create destination directory if needed
    if [[ ! -d "$dest_dir" ]]; then
        log_step "Creating destination directory..." "$FOLDER"
        mkdir -p "$dest_dir"
    fi

    # Move file
    log_step "Moving file to sshsync repo..." "$WRENCH"
    mv "$source_path" "$dest_path"
    log_success "Moved to $dest_path"

    # Symlink back
    log_step "Creating symlink..." "$LINK"
    ln -s "$dest_path" "$source_path"
    log_success "Symlink created"

    # Update symlinks.conf
    log_step "Updating sshsync symlinks configuration..." "$PENCIL"

    # Replace literal home path with $HOME variable
    local install_target_path="${source_path/#$HOME/\$HOME}"
    # Convert dest_path to use $SSHSYNC_DIR variable
    local install_source_path="${dest_path/#$sshsync_dir/\$SSHSYNC_DIR}"
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
    log_step "Staging changes in sshsync..." "$PACKAGE"
    git -C "$sshsync_dir" add .

    log_complete "Successfully added '$dest_filename' to private repo!"
    log_plain "Next: sshpush 'Add $dest_filename'"
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

# Fuzzy directory change with preview
fcd() {
    local dir
    local fd_cmd

    if command -v fd &>/dev/null; then
        fd_cmd="fd"
    elif command -v fdfind &>/dev/null; then
        fd_cmd="fdfind"
    fi

    if [[ -n "$fd_cmd" ]]; then
        dir=$("$fd_cmd" --type d --hidden --follow --exclude .git . "${1:-.}" 2>/dev/null | \
            fzf --preview 'eza --tree --level=1 --color=always {} 2>/dev/null || ls -la {}' \
                --preview-window=right:50% \
                --height=80% \
                --border \
                --prompt="📁 Select directory: ")
    else
        dir=$(find "${1:-.}" -type d 2>/dev/null | \
            fzf --preview 'ls -la {}' \
                --preview-window=right:50% \
                --height=80% \
                --border \
                --prompt="📁 Select directory: ")
    fi

    [[ -n "$dir" ]] && cd "$dir"
}

# Find and edit - Search file contents and open in editor
fne() {
    local file line query="${*:-}"

    if ! command -v rg >/dev/null 2>&1; then
        log_error "ripgrep (rg) is required but not installed"
        return 1
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        log_error "fzf is required but not installed"
        return 1
    fi

    local result
    result=$(rg --line-number --no-heading --color=always --smart-case "${query}" 2>/dev/null | \
        fzf --ansi \
            --delimiter ':' \
            --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
            --height=80% \
            --border \
            --prompt="🔍 Search results: ")

    if [[ -n "$result" ]]; then
        file=$(echo "$result" | cut -d: -f1)
        line=$(echo "$result" | cut -d: -f2)

        if [[ -n "$file" && -n "$line" ]]; then
            ${EDITOR:-micro} "$file" +"$line"
        fi
    fi
}

# Pack directory into archive
dotpack() {
    if [[ -z "$1" ]]; then
        log_error "No directory specified."
        log_plain "Usage: dotpack <directory> [format]"
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
    local ORIGINAL_DIR="$PWD"

    log_section "Starting Maintenance Sequence" "$ROCKET"

    dotpull --no-exec
    if [[ $? -ne 0 ]]; then
        log_error "dotpull failed. Stopping."
        return 1
    fi

    log_success "Configuration updated."
    log_info "Launching system updates...\n"

    updatep

    cd "$ORIGINAL_DIR" || true

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
    printf "${CYAN}${PACKAGE} Puckadots Version:${NC} ${GREEN}v${VERSION}${NC}\n"

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        local COMMIT=$(git -C "$DOTFILES_DIR" rev-parse --short HEAD 2>/dev/null)
        local BRANCH=$(git -C "$DOTFILES_DIR" branch --show-current 2>/dev/null)
        if [[ -n "$COMMIT" ]]; then
            printf "${BLUE}   Branch:${NC} $BRANCH\n"
            printf "${BLUE}   Commit:${NC} $COMMIT\n"
        fi
    fi
}

dotkeys() {
    local DATA_FILE="$DOTFILES_DIR/config/keys.dat"
    local HR=$(get_hr)

    printf "\n${BOLD}${CYAN}${KEYBOARD}  KEYBOARD SHORTCUTS${NC}\n"
    printf "${BLUE}${HR}${NC}\n"

    if [[ ! -f "$DATA_FILE" ]]; then
        log_error "Keys data file not found: $DATA_FILE"
        return 1
    fi

    awk -F'|' -v green="${GREEN}" -v yellow="${YELLOW}" -v nc="${NC}" -v arrow="${ARROW}" -v bold="${BOLD}" '
    /^#/ || /^$/ { next }
    $1 != last_cat {
        if (last_cat != "") print ""
        print bold green $1 nc
        last_cat = $1
    }
    { printf "  %s%-20s%s %s %s\n", yellow, $2, nc, arrow, $3 }
    ' "$DATA_FILE"

    printf "\n${BLUE}${HR}${NC}\n"
    printf "${BOLD}${CYAN}💡 Tips:${NC}${MAGENTA} Type ${BOLD}${YELLOW}dothelp${NC}${MAGENTA} for commands${NC}\n\n"
}

dothelp() {
    local DATA_FILE="$DOTFILES_DIR/config/help.dat"
    local HR=$(get_hr)

    printf "\n${BOLD}${CYAN}${BOOK} DOTFILES COMMANDS & FUNCTIONS${NC}\n"
    printf "${BLUE}${HR}${NC}\n"

    if [[ ! -f "$DATA_FILE" ]]; then
        log_error "Help data file not found: $DATA_FILE"
        return 1
    fi

    # Filter out SSH commands if sshsync is not active
    local awk_filter=""
    if [[ ! -d "$HOME/sshsync/.git" ]]; then
        awk_filter='($2 ~ /^sshpush|^sshpull|^sshpack|^add-dotfile/) { next }'
    fi

    awk -F'|' -v green="${GREEN}" -v yellow="${YELLOW}" -v nc="${NC}" -v arrow="${ARROW}" -v bold="${BOLD}" '
    /^#/ || /^$/ { next }
    '"$awk_filter"'
    $1 != last_cat {
        if (last_cat != "") print ""
        print bold green $1 nc
        last_cat = $1
    }
    { printf "  %s%-25s%s %s %s\n", yellow, $2, nc, arrow, $3 }
    ' "$DATA_FILE"

    printf "\n${BLUE}${HR}${NC}\n"
    printf "${BOLD}${CYAN}💡 Tips:${NC}${MAGENTA} Type ${BOLD}${YELLOW}dotkeys${NC}${MAGENTA} for keyboard shortcuts${NC}\n"
    printf "         ${MAGENTA}Use ${BOLD}${YELLOW}--help${NC}${MAGENTA} with any command for colorized output${NC}\n\n"
}

if [[ -d "$HOME/sshsync/.git" ]]; then

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

        git add . && \
        git commit -m "$COMMIT_MSG" && \
        git push

        local EXIT_CODE=$?

        cd "$ORIGINAL_DIR" || {
            log_warning "Could not return to original directory: $ORIGINAL_DIR"
        }

        return $EXIT_CODE
    }

    sshpull() {
        local ORIGINAL_DIR="$PWD"
        local SSHSYNC_DIR="$HOME/sshsync"

        cd "$SSHSYNC_DIR" || {
            log_error "Could not change to ~/sshsync directory"
            return 1
        }

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

else
    sshpush() {
        log_error "Enhanced mode not configured"
        log_info "sshpush requires a private sshsync repository"
        log_info ""
        log_info "To enable enhanced mode:"
        log_info "  1. Create ~/.config/dotfiles/dotfiles.env"
        log_info "  2. See: https://github.com/puckawayjeff/dotfiles/blob/main/PRIVATE_SETUP.md"
        return 1
    }

    sshpull() {
        log_error "Enhanced mode not configured"
        log_info "sshpull requires a private sshsync repository"
        log_info ""
        log_info "To enable enhanced mode:"
        log_info "  1. Create ~/.config/dotfiles/dotfiles.env"
        log_info "  2. See: https://github.com/puckawayjeff/dotfiles/blob/main/PRIVATE_SETUP.md"
        return 1
    }
fi

sshpack() {
    log_section "SSH Keys Packaging" "$PACKAGE"

    if [ ! -d "$HOME/.ssh" ]; then
        log_error "~/.ssh directory does not exist"
        return 1
    fi

    local SSH_KEY_FILES=$(find "$HOME/.ssh" -type f \( -name "id_*" ! -name "*.pub" \) 2>/dev/null || true)
    local SSH_PUB_FILES=$(find "$HOME/.ssh" -type f -name "id_*.pub" 2>/dev/null || true)

    if [ -z "$SSH_KEY_FILES" ]; then
        log_error "No SSH keys found in ~/.ssh"
        log_info "Generate keys with: ssh-keygen -t ed25519 -C \"your@email.com\""
        return 1
    fi

    log_info "Found SSH keys:"
    echo "$SSH_KEY_FILES" | while read -r keyfile; do
        echo "   • $(basename "$keyfile")"
    done
    echo "$SSH_PUB_FILES" | while read -r keyfile; do
        echo "   • $(basename "$keyfile")"
    done
    echo ""

    local PASSWORD="$1"
    if [ -z "$PASSWORD" ]; then
        log_warning "No password provided as argument"
        printf "Enter password for encryption: "
        read -s PASSWORD
        echo ""
        if [ -z "$PASSWORD" ]; then
            log_error "Password cannot be empty"
            return 1
        fi
        printf "Confirm password: "
        local PASSWORD_CONFIRM
        read -s PASSWORD_CONFIRM
        echo ""
        if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
            log_error "Passwords do not match"
            return 1
        fi
    fi

    if [ ${#PASSWORD} -lt 12 ]; then
        log_warning "Password is shorter than 12 characters. Consider using a stronger password."
        printf "Continue anyway? (y/N): "
        local CONTINUE
        read -r CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            return 0
        fi
    fi

    local TEMP_DIR=$(mktemp -d)
    local cleanup() {
        rm -rf "$TEMP_DIR"
    }
    trap cleanup EXIT INT TERM

    log_info "Creating archive..."

    mkdir -p "$TEMP_DIR/ssh"
    find "$HOME/.ssh" -type f \( -name "id_*" \) -exec cp {} "$TEMP_DIR/ssh/" \;

    local FILE_COUNT=$(find "$TEMP_DIR/ssh" -type f | wc -l)

    (cd "$TEMP_DIR" && tar -czf ssh-keys.tar.gz ssh/)

    openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in "$TEMP_DIR/ssh-keys.tar.gz" -out "$TEMP_DIR/ssh-keys.tar.gz.enc" -pass pass:"$PASSWORD"

    local OUTPUT_FILE="$HOME/ssh-keys.tar.gz.enc"
    mv "$TEMP_DIR/ssh-keys.tar.gz.enc" "$OUTPUT_FILE"

    local FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

    log_success "Archive created successfully!"
    echo ""
    log_info "Archive details:"
    echo "   • Location: $OUTPUT_FILE"
    echo "   • Files packaged: $FILE_COUNT"
    echo "   • Size: $FILE_SIZE"
    echo ""

    log_info "Verifying archive..."
    local VERIFY_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR $VERIFY_DIR" EXIT INT TERM

    if openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in "$OUTPUT_FILE" -out "$VERIFY_DIR/test.tar.gz" -pass pass:"$PASSWORD" 2>/dev/null; then
        if tar -tzf "$VERIFY_DIR/test.tar.gz" >/dev/null 2>&1; then
            log_success "Archive verified successfully"
            echo ""
            log_info "Contents:"
            tar -tzf "$VERIFY_DIR/test.tar.gz" | sed 's/^/   • /'
        else
            log_error "Archive verification failed - tar extraction failed"
            return 1
        fi
    else
        log_error "Archive verification failed - decryption failed"
        return 1
    fi

    echo ""
    log_info "Next steps:"
    echo "   1. Upload $OUTPUT_FILE to your secure web server"
    echo "   2. Note the URL where it's accessible"
    echo "   3. Add URL and password to your dotfiles.env file:"
    echo ""
    echo "      SSH_KEYS_ARCHIVE_URL=\"https://example.com/path/to/ssh-keys.tar.gz.enc\""
    echo "      SSH_KEYS_ARCHIVE_PASSWORD=\"<your-password>\""
    echo ""
    log_warning "Keep this file and password secure! Anyone with both can access your SSH keys."
    echo ""
}

sshlist() {
    log_section "SSH Configured Hosts" "$COMPUTER"

    local -a hosts
    local found_any=false

    if [[ -f ~/.ssh/config ]]; then
        local config_hosts=$(grep -i "^Host " ~/.ssh/config | grep -v "*" | grep -v "github.com" | awk '{print $2}' | sort -u)
        if [[ -n "$config_hosts" ]]; then
            log_info "${FOLDER} From ~/.ssh/config:"
            echo "$config_hosts" | while read -r host; do
                printf "   ${CYAN}•${NC} %s\n" "$host"
            done
            echo ""
            found_any=true
        fi
    fi

    if [[ "$found_any" = false ]]; then
        log_warning "No SSH hosts found in config files"
        log_info "Add hosts to ~/.ssh/config"
        echo ""
        log_plain "Example entry:"
        log_substep "Host myserver"
        log_substep "    HostName 192.168.1.100"
        log_substep "    User username"
        log_substep "    Port 22"
        echo ""
    fi
}
