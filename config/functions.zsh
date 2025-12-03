# config/functions.zsh - Custom Zsh functions
# Sourced by .zshrc

# --- Helper for Colors ---
# We can reuse the logic from utils.sh if we want, or just define simple vars here for zsh
# Zsh has built-in color support via %F{color} in print -P, or standard ANSI codes.
# Let's stick to standard ANSI for consistency with bash scripts where possible, 
# or use tput if we want to be robust.
autoload -U colors && colors

# --- Functions ---

# Update system packages
updatep() {
    # Define colors and emojis
    local GREEN YELLOW BLUE CYAN RED NC
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
    
    local ROCKET="🚀" WRENCH="🔧" CHECK="✅" CROSS="❌" COMPUTER="💻" PARTY="🎉"
    
    printf "${CYAN}${ROCKET} Starting system update process...${NC}\n"
    
    # Check for tmux
    if ! command -v tmux &> /dev/null; then
        printf "${YELLOW}${WRENCH} tmux not found. Attempting to install...${NC}\n"
        printf "Running 'sudo apt update' first...\n"
        if ! sudo apt update; then
            printf "${RED}${CROSS} Error: 'sudo apt update' failed.${NC}\n"
            return 1
        fi
        if ! sudo apt install tmux -y; then
            printf "${RED}${CROSS} Error: tmux installation failed.${NC}\n"
            return 1
        fi
        printf "${GREEN}${CHECK} tmux installed successfully.${NC}\n"
    else
        printf "${GREEN}${CHECK} tmux is already installed.${NC}\n"
    fi
    
    printf "${BLUE}${COMPUTER} Launching update in a new tmux session...${NC}\n"
    printf "You will be attached to the session. It will close on completion.\n"
    
    local UPDATE_CMD="
        printf '${GREEN}--- Starting System Updates ---${NC}\n\n';
        printf '${CYAN}Running: sudo apt update${NC}\n';
        sudo apt update && \\
        printf '\n${CYAN}Running: sudo apt full-upgrade -y${NC}\n';
        sudo apt full-upgrade -y && \\
        printf '\n${CYAN}Running: sudo apt autoremove -y${NC}\n';
        sudo apt autoremove -y;
        printf '\n${GREEN}--- Update Process Finished ---${NC}\n';
        printf 'Please review any messages above.\n';
        printf '${YELLOW}Session will close in 10 seconds (press any key to close now)...${NC}\n';
        read -n 1 -s -r -t 10;
    "
    
    local SESSION_NAME="system-update-$$"
    
    if ! tmux new-session -s "$SESSION_NAME" "bash -c \"$UPDATE_CMD\""; then
         printf "${RED}${CROSS} Error: Failed to create tmux session.${NC}\n"
         return 1
    fi
    
    printf "\n${BLUE}========== Process Summary ==========${NC}\n"
    printf "${GREEN}${CHECK} tmux update session has been closed.${NC}\n"
    printf "${CYAN}${PARTY} System maintenance task complete!${NC}\n\n"
    
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
            printf "No commit message provided. Aborting.\n"
            return 1
        fi
    fi
    
    cd "$HOME/dotfiles" || {
        printf "Error: Could not change to ~/dotfiles directory\n"
        return 1
    }
    
    git add . && \
    git commit -m "$COMMIT_MSG" && \
    git push
    
    local EXIT_CODE=$?
    
    cd "$ORIGINAL_DIR" || {
        printf "Warning: Could not return to original directory: $ORIGINAL_DIR\n"
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
        printf "Error: Could not change to ~/dotfiles directory\n"
        return 1
    }
    
    # Auto-stash if needed
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        printf "⚠️  Local changes detected. Stashing...\n"
        git stash push -m "Auto-stash before pull on $(date '+%Y-%m-%d %H:%M:%S')"
        printf "   ↳ Local changes stashed. Use 'git stash pop' to restore them.\n"
    fi
    
    printf "⬇️  Pulling latest changes...\n"
    if git pull; then
        printf "✅ Git pull successful.\n"
        
        # Run install.sh to update symlinks/config
        if [[ -f "./install.sh" ]]; then
            printf "\n🔧 Running install.sh...\n"
            ./install.sh
        fi
        
        if [[ "$NO_EXEC" == "true" ]]; then
            printf "\n✅ Dotfiles updated. Reload skipped (--no-exec).\n"
        else
            # Reload shell configuration by replacing the process
            printf "\n🔄 Reloading zsh configuration...\n"
            exec zsh
        fi
    else
        printf "❌ Error: Git pull failed.\n"
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
        print -P "%F{red}❌ Error: No file path provided.%f"
        print "Usage: add-dotfile <path_to_dotfile> [destination_path]"
        print ""
        print "Examples:"
        print "  add-dotfile ~/.gitconfig"
        print "  add-dotfile ~/.config/tmux/tmux.conf"
        print "  add-dotfile ~/.bashrc config/.bashrc.backup"
        return 1
    fi
    
    # Check if file is already a symlink
    if [[ -L "$file" ]]; then
        local link_target=$(readlink "$file")
        print -P "%F{red}❌ Error: Source '$file' is already a symlink.%f"
        print -P "   Target: $link_target"
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
        print -P "%F{red}❌ Error: Source '$source_path' does not exist.%f"
        return 1
    fi
    
    # Check if source is a directory
    if [[ -d "$source_path" ]]; then
        print -P "%F{red}❌ Error: Source '$source_path' is a directory.%f"
        print "This function currently only supports files."
        print "To add a directory, manually move it and create the symlink."
        return 1
    fi
    
    if [[ -e "$dest_path" ]]; then
        print -P "%F{red}❌ Error: Destination '$dest_path' already exists.%f"
        return 1
    fi
    
    if [[ ! -f "$install_script" ]]; then
        print -P "%F{red}❌ Error: install.sh not found.%f"
        return 1
    fi
    
    # Create destination directory if needed
    if [[ ! -d "$dest_dir" ]]; then
        print -P "%F{blue}📁 Creating destination directory...%f"
        mkdir -p "$dest_dir"
    fi
    
    # Move file
    print -P "%F{blue}🔧 Moving file to repo...%f"
    mv "$source_path" "$dest_path"
    print -P "%F{green}✅ Moved to $dest_path%f"
    
    # Symlink back
    print -P "%F{blue}🔗 Creating symlink...%f"
    ln -s "$dest_path" "$source_path"
    print -P "%F{green}✅ Symlink created%f"
    
    # Update install.sh
    print -P "%F{blue}📝 Updating install.sh...%f"
    
    # Replace literal home path with $HOME variable
    local install_target_path="${source_path/#$HOME/\$HOME}"
    # Convert dest_path to use $DOTFILES_DIR
    local install_source_path="${dest_path/#$dotfiles_dir/\$DOTFILES_DIR}"
    local new_entry="    [\"$install_source_path\"]=\"$install_target_path\""
    
    if grep -q "\"$install_target_path\"" "$install_script"; then
        print -P "%F{yellow}⚠️  Entry already exists in install.sh%f"
    else
        # Insert into SYMLINKS array
        # We assume the array definition ends with a closing parenthesis
        sed -i "/^declare -A SYMLINKS=/,/^)/ {
            /^)/ i\\
$new_entry
        }" "$install_script"
        print -P "%F{green}✅ Added to install.sh%f"
    fi
    
    # Stage changes
    print -P "%F{blue}📦 Staging changes...%f"
    # Get relative path from dotfiles_dir for git add
    local git_add_path="${dest_path/#$dotfiles_dir\//}"
    git -C "$dotfiles_dir" add "$git_add_path" "install.sh"
    
    print -P "\n%F{green}🎉 Successfully added '$dest_filename'!%f"
    print "Next: dotpush 'Add $dest_filename'"
}

# Run dotfiles setup scripts
dotsetup() {
    local SETUP_DIR="$HOME/dotfiles/setup"
    
    if [[ -z "$1" ]]; then
        printf "📦 Available setup scripts:\n"
        if [[ -d "$SETUP_DIR" ]]; then
            for script in "$SETUP_DIR"/*.sh; do
                if [[ -f "$script" ]]; then
                    local script_name=$(basename "$script" .sh)
                    if [[ ! "$script_name" =~ ^_ ]]; then
                        printf "   ↳ ${script_name}\n"
                    fi
                fi
            done
        else
            printf "❌ Error: Setup directory not found: $SETUP_DIR\n"
            return 1
        fi
        return 0
    fi
    
    local SCRIPT_NAME="$1"
    local SCRIPT_PATH="$SETUP_DIR/${SCRIPT_NAME}.sh"
    
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        printf "❌ Error: Setup script '${SCRIPT_NAME}' not found.\n"
        return 1
    fi
    
    if [[ ! -x "$SCRIPT_PATH" ]]; then
        chmod +x "$SCRIPT_PATH"
    fi
    
    printf "🚀 Running setup script: ${SCRIPT_NAME}\n"
    bash "$SCRIPT_PATH"
}

# Check PATH validity
paths() {
    local GREEN_CHECK='\e[32m✔\e[0m'
    local RED_X='\e[31m✘\e[0m'
    local BOLD='\e[1m'
    local NORMAL='\e[0m'
    
    print -P "${BOLD}Checking PATH entries...${NORMAL}"
    
    echo $PATH | tr ':' '\n' | while read -r path; do
        if [[ -d "$path" ]]; then
            print -P "$GREEN_CHECK $path"
        else
            print -P "$RED_X $path"
            print -u2 "Warning: PATH entry does not exist: $path"
        fi
    done
}

# Pack directory into archive
packk() {
    local GREEN YELLOW BLUE CYAN RED NC
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
    
    local ROCKET="🚀" CHECK="✅" CROSS="❌"
    
    if [[ -z "$1" ]]; then
        printf "${RED}${CROSS} Error: No directory specified.${NC}\n"
        printf "Usage: packk <directory> [format]\n"
        printf "Formats: tar.gz (default), zip, 7z\n"
        return 1
    fi
    
    local SOURCE_DIR="$1"
    local FORMAT="${2:-tar.gz}"
    
    if [[ ! -d "$SOURCE_DIR" ]]; then
        printf "${RED}${CROSS} Error: Directory '$SOURCE_DIR' does not exist.${NC}\n"
        return 1
    fi
    
    if [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
        printf "${RED}${CROSS} Error: Directory '$SOURCE_DIR' is empty.${NC}\n"
        return 1
    fi
    
    local DIR_NAME=$(basename "$SOURCE_DIR")
    local ARCHIVE_NAME=""
    
    case "$FORMAT" in
        tar.gz)
            ARCHIVE_NAME="${DIR_NAME}.tar.gz"
            if ! command -v tar &> /dev/null; then
                printf "${RED}${CROSS} Error: 'tar' is not installed.${NC}\n"
                return 1
            fi
            ;;
        zip)
            ARCHIVE_NAME="${DIR_NAME}.zip"
            if ! command -v zip &> /dev/null; then
                printf "${RED}${CROSS} Error: 'zip' is not installed.${NC}\n"
                return 1
            fi
            ;;
        7z)
            ARCHIVE_NAME="${DIR_NAME}.7z"
            if ! command -v 7z &> /dev/null; then
                printf "${RED}${CROSS} Error: '7z' is not installed.${NC}\n"
                return 1
            fi
            ;;
        *)
            printf "${RED}${CROSS} Error: Unsupported format '$FORMAT'.${NC}\n"
            printf "Supported formats: tar.gz, zip, 7z\n"
            return 1
            ;;
    esac
    
    if [[ -f "$ARCHIVE_NAME" ]]; then
        printf "${YELLOW}⚠️  Archive '$ARCHIVE_NAME' already exists.${NC}\n"
        printf "Overwrite? [y/N]: "
        read -r RESPONSE
        if [[ ! "$RESPONSE" =~ ^[Yy]$ ]]; then
            printf "${CYAN}Operation cancelled.${NC}\n"
            return 0
        fi
    fi
    
    printf "${CYAN}${ROCKET} Creating archive...${NC}\n"
    
    case "$FORMAT" in
        tar.gz)
            if tar -czf "$ARCHIVE_NAME" "$SOURCE_DIR"; then
                printf "${GREEN}${CHECK} Created: $ARCHIVE_NAME${NC}\n"
            else
                printf "${RED}${CROSS} Error: Failed to create archive.${NC}\n"
                return 1
            fi
            ;;
        zip)
            if zip -r "$ARCHIVE_NAME" "$SOURCE_DIR" > /dev/null; then
                printf "${GREEN}${CHECK} Created: $ARCHIVE_NAME${NC}\n"
            else
                printf "${RED}${CROSS} Error: Failed to create archive.${NC}\n"
                return 1
            fi
            ;;
        7z)
            if 7z a "$ARCHIVE_NAME" "$SOURCE_DIR" > /dev/null; then
                printf "${GREEN}${CHECK} Created: $ARCHIVE_NAME${NC}\n"
            else
                printf "${RED}${CROSS} Error: Failed to create archive.${NC}\n"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Maintenance sequence
maintain() {
    print "\n🚀 Starting Maintenance Sequence..."
    
    # Run dotpull without reloading shell immediately
    dotpull --no-exec
    if [[ $? -ne 0 ]]; then
        print "\n❌ dotpull failed. Stopping."
        return 1
    fi
    
    # Note: install.sh is already run by dotpull
    
    print "\n⏱️  Configuration updated."
    print -n "    Launching system updates in 5 seconds... "
    read -t 5 -k 1 -s
    print "\n"
    
    updatep
    
    # Reload shell at the very end
    print "\n🔄 Reloading zsh configuration..."
    exec zsh
}
