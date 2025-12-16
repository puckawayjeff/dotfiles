#!/usr/bin/env bash
# join.sh: Set up SSH keys and config, then run public dotfiles setup
# Usage: wget -qO - https://sub.domain.ext/path/join.sh | bash
# This script is idempotent and safe to re-run. SSH keys will be overwritten.

# --- Configuration and Setup ---
# Define the base URL for downloading SSH keys and config
BASEURL="https://sub.domain.ext/path"

# Public dotfiles repository setup script
PUBLIC_SETUP_URL="https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh"

# Exit immediately if a command exits with a non-zero status
set -e

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

# --- Helper Functions (matching public dotfiles utils.sh) ---

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

# --- Main Script ---

# Determine if we need sudo (root doesn't need it)
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# Download a file quietly and show pass/fail status
download_file() {
    local url=$1
    local dest=$2
    local filename=$(basename "$dest")

    echo -n "   ↳ Downloading $filename..."
    if wget -q "$url" -O "$dest"; then
        echo -e " ${GREEN}✔${NC}"
    else
        echo -e " ${RED}✖ FAILED${NC}"
        exit 1
    fi
}

# --- Main Script ---

log_section "Starting private SSH setup" "$ROCKET"
log_warning "${WARNING} This script handles sensitive SSH configuration."

# --- Tailscale Check ---
log_section "Checking Tailscale status" "$COMPUTER"

TAILSCALE_INSTALLED=false
TAILSCALE_RUNNING=false

# Check if tailscale is installed
if command -v tailscale &> /dev/null; then
    TAILSCALE_INSTALLED=true
    log_success "Tailscale is installed"

    # Check if tailscale is running and connected to a tailnet
    if $SUDO tailscale status &> /dev/null; then
        # Get the status output
        TAILSCALE_STATUS=$($SUDO tailscale status 2>&1)

        # Check if we're actually connected (not just installed)
        if echo "$TAILSCALE_STATUS" | grep -q "^100\."; then
            TAILSCALE_RUNNING=true
            log_success "Tailscale is running and connected to tailnet"
            log_substep "Your Tailscale IP: $(echo "$TAILSCALE_STATUS" | head -n1 | awk '{print $1}')"
        else
            log_warning "${WARNING} Tailscale is installed but not connected to a tailnet"
        fi
    else
        log_warning "${WARNING} Tailscale is installed but not running"
    fi
else
    log_warning "${WARNING} Tailscale is not installed"
fi

# If Tailscale is not properly set up, show installation instructions
if [ "$TAILSCALE_INSTALLED" = false ] || [ "$TAILSCALE_RUNNING" = false ]; then
    log_warning "\n${WARNING} SSH config uses Tailscale IPs - hosts won't be reachable without Tailscale!"
    log_info "\n   To install and set up Tailscale, copy and paste this command:"
    echo ""
    echo -e "${CYAN}curl -fsSL https://tailscale.com/install.sh | sh && $SUDO tailscale up --accept-routes${NC}"
    echo ""
    log_info "   Note: You'll need to authenticate via a URL after running the command."
fi

log_section "Setting up SSH" "$WRENCH"

# Create .ssh directory if it doesn't exist
mkdir -p "$HOME/.ssh"

# Download SSH keys and config from a secure location (will overwrite if they exist)
log_info "   Downloading SSH keys and config (existing files will be overwritten)..."
download_file "$BASEURL/038ce49f-351d-40a7-9ace-1eceae557ba1"     "$HOME/.ssh/id_ed25519_homelab"
download_file "$BASEURL/043aee74-3261-45ec-9f32-ee43e8c6c819" "$HOME/.ssh/id_ed25519_homelab.pub"
download_file "$BASEURL/6cfa8c11-72f4-4293-a71b-624bb079da81"      "$HOME/.ssh/id_ed25519_github"
download_file "$BASEURL/2cf96417-b48a-430c-a267-d90d50eba209"  "$HOME/.ssh/id_ed25519_github.pub"

# Write SSH config file
cat > "$HOME/.ssh/config" << 'EOF'
Host github.com
    HostName github.com
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
EOF

# Set appropriate permissions for SSH keys and config
log_substep "Setting file permissions..."
chmod 600 "$HOME/.ssh/id_ed25519_"*
chmod 644 "$HOME/.ssh/id_ed25519_"*.pub
chmod 600 "$HOME/.ssh/config"
log_success "SSH setup complete."

#--- Git Installation and Configuration ---
log_section "Checking for Git and configuring" "$WRENCH"
# Check if Git is installed
if ! command -v git &> /dev/null; then
    # Git not installed - check if apt is available
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

# Configure Git
log_substep "Configuring Git settings..."
git config --global pull.rebase false
git config --global user.name "puckawayjeff"
git config --global user.email "jeff@puckaway.net"
log_success "Git configured."

#--- Clone/Update sshsync Repository and Create Symlinks ---
log_section "Cloning sshsync repository" "$PACKAGE"
if [ -d "$HOME/sshsync/.git" ]; then
    log_warning "${WARNING} sshsync repository already exists."
    cd "$HOME/sshsync"

    # Discard local changes to ssh.conf (will be overwritten by symlink anyway)
    git checkout -- ssh.conf 2>/dev/null || true

    log_substep "Pulling latest changes..."
    git pull
    log_success "sshsync repository updated."
else
    # Clone this repository
    git clone git@github.com:puckawayjeff/sshsync.git "$HOME/sshsync"
    log_success "sshsync repository cloned."
fi

# Create symlinks
log_section "Creating SSH symlinks" "$WRENCH"

# Define symlink mappings (source -> target)
declare -A SYMLINKS=(
    ["$HOME/sshsync/ssh.conf"]="$HOME/.ssh/config"
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

#--- Run Public Dotfiles Setup ---
log_section "Running public dotfiles setup" "$PACKAGE"
log_info "   Downloading and executing public setup script..."
log_warning "   This will install and configure Zsh and Starship, clone dotfiles, and create symlinks.\n"

# Download and execute the public dotfiles setup script
if wget -qO - "$PUBLIC_SETUP_URL" | bash; then
    log_success "Public dotfiles setup completed successfully."
else
    log_error "Public dotfiles setup failed."
    exit 1
fi

log_success "\n${PARTY} Complete setup finished!"
log_info "   Terminal, SSH keys, config, and dotfiles are now configured.\n"
log_info "   You may need to restart your terminal or source your shell configuration to see changes."
