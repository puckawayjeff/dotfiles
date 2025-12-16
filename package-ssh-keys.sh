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
    log_info "Generate keys with: ssh-keygen -t ed25519 -C \"your@email.com\""
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
    printf "Enter password for encryption: "
    read -s PASSWORD
    echo ""
    if [ -z "$PASSWORD" ]; then
        log_error "Password cannot be empty"
        exit 1
    fi
    printf "Confirm password: "
    read -s PASSWORD_CONFIRM
    echo ""
    if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
        log_error "Passwords do not match"
        exit 1
    fi
fi

if [ ${#PASSWORD} -lt 12 ]; then
    log_warning "Password is shorter than 12 characters. Consider using a stronger password."
    printf "Continue anyway? (y/N): "
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
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

# Encrypt using openssl with AES-256-CBC (widely compatible, secure with PBKDF2)
openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in ssh-keys.tar.gz -out ssh-keys.tar.gz.enc -pass pass:"$PASSWORD"

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

if openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in "$OUTPUT_FILE" -out "$VERIFY_DIR/test.tar.gz" -pass pass:"$PASSWORD" 2>/dev/null; then
    if tar -tzf "$VERIFY_DIR/test.tar.gz" >/dev/null 2>&1; then
        log_success "Archive verified successfully"
        echo ""
        log_info "Contents:"
        tar -tzf "$VERIFY_DIR/test.tar.gz" | sed 's/^/   • /'
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
