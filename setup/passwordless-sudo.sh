#!/usr/bin/env bash
# Toggles passwordless sudo for the current user on Debian/Ubuntu-based systems.
# This script is idempotent and safe to run multiple times.
# Usage: ./passwordless-sudo.sh [--enable|--disable]
#   --enable   Enable passwordless sudo (default if no flag provided)
#   --disable  Disable passwordless sudo (restore password requirement)

# Exit immediately if a command exits with a non-zero status
set -e

# Load shared utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found"
    exit 1
fi

# --- Configuration ---
CURRENT_USER="${SUDO_USER:-$USER}"
SUDOERS_FILE="/etc/sudoers.d/99-${CURRENT_USER}-nopasswd"
ACTION="${1:-enable}"

# Normalize action flag
case "$ACTION" in
    --enable|-e|enable)
        ACTION="enable"
        ;;
    --disable|-d|disable)
        ACTION="disable"
        ;;
    --help|-h|help)
        echo "Usage: $0 [--enable|--disable]"
        echo ""
        echo "Options:"
        echo "  --enable, -e   Enable passwordless sudo for current user (default)"
        echo "  --disable, -d  Disable passwordless sudo (restore password requirement)"
        echo "  --help, -h     Show this help message"
        exit 0
        ;;
    *)
        log_error "Unknown option: $ACTION"
        echo "Usage: $0 [--enable|--disable]"
        exit 1
        ;;
esac

# --- Main Script ---
log_section "Passwordless Sudo Configuration" "$WRENCH"

# Display current user
log_info "Target user: ${BOLD}${CURRENT_USER}${NC}"
log_info "Sudoers file: ${BOLD}${SUDOERS_FILE}${NC}"

# Check if running with sudo privileges
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run with sudo privileges."
    log_substep "Try: sudo $0 $ACTION"
    exit 1
fi

# --- Enable Passwordless Sudo ---
if [ "$ACTION" == "enable" ]; then
    log_step "Enabling passwordless sudo..." "$ROCKET"
    
    # Check if already configured
    if [ -f "$SUDOERS_FILE" ]; then
        log_success "Passwordless sudo already enabled for ${CURRENT_USER}."
        log_substep "File exists: $SUDOERS_FILE"
    else
        log_substep "Creating sudoers entry..."
        
        # Create the sudoers file with proper permissions
        echo "${CURRENT_USER} ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
        
        # Ensure correct permissions (must be 0440 or 0400)
        chmod 0440 "$SUDOERS_FILE"
        
        # Validate syntax using visudo
        log_substep "Validating sudoers syntax..."
        if ! visudo -c -f "$SUDOERS_FILE" > /dev/null 2>&1; then
            log_error "Sudoers syntax validation failed!"
            rm -f "$SUDOERS_FILE"
            exit 1
        fi
        
        log_success "Passwordless sudo enabled for ${CURRENT_USER}."
    fi
    
    log_complete "Passwordless sudo is now active!"
    printf "\n${YELLOW}${WARNING} Note: You can now use 'sudo' without entering your password.${NC}\n"
    printf "${YELLOW}${ARROW} To disable, run: sudo $0 --disable${NC}\n"

# --- Disable Passwordless Sudo ---
elif [ "$ACTION" == "disable" ]; then
    log_step "Disabling passwordless sudo..." "$WRENCH"
    
    # Check if the file exists
    if [ -f "$SUDOERS_FILE" ]; then
        log_substep "Removing sudoers entry..."
        rm -f "$SUDOERS_FILE"
        log_success "Passwordless sudo disabled for ${CURRENT_USER}."
    else
        log_success "Passwordless sudo was not enabled for ${CURRENT_USER}."
        log_substep "File not found: $SUDOERS_FILE"
    fi
    
    log_complete "Password requirement restored!"
    printf "\n${YELLOW}${INFO} Note: You will now need to enter your password for sudo commands.${NC}\n"
    printf "${YELLOW}${ARROW} To re-enable, run: sudo $0 --enable${NC}\n"
fi
