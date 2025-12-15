# Dotfiles v1.3.0 Release Notes

**Release Date**: December 15, 2025

## Documentation Refinement & Naming Consistency

This release focuses on polishing documentation, improving discoverability of help resources, and establishing consistent naming conventions across all commands.

## What's New

### Function Rename: packk → dotpack

The archive creation function has been renamed from `packk` to `dotpack` for consistency with other dotfiles commands:

```bash
# New syntax (old syntax still works until you reload shell)
dotpack ~/projects/myapp          # Creates myapp.tar.gz
dotpack ~/documents/notes zip     # Creates notes.zip
dotpack data 7z                   # Creates data.7z
```

All references updated across:
- Function definition in `config/functions.zsh`
- Documentation in README, QUICKSTART, Functions Reference, Examples
- Help output in `dothelp`
- Copilot instructions

**Why?** The "dot" prefix signals it's part of the dotfiles toolkit: `dotpush`, `dotpull`, `dothelp`, `dotkeys`, `dotsetup`, `dotversion`, and now `dotpack`.

### Enhanced Help Discovery

Help functions are now front and center:

**QUICKSTART.md** - New "Quick Help" section at the top:
```markdown
## 📚 Quick Help

New to the setup? Start here:

- **`dothelp`** - Shows all available commands and functions
- **`dotkeys`** - Displays keyboard shortcuts and keybindings
```

**join.sh completion** - Now reminds you about help:
```
🎉 New host setup complete!
Start a new shell with: zsh

📚 Quick Help:
   ↳ dothelp - Show all available commands
   ↳ dotkeys - Show keyboard shortcuts
```

### Documentation Improvements

**Repository Structure** - Updated with complete file tree including:
- All config files (fastfetch-motd.jsonc, tmux.conf, micro.json, ssh_config, symlinks.conf)
- All lib scripts (utils.sh, terminal.sh, motd.sh, last-login.sh)
- All documentation files (Examples.md, MOTD Integration.md, etc.)
- Version tracking files (VERSION, CHANGELOG.md, QUICKSTART.md)

**Plugin Descriptions** - Changed from specific "8 power-user plugins" to category-based descriptions:
- Core Zinit plugins (autosuggestions, syntax highlighting, completions, history search)
- Oh-My-Zsh plugins (git, docker, sudo, extract, etc.)
- More maintainable as plugin list evolves

**Example 3 Enhanced** - Now demonstrates the custom destination feature properly:
- Shows renaming `~/.config/micro/settings.json` → `config/micro.json`
- Explains why renaming improves clarity ("settings.json" is too generic)
- Real-world use case instead of confusing duplicate example

**Custom Last Login** - Consolidated lengthy implementation doc into Functions Reference
- Removed standalone "Custom Last Login Implementation.md" (way too detailed)
- Brief, focused documentation now lives in Functions Reference.md
- Easier to find, maintain, and reference

### Developer Experience

**Copilot Instructions Enhanced** - Added explicit reminders to:
```bash
# Always source lib/utils.sh in scripts
DOTFILES_DIR="${HOME}/dotfiles"
source "${DOTFILES_DIR}/lib/utils.sh"
```

This ensures AI-generated scripts consistently use centralized color/emoji definitions instead of hardcoding values.

## Upgrading from v1.2.0

```bash
dotpull
```

**What changes:**

1. `packk` command renamed to `dotpack` (both work until shell reload)
2. Better help discovery via enhanced QUICKSTART and join.sh output
3. More accurate documentation across all files
4. Repository structure reflects current state

**What stays the same:**

Everything else. This is purely a documentation and naming consistency release - no behavioral changes to existing features.

## For New Users

If you're just discovering these dotfiles, check out:

1. **`dothelp`** - Your first stop for understanding what's available
2. **`dotkeys`** - Learn the keyboard shortcuts
3. **QUICKSTART.md** - Essential commands reference
4. **Examples.md** - Real-world usage patterns