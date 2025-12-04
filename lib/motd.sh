#!/usr/bin/env bash
# lib/motd.sh - Dynamic MOTD script for dotfiles
# This script is executed by update-motd system on login
# Symlinked from /etc/update-motd.d/99-dotfiles
#
# Purpose: Display system information on terminal login without running on every shell reload
# Extends beyond just fastfetch for customizable system information display

# Exit on error
set -e

# --- Fastfetch Display ---
if command -v fastfetch >/dev/null 2>&1; then
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
