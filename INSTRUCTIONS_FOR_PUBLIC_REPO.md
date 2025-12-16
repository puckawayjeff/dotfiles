# Instructions for Public Dotfiles Repo Refactor

## Overview
These instructions will transform the public dotfiles repo to work in two modes:
1. **Standalone Mode**: Works for anyone without a private companion repo
2. **Enhanced Mode**: Integrates with a private sshsync repo for users who create one

---

## Files to Create

### 1. Create `dotfiles.env.example`

This template shows users what variables they need to configure:

```bash
# dotfiles.env.example
# Copy this file to ~/.config/dotfiles/dotfiles.env and fill in your values
# This file enables private SSH sync and personalization features

# Your private sshsync repository URL
# Example: git@github.com:yourusername/sshsync.git
SSHSYNC_REPO_URL=""

# URL to your encrypted SSH keys archive
# This should be hosted on a secure web server you control
# Example: https://example.com/secure/ssh-keys.tar.gz.enc
SSH_KEYS_ARCHIVE_URL=""

# Password for decrypting the SSH keys archive
# Keep this secure! This file should never be committed to git
SSH_KEYS_ARCHIVE_PASSWORD=""

# Git global configuration
# These will be set via 'git config --global'
GIT_USER_NAME=""
GIT_USER_EMAIL=""
```

### 2. Create `package-ssh-keys.sh`

Helper script for users to package their SSH keys into an encrypted archive:

```bash
#!/usr/bin/env bash
# package-ssh-keys.sh - Package SSH keys into encrypted archive for dotfiles setup
# Usage: ./package-ssh-keys.sh [password]

set -e

# Color definitions
if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RED=$(tput setaf 1)
    NC=$(tput sgr0)
else
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m'
fi

log_info() { printf "${BLUE}ℹ️  $1${NC}\n"; }
log_success() { printf "${GREEN}✅ $1${NC}\n"; }
log_error() { printf "${RED}❌ Error: $1${NC}\n" >&2; }
log_warning() { printf "${YELLOW}⚠️  $1${NC}\n"; }

echo ""
log_info "SSH Keys Packaging Script"
echo ""

# Check if ~/.ssh exists
if [ ! -d "$HOME/.ssh" ]; then
    log_error "~/.ssh directory does not exist"
    exit 1
fi

# Check for SSH keys
SSH_KEY_FILES=$(find "$HOME/.ssh" -type f \( -name "id_*" ! -name "*.pub" \) 2>/dev/null || true)
SSH_PUB_FILES=$(find "$HOME/.ssh" -type f -name "id_*.pub" 2>/dev/null || true)

if [ -z "$SSH_KEY_FILES" ]; then
    log_error "No SSH keys found in ~/.ssh"
    log_info "Generate keys with: ssh-keygen -t ed25519 -C 'your@email.com'"
    exit 1
fi

# List found keys
log_info "Found SSH keys:"
echo "$SSH_KEY_FILES" | while read -r keyfile; do
    echo "   • $(basename "$keyfile")"
done
echo "$SSH_PUB_FILES" | while read -r keyfile; do
    echo "   • $(basename "$keyfile")"
done
echo ""

# Get password
PASSWORD="$1"
if [ -z "$PASSWORD" ]; then
    log_warning "No password provided as argument"
    echo -n "Enter password for encryption: "
    read -s PASSWORD
    echo ""
    echo -n "Confirm password: "
    read -s PASSWORD_CONFIRM
    echo ""
    
    if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
        log_error "Passwords do not match"
        exit 1
    fi
fi

if [ ${#PASSWORD} -lt 12 ]; then
    log_warning "Password is shorter than 12 characters. Consider using a stronger password."
    echo -n "Continue anyway? (y/N): "
    read -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Aborted"
        exit 0
    fi
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log_info "Creating archive..."

# Copy SSH keys to temp directory
mkdir -p "$TEMP_DIR/ssh"
find "$HOME/.ssh" -type f \( -name "id_*" \) -exec cp {} "$TEMP_DIR/ssh/" \;

# Count files
FILE_COUNT=$(find "$TEMP_DIR/ssh" -type f | wc -l)

# Create tar.gz
cd "$TEMP_DIR"
tar -czf ssh-keys.tar.gz ssh/

# Encrypt using openssl with AES-256-CBC
openssl enc -aes-256-cbc -salt -pbkdf2 -in ssh-keys.tar.gz -out ssh-keys.tar.gz.enc -pass pass:"$PASSWORD"

# Move to current directory
OUTPUT_FILE="$HOME/ssh-keys.tar.gz.enc"
mv ssh-keys.tar.gz.enc "$OUTPUT_FILE"

# Get file size
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

log_success "Archive created successfully!"
echo ""
log_info "Archive details:"
echo "   • Location: $OUTPUT_FILE"
echo "   • Files packaged: $FILE_COUNT"
echo "   • Size: $FILE_SIZE"
echo ""

# Verify archive can be decrypted
log_info "Verifying archive..."
VERIFY_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR $VERIFY_DIR" EXIT

if openssl enc -aes-256-cbc -d -pbkdf2 -in "$OUTPUT_FILE" -out "$VERIFY_DIR/test.tar.gz" -pass pass:"$PASSWORD" 2>/dev/null; then
    if tar -tzf "$VERIFY_DIR/test.tar.gz" >/dev/null 2>&1; then
        log_success "Archive verified successfully!"
    else
        log_error "Archive verification failed - tar extraction failed"
        exit 1
    fi
else
    log_error "Archive verification failed - decryption failed"
    exit 1
fi

echo ""
log_info "Next steps:"
echo "   1. Upload $OUTPUT_FILE to your secure web server"
echo "   2. Note the URL where it's accessible"
echo "   3. Add URL and password to your dotfiles.env file:"
echo ""
echo "      SSH_KEYS_ARCHIVE_URL=\"https://example.com/path/to/ssh-keys.tar.gz.enc\""
echo "      SSH_KEYS_ARCHIVE_PASSWORD=\"$PASSWORD\""
echo ""
log_warning "Keep this file and password secure! Anyone with both can access your SSH keys."
echo ""
```

### 3. Modify Existing `join.sh`

The join.sh needs major refactoring. Here are the key changes:

#### A. Keep These Sections As-Is
- Color and emoji definitions (lines 15-44)
- Helper functions: `log_section`, `log_success`, `log_error`, `log_info`, `log_warning`, `log_substep` (lines 47-67)
- Tailscale check section (lines 102-137) - keep for informational purposes

#### B. Remove These Sections Entirely
- Lines 7-11: BASEURL, PUBLIC_SETUP_URL configuration (moving to .env)
- Lines 154-164: Inline SSH config writing (replaced by sshsync symlink)
- Lines 206-229: sshsync repository cloning (moving to conditional logic)
- Lines 232-261: SSH symlink creation (moving to conditional logic)
- Lines 263-272: Public dotfiles setup call (this IS the public script now)

#### C. Add New Functions

Add these functions after the helper functions section (after line 67):

```bash
# Check if environment file exists and is valid
check_env_file() {
    local env_file="$HOME/.config/dotfiles/dotfiles.env"
    
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    
    # Source the env file
    source "$env_file"
    
    # Check required variables
    if [ -z "$SSHSYNC_REPO_URL" ] || \
       [ -z "$SSH_KEYS_ARCHIVE_URL" ] || \
       [ -z "$SSH_KEYS_ARCHIVE_PASSWORD" ] || \
       [ -z "$GIT_USER_NAME" ] || \
       [ -z "$GIT_USER_EMAIL" ]; then
        log_error "Environment file is missing required variables"
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
    
    local temp_enc="/tmp/ssh-keys.tar.gz.enc"
    local temp_tar="/tmp/ssh-keys.tar.gz"
    
    # Download encrypted archive
    log_info "   Downloading encrypted SSH keys..."
    if ! wget -q "$SSH_KEYS_ARCHIVE_URL" -O "$temp_enc"; then
        log_error "Failed to download SSH keys archive"
        return 1
    fi
    log_success "Archive downloaded"
    
    # Decrypt archive
    log_info "   Decrypting archive..."
    if ! openssl enc -aes-256-cbc -d -pbkdf2 -in "$temp_enc" -out "$temp_tar" -pass pass:"$SSH_KEYS_ARCHIVE_PASSWORD" 2>/dev/null; then
        log_error "Failed to decrypt archive - check your password"
        rm -f "$temp_enc" "$temp_tar"
        return 1
    fi
    log_success "Archive decrypted"
    
    # Extract to ~/.ssh
    log_info "   Extracting SSH keys..."
    if ! tar -xzf "$temp_tar" -C "$HOME/.ssh" --strip-components=1; then
        log_error "Failed to extract SSH keys"
        rm -f "$temp_enc" "$temp_tar"
        return 1
    fi
    log_success "SSH keys extracted"
    
    # Set permissions
    log_substep "Setting file permissions..."
    chmod 600 "$HOME/.ssh"/id_* 2>/dev/null || true
    chmod 644 "$HOME/.ssh"/id_*.pub 2>/dev/null || true
    
    # Clean up
    rm -f "$temp_enc" "$temp_tar"
    
    log_success "SSH keys setup complete"
    return 0
}

# Setup sshsync repository and create symlinks
setup_sshsync_repo() {
    log_section "Setting up sshsync repository" "$PACKAGE"
    
    # Create temporary SSH config for GitHub (needed to clone sshsync repo)
    if [ ! -f "$HOME/.ssh/config" ]; then
        log_substep "Creating temporary SSH config for GitHub..."
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
    fi
    
    # Clone or update sshsync repository
    if [ -d "$HOME/sshsync/.git" ]; then
        log_info "   sshsync repository already exists, updating..."
        cd "$HOME/sshsync"
        git checkout -- . 2>/dev/null || true
        git pull
        log_success "sshsync repository updated"
    else
        log_info "   Cloning sshsync repository..."
        if ! git clone "$SSHSYNC_REPO_URL" "$HOME/sshsync"; then
            log_error "Failed to clone sshsync repository"
            log_info "Make sure your SSH keys are set up correctly and you have access to the repo"
            return 1
        fi
        log_success "sshsync repository cloned"
    fi
    
    # Create symlink for SSH config
    log_section "Creating SSH config symlink" "$WRENCH"
    if [ -f "$HOME/sshsync/ssh.conf" ]; then
        ln -sf "$HOME/sshsync/ssh.conf" "$HOME/.ssh/config"
        log_success "SSH config symlinked from sshsync/ssh.conf"
    else
        log_warning "No ssh.conf found in sshsync repository"
    fi
    
    return 0
}
```

#### D. Rewrite Main Script Section

Replace the entire main script section (starting around line 69) with:

```bash
# --- Main Script ---

# Determine if we need sudo (root doesn't need it)
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# Check for environment file
ENHANCED_MODE=false
if check_env_file; then
    ENHANCED_MODE=true
    log_section "Starting dotfiles setup (Enhanced Mode)" "$ROCKET"
    log_info "   Environment file detected - will set up SSH and private sync"
else
    log_section "Starting dotfiles setup (Standalone Mode)" "$ROCKET"
    log_info "   No environment file detected - installing public dotfiles only"
    log_info "   For private SSH sync, see: https://github.com/puckawayjeff/dotfiles/blob/main/PRIVATE_SETUP.md"
fi

# Enhanced mode: Set up SSH first
if [ "$ENHANCED_MODE" = true ]; then
    # Tailscale check (informational only)
    log_section "Checking Tailscale status" "$COMPUTER"
    
    TAILSCALE_INSTALLED=false
    TAILSCALE_RUNNING=false
    
    if command -v tailscale &> /dev/null; then
        TAILSCALE_INSTALLED=true
        log_success "Tailscale is installed"
        
        if $SUDO tailscale status &> /dev/null; then
            TAILSCALE_STATUS=$($SUDO tailscale status 2>&1)
            
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
    
    if [ "$TAILSCALE_INSTALLED" = false ] || [ "$TAILSCALE_RUNNING" = false ]; then
        log_warning "\n${WARNING} SSH config may use Tailscale IPs - hosts might not be reachable without Tailscale!"
        log_info "\n   To install and set up Tailscale, run:"
        echo ""
        echo -e "${CYAN}curl -fsSL https://tailscale.com/install.sh | sh && $SUDO tailscale up --accept-routes${NC}"
        echo ""
    fi
    
    # Set up SSH from encrypted archive
    if ! setup_ssh_from_archive; then
        log_error "SSH setup failed - continuing with basic setup"
        ENHANCED_MODE=false
    fi
fi

# Git Installation
log_section "Checking for Git" "$WRENCH"
if ! command -v git &> /dev/null; then
    if ! command -v apt &> /dev/null; then
        log_error "Git is not installed and apt package manager is not available"
        log_error "Please install Git manually and re-run this script"
        exit 1
    fi
    
    log_info "Installing Git..."
    $SUDO apt update
    $SUDO apt install -y git
    log_success "Git installed successfully"
else
    log_success "Git is already installed"
fi

# Configure Git
log_section "Configuring Git" "$WRENCH"
git config --global pull.rebase false

if [ "$ENHANCED_MODE" = true ]; then
    log_substep "Setting user name and email from environment..."
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    log_success "Git configured with personal settings"
else
    log_info "Skipping personal git config (no environment file)"
    log_info "Set manually with: git config --global user.name 'Your Name'"
    log_info "                   git config --global user.email 'your@email.com'"
fi

# Enhanced mode: Set up sshsync repository
if [ "$ENHANCED_MODE" = true ]; then
    if ! setup_sshsync_repo; then
        log_error "sshsync setup failed - continuing with basic setup"
        ENHANCED_MODE=false
    fi
fi

# Install Zsh
log_section "Installing Zsh" "$PACKAGE"
if command -v zsh &> /dev/null; then
    log_success "Zsh is already installed"
else
    log_info "Installing Zsh..."
    $SUDO apt update
    $SUDO apt install -y zsh
    log_success "Zsh installed successfully"
fi

# Set Zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    log_substep "Setting Zsh as default shell..."
    chsh -s "$(which zsh)"
    log_success "Zsh set as default shell (restart terminal to apply)"
else
    log_success "Zsh is already the default shell"
fi

# Install Starship
log_section "Installing Starship" "$ROCKET"
if command -v starship &> /dev/null; then
    log_success "Starship is already installed"
else
    log_info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    log_success "Starship installed successfully"
fi

# Clone or update dotfiles repository
log_section "Setting up dotfiles repository" "$PACKAGE"
if [ -d "$HOME/dotfiles/.git" ]; then
    log_info "dotfiles repository already exists, updating..."
    cd "$HOME/dotfiles"
    git checkout -- . 2>/dev/null || true
    git pull
    log_success "dotfiles repository updated"
else
    log_info "Cloning dotfiles repository..."
    git clone https://github.com/puckawayjeff/dotfiles.git "$HOME/dotfiles"
    log_success "dotfiles repository cloned"
fi

# Create symlinks for dotfiles
log_section "Creating dotfiles symlinks" "$WRENCH"

# Define symlink mappings (source -> target)
declare -A SYMLINKS=(
    ["$HOME/dotfiles/.zshrc"]="$HOME/.zshrc"
    ["$HOME/dotfiles/.config/starship.toml"]="$HOME/.config/starship.toml"
)

# Add any other symlinks from your dotfiles repo here

CREATED=0
SKIPPED=0

for source in "${!SYMLINKS[@]}"; do
    target="${SYMLINKS[$source]}"
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"
    
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
    log_success "Created/updated $CREATED symlink(s)"
fi
if [ $SKIPPED -gt 0 ]; then
    log_info "Skipped $SKIPPED existing symlink(s)"
fi

# Final message
echo ""
if [ "$ENHANCED_MODE" = true ]; then
    log_success "${PARTY} Complete setup finished!"
    log_info "   Terminal, SSH keys, private sync, and dotfiles are configured"
else
    log_success "${PARTY} Setup finished!"
    log_info "   Terminal and public dotfiles are configured"
    log_info "   For private SSH sync, see: https://github.com/puckawayjeff/dotfiles/blob/main/PRIVATE_SETUP.md"
fi

echo ""
log_info "   Restart your terminal or run: exec zsh"
echo ""
```

---

## Files to Update

### 4. Update `README.md`

Replace the current README with:

---
---
---
# Dotfiles

**Modern terminal environment with Zsh, Starship prompt, and custom configurations**

This repository provides a consistent, powerful terminal setup that works standalone or integrates with a private companion repository for SSH key management and personal configurations.

## 🚀 Quick Start

### Basic Setup (Public Dotfiles Only)

```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

This installs:
- ✅ Zsh shell with custom configuration
- ✅ Starship prompt (modern, fast, customizable)
- ✅ Public dotfiles and configurations
- ✅ Sensible Git defaults

Perfect for: Anyone who wants a solid terminal setup without private sync.

### Advanced Setup (With Private Companion Repo)

For personal SSH key sync and private configurations:

1. Create `~/.config/dotfiles/dotfiles.env` (see [PRIVATE_SETUP.md](PRIVATE_SETUP.md))
2. Run the same command:
   ```bash
   wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
   ```

With an environment file, you also get:
- ✅ Encrypted SSH keys download and setup
- ✅ SSH config from your private repo
- ✅ Personal Git configuration
- ✅ Any other private configs you add

## 📚 Documentation

- **[PRIVATE_SETUP.md](PRIVATE_SETUP.md)** - Complete guide for setting up private companion repo
- **[dotfiles.env.example](dotfiles.env.example)** - Template for environment configuration
- **[package-ssh-keys.sh](package-ssh-keys.sh)** - Helper to create encrypted SSH key archives

## 🔧 What's Included

### Public Configurations
- `.zshrc` - Zsh configuration with aliases and functions
- `.config/starship.toml` - Starship prompt configuration
- Additional dotfiles and scripts

### Commands (when enhanced mode active)
- `dotpush` - Push changes to your private sshsync repo
- Additional custom commands from your dotfiles

## 🏗️ How It Works

The `join.sh` script detects whether you have a `dotfiles.env` file:

**Without .env (Standalone Mode)**:
- Installs tools and public dotfiles
- No SSH setup, no private configs
- Perfect for trying out or public machines

**With .env (Enhanced Mode)**:
- Downloads encrypted SSH keys archive
- Extracts and sets up SSH keys
- Clones your private sshsync repository
- Symlinks private SSH config
- Sets personal Git config
- Provides full sync capabilities

## 🤝 Contributing

This is a personal dotfiles repository, but feel free to:
- Fork and adapt for your own use
- Submit issues for bugs
- Suggest improvements via pull requests

## 📖 Creating Your Own Setup

See [PRIVATE_SETUP.md](PRIVATE_SETUP.md) for a complete guide to:
1. Creating your own private sshsync repository
2. Generating and packaging SSH keys
3. Hosting encrypted archives securely
4. Setting up your environment file
5. Customizing for your needs

## 📝 License

MIT License - feel free to use and modify for your own dotfiles!

---

**Questions?** Check [PRIVATE_SETUP.md](PRIVATE_SETUP.md) or open an issue.

---
---
---

### 5. Create `PRIVATE_SETUP.md`

Create comprehensive documentation:

```markdown
# Private Setup Guide

This guide walks you through creating your own private companion repository (sshsync) to enhance the public dotfiles with SSH key management and personal configurations.

## 🎯 Overview

The dotfiles system has two modes:

1. **Standalone**: Just public dotfiles (no setup needed beyond running join.sh)
2. **Enhanced**: Public dotfiles + private sshsync repo (requires setup)

This guide covers setting up **Enhanced Mode**.

## 📋 Prerequisites

- GitHub account
- Basic understanding of SSH keys
- Secure web server to host encrypted files (or use GitHub releases)

## 🔐 Step 1: Generate SSH Keys

### GitHub SSH Key

This key is used to authenticate with GitHub:

```bash
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519_github
```

**Add to GitHub**:
1. Go to GitHub → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste contents of `~/.ssh/id_ed25519_github.pub`

### Homelab/Server SSH Keys (Optional)

If you manage remote servers:

```bash
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519_homelab
```

Copy public key to your servers:
```bash
ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub user@server
```

## 📦 Step 2: Create Your Private Repository

### Create GitHub Repository

1. Go to GitHub → New Repository
2. Name it `sshsync` (or your preference)
3. Set to **Private**
4. Initialize with README
5. Clone it:
   ```bash
   git clone git@github.com:yourusername/sshsync.git ~/sshsync-setup
   cd ~/sshsync-setup
   ```

### Create SSH Config File

Create `ssh.conf` with your SSH hosts:

```bash
# ssh.conf
# This will be symlinked to ~/.ssh/config

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes

# Add your servers/hosts here
Host myserver
    HostName 192.168.1.100
    User yourusername
    IdentityFile ~/.ssh/id_ed25519_homelab
```

### Create README

Create a minimal `README.md`:

```markdown
# My Private SSH Sync

Private companion repository for [dotfiles](https://github.com/yourusername/dotfiles).

**⚠️ This repository is private and contains sensitive configuration.**

## Contents

- `ssh.conf` - SSH configuration with host definitions
- (SSH keys are stored as encrypted archive on web server, not in git)

## Setup

See the public dotfiles repository for setup instructions.
```

### Commit and Push

```bash
git add ssh.conf README.md
git commit -m "Initial sshsync setup"
git push
```

## 🔒 Step 3: Package SSH Keys

Download the packaging script from the public dotfiles repo:

```bash
cd ~/dotfiles
./package-ssh-keys.sh
```

Or run it directly:
```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/package-ssh-keys.sh | bash -s "your-secure-password"
```

This creates `~/ssh-keys.tar.gz.enc` containing all your SSH keys.

**Security Note**: Use a strong password (16+ characters). Store it securely (password manager recommended).

## 🌐 Step 4: Host Encrypted Archive

You need to host the encrypted archive at a URL accessible via wget/curl.

### Option A: Your Own Web Server

Upload `ssh-keys.tar.gz.enc` to your web server:

```bash
scp ~/ssh-keys.tar.gz.enc user@yourserver:/var/www/html/secure/
```

URL example: `https://yourserver.com/secure/ssh-keys.tar.gz.enc`

**Security**: 
- Use HTTPS
- Consider adding HTTP basic auth
- Use a non-obvious path
- The file is encrypted, but defense in depth is wise

### Option B: GitHub Releases (Not Recommended)

While technically possible to host on GitHub releases, it's not recommended for SSH keys even when encrypted. Use a web server you control.

### Option C: Cloud Storage with Direct Link

Services like Dropbox, AWS S3, etc. with direct download links can work, but ensure:
- Link is private/non-guessable
- HTTPS is used
- You trust the provider's security

## ⚙️ Step 5: Create Environment File

Create `dotfiles.env` with your configuration:

```bash
mkdir -p ~/dotfiles-env-backup
cat > ~/dotfiles-env-backup/dotfiles.env << 'EOF'
# Private dotfiles environment configuration
# Copy to ~/.config/dotfiles/dotfiles.env on new machines

SSHSYNC_REPO_URL="git@github.com:yourusername/sshsync.git"
SSH_KEYS_ARCHIVE_URL="https://yourserver.com/secure/ssh-keys.tar.gz.enc"
SSH_KEYS_ARCHIVE_PASSWORD="your-secure-password-here"
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"
EOF
```

**Storage Options**:

1. **In sshsync repo** (recommended):
   ```bash
   cp ~/dotfiles-env-backup/dotfiles.env ~/sshsync-setup/
   cd ~/sshsync-setup
   git add dotfiles.env
   git commit -m "Add environment configuration"
   git push
   ```

2. **Password manager**: Store as secure note

3. **Encrypted USB drive**: For air-gapped backup

## 🚀 Step 6: Set Up New Machine

On a new machine:

### 1. Transfer Environment File

Choose your method:

**From sshsync repo** (if stored there):
```bash
# Use personal access token or existing SSH setup
git clone https://github.com/yourusername/sshsync.git /tmp/sshsync
mkdir -p ~/.config/dotfiles
cp /tmp/sshsync/dotfiles.env ~/.config/dotfiles/
rm -rf /tmp/sshsync
```

**From password manager**: Copy and paste into file

**From USB**: 
```bash
mkdir -p ~/.config/dotfiles
cp /path/to/usb/dotfiles.env ~/.config/dotfiles/
```

### 2. Run Setup

```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

The script will:
1. Detect the environment file
2. Download encrypted SSH keys
3. Extract and set up SSH keys
4. Clone sshsync repository
5. Symlink SSH config
6. Clone dotfiles repository  
7. Set up terminal environment

### 3. Verify

```bash
# Check SSH keys
ls -la ~/.ssh/id_*

# Check SSH config
cat ~/.ssh/config

# Test GitHub connection
ssh -T git@github.com

# Check git config
git config --global --list
```

## 🔄 Updating Your Setup

### Update SSH Config

Edit in sshsync repo:
```bash
cd ~/sshsync
# Edit ssh.conf
git add ssh.conf
git commit -m "Update SSH config"
git push
```

On other machines:
```bash
cd ~/sshsync
git pull
# Symlink is already in place, changes take effect immediately
```

### Rotate SSH Keys

1. Generate new keys
2. Update GitHub/servers with new public keys
3. Re-run packaging script with new keys
4. Upload new archive (can use same URL)
5. Update password in environment file if changed
6. Re-run join.sh on machines

## 🛠️ Troubleshooting

### "Failed to decrypt archive"

- **Check password**: Verify `SSH_KEYS_ARCHIVE_PASSWORD` is correct
- **Check archive**: Re-download manually and test decryption:
  ```bash
  openssl enc -aes-256-cbc -d -pbkdf2 -in ssh-keys.tar.gz.enc -out test.tar.gz -pass pass:"your-password"
  ```

### "Failed to clone sshsync repository"

- **Check GitHub access**: Ensure SSH keys are set up for GitHub
- **Check repository URL**: Verify `SSHSYNC_REPO_URL` is correct
- **Check permissions**: Ensure you have access to the private repo

### "Command not found: dotpush"

- **Check mode**: Ensure environment file was detected
- **Check dotfiles**: Ensure dotfiles repo has the dotpush command
- **Reload shell**: Try `exec zsh` or restart terminal

### "Permission denied (publickey)"

- **Check key permissions**: Should be 600 for private keys
  ```bash
  chmod 600 ~/.ssh/id_*
  chmod 644 ~/.ssh/id_*.pub
  ```
- **Check SSH config**: Verify `~/.ssh/config` has correct key paths
- **Test SSH**: `ssh -vT git@github.com` for verbose output

## 🔐 Security Best Practices

1. **Never commit unencrypted SSH keys** to any git repository
2. **Use strong encryption passwords** (16+ characters, random)
3. **Rotate SSH keys periodically** (annually recommended)
4. **Use different keys** for different purposes (GitHub vs servers)
5. **Store environment file securely** (password manager or encrypted storage)
6. **Limit archive accessibility** (HTTPS, authentication, obscure URLs)
7. **Review sshsync repo access** (keep private, limit collaborators)
8. **Enable 2FA** on GitHub and hosting provider

## 📝 Customization Ideas

### Add More Private Configs

Add any private configuration files to sshsync:

```bash
cd ~/sshsync
# Add files
git add .
git commit -m "Add private configs"
git push
```

Update join.sh symlink section to include them.

### Add Environment-Specific Configs

Create multiple environment files for different scenarios:

- `dotfiles.env.work` - Work machine config
- `dotfiles.env.home` - Home machine config
- `dotfiles.env.minimal` - Minimal/temporary setup

### Conditional Features

Modify dotfiles to check for sshsync presence:

```bash
# In .zshrc
if [ -d "$HOME/sshsync" ]; then
    # Load private aliases
    source "$HOME/sshsync/private-aliases.zsh"
fi
```

## 🎓 Understanding the System

### Flow Diagram

```
New Machine
    ↓
Place dotfiles.env → ~/.config/dotfiles/
    ↓
Run join.sh
    ↓
[Detects .env] → Enhanced Mode
    ↓
Download encrypted keys → Extract to ~/.ssh
    ↓
Create temp SSH config (for GitHub)
    ↓
Clone sshsync repo → Symlink ssh.conf → ~/.ssh/config
    ↓
Clone dotfiles repo
    ↓
Install tools (Zsh, Starship)
    ↓
Create dotfiles symlinks
    ↓
Set Git config
    ↓
Complete! ✅
```

### File Locations

```
~/.config/dotfiles/dotfiles.env     # Environment configuration (you provide)
~/.ssh/config                        # Symlink → ~/sshsync/ssh.conf
~/.ssh/id_*                          # SSH keys (from encrypted archive)
~/sshsync/                           # Private repo (cloned via join.sh)
~/dotfiles/                          # Public repo (cloned via join.sh)
~/.zshrc                             # Symlink → ~/dotfiles/.zshrc
~/.config/starship.toml              # Symlink → ~/dotfiles/.config/starship.toml
```

## ❓ FAQ

**Q: Can I use this without creating a private repo?**  
A: Yes! Just run join.sh without creating a dotfiles.env file. You'll get all the public dotfiles features.

**Q: Is it safe to store dotfiles.env in the private repo?**  
A: Yes, if the repo is truly private. The passwords are still in plaintext, so ensure repo access is restricted.

**Q: Can I use this for multiple users/teams?**  
A: Each user needs their own sshsync repo with their own SSH keys. The dotfiles repo can be shared.

**Q: What if I don't have a web server?**  
A: Consider: GitHub releases (less secure), cloud storage with direct links, or SSH into a machine you control and use SCP.

**Q: Can I automate new machine setup completely?**  
A: Almost! You still need to manually place the dotfiles.env file (for security). Everything else is automated.

**Q: How do I migrate from old setup?**  
A: Package your existing SSH keys, upload archive, create environment file, then run the new join.sh on a test machine.

## 📞 Support

- **Issues**: Open an issue on the public dotfiles repository
- **Security concerns**: Contact repository owner directly (don't post sensitive info in issues)
- **Contributions**: PRs welcome for documentation improvements

---

**Happy configuring! 🎉**
```

---

## Files to Modify

### 6. Update `dotpush` Command (if exists)

If your dotfiles repo has a `dotpush` command/alias/function, modify it to check for sshsync:

```bash
# Example dotpush function (add to .zshrc or similar)
dotpush() {
    if [ ! -d "$HOME/sshsync/.git" ]; then
        echo "❌ dotpush requires a private sshsync repository"
        echo ""
        echo "This command syncs private configurations to your sshsync repo."
        echo "To set this up, see:"
        echo "https://github.com/puckawayjeff/dotfiles/blob/main/PRIVATE_SETUP.md"
        return 1
    fi
    
    cd "$HOME/sshsync" || return 1
    git add .
    git commit -m "Update private configs from $(hostname)"
    git push
    cd - > /dev/null
}
```

---

## Testing Checklist

After implementing all changes, test:

- [ ] **Standalone mode**: Delete dotfiles.env, run join.sh on fresh system
- [ ] **Enhanced mode**: With valid dotfiles.env, run join.sh on fresh system
- [ ] **Invalid password**: Test with wrong password in dotfiles.env
- [ ] **Missing variables**: Test with incomplete dotfiles.env
- [ ] **Network failure**: Test with unreachable archive URL
- [ ] **Existing installation**: Run join.sh on system that already has setup
- [ ] **SSH key permissions**: Verify all keys have correct permissions
- [ ] **Symlinks**: Verify all symlinks point to correct locations
- [ ] **Git config**: Verify git config is correct in both modes
- [ ] **Package script**: Test SSH key packaging and verification
- [ ] **Documentation**: Have someone else follow PRIVATE_SETUP.md

---

## Summary of Changes

### Public Repo Will Have:
1. ✅ Standalone-capable join.sh
2. ✅ Enhanced mode with .env detection
3. ✅ SSH key archive download/extract logic
4. ✅ Conditional sshsync repo setup
5. ✅ Complete documentation (README, PRIVATE_SETUP.md)
6. ✅ Helper script (package-ssh-keys.sh)
7. ✅ Template (.env.example)

### Private Repo (sshsync) Will Have:
1. ✅ Minimal README (data-only repo)
2. ✅ ssh.conf (SSH configuration)
3. ✅ Optional: dotfiles.env (for backup)
4. ✅ No functional scripts (removed join.sh, join.ps1)

---

## Migration Path

For existing machines already set up with old system:

1. Package SSH keys using new script
2. Upload encrypted archive
3. Create dotfiles.env file
4. Place in ~/.config/dotfiles/
5. Re-run new join.sh
6. Old setup will be updated to new structure

---

**This comprehensive refactor separates concerns perfectly:**
- **Public repo** = functionality + documentation
- **Private repo** = your personal data only
- **Other users** can fork public repo and create their own private repo following your documentation
