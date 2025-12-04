#!/usr/bin/env bash
# lib/last-login.sh - Custom last login display for SSH sessions
# Replaces PAM's pam_lastlog with styled output and IP-to-hostname mapping

# Source our utilities for colors and styling
# Handle both bash and zsh
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
elif [ -n "${(%):-%x}" ]; then
    # Zsh
    SCRIPT_DIR="$( cd "$( dirname "${(%):-%x}" )" && pwd )"
else
    # Fallback
    SCRIPT_DIR="$HOME/dotfiles/lib"
fi
source "$SCRIPT_DIR/utils.sh"

# --- IP to Hostname Mapping ---
# Add your known hosts here in the format: "IP:hostname"
# Example: "100.100.166.103:krang"
declare -A IP_HOSTNAMES=(
    ["100.100.166.103"]="krang"
    # Add more mappings as needed:
    # ["192.168.1.100"]="server1"
    # ["10.0.0.50"]="workstation"
)

# --- Format timestamp for cleaner display ---
# Input: "Thu Dec  4 13:43:56 2025" (lastlog format)
# Output: "Thu Dec 4, 2025 at 1:43 PM" (human-friendly)
format_timestamp() {
    local timestamp="$1"
    
    # Try to parse and reformat using date command
    # Handle both lastlog format and wtmp format
    if date_output=$(date -d "$timestamp" "+%a %b %-d, %Y at %-I:%M %p" 2>/dev/null); then
        echo "$date_output"
    else
        # Fallback: return original if parsing fails
        echo "$timestamp"
    fi
}

# --- Resolve IP to hostname ---
resolve_ip() {
    local ip="$1"
    
    # Check our mapping table first
    if [ -n "${IP_HOSTNAMES[$ip]}" ]; then
        echo "${IP_HOSTNAMES[$ip]}"
        return 0
    fi
    
    # Fallback to IP address
    echo "$ip"
    return 1
}

# --- Get last login information ---
get_last_login() {
    local current_user="${USER}"
    
    # Get last login from wtmp (excludes current session)
    # Format: username tty login_time - IP
    local last_entry=$(last -i -n 2 "$current_user" 2>/dev/null | grep -v "still logged in" | head -n 1)
    
    if [ -z "$last_entry" ]; then
        # Fallback to lastlog if last command fails
        local lastlog_output=$(lastlog -u "$current_user" 2>/dev/null | tail -n 1)
        
        if echo "$lastlog_output" | grep -q "Never logged in"; then
            return 1
        fi
        
        # Parse lastlog output
        # Format: Username Port From Latest
        local from_ip=$(echo "$lastlog_output" | awk '{print $3}')
        local timestamp=$(echo "$lastlog_output" | awk '{$1=$2=$3=""; print $0}' | sed 's/^[ \t]*//')
        
        if [ -n "$from_ip" ] && [ "$from_ip" != "**Never" ]; then
            local resolved=$(resolve_ip "$from_ip")
            local formatted_time=$(format_timestamp "$timestamp")
            echo "from ${CYAN}${resolved}${NC} on ${YELLOW}${formatted_time}${NC}"
            return 0
        fi
        
        return 1
    fi
    
    # Parse 'last' output
    # Example: jeff     pts/0        100.100.166.103  Thu Dec  4 13:43   still logged in
    local from_ip=$(echo "$last_entry" | awk '{print $3}')
    local timestamp=$(echo "$last_entry" | awk '{for(i=4;i<=NF-3;i++) printf "%s ", $i; print ""}' | sed 's/ *$//')
    
    # Handle cases where there's no IP (local login)
    if [ -z "$from_ip" ] || [ "$from_ip" = "-" ]; then
        local formatted_time=$(format_timestamp "$timestamp")
        echo "locally on ${YELLOW}${formatted_time}${NC}"
        return 0
    fi
    
    local resolved=$(resolve_ip "$from_ip")
    local formatted_time=$(format_timestamp "$timestamp")
    
    echo "from ${CYAN}${resolved}${NC} on ${YELLOW}${formatted_time}${NC}"
    return 0
}

# --- Main execution ---
# Only display during SSH sessions to replace PAM's lastlog
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
    last_login_info=$(get_last_login)
    
    if [ $? -eq 0 ] && [ -n "$last_login_info" ]; then
        printf "${GREEN}Last login${NC}: ${last_login_info}\n"
    fi
fi
