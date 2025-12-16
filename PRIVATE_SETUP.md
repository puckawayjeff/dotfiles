# Private Setup Guide - Enhanced Mode

This guide walks you through creating your own private companion repository (sshsync) to enhance the public dotfiles with SSH key management and personal configurations.

## 🎯 Overview

The dotfiles system has two modes:

1. **Standalone Mode**: Public dotfiles only (no setup needed beyond running join.sh)
2. **Enhanced Mode**: Public dotfiles + private sshsync repo (requires setup)

This guide covers setting up **Enhanced Mode**.

## 📋 Prerequisites

- GitHub account (or other git hosting)
- Basic understanding of SSH keys
- Secure web server to host encrypted files (or use GitHub releases/cloud storage)
- Access to your SSH keys on your current machine

## 🚀 Quick Start (For the Impatient)

If you're already familiar with SSH keys and want the fastest path:

```bash
# 1. Create your private sshsync repo on GitHub
# 2. Package your SSH keys
sshpack "your-secure-password"

# 3. Upload ~/ssh-keys.tar.gz.enc to your web server
# 4. Create ~/.config/dotfiles/dotfiles.env with your settings
# 5. Run join.sh on a new machine
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

For detailed instructions, continue reading.

---

## 🔐 Step 1: Generate SSH Keys

### GitHub SSH Key

This key is used to authenticate with GitHub:

```bash
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519_github
```

**Add to GitHub:**
1. Go to GitHub → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste contents of `~/.ssh/id_ed25519_github.pub`
4. Test: `ssh -T git@github.com`

### Homelab/Server SSH Keys (Optional)

If you manage remote servers:

```bash
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519_homelab
```

Copy public key to your servers:
```bash
ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub user@server
```

Or manually append to `~/.ssh/authorized_keys` on the server.

---

## 📦 Step 2: Create Your Private Repository

### Create GitHub Repository

1. Go to GitHub → New Repository
2. Name it `sshsync` (or your preference)
3. Set to **Private** ⚠️ This is crucial!
4. Initialize with README
5. Clone it:
   ```bash
   git clone git@github.com:yourusername/sshsync.git ~/sshsync
   cd ~/sshsync
   ```

### Create SSH Config File

Create `ssh.conf` with your SSH hosts:

```bash
cat > ssh.conf << 'EOF'
# ssh.conf
# This will be symlinked to ~/.ssh/config

Host github.com
    HostName github.com
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes

# Add your servers/hosts here
# Host myserver
#     HostName 192.168.1.100
#     User yourusername
#     IdentityFile ~/.ssh/id_ed25519_homelab
#     Port 22

# Host example
#     HostName example.com
#     User root
#     IdentityFile ~/.ssh/id_ed25519_homelab
EOF
```

Customize this file with your own servers and hosts.

### Create README

Create a minimal `README.md`:

```bash
cat > README.md << 'EOF'
# My Private SSH Sync

Private companion repository for [dotfiles](https://github.com/yourusername/dotfiles).

**⚠️ This repository is private and contains sensitive configuration.**

## Contents

- `ssh.conf` - SSH configuration with host definitions
- (SSH keys are stored as encrypted archive on web server, not in git)

## Setup

See the public dotfiles repository for setup instructions.
EOF
```

### Commit and Push

```bash
git add ssh.conf README.md
git commit -m "Initial sshsync setup"
git push
```

---

## 🔒 Step 3: Package SSH Keys

The `package-ssh-keys.sh` script creates an encrypted archive of all your SSH keys.

### Run the Packaging Script

```bash
cd ~/dotfiles
./package-ssh-keys.sh
```

Or provide a password as an argument:

```bash
./package-ssh-keys.sh "your-secure-password-here"
```

This creates `~/ssh-keys.tar.gz.enc` containing all your SSH keys encrypted with AES-256-CBC.

**Important Security Notes:**
- Use a strong password (16+ characters recommended)
- Store password in a password manager
- The file is encrypted, but still treat it as sensitive
- Don't commit it to any git repository

### What Gets Packaged

The script finds all files matching `~/.ssh/id_*` (both private keys and public keys):
- `id_ed25519_github`
- `id_ed25519_github.pub`
- `id_ed25519_homelab`
- `id_ed25519_homelab.pub`
- Any other `id_*` keys you have

---

## 🌐 Step 4: Host Encrypted Archive

You need to host the encrypted archive at a URL accessible via wget/curl.

### Option A: Your Own Web Server (Recommended)

Upload `ssh-keys.tar.gz.enc` to your web server:

```bash
scp ~/ssh-keys.tar.gz.enc user@yourserver:/var/www/html/secure/
```

URL example: `https://yourserver.com/secure/ssh-keys.tar.gz.enc`

**Security Best Practices:**
- Use HTTPS (required)
- Consider adding HTTP basic authentication
- Use a non-obvious path (security through obscurity + encryption = defense in depth)
- Regularly rotate your SSH keys and archive password
- Set proper file permissions on the server (600 or 640)

**Apache example (.htaccess for basic auth):**
```apache
AuthType Basic
AuthName "Restricted Area"
AuthUserFile /path/to/.htpasswd
Require valid-user
```

**Nginx example:**
```nginx
location /secure/ {
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

### Option B: Cloud Storage with Direct Link

Services like Dropbox, AWS S3, Google Drive, etc. can work:

**Requirements:**
- Direct download link (not a preview page)
- HTTPS enabled
- Private/non-guessable URL
- You trust the provider's security

**Examples:**
- AWS S3 with pre-signed URLs
- Dropbox shared link (change `www.dropbox.com` to `dl.dropboxusercontent.com`)
- Google Drive (requires some URL manipulation)

### Option C: GitHub Release (Not Recommended)

While technically possible, hosting SSH keys on GitHub (even encrypted) is not recommended. Use a web server you fully control.

### Verify Your Archive URL

Test the download:
```bash
wget -q https://yourserver.com/path/to/ssh-keys.tar.gz.enc -O /tmp/test-download
ls -lh /tmp/test-download
rm /tmp/test-download
```

---

## ⚙️ Step 5: Create Environment File

Create `dotfiles.env` with your configuration:

```bash
mkdir -p ~/dotfiles-env-backup
cat > ~/dotfiles-env-backup/dotfiles.env << 'EOF'
# Private dotfiles environment configuration
# Copy to ~/.config/dotfiles/dotfiles.env on new machines

SSHSYNC_REPO_URL="git@github.com:yourusername/sshsync.git"
SSH_KEYS_ARCHIVE_URL="https://yourserver.com/secure/ssh-keys.tar.gz.enc"
SSH_KEYS_ARCHIVE_PASSWORD="your-secure-password-here"
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"
EOF
```

**Replace with your values:**
- `yourusername` - Your GitHub username
- `yourserver.com/secure/...` - URL to your encrypted archive
- `your-secure-password-here` - The password you used in Step 3
- `Your Name` - Your actual name
- `your@email.com` - Your actual email

### Storage Options for dotfiles.env

**⚠️ NEVER commit this file to a public repository!**

Choose one or more storage methods:

#### 1. In sshsync Repo (Recommended)

```bash
cp ~/dotfiles-env-backup/dotfiles.env ~/sshsync/
cd ~/sshsync
git add dotfiles.env
git commit -m "Add dotfiles.env (private repo only)"
git push
```

Retrieve on new machine with a temporary access method (GitHub token, manual copy via USB, etc.)

#### 2. Password Manager

Store as a secure note in 1Password, Bitwarden, LastPass, etc. Easy to retrieve on any device.

#### 3. Encrypted USB Drive

For air-gapped backups or machines without internet during initial setup.

#### 4. Encrypted Cloud Storage

Use encrypted cloud storage (Cryptomator, Veracrypt container, etc.) synced via Dropbox/Nextcloud/etc.

---

## 🚀 Step 6: Set Up New Machine

### Transfer Environment File

On the new machine, you need to get `dotfiles.env` in place before running join.sh.

#### Method 1: From sshsync (if stored there)

```bash
# Temporarily clone via HTTPS with a personal access token
git clone https://YOUR_TOKEN@github.com/yourusername/sshsync.git /tmp/sshsync
mkdir -p ~/.config/dotfiles
cp /tmp/sshsync/dotfiles.env ~/.config/dotfiles/
rm -rf /tmp/sshsync
```

#### Method 2: From Password Manager

Copy and paste:
```bash
mkdir -p ~/.config/dotfiles
nano ~/.config/dotfiles/dotfiles.env
# Paste content, save with Ctrl+O, exit with Ctrl+X
```

#### Method 3: From USB

```bash
mkdir -p ~/.config/dotfiles
cp /path/to/usb/dotfiles.env ~/.config/dotfiles/
```

### Run Setup

Once `dotfiles.env` is in place:

```bash
wget -qO - https://raw.githubusercontent.com/puckawayjeff/dotfiles/main/join.sh | bash
```

The script will:
1. Detect the environment file
2. Download encrypted SSH keys from your URL
3. Decrypt using your password
4. Extract and set up SSH keys with proper permissions
5. Configure git with your name and email
6. Clone sshsync repository via SSH
7. Clone dotfiles repository via SSH
8. Run sync.sh to set up everything
9. Symlink SSH config from sshsync
10. Enable enhanced functions (dotpush, sshpush, sshpull)

### Verify Setup

```bash
# Check SSH keys
ls -la ~/.ssh/id_*

# Check SSH config
cat ~/.ssh/config

# Test GitHub connection
ssh -T git@github.com
# Should see: "Hi username! You've successfully authenticated..."

# Check git config
git config --global --list

# Check repos
ls -ld ~/dotfiles ~/sshsync

# Try enhanced commands
dotpush --help  # Should work
sshpush --help  # Should work
```

---

## 🔄 Updating Your Setup

### Update SSH Config

Edit in sshsync repo:
```bash
cd ~/sshsync
nano ssh.conf
# Make changes
sshpush "Update SSH config for new server"
```

On other machines:
```bash
sshpull  # Pulls latest, symlink updates automatically
```

### Rotate SSH Keys

When you need to rotate keys:

1. Generate new keys on your current machine
2. Update GitHub/servers with new public keys
3. Re-run packaging script:
   ```bash
   cd ~/dotfiles
   sshpack "new-password-or-same-password"
   ```
4. Upload new archive to your web server (can use same URL)
5. Update `SSH_KEYS_ARCHIVE_PASSWORD` in dotfiles.env if password changed
6. Update dotfiles.env in your storage location(s)
7. Re-run join.sh on machines, or manually:
   ```bash
   # Backup old keys
   mv ~/.ssh/id_* ~/.ssh/backup/
   
   # Download and extract new archive
   # (manually run the commands from join.sh's setup_ssh_from_archive function)
   ```

### Add More Machines

Just run join.sh with dotfiles.env in place. That's it!

---

## 🛠️ Troubleshooting

### "Failed to decrypt archive"

**Cause:** Wrong password or corrupted archive

**Solutions:**
1. Verify password in dotfiles.env matches the one used in sshpack
2. Re-download the archive manually and test:
   ```bash
   wget https://yourserver.com/.../ssh-keys.tar.gz.enc -O /tmp/test.enc
   openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in /tmp/test.enc -out /tmp/test.tar.gz -pass pass:"YOUR_PASSWORD"
   tar -tzf /tmp/test.tar.gz
   ```
3. Re-package keys if archive is corrupted

### "Failed to clone sshsync repository"

**Cause:** SSH key not set up for GitHub, or wrong repo URL

**Solutions:**
1. Verify SSH keys were extracted: `ls -la ~/.ssh/id_ed25519_github*`
2. Test GitHub SSH: `ssh -T git@github.com`
3. Check repo URL in dotfiles.env
4. Verify you have access to the private repo

### "Permission denied (publickey)"

**Cause:** SSH key permissions or configuration issue

**Solutions:**
1. Check key permissions:
   ```bash
   chmod 600 ~/.ssh/id_ed25519_*
   chmod 644 ~/.ssh/id_ed25519_*.pub
   chmod 600 ~/.ssh/config
   ```
2. Verify key is loaded: `ssh-add -l`
3. Add key if needed: `ssh-add ~/.ssh/id_ed25519_github`
4. Check SSH config points to correct key

### "Command not found: dotpush/sshpush/sshpull"

**Cause:** Functions not loaded or enhanced mode not active

**Solutions:**
1. Verify sshsync exists: `ls -ld ~/sshsync`
2. Reload shell: `exec zsh`
3. Check if functions.zsh is sourced in .zshrc
4. Manually source: `source ~/dotfiles/config/functions.zsh`

### Archive Download Fails

**Cause:** Network issue, wrong URL, or server authentication

**Solutions:**
1. Test URL in browser
2. Test with curl: `curl -I https://yourserver.com/.../ssh-keys.tar.gz.enc`
3. Check for HTTP basic auth requirements
4. Verify HTTPS certificate is valid
5. Try alternate hosting location

### Falling Back to Standalone Mode

If enhanced mode setup fails, join.sh automatically falls back to standalone mode. You'll get:
- Public dotfiles via HTTPS
- Default git credentials
- No SSH keys
- No sshsync repo

To retry enhanced mode:
1. Fix the issue (password, URL, etc.)
2. Update ~/.config/dotfiles/dotfiles.env
3. Run: `bash ~/dotfiles/sync.sh --from-join`

---

## 🔒 Security Considerations

### Encryption

- Archive uses AES-256-CBC with PBKDF2 (100,000 iterations)
- Secure encryption resistant to brute-force
- Password is the weakest link - use a strong one!

### Password Strength

Minimum recommendations:
- 16+ characters
- Mix of upper, lower, numbers, symbols
- Not based on dictionary words
- Unique (not reused elsewhere)

Consider using a passphrase generator:
```bash
# Generate a strong passphrase
openssl rand -base64 32
```

### Defense in Depth

The system uses multiple security layers:
1. Private GitHub repository (access control)
2. Encrypted archive (protection at rest)
3. Strong password (encryption key strength)
4. HTTPS transport (protection in transit)
5. Optional HTTP auth on web server (additional access control)
6. SSH key passphrases (optional additional layer)

### What to Store Where

**Public dotfiles repo:**
- Shell configurations
- Application configs (without secrets)
- Scripts and utilities
- Documentation

**Private sshsync repo:**
- SSH config with hosts
- Future: encrypted password store
- Future: environment variables with secrets
- The dotfiles.env file (optional)

**Not in any repo:**
- SSH private keys (only in encrypted archive)
- Passwords in plain text
- API tokens in plain text

### Revoking Access

If a machine is compromised:
1. Remove SSH keys from GitHub/servers
2. Rotate to new SSH keys
3. Change archive encryption password
4. Update archive and dotfiles.env
5. Re-deploy to trusted machines only

---

## 🎓 Advanced Topics

### Multiple SSH Keys for Different Purposes

Organize your keys by purpose:
```bash
~/.ssh/
├── id_ed25519_github          # GitHub access
├── id_ed25519_github.pub
├── id_ed25519_work            # Work servers
├── id_ed25519_work.pub
├── id_ed25519_personal        # Personal servers
└── id_ed25519_personal.pub
```

Update ssh.conf accordingly:
```
Host github-work
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519_work

Host github-personal
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519_personal
```

All keys are packaged together in the archive.

### SSH Key Passphrases

Add an extra security layer:
```bash
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519_github
# Enter passphrase when prompted
```

Use ssh-agent to avoid typing it repeatedly:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github
```

Add to .zshrc for automatic loading:
```bash
# Start ssh-agent and load keys
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519_github
fi
```

### Separate Archives for Different Key Sets

For high-security scenarios, maintain separate archives:
```bash
# Work keys only
sshpack work-password
mv ~/ssh-keys.tar.gz.enc ~/ssh-keys-work.tar.gz.enc

# Personal keys only
./package-ssh-keys.sh personal-password
mv ~/ssh-keys.tar.gz.enc ~/ssh-keys-personal.tar.gz.enc
```

Create different dotfiles.env for work vs personal machines.

### Automating Sync

Create a cron job or systemd timer to auto-sync:
```bash
# Add to crontab
0 */6 * * * /bin/bash -c 'cd ~/dotfiles && bash sync.sh --quiet'
```

This pulls changes every 6 hours silently.

---

## 📚 Additional Resources

- [GitHub SSH Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [SSH Config File Reference](https://man.openbsd.org/ssh_config)
- Main dotfiles README: [README.md](README.md)
- Examples and usage: [docs/Examples.md](docs/Examples.md)

---

## 🤝 Questions or Issues?

- Check this guide's troubleshooting section
- Review the main [README.md](README.md)
- Open an issue on GitHub
- Check dotfiles documentation in `docs/`

---

**Happy syncing! 🎉**
