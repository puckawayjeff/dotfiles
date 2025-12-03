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

# --- Logging Helpers ---

# Print a section header
# Usage: log_section "Section Name" "Optional Icon"
log_section() {
    local title="$1"
    local icon="${2:-$ROCKET}"
    printf "\n${CYAN}${icon} ${title}...${NC}\n"
}

# Print a success message
# Usage: log_success "Message"
log_success() {
    printf "${GREEN}${CHECK} $1${NC}\n"
}

# Print an error message
# Usage: log_error "Message"
log_error() {
    printf "${RED}${CROSS} Error: $1${NC}\n" >&2
}

# Print an info message (blue)
# Usage: log_info "Message"
log_info() {
    printf "${BLUE}$1${NC}\n"
}

# Print a warning message (yellow)
# Usage: log_warning "Message"
log_warning() {
    printf "${YELLOW}$1${NC}\n"
}

# Print a sub-step description
# Usage: log_substep "Message"
log_substep() {
    echo "   ↳ $1"
}
