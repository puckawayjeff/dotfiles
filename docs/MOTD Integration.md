# MOTD (Message of the Day) Integration

## Overview

The dotfiles repository integrates with the Linux `update-motd` system to display system information on terminal login, rather than on every shell reload. This provides a better user experience by showing the information once per session while keeping shell startup fast.

## How It Works

### Dynamic MOTD System

Modern Debian-based systems use a dynamic MOTD framework where:
- Scripts in `/etc/update-motd.d/` are executed at login by `pam_motd`
- Scripts are run in alphabetical order (named `NN-description`)
- Output is concatenated to `/run/motd.dynamic`

### Dotfiles Implementation

The dotfiles repository provides:

1. **`lib/motd.sh`** - The main MOTD script containing:
   - Fastfetch system information display
   - Placeholder for future extensions (disk warnings, update notifications, etc.)
   - Graceful fallback if fastfetch isn't installed

2. **`/etc/update-motd.d/99-dotfiles`** - Standalone script that execs `lib/motd.sh`:
   - Created automatically by `install.sh` (not a symlink, per man update-motd)
   - Simple wrapper that calls `exec ~/dotfiles/lib/motd.sh`
   - Runs last (99-prefix) to display after system MOTD fragments
   - Requires sudo for initial setup
   - Can be safely modified by admins without being overwritten on updates

3. **Modified `.zshrc`** - Fastfetch no longer runs on every shell reload:
   - Compatibility aliases still provided (`neofetch`, `screenfetch`, `ff`)
   - Can manually invoke fastfetch anytime with `fastfetch` or `ff`

## Setup

The MOTD integration is configured automatically when running `install.sh`:

```bash
cd ~/dotfiles && ./install.sh
### What Happens

1. Checks if `/etc/update-motd.d/` exists (standard on Debian/Ubuntu)
2. Creates standalone script at `/etc/update-motd.d/99-dotfiles` that execs `lib/motd.sh`
3. Makes the fragment executable
4. Removes auto-launch from `.zshrc` (keeps aliases)

**Note:** Following `man update-motd` best practices, we create a standalone script rather than a symlink. This allows administrators to modify the fragment without having changes overwritten during dotfiles updates.on Debian/Ubuntu)
### Manual Setup

If `install.sh` was run without sudo, or on a system that doesn't support update-motd:

```bash
# Create the MOTD fragment manually (not a symlink, per man update-motd)
sudo tee /etc/update-motd.d/99-dotfiles > /dev/null << 'EOF'
#!/bin/sh
# Dotfiles MOTD fragment - calls external script
exec ~/dotfiles/lib/motd.sh
EOF

sudo chmod +x /etc/update-motd.d/99-dotfiles

# Or skip MOTD and let fastfetch run from .zshrc instead
# (No action needed - .zshrc will auto-launch if MOTD isn't configured)
```
# Or skip MOTD and let fastfetch run from .zshrc instead
# (No action needed - .zshrc will auto-launch if MOTD isn't configured)
```

## Customization

### Extending lib/motd.sh

Add custom information to display on login:

```bash
# Example additions to lib/motd.sh

# Disk usage warning
df -h / | awk 'NR==2 {if ($5+0 > 90) print "⚠️  Root disk usage: " $5}'

# Available updates
if command -v apt &> /dev/null; then
    updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    if [ "$updates" -gt 0 ]; then
        echo "📦 $updates package updates available"
    fi
fi

# Git status for development hosts
if [ -d ~/projects ]; then
    echo "📁 Project status:"
    find ~/projects -maxdepth 2 -name .git -type d | while read gitdir; do
### Disabling MOTD

To stop showing MOTD on login:

```bash
# Remove the fragment
sudo rm /etc/update-motd.d/99-dotfiles

# Or make it non-executable
sudo chmod -x /etc/update-motd.d/99-dotfiles

# Re-enable in .zshrc if desired
# Edit config/.zshrc and restore the fastfetch auto-launch
```
To stop showing MOTD on login:

```bash
# Remove the symlink
sudo rm /etc/update-motd.d/99-dotfiles

# Re-enable in .zshrc if desired
# Edit config/.zshrc and restore the fastfetch auto-launch
```

## System Compatibility

### Supported Systems
- Debian 10+
- Ubuntu 18.04+
- Linux Mint
- Raspberry Pi OS
- Proxmox VE
- Most Debian derivatives

### Fallback Behavior

If the system doesn't support `update-motd`:
- `install.sh` displays info message and skips MOTD setup
- `.zshrc` can be modified to auto-launch fastfetch as before
- No errors or broken functionality

### PAM Configuration

The MOTD system requires PAM configuration (standard on Debian/Ubuntu):

```bash
### MOTD Not Showing

1. **Check fragment exists and is executable:**
   ```bash
   ls -la /etc/update-motd.d/99-dotfiles
   test -x /etc/update-motd.d/99-dotfiles && echo "Executable" || echo "Not executable"
   ```
/etc/pam.d/login:session    optional   pam_motd.so motd=/run/motd.dynamic
/etc/pam.d/sshd:session     optional   pam_motd.so motd=/run/motd.dynamic
```

## Troubleshooting

### MOTD Not Showing

1. **Check symlink exists:**
   ```bash
   ls -la /etc/update-motd.d/99-dotfiles
   ```

2. **Verify script is executable:**
   ```bash
   test -x ~/dotfiles/lib/motd.sh && echo "Executable" || echo "Not executable"
   ```

3. **Test manually:**
   ```bash
   ~/dotfiles/lib/motd.sh
   ```

4. **Check PAM configuration:**
   ```bash
   grep pam_motd /etc/pam.d/login /etc/pam.d/sshd
   ```

### MOTD Shows on Shell Reload

This is expected behavior if connecting via SSH or using certain terminal emulators. The MOTD shows on:
- SSH login
- Console login (Ctrl+Alt+F1)
- `login` shell sessions

It should NOT show on:
- New terminal tabs in GUI
- New tmux windows/panes
- Running `zsh` from an existing shell

### Fastfetch Still Running from .zshrc

Check if the MOTD setup section in `.zshrc` was updated:

```bash
grep -A 5 "Fastfetch Integration" ~/.zshrc
```

Should see a note about MOTD, not an auto-launch command.

## Benefits

1. **Performance** - Shell startup is faster without running fastfetch on every reload
2. **Cleaner UX** - Information shown once per session, not every new shell/tab
3. **Extensible** - Easy to add custom login messages and system checks
4. **Standard** - Uses the Linux standard MOTD framework
5. **Portable** - Graceful fallback on unsupported systems

## References

- `man update-motd` - Full documentation on the MOTD system
- `man pam_motd` - PAM module for MOTD display
- `man run-parts` - Script execution order rules
