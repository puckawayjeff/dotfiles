# Dotfiles v1.2.0 Release Notes

**Release Date**: December 5, 2025

## Welcome Home - The Login Experience Release

This release focuses on making terminal login more informative and pleasant. The generic "Last login" message is replaced with styled output, fastfetch displays system info via MOTD, and the configuration architecture got cleaner.

## What's New

### Better Login Display

The standard PAM lastlog message is gone. Now when logging in via SSH:

**MOTD shows fastfetch output:**
- Distribution logo (ASCII art)
- System identity, uptime, shell
- Hardware specs (CPU, GPU, memory, disk)
- Network info including Tailscale IPs
- Battery status on mobile devices
- Dotfiles version

**Then a styled login message:**
```
Last login: from krang on Thu Dec 5, 2025 at 9:23 AM
```

IP addresses can map to friendly hostnames via a lookup table in `lib/last-login.sh`. Timestamps are formatted more readably. Nothing revolutionary, just cleaner.

### Fastfetch Split Into Two Configs

Fastfetch now has separate configs for different contexts:

**Login Display** (`config/fastfetch-motd.jsonc`):
- System identity and health metrics
- 3-second timeout for speed
- Drops package counts, desktop environment details, display info

**Interactive Use** (`config/fastfetch.jsonc`):
- Full system information with all modules
- Available via `fastfetch`, `ff`, `neofetch`, or `screenfetch` aliases

Fastfetch no longer runs on every shell reload, just at login. Shells start faster, system info appears when it's actually useful.

### Configuration Architecture Refactored

How configs are managed got reorganized:

**Core tools** (zsh, starship, fastfetch, tmux):
- Handled by their installer scripts in `lib/terminal.sh`
- Installed and configured as a unit
- Automatic setup during initial deployment

**User-added configs** (via `add-dotfile`):
- Tracked in `config/symlinks.conf`
- Separate from core tool management
- Easier to add and track individual dotfiles

This makes `install.sh` cleaner and troubleshooting simpler.

### Other Improvements

**IP-to-Hostname Mapping**: The last login script has a lookup table for mapping IPs to friendly names. Edit the associative array in `lib/last-login.sh` to add mappings.

**Directory Context in `maintain`**: The `maintain` function now properly returns to the original directory before reloading the shell.

**MOTD Color Rendering**: Fixed fastfetch color output in MOTD context by forcing `TERM` and `COLORTERM` environment variables.

## Upgrading from v1.1.0

```bash
dotpull
# or
maintain
```

**What changes:**

1. Login screen shows fastfetch via MOTD plus styled last login message
2. Fastfetch no longer runs on shell reload (faster startup)
3. New functions: `maintain`, `dotversion`, and optional `sshpush`/`sshpull`
4. Configuration architecture reorganized (symlinks.conf added)

**What stays the same:**

Everything else. All existing aliases, functions, and workflows work as before. This is purely additive.

## Documentation Updates

Filled in the missing pieces:

- **Functions Reference** now documents `maintain()`, `dotversion()`, and the SSH sync functions
- **MOTD Integration** guide covers the new login system
- **Last Login Display** documented in Setup Scripts Reference
- **Changelog** has full technical details

## Implementation Details

- **MOTD Integration**: Uses Debian's `update-motd` system
- **Custom Last Login**: Replaces PAM lastlog with styled version
- **Execution Context**: Fixed fastfetch to run as login user (not root) in MOTD
- **Color Support**: Forces truecolor mode in MOTD context
- **Symlink Architecture**: Core configs separated from user configs
- **Conditional Loading**: SSH sync functions only load when `~/sshsync` exists

Full technical details in [CHANGELOG](CHANGELOG.md).

---

Documentation: `docs/` directory  
Functions: [Functions Reference](docs/Functions%20Reference.md)

```bash
# Start a new tmux session
tmux

# Split vertically with |
# Press: Ctrl+b then |

# Split horizontally with -
# Press: Ctrl+b then -

# Navigate panes with vim keys
# Press: Ctrl+b then h/j/k/l

# Detach from session
# Press: Ctrl+b then d

# List sessions
tmux ls

# Reattach to session
tmux attach
```

### Test Enhanced updatep

```bash
# Run system updates (runs in background)
updatep

# View the log after completion
cat ~/.cache/updatep.log

# Or use the full maintenance workflow
maintain
```

## 📦 What's Included

### Core Components
- **install.sh**: Symlink management and installation orchestration
- **lib/terminal.sh**: Terminal utilities including tmux installation
- **config/tmux.conf**: Complete tmux configuration with sensible defaults
- **config/functions.zsh**: Enhanced `updatep` and `maintain` functions

### Documentation
- **docs/Setup Scripts Reference.md**: Complete tmux documentation
- **docs/Functions Reference.md**: Updated function documentation
- **CHANGELOG.md**: Detailed version history
- **QUICKSTART.md**: Essential commands reference

## 🔄 Breaking Changes

**None** - This release is fully backward compatible with v1.0.0.

## 🐛 Known Issues

None at this time. All features tested and validated with `./test.sh`.

## 🚀 Performance Improvements

- **Faster Updates**: Removed artificial delays, `maintain` workflow runs ~5-10 seconds faster
- **Background Execution**: `updatep` no longer blocks your terminal during system updates
- **Efficient Logging**: Single log file approach reduces disk I/O

## 🙏 Acknowledgments

Special thanks to:
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer that makes this all possible
- All the existing tools that continue to make this dotfiles setup amazing

## 📄 System Requirements

Same as v1.0.0:
- **OS**: Debian-based Linux (Debian, Ubuntu, Linux Mint, Raspberry Pi OS, Proxmox VE)
- **Shell**: Zsh (installed automatically)
- **Privileges**: User with sudo access
- **Network**: Internet access for package installation

## 🔮 What's Next?

Planned for future releases:
- **Host-specific overrides**: Per-host customization support
- **Backup/restore functions**: Safety net for configuration changes
- **Extended validation**: Additional tests for plugin health and performance

---

**Full Changelog**: [`CHANGELOG.md`](CHANGELOG.md)

**Previous Release**: [v1.0.0](RELEASE_NOTES.md)
