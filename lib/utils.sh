#!/usr/bin/env bash
# lib/utils.sh - Shared library for colors, icons, and helper functions

# --- Color Definitions ---
if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    RED=$(tput setaf 1)
    BOLD=$(tput bold)
    NC=$(tput sgr0)
else
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    RED='\033[0;31m'
    BOLD='\033[1m'
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
CLOCK="🕒"
KEYBOARD="⌨️"
BOOK="📚"
ARROW="→"
LIGHTBULB="💡"
INFO="ℹ️"

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

# Print a data item with icon and custom color formatting
# Usage: log_data "Icon" "Color" "Message"
# Example: log_data "$CLOCK" "$YELLOW" "Thu Dec 4, 2025 at 3:02 PM"
log_data() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        local icon="$1"
        local color="$2"
        local message="$3"
        printf "${icon} ${color}${message}${NC}\n"
    fi
}

# --- Terminal Utilities ---

# Get terminal width-adjusted horizontal rule
# Usage: HR=$(get_hr)
# Returns: String of box-drawing characters (━) matching terminal width
get_hr() {
    local term_width=$(tput cols 2>/dev/null || echo 80)
    printf "━%.0s" $(seq 1 $term_width)
}
