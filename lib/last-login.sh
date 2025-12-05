#!/usr/bin/env bash
# lib/last-login.sh - Custom last login display for SSH sessions
# Uses 'last' command (wtmp) for login history with styled output and IP-to-hostname mapping

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
    ["100.119.235.30"]="486turbo"
    ["100.121.137.4"]="ahma-sensor"
    ["100.79.132.105"]="bearmedal-dockarr"
    ["100.105.99.24"]="bearmedal-dockge"
    ["100.80.173.59"]="bearmedal-jellyfin"
    ["100.72.150.27"]="bearmedal"
    ["100.75.19.2"]="goots"
    ["100.96.225.119"]="homeassistant"
    ["100.120.65.113"]="homeassistantpw"
    ["100.124.217.71"]="i360-vault"
    ["100.100.166.103"]="krang"
    ["100.85.17.10"]="memoryalpha"
    ["100.108.231.16"]="molterpi"
    ["100.72.161.73"]="muncle"
    ["100.127.136.19"]="puckamedia"
    ["100.80.96.108"]="puckapixelpro"
    ["100.94.232.123"]="puckasurface"
    ["100.81.251.77"]="puttputt"
    ["100.74.28.50"]="rubbermaid-dockge"
    ["100.125.82.55"]="rubbermaid-qbittorrent"
    ["100.108.11.1"]="rubbermaid-syncthing"
    ["100.121.220.125"]="rubbermaid"
    ["100.108.232.61"]="workshop-sensor"
    ["100.113.116.36"]="yggyfin"
    ["100.123.105.87"]="yggymedia"
    ["100.99.219.32"]="yggystump"
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

# --- Get last login host for fastfetch ---
get_last_login_host() {
    local current_user="${USER}"
    
    # Get the most recent completed login (excluding current session)
    # -i shows IPs instead of hostnames, -n limits results
    local last_entry=$(last -i -n 3 "$current_user" 2>/dev/null | grep -v "still logged in" | head -n 1)
    
    if [ -z "$last_entry" ]; then
        echo "never"
        return
    fi
    
    # Extract the source (3rd column)
    local from_source=$(echo "$last_entry" | awk '{print $3}')
    
    if [ -z "$from_source" ] || [ "$from_source" = "-" ]; then
        echo "local"
        return
    fi
    
    # Check if it's an IP address (contains dots or colons for IPv6)
    if [[ "$from_source" =~ [.:] ]]; then
        resolve_ip "$from_source"
    else
        # Already a hostname or display (e.g., :0, tty)
        echo "$from_source"
    fi
}

# --- Get last login time for fastfetch ---
get_last_login_time() {
    local current_user="${USER}"
    
    # Get the most recent completed login (excluding current session)
    local last_entry=$(last -i -n 3 "$current_user" 2>/dev/null | grep -v "still logged in" | head -n 1)
    
    if [ -z "$last_entry" ]; then
        echo "never"
        return
    fi
    
    # Extract timestamp from last output
    # Format: username tty source day month date time - time year
    # Example: jeff pts/0 100.75.19.2 Thu Dec 5 14:23 - 15:30 (01:07)
    local timestamp=$(echo "$last_entry" | awk '{for(i=4;i<=NF-3;i++) printf "%s ", $i; print ""}' | sed 's/ *$//')
    
    format_timestamp "$timestamp"
}
