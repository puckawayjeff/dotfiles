# Changelog

All notable changes to this dotfiles repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to semantic versioning principles for major structural changes.

## [2.0.0] - 2025-12-16

This release focuses on clarifying the repository architecture, streamlining documentation, and improving maintainability while maintaining 100% backward compatibility.

### Added
- **ARCHITECTURE.md**: Comprehensive system design documentation (12KB)
  - Repository structure and two-repo pattern explanation
  - Standalone vs Enhanced mode architecture
  - Symlink management architecture
  - Library architecture and common patterns
  - Security model and extension points
  - Complete workflow diagrams
- **INFO emoji constant** (ℹ️) to lib/utils.sh for consistent logging
- **Self-contained comment** in join.sh explaining why it cannot use lib/utils.sh

### Changed
- **README.md**: Streamlined from 24KB to 8KB (66% reduction)
  - Focused on quick start and essential commands
  - Removed redundant detailed explanations
  - Better cross-references to detailed documentation
  - Improved navigation and organization
- **Documentation structure**: Reduced from ~3,700 lines to ~2,500 lines (32% reduction)
  - Moved architectural details to ARCHITECTURE.md
  - Consolidated related information
  - Clearer separation between user guides and developer docs
- **package-ssh-keys.sh**: Now uses lib/utils.sh for consistent logging
- **RELEASE_NOTES.md**: Updated for 2.0.0 release with clear migration guide

### Fixed
- Documentation cross-references now point to correct locations
- Consistent terminology throughout all documentation
- Better explanation of public/private repository pattern

### Documentation
- New comprehensive ARCHITECTURE.md for system understanding
- Streamlined README.md for faster onboarding
- Updated all cross-references for better navigation
- Clearer explanation of dotfiles.env and enhanced mode

### For Developers
- Architectural decisions now documented in code comments
- Clear separation between bootstrap (join.sh) and post-clone scripts
- Common patterns documented in ARCHITECTURE.md
- Extension points clearly identified

## [Unreleased]

### Coming Soon
- Host-specific configuration overrides
- Backup/restore functions for safety net
- Extended validation in test.sh

## [1.3.0] - 2025-12-15

This release refines documentation, improves command naming consistency, and enhances user experience with better help resources and examples.

### Changed
- **Function Rename**: `packk()` renamed to `dotpack()` for naming consistency
  - Aligns with other dotfiles commands (`dotpush`, `dotpull`, `dothelp`, etc.)
  - Updated all references across documentation and code
  - Function behavior unchanged, only name updated
- **Documentation Organization**: Consolidated and streamlined documentation
  - Removed "Custom Last Login Implementation.md" (details now in Functions Reference.md)
  - Updated Repository Structure in README.md with complete file listings
  - Improved plugin descriptions (replaced "8 power-user plugins" with category-based list)
  - Enhanced Example 3 in Examples.md to demonstrate custom destination paths with micro.json use case

### Added
- **Enhanced Quick Help**: Added prominent references to help functions
  - `dothelp` and `dotkeys` now featured in QUICKSTART.md Quick Help section
  - `join.sh` completion output now mentions these commands
  - Improved discoverability for new users
- **Copilot Instructions**: Added reminders to always use centralized libraries
  - Explicit instructions to source `lib/utils.sh` in all scripts
  - Reminder to use color/emoji constants from utils.sh instead of hardcoding
  - Improved AI assistant consistency in code generation

### Fixed
- Documentation accuracy improvements across multiple files
- Consistent function references throughout all documentation

## [1.2.0] - 2025-12-05

This release transforms the terminal login experience with polished system information display, custom login messages, and improved configuration organization. It also adds powerful oh-my-zsh plugin integration and helpful quick reference functions.

### Added
- **Oh-My-Zsh Plugin Integration**: Eight curated plugins loaded via Zinit snippets
  - `git` - Comprehensive git aliases (`gst`, `gco`, `gp`, `gl`, `gcmsg`, etc.)
  - `docker` - Docker shortcuts and completions (`dps`, `dex`, `dlog`, `dstop`)
  - `sudo` - Press ESC twice to prepend sudo to any command
  - `extract` - Universal archive extraction (replaces `unpackk` function)
  - `command-not-found` - Suggests package installations for missing commands
  - `colored-man-pages` - Syntax-highlighted documentation pages
  - `copypath` - Copy current directory path to clipboard
  - `copyfile` - Copy file contents to clipboard
- **Quick Reference Functions**: Two new colorful help functions
  - `dothelp()` - Multi-column reference of all custom functions and plugin commands
  - `dotkeys()` - Keyboard shortcuts quick reference with color-coded categories
  - Optimized layout for IDE terminal windows (140x20 typical size)
  - Emoji icons and bold formatting for visual clarity
- **Micro Text Editor**: Core terminal tool for intuitive text editing
  - Automatic installation via `lib/terminal.sh`
  - Dracula color scheme matching dotfiles aesthetic
  - Familiar keyboard shortcuts (Ctrl+S, Ctrl+Q, etc.)
  - Configuration symlinked to `~/.config/micro/settings.json`
  - Features: syntax highlighting, diff gutter, mouse support, trailing whitespace removal
  - Comprehensive documentation in "Setup Scripts Reference.md"
- **Custom Last Login Display**: Core terminal feature replacing SSH's default lastlog
  - New `lib/last-login.sh` script for custom login messages
  - IP-to-hostname mapping with configurable lookup table
  - Cleaner timestamp formatting (e.g., "Thu Dec 5, 2025 at 9:23 AM")
  - Styled output using `lib/utils.sh` colors (green, cyan, yellow)
  - Automatic detection of SSH sessions (only displays when appropriate)
  - Multiple data sources: `last` (wtmp) and `lastlog` for reliability
  - Integrated into `.zshrc` for automatic execution on SSH login
  - Integrated into `lib/terminal.sh` for automatic SSH configuration
  - Disables `PrintLastLog` in `/etc/ssh/sshd_config` during setup
  - Comprehensive documentation in "Setup Scripts Reference.md" and "Functions Reference.md"
- **MOTD Integration**: Fastfetch now runs via update-motd system on terminal login
  - New `lib/motd.sh` script for dynamic MOTD generation
  - Standalone fragment at `/etc/update-motd.d/99-dotfiles` that execs `lib/motd.sh`
  - Follows `man update-motd` best practices (standalone script, not symlink)
  - Prevents fastfetch from running on every shell reload (better performance)
  - Extensible framework for future login messages (disk warnings, updates, etc.)
  - Comprehensive documentation in `docs/MOTD Integration.md`
  - Graceful fallback on systems without update-motd support
- **Dual fastfetch configs**: Separate configs for MOTD vs interactive use
  - `config/fastfetch.jsonc` - Full config (symlinked to `~/.config/fastfetch/config.jsonc`)
  - `config/fastfetch-motd.jsonc` - Streamlined MOTD config (called directly by motd.sh)
  - MOTD config removes: packages, DE/WM/themes, display info, poweradapter, locale, version
  - MOTD config keeps: system identity, uptime, shell, CPU/GPU, memory/swap/disk, IPs, battery, dotfiles version
  - Faster MOTD execution (3s timeout vs 5s, version detection disabled)
- **SSH Sync Functions**: Optional companion repo workflow functions
  - `sshpush()` and `sshpull()` functions for managing separate SSH config repository
  - Conditionally loaded only when `~/sshsync/.git` exists
  - Documented in "Functions Reference.md" with availability notes

### Enhanced
- **Functions Documentation**: Added missing function documentation
  - `maintain()` - Complete maintenance workflow fully documented
  - `dotversion()` - Version display command documented
  - `sshpush()` / `sshpull()` - SSH sync functions documented (optional)
  - All functions now have comprehensive documentation in "Functions Reference.md"

### Changed
- **Archive Extraction**: Replaced custom `unpackk` function with oh-my-zsh `extract` plugin
  - More format support (30+ archive types vs 4)
  - Better maintained and tested
  - Simpler command name
  - Updated all documentation references
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

### Fixed
- **MOTD fastfetch execution context**: Fixed fastfetch to run as the actual login user during SSH MOTD
  - Detects actual login user via `$PAM_USER`, `$USER`, or `logname`
  - Uses `su - username` to execute fastfetch with proper login environment
  - Correctly displays `user@hostname` instead of `root@hostname`
  - Proper locale detection (`en_US.UTF-8` instead of `C`)
  - Shell detection works correctly
  - Custom modules (Tailscale IP, Dotfiles version) display correctly
  - Respects user's fastfetch config (no color bars, custom formatting)
  - Removed terminal/terminalfont modules (not useful in MOTD context, always blank)
- **MOTD color output**: Fixed fastfetch color rendering in SSH MOTD context
  - Set `TERM=xterm-256color` when not defined or set to "dumb"
  - Export `COLORTERM=truecolor` to force color support detection
  - Ensures colored output during SSH login matches interactive execution
- **Directory navigation**: Fixed `dotpull` and `maintain` functions to properly restore original directory before reloading shell

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
- `sync.sh` - Symlink creation and system setup
- `join.sh` - One-command new host deployment
- `config/` - Configuration files (.zshrc, .zprofile, functions.zsh)
- `lib/` - Shared libraries (utils.sh for colors/logging, terminal.sh for setup)
- `setup/` - Optional tool installers (foot, glow, nvm, syncthing)
- `docs/` - Comprehensive documentation

### Key Features
- Symlink-based dotfiles management
- Git workflow functions (`dotpush`, `dotpull`)
- System update automation (`updatep` with tmux)
- Archive utilities (`dotpack` for creating, `extract` plugin for extracting)
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
