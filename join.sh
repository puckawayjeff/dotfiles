#!/usr/bin/env bash
# join.sh: Deploy dotfiles to a new host
# Usage: wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
#
# Two modes:
#   Standalone: Public dotfiles only (one-way sync from GitHub)
#   Enhanced:   Private SSH sync + dotfiles (requires ~/.config/dotfiles/dotfiles.env)
#
# This script is idempotent and safe to re-run.

# Exit immediately if a command exits with a non-zero status
set -e

# --- IMPORTANT: Self-Contained Design ---
# This script CANNOT use lib/utils.sh because it's downloaded independently via wget
# before the dotfiles repository exists on the target system. All color definitions
# and logging functions must be embedded here for bootstrap functionality.
# Once dotfiles is cloned, subsequent scripts (sync.sh, etc.) use lib/utils.sh.

# --- Color Definitions ---
# Define colors using tput (portable across terminals)
if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)   # Success messages
    YELLOW=$(tput setaf 3)  # Warnings, prompts, user attention
    BLUE=$(tput setaf 4)    # Section headers, informational
    CYAN=$(tput setaf 6)    # Command output, sub-steps
    RED=$(tput setaf 1)     # Errors, failures
    NC=$(tput sgr0)         # Reset/No Color
else
    # Fallback to ANSI escape codes if tput unavailable
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
WARNING="⚠️"
PACKAGE="📦"

# --- Helper Functions (matching utils.sh) ---

# Print a section header
log_section() {
    local title="$1"
    local icon="${2:-$PACKAGE}"
    printf "\n${CYAN}${icon} ${title}...${NC}\n"
}

# Print a success message
log_success() {
    printf "${GREEN}${CHECK} $1${NC}\n"
}

# Print an error message
log_error() {
    printf "${RED}${CROSS} Error: $1${NC}\n" >&2
}

# Print an info message
log_info() {
    printf "${BLUE}$1${NC}\n"
}

# Print a warning message
log_warning() {
    printf "${YELLOW}$1${NC}\n"
}

# Print a sub-step
log_substep() {
    echo "   ↳ $1"
}

# Check if environment file exists and is valid
check_env_file() {
    local env_file="$HOME/.config/dotfiles/dotfiles.env"
    
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    
    # Source the file
    source "$env_file"
    
    # Validate required variables for enhanced mode
    if [ -z "$SSHSYNC_REPO_URL" ] || \
       [ -z "$SSH_KEYS_ARCHIVE_URL" ] || \
       [ -z "$SSH_KEYS_ARCHIVE_PASSWORD" ] || \
       [ -z "$GIT_USER_NAME" ] || \
       [ -z "$GIT_USER_EMAIL" ]; then
        log_error "dotfiles.env is missing required variables"
        log_info "Required: SSHSYNC_REPO_URL, SSH_KEYS_ARCHIVE_URL, SSH_KEYS_ARCHIVE_PASSWORD, GIT_USER_NAME, GIT_USER_EMAIL"
        return 1
    fi
    
    return 0
}

# Download and extract encrypted SSH keys archive
setup_ssh_from_archive() {
    log_section "Setting up SSH from encrypted archive" "$WRENCH"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Download encrypted archive
    local TEMP_FILE=$(mktemp)
    log_substep "Downloading SSH keys archive..."
    if ! wget -q "$SSH_KEYS_ARCHIVE_URL" -O "$TEMP_FILE"; then
        log_error "Failed to download SSH keys archive from $SSH_KEYS_ARCHIVE_URL"
        rm -f "$TEMP_FILE"
        return 1
    fi
    
    # Decrypt archive
    log_substep "Decrypting archive..."
    local DECRYPTED_FILE=$(mktemp)
    if ! openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in "$TEMP_FILE" -out "$DECRYPTED_FILE" -pass pass:"$SSH_KEYS_ARCHIVE_PASSWORD" 2>/dev/null; then
        log_error "Failed to decrypt archive - check SSH_KEYS_ARCHIVE_PASSWORD"
        rm -f "$TEMP_FILE" "$DECRYPTED_FILE"
        return 1
    fi
    
    # Extract to .ssh directory
    log_substep "Extracting SSH keys..."
    local EXTRACT_DIR=$(mktemp -d)
    if ! tar -xzf "$DECRYPTED_FILE" -C "$EXTRACT_DIR"; then
        log_error "Failed to extract archive"
        rm -f "$TEMP_FILE" "$DECRYPTED_FILE"
        rm -rf "$EXTRACT_DIR"
        return 1
    fi
    
    # Move keys to .ssh (will overwrite existing)
    mv "$EXTRACT_DIR"/ssh/* "$HOME/.ssh/"
    
    # Set proper permissions
    log_substep "Setting permissions..."
    chmod 600 "$HOME/.ssh/id_"* 2>/dev/null || true
    chmod 644 "$HOME/.ssh/id_"*.pub 2>/dev/null || true
    
    # Cleanup
    rm -f "$TEMP_FILE" "$DECRYPTED_FILE"
    rm -rf "$EXTRACT_DIR"
    
    log_success "SSH keys installed successfully"
    return 0
}

# Setup minimal SSH config for GitHub
setup_github_ssh_config() {
    log_section "Configuring SSH for GitHub" "$WRENCH"
    
    # Create minimal config for GitHub (will be replaced by sshsync later)
    cat > "$HOME/.ssh/config" << 'EOF'
Host github.com
    HostName github.com
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
EOF
    
    chmod 600 "$HOME/.ssh/config"
    log_success "SSH config created"
    return 0
}

# Setup sshsync repository
setup_sshsync_repo() {
    log_section "Setting up sshsync repository" "$PACKAGE"
    
    if [ -d "$HOME/sshsync/.git" ]; then
        log_info "sshsync repository already exists, updating..."
        cd "$HOME/sshsync"
        
        # Stash any local changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            log_substep "Stashing local changes..."
            git stash push -m "Auto-stash before pull on $(date '+%Y-%m-%d %H:%M:%S')"
        fi
        
        GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull
        log_success "sshsync repository updated"
    else
        log_info "Cloning sshsync repository..."
        if ! GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git clone "$SSHSYNC_REPO_URL" "$HOME/sshsync"; then
            log_error "Failed to clone sshsync repository"
            log_info "Ensure SSH_KEYS_ARCHIVE contains a key with access to $SSHSYNC_REPO_URL"
            return 1
        fi
        log_success "sshsync repository cloned"
    fi
    
    return 0
}

# --- Main Script ---

# Determine if we need sudo (root doesn't need it)
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# Check for environment file to determine mode
ENHANCED_MODE=false
if check_env_file; then
    ENHANCED_MODE=true
    log_section "Starting dotfiles setup (Enhanced Mode)" "$ROCKET"
    log_success "Environment file detected"
    log_info "   Will configure: SSH keys, private sync, and dotfiles"
else
    log_section "Starting dotfiles setup (Standalone Mode)" "$ROCKET"
    log_info "   Public dotfiles only (one-way sync from GitHub)"
    log_info "   For enhanced mode with private SSH sync:"
    log_info "   → Create ~/.config/dotfiles/dotfiles.env (see dotfiles.env.example)"
fi

# Enhanced mode: Set up SSH and private repository
if [ "$ENHANCED_MODE" = true ]; then
    # Download and extract SSH keys
    if ! setup_ssh_from_archive; then
        log_error "SSH setup failed - falling back to standalone mode"
        ENHANCED_MODE=false
    else
        # Create GitHub SSH config
        setup_github_ssh_config
        
        # Configure git with personal settings
        log_section "Configuring Git" "$WRENCH"
        git config --global pull.rebase false
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"
        log_success "Git configured: $GIT_USER_NAME <$GIT_USER_EMAIL>"
        
        # Clone/update sshsync repository
        if ! setup_sshsync_repo; then
            log_warning "sshsync setup failed - continuing with dotfiles only"
        fi
    fi
fi

log_section "Installing Base Utilities" "$PACKAGE"
if ! command -v apt &> /dev/null; then
    log_error "Cannot update packages without apt package manager."
else
    log_warning "Updating package lists..."
    $SUDO apt update &> /dev/null
    log_success "Package lists updated"
fi

# Install git if not present
# Install git if not present
if ! command -v git &> /dev/null; then
    if ! command -v apt &> /dev/null; then
        log_error "Git is not installed and apt package manager is not available"
        log_error "This script requires Debian-based systems (Debian, Ubuntu, Mint, etc.)"
        exit 1
    fi
    
    log_warning "Git is not installed. Installing..."
    $SUDO apt install -y git
    log_success "Git installed successfully"
else
    log_success "Git is already installed"
fi

log_substep "Git version: $(git --version | cut -d' ' -f3)"

# Standalone mode: Configure git with defaults
if [ "$ENHANCED_MODE" = false ]; then
    log_section "Configuring Git" "$WRENCH"
    git config --global pull.rebase false
    
    # Only set defaults if not already configured
    if ! git config --global user.name > /dev/null 2>&1; then
        git config --global user.name "dotfiles-user"
    fi
    if ! git config --global user.email > /dev/null 2>&1; then
        git config --global user.email "dotfiles@change.me"
    fi
    
    CURRENT_NAME=$(git config --global user.name)
    CURRENT_EMAIL=$(git config --global user.email)
    
    if [ "$CURRENT_NAME" = "dotfiles-user" ] || [ "$CURRENT_EMAIL" = "dotfiles@change.me" ]; then
        log_warning "Using default git credentials"
        log_substep "Update with: git config --global user.name 'Your Name'"
        log_substep "Update with: git config --global user.email 'your@email.com'"
    else
        log_success "Git configured: $CURRENT_NAME <$CURRENT_EMAIL>"
    fi
fi

log_section "Cloning dotfiles repository" "$ROCKET"
if [ -d "$HOME/dotfiles/.git" ]; then
    log_warning "Dotfiles repository already exists"
    cd "$HOME/dotfiles"
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_substep "Stashing local changes..."
        git stash push -m "Auto-stash before pull on $(date '+%Y-%m-%d %H:%M:%S')"
        log_info "   ↳ Local changes stashed. Use 'git stash pop' to restore them."
    fi
    
    log_substep "Pulling latest changes..."
    GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull
    log_success "Dotfiles repository updated"
else
    # Enhanced mode uses SSH, standalone uses HTTPS
    if [ "$ENHANCED_MODE" = true ] && [ -f "$HOME/.ssh/id_ed25519_github" ]; then
        log_substep "Cloning via SSH..."
        GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git clone git@github.com:puckawayjeff/dotfiles.git "$HOME/dotfiles"
    else
        log_substep "Cloning via HTTPS..."
        git clone https://github.com/puckawayjeff/dotfiles.git "$HOME/dotfiles"
    fi
    log_success "Dotfiles repository cloned"
fi

log_section "Running dotfiles sync script" "$WRENCH"
bash "$HOME/dotfiles/sync.sh" --from-join
log_success "Sync script finished"

log_section "Finalizing setup" "$PARTY"

# Check if default shell was changed 
if [ "$(basename "$SHELL")" != "zsh" ] && command -v zsh &> /dev/null; then
    log_substep "Default shell changed to zsh"
    log_substep "Logout and login to activate zsh"
fi

# Show appropriate completion message
if [ "$ENHANCED_MODE" = true ]; then
    printf "\n${GREEN}${PARTY} Enhanced setup complete!${NC}\n"
    log_info "Configured: SSH keys, private sync, and dotfiles"
    if [ -d "$HOME/sshsync/.git" ]; then
        log_info "Commands available: dotpush, sshpush, sshpull"
    fi
else
    printf "\n${GREEN}${PARTY} Standalone setup complete!${NC}\n"
    log_info "Public dotfiles installed (one-way sync from GitHub)"
    log_info ""
    log_info "For enhanced mode with private SSH sync:"
    log_info "   1. Create ~/.config/dotfiles/dotfiles.env"
    log_info "   2. See: https://github.com/puckawayjeff/dotfiles/blob/main/PRIVATE_SETUP.md"
fi

echo ""
log_info "Start a new shell with: zsh"
log_info ""
log_info "${CYAN}📚 Quick Help:${NC}"
log_substep "dothelp - Show all available commands"
log_substep "dotkeys - Show keyboard shortcuts"

