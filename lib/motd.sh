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

# --- Fastfetch Display ---
if command -v fastfetch >/dev/null 2>&1; then
    # Run fastfetch normally - environment variables ensure color output
    # The --pipe flag would disable colors, so we explicitly avoid it
    fastfetch
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
