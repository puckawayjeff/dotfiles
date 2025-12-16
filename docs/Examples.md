# Dotfiles Examples

This document provides practical examples of common dotfiles workflows.

## Adding New Dotfiles

The `add-dotfile` function automates the process of adding configuration files to your dotfiles repository. It handles the file movement, symlink creation, and `config/symlinks.conf` updates automatically.

### Example 1: Adding a Simple Config File

Let's say you have a custom `.gitconfig` file in your home directory that you want to track.

**Before:**
```bash
$ ls -la ~/.gitconfig
-rw-r--r-- 1 jeff jeff 245 Dec 3 10:30 /home/jeff/.gitconfig
```

**Command:**
```bash
$ add-dotfile ~/.gitconfig
```

**Output:**
```
🔧 Moving file to repo (config/)...
✅ Moved to /home/jeff/dotfiles/config/.gitconfig
🔗 Creating symlink...
✅ Symlink created
📝 Updating sync.sh...
✅ Added to sync.sh
📦 Staging changes...

🎉 Successfully added '.gitconfig'!
Next: dotpush 'Add .gitconfig'
```

**After:**
```bash
$ ls -la ~/.gitconfig
lrwxrwxrwx 1 jeff jeff 42 Dec 3 10:35 /home/jeff/.gitconfig -> /home/jeff/dotfiles/config/.gitconfig

$ ls -la ~/dotfiles/config/.gitconfig
-rw-r--r-- 1 jeff jeff 245 Dec 3 10:30 /home/jeff/dotfiles/config/.gitconfig
```

The file is now tracked in git, symlinked back to its original location, and `config/symlinks.conf` has been updated to recreate the symlink on other hosts.

**Commit the changes:**
```bash
$ dotpush "Add .gitconfig"
```

### Example 2: Adding a Nested Config File

Many applications store their configuration in `~/.config/`. Let's add a tmux configuration.

**Before:**
```bash
$ ls -la ~/.config/tmux/tmux.conf
-rw-r--r-- 1 jeff jeff 1234 Dec 2 15:20 /home/jeff/.config/tmux/tmux.conf
```

**Command:**
```bash
$ add-dotfile ~/.config/tmux/tmux.conf
```

**Output:**
```
🔧 Moving file to repo (config/)...
✅ Moved to /home/jeff/dotfiles/config/tmux.conf
🔗 Creating symlink...
✅ Symlink created
📝 Updating sync.sh...
✅ Added to sync.sh
📦 Staging changes...

🎉 Successfully added 'tmux.conf'!
Next: dotpush 'Add tmux.conf'
```

**Result:**
- File moved to: `~/dotfiles/config/tmux.conf`
- Symlink created at: `~/.config/tmux/tmux.conf -> ~/dotfiles/config/tmux.conf`
- Entry added to `config/symlinks.conf`

**Note:** The function uses the basename of the file (`tmux.conf`), but preserves the full path for the symlink target.

### Example 3: Renaming During Add (Custom Destination)

Sometimes the original filename lacks context (like `settings.json`). Use the second parameter to provide a more descriptive name. This example shows renaming `~/.config/micro/settings.json` to `micro.json`:

**Before:**
```bash
$ ls -la ~/.config/micro/settings.json
-rw-r--r-- 1 jeff jeff 456 Dec 10 09:30 /home/jeff/.config/micro/settings.json
```

**Command:**
```bash
$ add-dotfile ~/.config/micro/settings.json config/micro.json
```

**Output:**
```
🔧 Moving file to repo (config/micro.json)...
✅ Moved to /home/jeff/dotfiles/config/micro.json
🔗 Creating symlink...
✅ Symlink created
📝 Updating config/symlinks.conf...
✅ Added to config/symlinks.conf
📦 Staging changes...

🎉 Successfully added 'micro.json'!
Next: dotpush 'Add micro editor settings'
```

**Result:**
- Repo file: `~/dotfiles/config/micro.json` (renamed for clarity)
- Symlink: `~/.config/micro/settings.json -> ~/dotfiles/config/micro.json`

**Why rename?** The name `micro.json` immediately tells you which app it belongs to, unlike the generic `settings.json`.

### Example 4: What Happens on Error

**Trying to add a file that doesn't exist:**
```bash
$ add-dotfile ~/.nonexistent
❌ Error: Source '/home/jeff/.nonexistent' does not exist.
```

**Trying to add a file already in the repo:**
```bash
$ add-dotfile ~/.zshrc
❌ Error: Destination '/home/jeff/dotfiles/config/.zshrc' already exists.
```

**Trying to add a file that's already a symlink:**
```bash
$ add-dotfile ~/.zshrc
❌ Error: Source '/home/jeff/.zshrc' is already a symlink.
   Target: /home/jeff/dotfiles/config/.zshrc
```

## Syncing Changes Across Hosts

### Push Changes from Development Host

After making changes to any dotfile:

```bash
$ dotpush "Update starship prompt colors"
```

**Output:**
```
[main abc1234] Update starship prompt colors
 1 file changed, 3 insertions(+), 1 deletion(-)
Enumerating objects: 7, done.
...
To github.com:user/dotfiles.git
   def5678..abc1234  main -> main
```

The function automatically:
1. Stages all changes (`git add .`)
2. Commits with your message
3. Pushes to GitHub
4. Returns you to your original directory

### Pull Changes on Other Hosts

On another machine where you want the updates:

```bash
$ dotpull
```

**Output:**
```
⬇️  Pulling latest changes...
remote: Enumerating objects: 7, done.
...
Updating def5678..abc1234
Fast-forward
 config/starship.toml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
✅ Git pull successful.

🔧 Running sync.sh...
[sync.sh output shows symlinks being verified/created]

🔄 Reloading zsh configuration...
```

The changes are immediately applied because of the symlinks. The `dotpull` function:
1. Auto-stashes any local uncommitted changes
2. Pulls from GitHub
3. Runs `sync.sh` to ensure symlinks are current
4. Reloads your shell configuration

### Handling Local Uncommitted Changes

If you have uncommitted changes when pulling:

```bash
$ dotpull
⚠️  Local changes detected. Stashing...
Saved working directory and index state WIP on main: abc1234 Auto-stash before pull on 2025-12-03 14:30:15
   ↳ Local changes stashed. Use 'git stash pop' to restore them.
⬇️  Pulling latest changes...
...
```

Your local changes are safely stashed and can be recovered with:
```bash
$ cd ~/dotfiles && git stash pop
```

## Running Setup Scripts

Setup scripts install optional tools following consistent patterns.

### List Available Scripts

```bash
$ dotsetup
📦 Available setup scripts:
   ↳ foot
   ↳ glow
   ↳ nvm
   ↳ syncthing
```

### Installing a Tool

```bash
$ dotsetup glow
🚀 Running setup script: glow

🚀 Glow (Markdown Viewer) Installation...
📦 Installing dependencies...
✅ Dependencies installed
📥 Downloading latest Glow release...
✅ Downloaded glow_1.5.1_linux_amd64.deb
📦 Installing Glow...
✅ Glow installed successfully
🧹 Cleaning up...
✅ Cleanup complete

🎉 Installation Complete
💡 Try it: glow README.md
```

### Running Setup Scripts Directly

You can also run setup scripts directly if needed:

```bash
$ bash ~/dotfiles/setup/nvm.sh
```

## Testing Your Dotfiles

Before committing major changes, run the validation suite:

```bash
$ ~/dotfiles/test.sh
```

**Output:**
```
🚀 Dotfiles Validation Tests...
TEST 1: Required core files exist... ✓
TEST 2: Symlink sources in config/symlinks.conf exist... ✓
TEST 3: functions.zsh sources without errors... ✓
TEST 4: .zshrc sources without errors... ✓
TEST 5: Setup scripts exist and are valid... ✓
TEST 6: Documentation files exist... ✓
TEST 7: lib/utils.sh defines required helpers... ✓
TEST 8: Git repository is valid... ✓
TEST 9: Git has remote origin configured... ✓

🎉 Test Results...
Total Tests: 9
Passed:      9
Failed:      0

✅ All tests passed!
```

If tests fail, you'll see detailed error messages about what needs to be fixed.

## Common Workflows

### Daily Maintenance

Keep your system updated across all hosts:

```bash
$ maintain
```

This convenience function runs:
1. `dotpull` - Get latest dotfiles changes
2. `updatep` - Full system package update in tmux
3. Shell reload

Perfect for morning routine or after returning from vacation.

### Quick Path Diagnostics

Check if all directories in your PATH actually exist:

```bash
$ paths
Checking PATH entries...
✔ /home/jeff/bin
✔ /home/jeff/.local/bin
✔ /usr/local/bin
✔ /usr/bin
✘ /opt/nonexistent/bin
Warning: PATH entry does not exist: /opt/nonexistent/bin
```

### Creating Archives

Package a directory for backup or transfer:

```bash
$ dotpack ~/projects/myapp
🚀 Creating archive...
✅ Created: myapp.tar.gz
```

With custom format:
```bash
$ dotpack ~/documents/notes zip
🚀 Creating archive...
✅ Created: notes.zip
```

## New Host Deployment

Deploy your entire dotfiles setup to a fresh Linux installation with one command:

```bash
$ wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

This automated process:
1. Installs Git and core utilities (bat, p7zip-full, tree)
2. Clones your dotfiles repository
3. Runs terminal setup (zsh, eza, fastfetch, starship)
4. Creates all symlinks via `sync.sh`
5. Configures zsh as your default shell

**After completion**, log out and back in for the shell change to take effect. On your first zsh session, Zinit will auto-install all plugins (~30 seconds).

See [New Host Deployment](New%20Host%20Deployment.md) for detailed information.
