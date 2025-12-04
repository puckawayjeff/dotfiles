# Changelog

All notable changes to this dotfiles repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to semantic versioning principles for major structural changes.

## [Unreleased]

### Fixed
- **MOTD fastfetch configuration**: Fixed fastfetch to load user's custom config during SSH login
  - Detects actual login user via `$PAM_USER`, `$USER`, or `logname`
  - Resolves user's home directory via `getent passwd`
  - Explicitly passes `--config` flag with user's config path
  - Ensures custom modules (Tailscale, Dotfiles version) display correctly
  - Respects user's color bar preferences and other config settings
- **MOTD color output**: Fixed fastfetch color rendering in SSH MOTD context
  - Set `TERM=xterm-256color` when not defined or set to "dumb"
  - Export `COLORTERM=truecolor` to force color support detection
  - Ensures colored output during SSH login matches interactive execution

### Added
- **MOTD Integration**: Fastfetch now runs via update-motd system on terminal login
  - New `lib/motd.sh` script for dynamic MOTD generation
  - Standalone fragment at `/etc/update-motd.d/99-dotfiles` that execs `lib/motd.sh`
  - Follows `man update-motd` best practices (standalone script, not symlink)
  - Prevents fastfetch from running on every shell reload (better performance)
  - Extensible framework for future login messages (disk warnings, updates, etc.)
  - Comprehensive documentation in `docs/MOTD Integration.md`
  - Graceful fallback on systems without update-motd support

### Changed
- **`.zshrc` Fastfetch behavior**: Removed auto-launch on shell startup
  - Fastfetch now displays only on terminal login (via MOTD)
  - Manual aliases still available: `fastfetch`, `ff`, `neofetch`, `screenfetch`
  - Faster shell startup time
- **Tmux setup consolidated**: Optimized tmux installation and configuration
  - Removed redundant `setup/tmux.sh` - tmux is now a core utility
  - Enhanced `lib/terminal.sh` to handle full tmux setup (install + config + validation)
  - Configuration symlink automatically created during initial installation
  - Backs up existing configs before linking
  - Validates tmux.conf syntax after setup
  - Removed tmux.conf from `install.sh` SYMLINKS array (handled by terminal.sh)
- **Symlink management architecture refactored**: Cleaner separation of concerns
  - Created `config/symlinks.conf` for user-added dotfiles (via `add-dotfile`)
  - Moved all core tool configs to `lib/terminal.sh` (zsh, starship, fastfetch, tmux)
  - `install.sh` now only manages user-defined symlinks from symlinks.conf
  - `add-dotfile` function now writes to symlinks.conf instead of editing install.sh directly
  - Better separation: core configs with their installers, user configs in dedicated file
  - Automatic backup of existing files before creating symlinks
  - Simpler, more maintainable architecture

### Coming Soon
- Host-specific configuration overrides
- Backup/restore functions for safety net

## [1.1.0] - 2025-12-03

This release enhances system maintenance workflows with complete tmux integration and improved update automation.

### Added
- **Tmux Integration**: Complete tmux setup with sensible defaults
  - Automatic installation via `lib/terminal.sh`
  - Mouse support enabled for modern workflow
  - Vim-style keybindings for pane navigation (`h/j/k/l`)
  - Intuitive split commands (`|` for vertical, `-` for horizontal)
  - Customized status bar with session name, date, and time
  - 10,000 line scrollback buffer
  - Symlinked configuration at `~/.tmux.conf`
  - Comprehensive documentation in Setup Scripts Reference

### Enhanced
- **`updatep` function**: Improved system update automation
  - Runs updates in background tmux session
  - Logs all output to `~/.cache/updatep.log` (non-cumulative)
  - Auto-closes after completion (no user input required)
  - Removed artificial delays for faster execution
  - Better integration with `maintain` workflow

### Fixed
- Removed 5-second delay before system updates in `maintain` function
- Fixed log file creation and output capture in `updatep`

## [1.0.0] - 2025-12-03

This release marks the first stable version of the dotfiles repository with comprehensive documentation, validation tools, and a robust workflow system.

### Added
- **Version Tracking**: Added `VERSION` file and `dotversion` command to track dotfiles version
- **Validation Suite**: `test.sh` script to check repository health and configuration (9 comprehensive tests)
- **Examples Documentation**: Practical workflows and usage patterns for common operations
- **Quick Start Guide**: Essential commands reference card (`QUICKSTART.md`)
- **Enhanced `add-dotfile`**: Support for custom destination paths and filenames
- **Symlink Detection**: Prevents double-linking and validates source files
- **Directory Creation**: Automatically creates nested destination paths
- **Fastfetch Integration**: Displays dotfiles version in system information
- **Changelog**: This file to track repository evolution
- **License**: MIT license for open source distribution

### Enhanced
- `add-dotfile` function with custom destination path support
- `add-dotfile` validates that source is not already a symlink
- `add-dotfile` improved error messages with better context
- `dotpull` with `--no-exec` flag to skip shell reload
- `maintain` function for comprehensive maintenance workflow
- `install.sh` with quiet mode for reduced output on subsequent runs

### Documentation
- Comprehensive documentation structure in `docs/` directory
- Functions Reference with detailed function documentation
- New Host Deployment guide explaining `join.sh` workflow
- Script Development Best Practices for consistent coding standards
- Setup Scripts Reference documenting optional tool installers
- Terminal Font Setup guide for Nerd Fonts configuration
- GitHub Copilot instructions for AI-assisted development

## [2025-12-03] - Initial Documentation Release

### Added
- Comprehensive documentation structure in `docs/` directory
- Functions Reference with detailed function documentation
- New Host Deployment guide explaining `join.sh` workflow
- Script Development Best Practices for consistent coding standards
- Setup Scripts Reference documenting optional tool installers
- Terminal Font Setup guide for Nerd Fonts configuration
- GitHub Copilot instructions for AI-assisted development

### Structure
- `install.sh` - Symlink creation and system setup
- `join.sh` - One-command new host deployment
- `config/` - Configuration files (.zshrc, .zprofile, functions.zsh)
- `lib/` - Shared libraries (utils.sh for colors/logging, terminal.sh for setup)
- `setup/` - Optional tool installers (foot, glow, nvm, syncthing)
- `docs/` - Comprehensive documentation

### Key Features
- Symlink-based dotfiles management
- Git workflow functions (`dotpush`, `dotpull`)
- System update automation (`updatep` with tmux)
- Archive utilities (`packk`, `unpackk`)
- Maintenance workflow (`maintain`)
- Path validation (`paths`)
- Setup script runner (`dotsetup`)

### Environment
- Zsh with Zinit plugin manager
- Autosuggestions and syntax highlighting
- FZF for fuzzy finding
- Zoxide for smart directory navigation
- Eza for enhanced ls with icons
- Starship prompt
- Fastfetch system info display

## Migration Notes

### For Existing Users

If you're updating from an older version of this dotfiles repository:

1. **Pull latest changes**: Run `dotpull` to get all updates
2. **Review new functions**: Check `docs/Functions Reference.md` for new capabilities
3. **Run validation**: Execute `./test.sh` to ensure everything is configured correctly
4. **Update workflows**: Review `docs/Examples.md` for improved `add-dotfile` usage

### Breaking Changes

None yet - this is the initial documented release.

## Future Roadmap

See the [Project Roadmap](#project-roadmap-december-2025) section in `.github/copilot-instructions.md` for planned enhancements.

---

**Note**: Dates in this changelog represent when features were documented/formalized, not necessarily when they were first implemented.
