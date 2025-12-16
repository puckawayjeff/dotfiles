# Testing Guide - Dotfiles Repository

This guide explains how to test the dotfiles system to ensure everything works correctly.

## Automated Testing

### test.sh - Validation Suite

Run the automated test suite to check repository health:

```bash
cd ~/dotfiles
./test.sh
```

**What it tests**:
1. Required core files exist (sync.sh, join.sh, config files, libs)
2. Symlink sources in sync.sh are valid
3. functions.zsh sources without errors
4. .zshrc sources without errors
5. Setup scripts have proper format (shebangs, readability)
6. Documentation files are present
7. lib/utils.sh defines required helper functions
8. Git repository is valid
9. Git remote origin is configured

**Expected output**:
```
🚀 Dotfiles Validation Tests...
TEST 1: Required core files exist... ✓
TEST 2: Symlink sources in sync.sh exist... ✓
...
TEST 9: Git has remote origin configured... ✓

🎉 Test Results...
Total Tests: 9
Passed:      9
Failed:      0

🎉 All tests passed!
```

## Manual Testing

### Test 1: Standalone Mode Deployment

**Purpose**: Verify clean installation on a new system without enhanced mode.

**Prerequisites**: Clean Linux VM or container (Debian-based)

**Steps**:
```bash
# 1. Deploy dotfiles
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash

# 2. Start new shell
exec zsh

# 3. Verify installation
dothelp          # Should display command reference
dotkeys          # Should display keyboard shortcuts
dotversion       # Should show 2.0.0

# 4. Check core tools
command -v starship  # Should exist
command -v eza       # Should exist
command -v fastfetch # Should exist
command -v micro     # Should exist

# 5. Verify shell features
# - Type a command and see autosuggestions (grey text)
# - Press Ctrl+R for FZF history search
# - Type 'll' to see eza output with icons

# 6. Test dotpull
dotpull          # Should pull latest changes and reload shell
```

**Expected Results**:
- All tools installed successfully
- Shell features work (autosuggestions, FZF, syntax highlighting)
- dothelp and dotkeys display correctly
- Symlinks created for all config files
- MOTD displays on new terminal session

**What to Check**:
- No error messages during installation
- Git configured with default credentials
- Cannot use dotpush (enhanced mode only)
- Terminal displays icons correctly (Nerd Fonts)

### Test 2: Enhanced Mode Deployment

**Purpose**: Verify installation with SSH keys and private repository.

**Prerequisites**:
- Clean Linux VM or container
- Valid dotfiles.env file
- SSH keys packaged and hosted
- Private sshsync repository set up

**Steps**:
```bash
# 1. Create environment file
mkdir -p ~/.config/dotfiles
cat > ~/.config/dotfiles/dotfiles.env << 'EOF'
SSHSYNC_REPO_URL="git@github.com:username/sshsync.git"
SSH_KEYS_ARCHIVE_URL="https://example.com/ssh-keys.tar.gz.enc"
SSH_KEYS_ARCHIVE_PASSWORD="your-password"
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"
EOF

# 2. Deploy dotfiles
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash

# 3. Start new shell
exec zsh

# 4. Verify enhanced mode
ls -la ~/.ssh/id_*        # SSH keys should exist
cat ~/.ssh/config         # Should show sshsync SSH config
ls -ld ~/sshsync          # sshsync repo should exist
git config --global --list # Should show personal credentials

# 5. Test enhanced commands
dotpush --help    # Should work (not error about enhanced mode)
sshpush --help    # Should work
sshpull           # Should work
```

**Expected Results**:
- SSH keys decrypted and installed
- SSH config symlinked from sshsync
- Both dotfiles and sshsync repos cloned
- Git configured with personal credentials
- Enhanced commands available

**What to Check**:
- SSH keys have correct permissions (600 for private, 644 for public)
- SSH config points to correct identity files
- GitHub SSH connection works: `ssh -T git@github.com`
- Can push to both repos (dotpush, sshpush)

### Test 3: Add Dotfile Workflow

**Purpose**: Verify add-dotfile command works correctly.

**Prerequisites**: Dotfiles installed (standalone or enhanced mode)

**Steps**:
```bash
# 1. Create a test config file
echo "test=value" > ~/.testconfig

# 2. Add it to dotfiles
add-dotfile ~/.testconfig

# 3. Verify results
ls -la ~/.testconfig           # Should be a symlink
readlink ~/.testconfig         # Should point to ~/dotfiles/config/.testconfig
cat ~/dotfiles/config/.testconfig  # Should contain "test=value"
grep "testconfig" ~/dotfiles/config/symlinks.conf  # Should have entry

# 4. Check git status
cd ~/dotfiles
git status  # Should show config/.testconfig and config/symlinks.conf staged

# 5. Test custom destination
echo "custom=test" > ~/.customfile
add-dotfile ~/.customfile config/renamed.conf
ls -la ~/.customfile           # Should be a symlink
cat ~/dotfiles/config/renamed.conf  # Should contain "custom=test"

# 6. Clean up
git reset HEAD .
rm -f ~/.testconfig ~/.customfile
rm -f ~/dotfiles/config/.testconfig ~/dotfiles/config/renamed.conf
```

**Expected Results**:
- File moved to repository
- Symlink created at original location
- Entry added to config/symlinks.conf
- Changes staged in Git

**What to Check**:
- Original file content preserved
- Symlink points to correct location
- symlinks.conf uses $DOTFILES_DIR and $HOME variables
- Error handling for existing files/symlinks

### Test 4: Sync Workflow

**Purpose**: Verify sync.sh handles updates correctly.

**Prerequisites**: Dotfiles installed

**Steps**:
```bash
# 1. Run sync script directly
cd ~/dotfiles
bash sync.sh

# 2. Run in quiet mode
bash sync.sh --quiet

# 3. Make a change and pull
echo "# test" >> ~/.zshrc
dotpull  # Should stash changes, pull updates, run sync.sh

# 4. Check stash
cd ~/dotfiles
git stash list  # Should show auto-stash entry

# 5. Restore stash if needed
git stash pop
```

**Expected Results**:
- Sync completes without errors
- Local changes auto-stashed before pull
- Symlinks updated/created
- New tools installed if added

**What to Check**:
- No duplicate symlinks created
- Existing symlinks not broken
- Git stash preserves local changes
- Sync script is idempotent (run multiple times safely)

### Test 5: Optional Tool Installation

**Purpose**: Verify setup scripts work correctly.

**Prerequisites**: Dotfiles installed

**Steps**:
```bash
# 1. List available tools
dotsetup

# 2. Install a tool (example: glow)
dotsetup glow

# 3. Verify installation
command -v glow  # Should exist
glow --version   # Should show version

# 4. Test idempotency
dotsetup glow    # Should detect already installed

# 5. Try other tools
dotsetup nvm     # Install Node Version Manager
command -v node  # Should exist after nvm installs Node
```

**Expected Results**:
- Tool installs successfully
- Configuration added to .zshrc (if applicable)
- Re-running installer detects existing installation
- No errors or warnings

**What to Check**:
- Tool works after installation
- Configuration markers in .zshrc (if applicable)
- Idempotent behavior (safe to re-run)
- Proper error messages for failures

### Test 6: System Update Workflow

**Purpose**: Verify updatep function works in tmux.

**Prerequisites**: Dotfiles installed

**Steps**:
```bash
# 1. Run system update
updatep

# 2. Observe tmux session
# - Should create new tmux session
# - Should run apt update, upgrade, autoremove
# - Should display progress
# - Should auto-close when done

# 3. Check log file
cat ~/.cache/updatep.log  # Should contain update output

# 4. Test maintain workflow
maintain
# Should:
# - Pull latest dotfiles
# - Run sync.sh
# - Run updatep
# - Reload shell
```

**Expected Results**:
- Tmux installs if missing
- Updates run in tmux session
- Log file created with output
- Session closes after completion
- maintain runs full workflow

**What to Check**:
- Tmux session created successfully
- All update commands execute
- Log file has complete output
- No permission errors with sudo

### Test 7: Documentation Validation

**Purpose**: Verify documentation is complete and accurate.

**Prerequisites**: Dotfiles repository

**Steps**:
```bash
cd ~/dotfiles

# 1. Check documentation exists
ls -la docs/
ls -la README.md ARCHITECTURE.md PRIVATE_SETUP.md

# 2. Check for broken links
grep -r "](docs/" *.md docs/*.md | grep -v "Binary"
# Manually verify each link exists

# 3. Check version consistency
cat VERSION                    # Should be 2.0.0
grep "## \[2.0.0\]" CHANGELOG.md  # Should exist
grep "Version 2.0.0" RELEASE_NOTES.md  # Should exist

# 4. Verify examples work
# Follow examples in docs/Examples.md
# Verify each command works as documented

# 5. Check cross-references
grep -r "ARCHITECTURE.md" *.md
grep -r "PRIVATE_SETUP.md" *.md
# Verify links are valid
```

**Expected Results**:
- All documentation files present
- No broken internal links
- Version numbers consistent
- Examples work as documented
- Cross-references valid

### Test 8: SSH Key Packaging (For Enhanced Mode Setup)

**Purpose**: Verify SSH key packaging script works.

**Prerequisites**: System with SSH keys

**Steps**:
```bash
cd ~/dotfiles

# 1. Run packaging script
./package-ssh-keys.sh "test-password-123"

# 2. Verify archive created
ls -lh ~/ssh-keys.tar.gz.enc

# 3. Test decryption
openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 \
  -in ~/ssh-keys.tar.gz.enc \
  -out /tmp/test.tar.gz \
  -pass pass:"test-password-123"

# 4. List contents
tar -tzf /tmp/test.tar.gz

# 5. Clean up
rm ~/ssh-keys.tar.gz.enc /tmp/test.tar.gz
```

**Expected Results**:
- Archive created successfully
- Verification passes
- Contains all id_* files from ~/.ssh/
- Decryption works with password

**What to Check**:
- File permissions in archive
- All keys included (private and public)
- Encryption strength (AES-256-CBC, PBKDF2)
- Archive integrity

## Performance Testing

### Shell Startup Time

**Purpose**: Verify shell loads quickly.

**Steps**:
```bash
# 1. Time shell startup
time zsh -i -c exit

# 2. Should be under 0.2 seconds
# If slower, check:
# - Zinit plugins loading slowly
# - Network issues with git operations
# - Disk I/O problems
```

**Expected**: < 0.2 seconds for interactive shell startup

### Sync Performance

**Purpose**: Verify sync.sh completes quickly.

**Steps**:
```bash
cd ~/dotfiles
time bash sync.sh --quiet
```

**Expected**: < 5 seconds on subsequent runs (first run installs tools)

## Troubleshooting Test Failures

### Test Suite Failures

**TEST 2: Symlink sources invalid**
- Fix: Ensure all files referenced in sync.sh exist
- Check: config/ directory for missing files

**TEST 3/4: Shell files syntax errors**
- Fix: Run `zsh -n <file>` to check syntax
- Check: Recent changes to .zshrc or functions.zsh

**TEST 5: Setup scripts invalid**
- Fix: Ensure all .sh files in setup/ have shebangs
- Check: File permissions (should be readable)

### Manual Test Failures

**join.sh fails to clone**
- Check: Internet connection
- Check: Git is installed
- Check: GitHub is accessible

**Enhanced mode fails**
- Check: dotfiles.env exists and has correct variables
- Check: SSH keys archive URL is accessible
- Check: Password is correct
- Check: sshsync repository exists and is accessible

**Symlinks broken**
- Check: Original files exist in config/
- Check: symlinks.conf has correct paths
- Fix: Run `sync.sh` to recreate symlinks

**Commands not found**
- Check: Shell reloaded (exec zsh)
- Check: functions.zsh is sourced in .zshrc
- Fix: Source manually: `source ~/dotfiles/config/functions.zsh`

## Test Coverage

### What's Tested
- ✅ Core file existence
- ✅ Symlink validity
- ✅ Shell syntax
- ✅ Library functions
- ✅ Git repository health
- ✅ Documentation completeness

### What's Not Tested (Manual Only)
- ⚠️ Actual tool installation (requires sudo)
- ⚠️ Network operations (git clone, wget)
- ⚠️ SSH key decryption
- ⚠️ Enhanced mode full workflow
- ⚠️ Terminal rendering (colors, icons)
- ⚠️ Plugin functionality

## Continuous Testing

### Before Commits
```bash
# Always run before committing changes
./test.sh
```

### After Major Changes
```bash
# Test in clean VM/container
# - Standalone mode deployment
# - Enhanced mode deployment (if applicable)
# - Add dotfile workflow
# - Update workflow
```

### Release Testing
```bash
# Before tagging new version:
1. Run test.sh
2. Test standalone deployment in VM
3. Test enhanced deployment in VM
4. Verify documentation accuracy
5. Check version numbers in all files
6. Test upgrade from previous version
```

## Contributing Tests

To add new tests to test.sh:

1. Add test function following existing pattern
2. Use test_start(), test_pass(), test_fail()
3. Increment TESTS_RUN counter
4. Update this documentation

Example:
```bash
# Test 10: Check custom validation
test_start "Custom validation passes"
if custom_check; then
    test_pass
else
    test_fail "Custom check failed"
fi
```

## References

- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design
- [docs/Script Development Best Practices.md](Script%20Development%20Best%20Practices.md) - Coding standards
- [docs/Examples.md](Examples.md) - Usage examples
- [test.sh](../test.sh) - Validation suite source

---

**For issues**: Open a GitHub issue with test results and error messages.
