# Terminal Font Setup Guide

This guide covers how to configure **FiraCode Nerd Font** in various terminal emulators for optimal Starship prompt display and icon support.

## Why Nerd Fonts?

Nerd Fonts are patched fonts that include thousands of additional glyphs (icons) from popular icon sets like Font Awesome, Devicons, Octicons, and more. Starship uses these icons extensively to display:

- Git branch symbols ( )
- Programming language indicators ( ,  ,  )
- Docker, Node, Python version indicators
- File/folder icons
- Status indicators

**Regular fonts don't include these glyphs** - you'll see missing character boxes (▯) or question marks (?) instead.

## Font Installation

### Linux (Debian/Ubuntu/Mint)

The `setup/starship.sh` and `setup/foot.sh` scripts automatically install FiraCode Nerd Font to `~/.local/share/fonts/NerdFonts/`.

**Manual installation:**

```bash
# Download latest release
NERD_FONT_VERSION="v3.3.0"
mkdir -p ~/.local/share/fonts/NerdFonts
cd /tmp
curl -fLo FiraCode.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/FiraCode.zip"
unzip FiraCode.zip -d ~/.local/share/fonts/NerdFonts
rm FiraCode.zip

# Update font cache
fc-cache -fv
```

**Verify installation:**

```bash
fc-list | grep "FiraCode Nerd Font"
```

You should see output like:

```text
/home/username/.local/share/fonts/NerdFonts/FiraCodeNerdFont-Regular.ttf: FiraCode Nerd Font:style=Regular
/home/username/.local/share/fonts/NerdFonts/FiraCodeNerdFont-Bold.ttf: FiraCode Nerd Font:style=Bold
...
```

### Windows

#### Option 1: Download from GitHub

1. Visit: [https://github.com/ryanoasis/nerd-fonts/releases/latest]
2. Download `FiraCode.zip`
3. Extract the ZIP file
4. Select all `.ttf` files
5. Right-click → **Install** (or **Install for all users** if you have admin rights)

#### Option 2: Using Scoop (Package Manager)

```powershell
# If Scoop isn't installed:
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# irm get.scoop.sh | iex

scoop bucket add nerd-fonts
scoop install FiraCode-NF
```

#### Option 3: Using Chocolatey

```powershell
choco install firacodenf
```

**Verify installation (PowerShell):**

```powershell
[System.Drawing.Text.InstalledFontCollection]::new().Families | Where-Object { $_.Name -like "*FiraCode*Nerd*" }
```

---

## Terminal Configuration

### 1. VS Code Integrated Terminal

**Settings UI:**

1. Open VS Code
2. Press `Ctrl+,` (or `Cmd+,` on Mac) to open Settings
3. Search for: `terminal.integrated.fontFamily`
4. Set value to: `FiraCode Nerd Font`
5. Optionally adjust size: Search `terminal.integrated.fontSize` → Set to `12` or `14`

**settings.json (Manual):**

```json
{
  "terminal.integrated.fontFamily": "FiraCode Nerd Font",
  "terminal.integrated.fontSize": 12
}
```

**Location of settings.json:**

- **Linux:** `~/.config/Code/User/settings.json`
- **Windows:** `%APPDATA%\Code\User\settings.json`
- **macOS:** `~/Library/Application Support/Code/User/settings.json`

**Test:**

- Open a new terminal in VS Code (`Ctrl+\``)
- Run: `starship preset nerd-font-symbols -o ~/.config/starship.toml.preview`
- You should see icons render correctly

---

### 2. Linux Mint Default Terminal (Gnome Terminal / Mate Terminal)

**Via GUI:**

1. Open terminal
2. Go to: **Edit** → **Preferences** (or **Profile Preferences**)
3. Navigate to: **Text** or **General** tab
4. Uncheck "Use system fixed width font"
5. Click **Font** button
6. Search for: `FiraCode Nerd Font` or `FiraCode NF`
7. Select **Regular** or **Medium** variant
8. Set size to: `12` or your preference
9. Click **Select** / **OK**

**Via dconf (Command Line):**

```bash
# Get your profile UUID (usually 'default')
PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# Set font (Gnome Terminal)
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ font 'FiraCode Nerd Font 12'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ use-system-font false

# For Mate Terminal:
# gsettings set org.mate.terminal.profile:/org/mate/terminal/profiles/default/ font 'FiraCode Nerd Font 12'
# gsettings set org.mate.terminal.profile:/org/mate/terminal/profiles/default/ use-system-font false
```

---

### 3. Windows Terminal (Preview)

**Settings UI:**

1. Open Windows Terminal
2. Press `Ctrl+,` to open Settings
3. Navigate to: **Profiles** → **Defaults** (or select specific profile like PowerShell/Ubuntu)
4. Scroll to **Appearance** section
5. Under **Font face**, select: `FiraCode Nerd Font` or `FiraCode NF`
6. Set **Font size** to `10` or `12`
7. Click **Save**

**settings.json (Manual):**

```json
{
  "profiles": {
    "defaults": {
      "font": {
        "face": "FiraCode Nerd Font",
        "size": 12
      }
    }
  }
}
```

**Access settings.json:**

- Click dropdown arrow → **Settings** → Gear icon (⚙️) at bottom left

**Per-profile configuration:**

```json
{
  "profiles": {
    "list": [
      {
        "name": "Ubuntu",
        "source": "Windows.Terminal.Wsl",
        "font": {
          "face": "FiraCode Nerd Font",
          "size": 12
        }
      }
    ]
  }
}
```

---

### 4. Guake (Drop-down Terminal)

**Via GUI:**

1. Open Guake
2. Right-click tray icon → **Preferences**
3. Go to: **Appearance** tab
4. Uncheck "Use the system fixed width font"
5. Click **Font** button
6. Search: `FiraCode Nerd Font`
7. Select variant and size (e.g., `Regular 12`)
8. Click **OK**

**Via dconf (Command Line):**

```bash
dconf write /apps/guake/style/font/style "'FiraCode Nerd Font 12'"
dconf write /apps/guake/style/font/use-system-font false
```

**Restart Guake:**

```bash
guake --quit
guake &
```

---

### 5. Foot Terminal (Wayland)

**Configuration:**
The `setup/foot.sh` script automatically creates `~/.config/foot/foot.ini` with:

```ini
font=FiraCode Nerd Font:size=12
```

**Manual configuration:**
Edit `~/.config/foot/foot.ini`:

```ini
[main]
font=FiraCode Nerd Font:size=12
# or specify exact variant:
# font=FiraCode Nerd Font Mono:size=12

# Optional: Enable ligatures (programming ligatures like != -> ≠)
# dpi-aware=yes
```

**Test:**

```bash
foot -e bash
echo "   Test icons"
```

---

### 6. Proxmox Web Terminal (xterm.js)

**Important:** Proxmox's web-based terminal uses xterm.js in the browser, which relies on **browser-installed fonts**.

**Limitations:**

- You cannot directly configure the Proxmox server's terminal font
- The browser must have the font installed locally
- Not all browsers support custom web fonts for terminal emulators

**Workaround (Limited Success):**

1. **Install font on your local machine** (Windows/Linux/Mac - see above)

2. **SSH with your own terminal:** Instead of using the Proxmox web UI, connect via:

   ```bash
   ssh root@proxmox-host
   ```
  
   Your local terminal (with Nerd Font) will render icons correctly.

3. **Browser Font Injection (Advanced):**
   Some browsers allow custom CSS injection via extensions:
   - Install browser extension: **Stylus** (Chrome/Firefox)
   - Create a new style for `https://your-proxmox-ip:8006`
   - Add CSS:
  
     ```css
     .xterm .xterm-screen {
       font-family: "FiraCode Nerd Font", monospace !important;
     }
     ```

   - **Caveat:** This only works if the browser has the font installed locally

4. **Best Solution:** Use a proper SSH client (VS Code Remote SSH, Windows Terminal, native terminal) instead of the web console for everyday work.

**For cluster management:**

- Keep using web UI for GUI tasks (VM management, storage, etc.)
- Use SSH terminal for command-line work with proper font rendering

---

## Troubleshooting

### Icons show as boxes or question marks

**Possible causes:**

1. Font not installed correctly
2. Terminal not configured to use Nerd Font
3. Font cache not updated (Linux)

**Fix:**

```bash
# Linux: Verify font is installed
fc-list | grep -i "nerd"

# Update font cache
fc-cache -fv

# Restart terminal completely
```

### Font is installed but not showing in terminal dropdown

**Fix:**

- Restart the terminal application completely
- On Windows, log out and log back in
- Check if font name has variant suffix (try "FiraCode Nerd Font Mono")

### Ligatures not working (!=, =>, ->, etc.)

**Note:** Font ligatures are different from Nerd Font icons.

- Some terminals don't support ligatures
- In foot: Ensure `dpi-aware=yes` in config
- In VS Code: Add `"editor.fontLigatures": true` to settings
- In Windows Terminal: Ligatures are automatically enabled

### Performance issues with Nerd Fonts

Nerd Fonts are larger files (~10-20MB) due to extra glyphs.

- Most modern terminals handle this fine
- If you experience lag, try the "Mono" variant: `FiraCode Nerd Font Mono`
- Reduce font size slightly

---

## Alternative Nerd Fonts

If FiraCode doesn't suit your preference:

| Font Name | Description | Best For |
|-----------|-------------|----------|
| **JetBrains Mono NF** | Clean, optimized for code | Developers who want excellent readability |
| **Hack NF** | Condensed, fits more text | Smaller screens, 80+ column code |
| **Meslo NF** | Apple's Menlo + patches | macOS users, similar to default terminal |
| **CaskaydiaCove NF** | Microsoft Cascadia Code | Windows Terminal users |

**Install alternative:**

```bash
# Linux
cd /tmp
curl -fLo JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"
unzip JetBrainsMono.zip -d ~/.local/share/fonts/NerdFonts
fc-cache -fv
```

Then update terminal config to use the new font name (e.g., `JetBrains Mono Nerd Font`).

---

## Testing Your Configuration

After configuring your terminal, test icon rendering:

```bash
# Show Starship config
starship config

# Test with simple prompt
echo "   Nerd Font Icons Test"

# Check if prompt renders correctly
# You should see colorful icons for:
# - Git branch symbol ()
# - Folder symbol
# - Language icons (,  , )
# - Arrow symbol (➜)
```

**Expected output:**

```text
jeff@hostname ~/dotfiles  main !1 ?2                                              2.3s 14:35:42
➜
```

If you see `▯` or `?` instead of icons, your font is not configured correctly.

---

## Quick Reference

| Terminal | Config File/Location | Font Setting |
|----------|---------------------|--------------|
| VS Code | `settings.json` | `"terminal.integrated.fontFamily": "FiraCode Nerd Font"` |
| Gnome Terminal | GUI or dconf | `gsettings set ... font 'FiraCode Nerd Font 12'` |
| Windows Terminal | `settings.json` | `"font": { "face": "FiraCode Nerd Font" }` |
| Guake | GUI or dconf | `dconf write /apps/guake/style/font/style "'FiraCode Nerd Font 12'"` |
| Foot | `~/.config/foot/foot.ini` | `font=FiraCode Nerd Font:size=12` |
| Proxmox Web | ❌ Not directly supported | Use SSH client instead |

---

## Additional Resources

- **Nerd Fonts Homepage:** [https://www.nerdfonts.com/]
- **GitHub Releases:** [https://github.com/ryanoasis/nerd-fonts/releases]
- **Font Preview:** [https://www.programmingfonts.org/]
- **Starship Documentation:** [https://starship.rs/config/]
