# Release Notes - Version 2.1.0

**Release Date**: December 21, 2025  
**Minor Version**: SSH improvements and plugin optimization

## 🎯 What's New in 2.1.0

### SSH Host Management

#### Smart SSH Autocomplete
- **NEW**: SSH host completion from `~/.ssh/config` and `~/sshsync/ssh.conf`
- Tab completion for `ssh`, `scp`, and `sftp` commands
- Automatically reads all configured hosts from both config files
- No more typing full hostnames manually

#### sshlist Function
- **NEW**: `sshlist` command displays all configured SSH hosts
- Shows hosts from both `~/.ssh/config` and enhanced mode `~/sshsync/ssh.conf`
- Color-coded output with clear section headers
- Helpful examples when no hosts are configured

### Plugin Improvements

#### Removed zsh-sshinfo
- **REMOVED**: `SckyzO/zsh-sshinfo` plugin
- Reason: Box-drawing characters rendered incorrectly causing visual issues
- Replaced with native SSH completion (better functionality)

#### Removed sudo Plugin
- **REMOVED**: Oh-My-Zsh `sudo` plugin
- Reason: Conflicted with thefuck plugin keybinding
- TheFuck now uses default ESC ESC binding (more intuitive)

#### Fixed zsh-thefuck Integration
- Resolved ZLE widget loading order issue
- Moved thefuck plugin to load before fast-syntax-highlighting
- Eliminated "unhandled ZLE widget" error messages
- ESC ESC keybinding now works reliably

### Documentation Updates

- Updated `dothelp` to include `sshlist` command
- Updated `dotkeys` to reflect ESC ESC for TheFuck (not sudo)
- Updated README.md plugin list
- Corrected SSH config path references in functions

## 🚀 Migration Guide

### For Existing Users (2.0.0 → 2.1.0)

**No breaking changes!** All existing functionality preserved.

1. Pull latest changes:
   ```bash
   dotpull
   ```

2. The changes take effect immediately:
   - Type `ssh <Tab>` to see your configured hosts
   - Run `sshlist` to view all SSH hosts
   - Use ESC ESC for TheFuck command correction

3. Optional: Remove cached zsh-sshinfo plugin data:
   ```bash
   rm -rf ~/.local/share/zinit/plugins/SckyzO---zsh-sshinfo
   ```

### For New Users

Just run the standard deployment command:
```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

## 📖 Key Features

### SSH Tab Completion

Type partial hostname and press Tab:
```bash
$ ssh med<Tab>
$ ssh mediabarn
```

View all hosts:
```bash
$ sshlist
💻 SSH Configured Hosts...
📁 From ~/.ssh/config:
   • mediabarn
   • puckaplex
   • workshop-sensor
   ...
```

### TheFuck Integration

Mistyped a command? Press ESC ESC:
```bash
$ apt install package
Permission denied
$ <ESC ESC>
$ sudo apt install package
```

## 🔧 Technical Changes

- Added `_ssh_hosts()` completion function to `.zshrc`
- Added `sshlist()` function to `functions.zsh`
- Reordered Zinit plugin loading sequence
- Fixed sshsync config path (`ssh.conf` not `config`)
- Removed conflicting keybinding configurations

## 📊 Statistics

- **Plugins**: Removed 2 (zsh-sshinfo, sudo), improved 1 (thefuck)
- **New functions**: 2 (sshlist, _ssh_hosts)
- **Bug fixes**: 1 (ZLE widget error)
- **Documentation updates**: 4 files (README.md, functions.zsh, .zshrc, RELEASE_NOTES.md)

---

**Version**: 2.1.0  
**Type**: Minor release - SSH improvements and plugin optimization  
**Breaking Changes**: None  
**Upgrade Recommended**: Yes - Better SSH workflow and cleaner shell startup
