# ~/.zprofile - Executed by login shells

# Check if cage and foot are installed before attempting to autostart
if command -v cage &> /dev/null && command -v foot &> /dev/null; then
  # Autostart cage+foot on tty1 if not already in a graphical session
  if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec cage foot
  fi
fi
