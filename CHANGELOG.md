# Changelog

All notable changes to this dotfiles repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to semantic versioning principles for major structural changes.

## [Unreleased]

### Added
- Validation script (`test.sh`) to check repository health and configuration
- Examples documentation with practical `add-dotfile` workflows
- Support for custom destination paths in `add-dotfile` function
- Symlink detection in `add-dotfile` to prevent double-linking
- Directory creation in `add-dotfile` for nested destination paths
- This changelog to track repository evolution

### Enhanced
- `add-dotfile` function now supports custom destination paths and filenames
- `add-dotfile` validates that source is not already a symlink
- `add-dotfile` improved error messages with better context

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
