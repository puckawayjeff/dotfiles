#!/usr/bin/env bash
# lib/motd.sh - Dynamic MOTD script for dotfiles
# This script is executed by update-motd system on login
# Symlinked from /etc/update-motd.d/99-dotfiles
#
# Purpose: Display system information on terminal login without running on every shell reload
# Extends beyond just fastfetch for customizable system information display

# Exit on error
set -e

# --- Ensure proper terminal environment for colors ---
# MOTD scripts run in a limited environment during SSH login
# Explicitly set TERM if not already set to enable color output
if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
    export TERM=xterm-256color
fi

# Force color output for fastfetch (it may detect non-interactive context)
export COLORTERM=truecolor

# --- Determine user home directory ---
# MOTD runs during PAM session, may not have proper HOME set
# Try to detect the actual user logging in
if [ -n "$PAM_USER" ]; then
    LOGIN_USER="$PAM_USER"
elif [ -n "$USER" ] && [ "$USER" != "root" ]; then
    LOGIN_USER="$USER"
else
    # Fallback: try to get from environment or default
    LOGIN_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
fi

# Get the user's actual home directory
if [ -n "$LOGIN_USER" ]; then
    USER_HOME=$(getent passwd "$LOGIN_USER" | cut -d: -f6)
else
    USER_HOME="$HOME"
fi

# --- Fastfetch Display ---
if command -v fastfetch >/dev/null 2>&1; then
    # Explicitly specify config file path using detected user home
    FASTFETCH_CONFIG="$USER_HOME/.config/fastfetch/config.jsonc"
    
    if [ -n "$LOGIN_USER" ] && [ "$LOGIN_USER" != "root" ]; then
        # Run fastfetch as the actual login user with login environment
        # Use - flag to create a proper login shell environment for correct locale, shell detection
        # Export TERM and COLORTERM explicitly for color support
        if [ -f "$FASTFETCH_CONFIG" ]; then
            su - "$LOGIN_USER" -c "export TERM='$TERM' COLORTERM='$COLORTERM'; fastfetch --config '$FASTFETCH_CONFIG'"
        else
            su - "$LOGIN_USER" -c "export TERM='$TERM' COLORTERM='$COLORTERM'; fastfetch"
        fi
    else
        # Fallback: run as current user (shouldn't happen in normal MOTD context)
        if [ -f "$FASTFETCH_CONFIG" ]; then
            fastfetch --config "$FASTFETCH_CONFIG"
        else
            fastfetch
        fi
    fi
else
    # Fallback if fastfetch is not installed
    echo "Dotfiles MOTD: fastfetch not installed"
fi

# --- Future Extensions ---
# Add additional system information here:
# - Disk usage warnings
# - Available system updates
# - Custom reminders or alerts
# - Git repository status
# - Container/service status
# etc.
