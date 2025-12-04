#!/usr/bin/env bash
# lib/utils.sh - Shared library for colors, icons, and helper functions

# --- Color Definitions ---
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

# --- Emoji Constants ---
ROCKET="🚀"
WRENCH="🔧"
CHECK="✅"
CROSS="❌"
COMPUTER="💻"
PARTY="🎉"
PACKAGE="📦"
FOLDER="📁"
LINK="🔗"
PENCIL="📝"
ARROW_DOWN="⬇️"
ARROW_UP="⬆️"
RELOAD="🔄"
WARNING="⚠️"

# --- Logging Helpers ---
# Supports QUIET_MODE environment variable to suppress verbose output

# Print a section header
# Usage: log_section "Section Name" "Optional Icon"
log_section() {
    # Always show section headers, even in quiet mode
    local title="$1"
    local icon="${2:-$ROCKET}"
    printf "\n${CYAN}${icon} ${title}...${NC}\n"
}

# Print a success message
# Usage: log_success "Message"
log_success() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        printf "${GREEN}${CHECK} $1${NC}\n"
    fi
}

# Print an error message
# Usage: log_error "Message"
log_error() {
    # Always show errors, even in quiet mode
    printf "${RED}${CROSS} Error: $1${NC}\n" >&2
}

# Print an info message (blue)
# Usage: log_info "Message"
log_info() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        printf "${BLUE}$1${NC}\n"
    fi
}

# Print a warning message (yellow)
# Usage: log_warning "Message"
log_warning() {
    # Always show warnings, even in quiet mode
    printf "${YELLOW}$1${NC}\n"
}

# Print a sub-step description
# Usage: log_substep "Message"
log_substep() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "   ↳ $1"
    fi
}

# Print a step with custom icon (blue text)
# Usage: log_step "Message" "Icon"
log_step() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        local message="$1"
        local icon="${2:-$WRENCH}"
        printf "${BLUE}${icon} ${message}${NC}\n"
    fi
}

# Print a plain message without icon or color
# Usage: log_plain "Message"
log_plain() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo "$1"
    fi
}

# Print a completion/celebration message (green with party icon)
# Usage: log_complete "Message"
log_complete() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        printf "\n${GREEN}${PARTY} $1${NC}\n"
    fi
}

# Print an action in progress with custom icon (cyan text)
# Usage: log_action "Message" "Optional Icon"
log_action() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        local message="$1"
        local icon="${2:-$COMPUTER}"
        printf "${CYAN}${icon} ${message}${NC}\n"
    fi
}
