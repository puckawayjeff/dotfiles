# Quick Start Guide

Essential commands and workflows for managing your dotfiles. Keep this handy for quick reference.

## 🚀 One-Line New Host Setup

Deploy everything to a fresh Linux system:

```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

Then log out and back in for zsh to become default shell.

## 📦 Core Commands

### Dotfiles Management

| Command | Description |
|---------|-------------|
| `add-dotfile <file>` | Add a config file to dotfiles repo |
| `dotpush "message"` | Commit and push changes to GitHub |
| `dotpull` | Pull latest changes from GitHub |
| `maintain` | Full maintenance (pull dotfiles + system update) |
| `dotsetup` | List available setup scripts |
| `dotsetup <tool>` | Run a specific setup script |

### System Utilities

| Command | Description |
|---------|-------------|
| `updatep` | System update in tmux (full-upgrade + cleanup) |
| `paths` | Check if all PATH directories exist |
| `mkd <dir>` | Create directory and cd into it |
| `packk <dir> [format]` | Create archive (tar.gz/zip/7z) |
| `unpackk <archive>` | Extract archive intelligently |

### File Operations (with eza)

| Command | Description |
|---------|-------------|
| `ll` | Detailed list with icons and git status |
| `la` | List all files including hidden |
| `lt` | Tree view (2 levels deep) |
| `l` | Simple one-column list |

## 🔧 Common Workflows

### Adding a New Config File

```bash
# Simple: uses default location (config/)
add-dotfile ~/.gitconfig

# Custom destination
add-dotfile ~/.bashrc config/.bashrc.backup

# Then commit
dotpush "Add gitconfig"
```

### Syncing Between Hosts

**On your main machine (after changes):**
```bash
dotpush "Update prompt colors"
```

**On other machines (to get changes):**
```bash
dotpull
```

### Daily Maintenance

```bash
maintain  # Pulls dotfiles + runs system update
```

### Installing Optional Tools

```bash
dotsetup           # List available tools
dotsetup glow      # Install markdown viewer
dotsetup nvm       # Install Node Version Manager
```

### Quick Navigation

```bash
# Smart cd with frecency
j dotfiles         # Jumps to ~/dotfiles if visited before
j conf             # Jumps to ~/.config or similar

# Fuzzy find files/directories
Ctrl+T             # Find files in current directory
Ctrl+R             # Search command history
Alt+C              # cd into directory (fuzzy)
```

## 🎯 Keyboard Shortcuts

### Command Line

| Shortcut | Action |
|----------|--------|
| `→` | Accept autosuggestion |
| `Ctrl+Space` | Accept autosuggestion (alternative) |
| `Ctrl+R` | Fuzzy search command history |
| `Ctrl+T` | Fuzzy find files |
| `Alt+C` | Fuzzy cd to directory |
| `↑` / `↓` | Filter history by typed prefix |

### Completion

| Shortcut | Action |
|----------|--------|
| `Tab` | Show completion menu |
| `Tab Tab` | Navigate completions |
| `Shift+Tab` | Navigate backwards |

## 🔍 Troubleshooting Quick Fixes

### Shell not reloading after dotpull?

```bash
exec zsh  # Force reload current shell
```

### PATH looks wrong?

```bash
paths  # Shows which directories exist (✓) or missing (✗)
```

### Git complains about credentials?

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### Symlink broken?

```bash
cd ~/dotfiles
./install.sh  # Recreates all symlinks
```

### Want to see what changed?

```bash
cd ~/dotfiles
git status
git diff
```

### Accidentally committed to dotfiles?

```bash
cd ~/dotfiles
git reset --soft HEAD~1  # Undo commit, keep changes
git reset --hard HEAD~1  # Undo commit, discard changes
```

### Need to recover stashed changes?

```bash
cd ~/dotfiles
git stash list           # See all stashes
git stash pop            # Apply most recent stash
git stash apply stash@{N}  # Apply specific stash
```

### Zinit plugins not loading?

```bash
# Reinstall zinit
rm -rf ~/.local/share/zinit
exec zsh  # Reinstalls automatically
```

### System update stuck?

```bash
# If updatep hangs, Ctrl+C and run manually
sudo apt update
sudo apt full-upgrade
sudo apt autoremove
```

### Setup script failed?

```bash
# Run with manual error checking
bash -x ~/dotfiles/setup/<script>.sh
```

## 📝 Git Basics

### Common Git Commands

```bash
cd ~/dotfiles

# Check status
git status

# See what changed
git diff

# Unstage changes
git restore --staged <file>

# Discard local changes
git restore <file>

# View commit history
git log --oneline
git log --oneline -10  # Last 10 commits

# Undo last commit (keep changes)
git reset --soft HEAD~1
```

## 🧪 Testing Your Setup

Run validation tests:

```bash
~/dotfiles/test.sh
```

All 9 tests should pass ✓

## 📚 Need More Details?

- **Full function documentation**: `docs/Functions Reference.md`
- **Detailed examples**: `docs/Examples.md`
- **New host deployment**: `docs/New Host Deployment.md`
- **Setup scripts**: `docs/Setup Scripts Reference.md`
- **Script standards**: `docs/Script Development Best Practices.md`
- **Font configuration**: `docs/Terminal Font Setup.md`

## 💡 Pro Tips

1. **Tab completion works everywhere** - Type partial command, hit Tab
2. **Autosuggestions learn from your history** - The more you use it, the better it gets
3. **Use `j` instead of `cd`** - It remembers frequently visited directories
4. **Run `maintain` weekly** - Keeps everything synced and updated
5. **Check `paths` if commands aren't found** - Might be missing from PATH
6. **Use `Ctrl+R` extensively** - Your command history is searchable gold
7. **Commit dotfile changes frequently** - Small commits are easier to track/revert
8. **Test major changes locally first** - Run `./test.sh` before pushing

## 🎨 Customization

### Change Prompt

Edit `~/dotfiles/config/starship.toml`, then:
```bash
dotpush "Update prompt config"
```

### Add Custom Aliases

Edit `~/.zsh_aliases` (create if needed), then:
```bash
source ~/.zshrc  # Reload
```

### Modify Functions

Edit `~/dotfiles/config/functions.zsh`, then:
```bash
source ~/.zshrc  # Reload
dotpush "Update function"
```

---

**Remember**: Changes to dotfiles take effect immediately thanks to symlinks. Just reload your shell with `source ~/.zshrc` or `exec zsh`.
