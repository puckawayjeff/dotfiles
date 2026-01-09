#!/usr/bin/env bash

set -e

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

ROCKET="🚀"
WRENCH="🔧"
CHECK="✅"
CROSS="❌"
COMPUTER="💻"
PARTY="🎉"
PACKAGE="📦"

log_section() { printf "\n${CYAN}${2:-$PACKAGE} $1...${NC}\n"; }
log_success() { printf "${GREEN}${CHECK} $1${NC}\n"; }
log_error() { printf "${RED}${CROSS} Error: $1${NC}\n" >&2; }
log_info() { printf "${BLUE}$1${NC}\n"; }
log_warning() { printf "${YELLOW}$1${NC}\n"; }
log_substep() { echo "   ↳ $1"; }

install_git() {
    if command -v git &> /dev/null; then
        log_success "Git is already installed"
        return 0
    fi

    log_warning "Git not found. Attempting to install..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
    else
        OS_ID=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi

    local SUDO=""
    [ "$EUID" -ne 0 ] && SUDO="sudo"

    case "$OS_ID" in
        ubuntu|debian|pop|linuxmint|kali|raspbian)
            $SUDO apt update && $SUDO apt install -y git
            ;;
        fedora|rhel|centos|almalinux|rocky)
            $SUDO dnf install -y git
            ;;
        arch|manjaro|endeavouros)
            $SUDO pacman -Sy --noconfirm git
            ;;
        alpine)
            $SUDO apk add git
            ;;
        *)
            log_error "Unsupported OS for automatic git installation: $OS_ID"
            log_info "Please install git manually and re-run this script."
            return 1
            ;;
    esac
}

check_env_file() {
    local env_file="$HOME/.config/dotfiles/dotfiles.env"
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    source "$env_file"
    if [ -z "$SSHSYNC_REPO_URL" ] || [ -z "$SSH_KEYS_ARCHIVE_URL" ] || [ -z "$SSH_KEYS_ARCHIVE_PASSWORD" ]; then
        log_error "dotfiles.env is missing required variables"
        return 1
    fi
    return 0
}

setup_ssh_from_archive() {
    log_section "Setting up SSH from encrypted archive" "$WRENCH"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    local TEMP_FILE=$(mktemp)
    log_substep "Downloading SSH keys archive..."
    if ! wget -q "$SSH_KEYS_ARCHIVE_URL" -O "$TEMP_FILE"; then
        log_error "Failed to download SSH keys archive"
        rm -f "$TEMP_FILE"
        return 1
    fi
    
    log_substep "Decrypting archive..."
    local DECRYPTED_FILE=$(mktemp)
    if ! openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in "$TEMP_FILE" -out "$DECRYPTED_FILE" -pass pass:"$SSH_KEYS_ARCHIVE_PASSWORD" 2>/dev/null; then
        log_error "Failed to decrypt archive"
        rm -f "$TEMP_FILE" "$DECRYPTED_FILE"
        return 1
    fi
    
    log_substep "Extracting SSH keys..."
    local EXTRACT_DIR=$(mktemp -d)
    if ! tar -xzf "$DECRYPTED_FILE" -C "$EXTRACT_DIR"; then
        log_error "Failed to extract archive"
        rm -f "$TEMP_FILE" "$DECRYPTED_FILE"
        rm -rf "$EXTRACT_DIR"
        return 1
    fi
    
    mv "$EXTRACT_DIR"/ssh/* "$HOME/.ssh/"
    chmod 600 "$HOME/.ssh/id_"* 2>/dev/null || true
    chmod 644 "$HOME/.ssh/id_"*.pub 2>/dev/null || true
    
    rm -f "$TEMP_FILE" "$DECRYPTED_FILE"
    rm -rf "$EXTRACT_DIR"
    log_success "SSH keys installed successfully"
    return 0
}

setup_github_ssh_config() {
    log_section "Configuring SSH for GitHub" "$WRENCH"
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
}

setup_sshsync_repo() {
    log_section "Setting up sshsync repository" "$PACKAGE"
    if [ -d "$HOME/sshsync/.git" ]; then
        log_info "sshsync repository already exists, updating..."
        cd "$HOME/sshsync"
        git pull
        log_success "sshsync repository updated"
    else
        log_info "Cloning sshsync repository..."
        if ! GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git clone "$SSHSYNC_REPO_URL" "$HOME/sshsync"; then
            log_error "Failed to clone sshsync repository"
            return 1
        fi
        log_success "sshsync repository cloned"
    fi
    return 0
}

log_section "Puckadots v3.0 Setup" "$ROCKET"

if ! check_env_file; then
    log_error "Missing configuration file!"
    log_info "Puckadots requires a valid 'dotfiles.env' file at:"
    log_info "~/.config/dotfiles/dotfiles.env"
    echo ""
    log_info "Please set up your private repository and environment file first."
    log_info "See instructions here: https://github.com/puckawayjeff/dotfiles#private-setup-guide-required"
    exit 1
fi

log_success "Environment file detected"

install_git

if ! setup_ssh_from_archive; then
    log_error "SSH setup failed. Cannot continue with private repo clone."
    exit 1
fi

setup_github_ssh_config

log_section "Configuring Git" "$WRENCH"
git config --global pull.rebase false
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    log_success "Git configured: $GIT_USER_NAME"
fi

setup_sshsync_repo

log_section "Cloning Puckadots repository" "$ROCKET"
if [ -d "$HOME/dotfiles/.git" ]; then
    log_warning "Dotfiles repository already exists"
    cd "$HOME/dotfiles"
    GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git pull
    log_success "Dotfiles repository updated"
else
    if [ -f "$HOME/.ssh/id_ed25519_github" ]; then
        log_substep "Cloning via SSH..."
        GIT_SSH_COMMAND="ssh -o LogLevel=ERROR" git clone git@github.com:puckawayjeff/dotfiles.git "$HOME/dotfiles"
        log_success "Dotfiles repository cloned"
    else
        log_error "GitHub SSH key missing after setup. Cloning failed."
        exit 1
    fi
fi

log_section "Handing off to sync.sh" "$WRENCH"
bash "$HOME/dotfiles/sync.sh" --from-join

log_success "Setup complete!"
log_info "Please restart your shell or run: exec zsh"
