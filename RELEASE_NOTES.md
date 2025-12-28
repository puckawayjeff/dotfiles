# Release Notes - Version 2.2.0

**Release Date**: December 28, 2025  
**Minor Version**: Power user features and completion system overhaul

## 🐛 Bug Fixes

### mkd() Function Fixed
- **FIXED**: mkd() now properly navigates to created directories
- Previously failed due to conflict with custom cd() wrapper
- Now uses `builtin cd` to avoid zoxide interference
- Gives friendly message if directory already exists ("Directory 'name' already exists, navigating there...")
- Successfully navigates even when directory exists

## 🎯 What's New in 2.2.0

### Power User Navigation & Search

#### fcd() - Fuzzy Directory Change
- **NEW**: Interactive directory navigation with FZF and tree preview
- Press Ctrl+T → See directory tree → Navigate instantly
- Smart detection for `fd` vs `fdfind` (Debian compatibility)
- Graceful fallback to `find` if fd not available
- Uses eza for beautiful tree previews

#### fne() - Find 'n Edit  
- **NEW**: Search file contents and edit instantly
- Ripgrep + FZF + Micro = lightning-fast code search
- Preview search results with bat syntax highlighting
- Opens files at exact line number of match
- Ripgrep now auto-installed via terminal.sh

### History System Revolution

#### 1 Million Line History
- **CHANGED**: Increased from 10,000 to 1,000,000 commands
- Find obscure commands from months ago
- HIST_IGNORE_ALL_DUPS removes all duplicates (not just consecutive)
- HIST_REDUCE_BLANKS cleans up commands before saving
- EXTENDED_HISTORY records timestamps for analysis

#### history-search-multi-word Plugin
- **CHANGED**: Replaced history-substring-search with multi-word
- Better multi-word searching capabilities
- Enhanced syntax highlighting in search results
- More powerful pattern matching

### FZF-Tab Integration

#### Revolutionary Tab Completion
- **NEW**: FZF-Tab plugin replaces standard completion
- Fuzzy matching on all tab completions
- File previews with bat syntax highlighting (first 50 lines)
- Directory previews with eza tree view
- Smart fallbacks if bat/eza not installed
- SSH commands exempted (use custom _ssh_hosts function)
- Press `<` or `>` to switch between completion groups

#### Enhanced FZF Configuration
- **CHANGED**: Preview windows on all FZF operations
- Added --preview-window=right:60% to defaults
- FZF_ALT_C_OPTS shows directory tree before cd
- Ctrl+T file selection shows file previews
- Alt+C directory navigation shows structure

### Completion System Overhaul

#### Colorful & Fast
- **CHANGED**: Complete redesign of completion styling
- Added completion caching in ~/.zsh/cache for speed
- Case-insensitive matching with fuzzy support
- Verbose mode with progress indicators
- Works harmoniously with FZF-Tab
- Group-based organization (external command, builtin, etc.)

### Editor & Command Line

#### Micro as Default Editor
- **CHANGED**: Set micro as EDITOR and VISUAL
- No VI keybindings (user-friendly default)
- Syntax highlighting and modern keybindings
- Full keybinding reference in dotkeys
- PAGER=less for viewing long outputs

#### Enhanced command_not_found_handler
- **CHANGED**: Beautiful error messages with package suggestions
- Color-coded output hierarchy
- Shows package suggestions from system database
- Maintains helpful dothelp tip reminder
- Better visual separation of sections

### Configuration Architecture

#### Symlink Management Refactor
- **CHANGED**: Single source of truth in `config/symlinks.conf`
- Removed setup_config_symlinks() from lib/terminal.sh
- Terminal.sh now only installs binaries
- All symlinks (core + user-added) in one location
- Added micro.json and tmux.conf to symlinks.conf
- Better transparency and maintainability

#### Configuration File Naming
- **CHANGED**: Removed dot-prefix from config files
- `config/.zshrc` → `config/zshrc.conf`
- `config/.zprofile` → `config/zprofile.conf`
- Visible by default in file listings
- Follows best practice (descriptive names)
- Updated all references in codebase

### Plugins & Tools

#### git-open Plugin
- **NEW**: Type `git open` to open repo in browser
- Works with GitHub, GitLab, Bitbucket, etc.
- Auto-detects remote URL and opens appropriate page

#### Snap Package Support
- **NEW**: Added to updatep() function
- Runs `sudo snap refresh` alongside apt/flatpak
- Covers all major package managers

#### Eza Theme Customization
- **NEW**: Custom theme with special directory icons
- Developer directory (󰲋) - yellow/bold with console icon
- dotfiles directory (󰴋) - yellow/bold with sync folder icon  
- sshsync directory (󰒃) - yellow/bold with shield icon

#### zsh-thefuck Plugin Disabled
- **CHANGED**: Disabled due to Python 3.13+ incompatibility
- TheFuck requires distutils and imp modules (removed in 3.13)
- Awaiting upstream fix: https://github.com/nvbn/thefuck/issues/1495

### Documentation Updates

- Updated dothelp with fcd() and fne() functions
- Updated dotkeys with micro keybindings
- Added power features sections to README.md
- Updated QUICKSTART.md with new function references
- Enhanced Functions Reference.md with full examples
- Updated ARCHITECTURE.md for symlink refactor

## 🚀 Migration Guide

### For Existing Users (2.1.x → 2.2.0)

**No breaking changes** - just run sync.sh to update:

```bash
cd ~/dotfiles
git pull
./sync.sh
source ~/.zshrc
```

**New Features to Try:**
```bash
# Try fuzzy directory navigation
fcd

# Search and edit files
fne "function name"

# Fuzzy tab completion with previews
cd <Tab>
ls <Tab>

# Git repository shortcuts
git open
```

**What You'll Notice:**
- Tab completion now uses FZF interface with previews
- Much larger command history (1M vs 10K)
- New fcd() and fne() commands available
- Completion groups work properly with FZF
- SSH tab completion uses standard interface (not FZF)

## 📦 What's Included

- Complete ZSH configuration with 18 plugins
- Zinit plugin manager (lazy loading for speed)
- FZF-Tab for fuzzy tab completion
- Starship cross-shell prompt
- Fastfetch system info (replaces neofetch)
- Tmux multiplexer with sensible defaults
- Micro text editor with modern keybindings
- Eza file listing with custom theme
- 1M line command history with smart deduplication
- Power user functions: fcd, fne, dotpush, updatep
- One-line deployment: `join.sh`

## 🔧 Technical Notes

### Performance Optimizations
- Completion caching in ~/.zsh/cache
- Zcompdump compilation for faster startup
- Daily zcompdump regeneration check
- Lazy loading of plugins via Zinit
- Background zcompile of completion files

### Compatibility
- Debian-based systems (Debian, Ubuntu, Mint, Pi OS, Proxmox)
- apt package manager required
- Zsh 5.8+ recommended
- Nerd Fonts required for icons
- Works with/without GUI

### Dependencies Auto-Installed
- Zsh, Starship, Fastfetch, Tmux, Eza, Micro
- FZF, fd-find (fdfind on Debian), bat (batcat)
- Ripgrep (new in 2.2.0)
- Git, curl, wget, unzip

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete list of changes.

## 🐛 Known Issues

- zsh-thefuck plugin disabled (Python 3.13+ incompatibility)
- FZF-Tab overrides custom completion functions by default
  - Workaround: Use `disabled-on any` for specific commands

## 💬 Feedback & Contributions

This is a personal dotfiles repository, but feedback and suggestions are welcome!

**Repository**: https://github.com/puckawayjeff/dotfiles  
**Issues**: https://github.com/puckawayjeff/dotfiles/issues
