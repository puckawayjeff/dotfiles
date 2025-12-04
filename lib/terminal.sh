#!/usr/bin/env bash
# lib/terminal.sh - Consolidated terminal utilities installation
# Installs zsh, eza, fastfetch, starship, and supporting tools
# Idempotent - safe to run multiple times
# Configuration is handled by existing .zshrc - this only installs binaries

# Load shared utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
else
    echo "Error: utils.sh not found"
    return 1 2>/dev/null || exit 1
fi

# Track success/failure counts for summary
INSTALLS_SUCCESS=0
INSTALLS_FAILED=0
INSTALLS_SKIPPED=0

# Helper function to track results
track_success() { INSTALLS_SUCCESS=$((INSTALLS_SUCCESS + 1)); }
track_failure() { INSTALLS_FAILED=$((INSTALLS_FAILED + 1)); }
track_skip() { INSTALLS_SKIPPED=$((INSTALLS_SKIPPED + 1)); }

# ============================================================================
# ZSH INSTALLATION
# ============================================================================
install_zsh() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Zsh Installation" "$COMPUTER"
    fi
    
    if command -v zsh &> /dev/null; then
        ZSH_VERSION=$(zsh --version | head -n1)
        log_success "Zsh already installed: $ZSH_VERSION"
        track_skip
    else
        log_info "Installing zsh..."
        if sudo apt install -y zsh 2>/dev/null; then
            log_success "Zsh installed successfully"
            track_success
            
            # Change default shell if not already zsh
            if [[ "$(basename "$SHELL")" != "zsh" ]]; then
                log_info "Changing default shell to zsh..."
                ZSH_PATH=$(which zsh)
                
                # Ensure zsh is in /etc/shells
                if ! grep -q "^${ZSH_PATH}$" /etc/shells 2>/dev/null; then
                    echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
                fi
                
                if chsh -s "$ZSH_PATH" 2>/dev/null; then
                    log_success "Default shell changed to zsh (logout required)"
                else
                    log_warning "Could not change default shell automatically"
                fi
            fi
        else
            log_error "Zsh installation failed"
            track_failure
        fi
    fi
}

# ============================================================================
# FZF (Fuzzy Finder)
# ============================================================================
install_fzf() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "FZF (Fuzzy Finder)" "$COMPUTER"
    fi
    
    if command -v fzf &> /dev/null; then
        log_success "FZF already installed"
        track_skip
    else
        log_info "Installing fzf..."
        if sudo apt install -y fzf 2>/dev/null; then
            log_success "FZF installed successfully"
            track_success
        else
            log_warning "FZF installation failed, continuing..."
            track_failure
        fi
    fi
}

# ============================================================================
# ZOXIDE (Smart cd)
# ============================================================================
install_zoxide() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Zoxide (Smart cd)" "$COMPUTER"
    fi
    
    if command -v zoxide &> /dev/null; then
        log_success "Zoxide already installed"
        track_skip
    else
        log_info "Installing zoxide..."
        # Try apt first
        if sudo apt install -y zoxide 2>/dev/null; then
            log_success "Zoxide installed via apt"
            track_success
        # Fallback to curl installer
        elif curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh 2>/dev/null | bash; then
            log_success "Zoxide installed via curl"
            track_success
        else
            log_warning "Zoxide installation failed, continuing..."
            track_failure
        fi
    fi
}

# ============================================================================
# FD (Fast find alternative)
# ============================================================================
install_fd() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "fd (Fast find)" "$COMPUTER"
    fi
    
    if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
        log_success "fd already installed"
        track_skip
    else
        log_info "Installing fd-find..."
        if sudo apt install -y fd-find 2>/dev/null; then
            # Create symlink if fdfind is installed (Debian naming)
            if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
                mkdir -p ~/.local/bin
                ln -sf $(which fdfind) ~/.local/bin/fd 2>/dev/null
            fi
            log_success "fd installed successfully"
            track_success
        else
            log_warning "fd installation failed, continuing..."
            track_failure
        fi
    fi
}

# ============================================================================
# DIRENV (Directory environment loader)
# ============================================================================
install_direnv() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "direnv (Directory environments)" "$COMPUTER"
    fi
    
    if command -v direnv &> /dev/null; then
        log_success "direnv already installed"
        track_skip
    else
        log_info "Installing direnv..."
        if sudo apt install -y direnv 2>/dev/null; then
            log_success "direnv installed successfully"
            track_success
        else
            log_warning "direnv installation failed, continuing..."
            track_failure
        fi
    fi
}

# ============================================================================
# EZA (Modern ls replacement)
# ============================================================================
install_eza() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "eza (Modern ls)" "$COMPUTER"
    fi
    
    # Check if already installed from official repo
    if command -v eza &> /dev/null && [ -f /etc/apt/sources.list.d/gierens.list ]; then
        log_success "eza already installed from official repository"
        track_skip
        return 0
    fi
    
    # Remove distro version if present
    if dpkg -l 2>/dev/null | grep -q "^ii.*eza"; then
        log_info "Removing distro-installed eza..."
        sudo apt remove -y eza 2>/dev/null
    fi
    
    # Install gpg if needed
    if ! command -v gpg &> /dev/null; then
        log_substep "Installing gpg for repository verification..."
        if ! sudo apt install -y gpg 2>/dev/null; then
            log_warning "Could not install gpg, skipping eza installation"
            track_failure
            return 1
        fi
    fi
    
    log_info "Setting up official eza repository..."
    
    # Create keyrings directory
    sudo mkdir -p /etc/apt/keyrings 2>/dev/null
    
    # Add GPG key
    if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
        if ! wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
            log_warning "Failed to download eza repository key, continuing..."
            track_failure
            return 1
        fi
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    fi
    
    # Add repository source
    if [ ! -f /etc/apt/sources.list.d/gierens.list ]; then
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        sudo chmod 644 /etc/apt/sources.list.d/gierens.list
    fi
    
    # Update and install
    if sudo apt update 2>/dev/null && sudo apt install -y eza 2>/dev/null; then
        log_success "eza installed successfully"
        track_success
    else
        log_warning "eza installation failed, continuing..."
        track_failure
    fi
}

# ============================================================================
# FASTFETCH (System info)
# ============================================================================
install_fastfetch() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "fastfetch (System info)" "$COMPUTER"
    fi
    
    # Remove package-based installations first
    local removed_any=false
    if dpkg -l 2>/dev/null | grep -q "^ii.*\(fastfetch\|neofetch\|screenfetch\)"; then
        log_substep "Removing old package-based installations..."
        sudo apt remove -y fastfetch neofetch screenfetch 2>/dev/null && removed_any=true
    fi
    
    # Check if we need to install
    local current_version=""
    if command -v fastfetch &> /dev/null; then
        current_version=$(fastfetch --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "")
    fi
    
    local latest_version=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest 2>/dev/null | grep -oP '"tag_name": "\K[^"]+' | sed 's/^v//' || echo "")
    
    if [ -n "$current_version" ] && [ "$current_version" = "$latest_version" ]; then
        log_success "fastfetch already at latest version ($current_version)"
        track_skip
        return 0
    fi
    
    if [ -z "$latest_version" ]; then
        log_warning "Could not determine latest fastfetch version, skipping..."
        track_failure
        return 1
    fi
    
    log_info "Building fastfetch v${latest_version} from source..."
    
    # Install minimal build dependencies
    log_substep "Installing build dependencies..."
    if ! sudo apt install -y git cmake build-essential 2>/dev/null; then
        log_warning "Could not install build dependencies, skipping fastfetch"
        track_failure
        return 1
    fi
    
    # Clone and build
    cd /tmp
    rm -rf fastfetch 2>/dev/null
    
    if ! git clone --depth 1 --branch "${latest_version}" https://github.com/fastfetch-cli/fastfetch.git 2>/dev/null; then
        log_warning "Could not clone fastfetch repository, continuing..."
        track_failure
        return 1
    fi
    
    cd fastfetch
    
    if ! cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/usr/local" 2>/dev/null; then
        log_warning "fastfetch CMake configuration failed, continuing..."
        cd ~ && rm -rf /tmp/fastfetch
        track_failure
        return 1
    fi
    
    if ! cmake --build build --target fastfetch -j$(nproc) 2>/dev/null; then
        log_warning "fastfetch build failed, continuing..."
        cd ~ && rm -rf /tmp/fastfetch
        track_failure
        return 1
    fi
    
    if ! sudo cp build/fastfetch /usr/local/bin/fastfetch 2>/dev/null; then
        log_warning "fastfetch installation failed, continuing..."
        cd ~ && rm -rf /tmp/fastfetch
        track_failure
        return 1
    fi
    
    sudo chmod 755 /usr/local/bin/fastfetch
    cd ~ && rm -rf /tmp/fastfetch
    
    log_success "fastfetch v${latest_version} installed successfully"
    track_success
}

# ============================================================================
# STARSHIP (Cross-shell prompt)
# ============================================================================
install_starship() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "starship (Shell prompt)" "$COMPUTER"
    fi
    
    if command -v starship &> /dev/null; then
        local current_version=$(starship --version 2>/dev/null | head -n1)
        log_success "starship already installed: $current_version"
        track_skip
    else
        log_info "Installing starship..."
        if curl -sS https://starship.rs/install.sh 2>/dev/null | sh -s -- --yes > /dev/null 2>&1; then
            log_success "starship installed successfully"
            track_success
        else
            log_warning "starship installation failed, continuing..."
            track_failure
        fi
    fi
}

# ============================================================================
# NERD FONT
# ============================================================================
install_nerd_font() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "FiraCode Nerd Font" "$COMPUTER"
    fi
    
    local FONT_DIR="$HOME/.local/share/fonts"
    local FONT_NAME="FiraCodeNerdFont-Regular.ttf"
    
    if [ -f "$FONT_DIR/$FONT_NAME" ]; then
        log_success "FiraCode Nerd Font already installed"
        track_skip
        return 0
    fi
    
    log_info "Installing FiraCode Nerd Font..."
    
    mkdir -p "$FONT_DIR"
    
    local DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    local TEMP_ZIP="/tmp/FiraCode.zip"
    
    if ! wget -q "$DOWNLOAD_URL" -O "$TEMP_ZIP" 2>/dev/null; then
        log_warning "Could not download font, continuing..."
        track_failure
        return 1
    fi
    
    if ! unzip -q -o "$TEMP_ZIP" -d "$FONT_DIR" 2>/dev/null; then
        log_warning "Could not extract font, continuing..."
        rm -f "$TEMP_ZIP"
        track_failure
        return 1
    fi
    
    rm -f "$TEMP_ZIP"
    
    # Refresh font cache
    if command -v fc-cache &> /dev/null; then
        fc-cache -f "$FONT_DIR" 2>/dev/null
    fi
    
    log_success "FiraCode Nerd Font installed"
    log_info "Configure your terminal to use 'FiraCode Nerd Font'"
    track_success
}

# ============================================================================
# EMOJI FONT SUPPORT
# ============================================================================
install_emoji_fonts() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Emoji Font Support" "$COMPUTER"
    fi
    
    if dpkg -l 2>/dev/null | grep -q "^ii.*fonts-noto-color-emoji"; then
        log_success "Emoji fonts already installed"
        track_skip
    else
        log_info "Installing emoji fonts..."
        if sudo apt install -y fonts-noto-color-emoji 2>/dev/null; then

            if command -v fc-cache &> /dev/null; then
                fc-cache -fv > /dev/null 2>&1
            fi
            log_success "Emoji fonts installed"
            track_success
        else
            log_warning "Emoji font installation failed, continuing..."
            track_failure
        fi
    fi
}

# ============================================================================
# TMUX (Terminal multiplexer)
# ============================================================================
install_tmux() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "tmux (Terminal multiplexer)" "$COMPUTER"
    fi
    
    local tmux_installed=false
    local config_verified=false
    
    # Check/install tmux binary
    if command -v tmux &> /dev/null; then
        TMUX_VERSION=$(tmux -V)
        log_success "tmux already installed: $TMUX_VERSION"
        tmux_installed=true
        track_skip
    else
        log_info "Installing tmux..."
        if sudo apt install -y tmux 2>/dev/null; then
            TMUX_VERSION=$(tmux -V)
            log_success "tmux installed: $TMUX_VERSION"
            tmux_installed=true
            track_success
        else
            log_warning "tmux installation failed, skipping configuration"
            track_failure
            return 1
        fi
    fi
    
    # Verify configuration is properly symlinked
    if [ "$tmux_installed" = true ]; then
        local TMUX_CONF="$HOME/.tmux.conf"
        local TMUX_CONF_SOURCE="$DOTFILES_DIR/config/tmux.conf"
        
        if [[ -L "$TMUX_CONF" ]]; then
            local LINK_TARGET=$(readlink -f "$TMUX_CONF" 2>/dev/null)
            local EXPECTED_TARGET=$(readlink -f "$TMUX_CONF_SOURCE" 2>/dev/null)
            
            if [[ "$LINK_TARGET" == "$EXPECTED_TARGET" ]]; then
                log_substep "Configuration already linked"
                config_verified=true
            else
                log_substep "Fixing configuration symlink..."
                rm "$TMUX_CONF"
                ln -sf "$TMUX_CONF_SOURCE" "$TMUX_CONF"
                log_substep "Configuration symlink corrected"
                config_verified=true
            fi
        elif [[ -f "$TMUX_CONF" ]]; then
            log_substep "Backing up existing config and creating symlink..."
            local BACKUP_FILE="${TMUX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$TMUX_CONF" "$BACKUP_FILE"
            ln -sf "$TMUX_CONF_SOURCE" "$TMUX_CONF"
            log_substep "Configuration symlinked (backup: $(basename $BACKUP_FILE))"
            config_verified=true
        elif [[ -f "$TMUX_CONF_SOURCE" ]]; then
            log_substep "Creating configuration symlink..."
            ln -sf "$TMUX_CONF_SOURCE" "$TMUX_CONF"
            log_substep "Configuration symlinked"
            config_verified=true
        else
            log_warning "Configuration source not found at $TMUX_CONF_SOURCE"
        fi
        
        # Test configuration syntax if successfully linked
        if [ "$config_verified" = true ] && [[ -f "$TMUX_CONF" ]]; then
            if tmux -f "$TMUX_CONF" new-session -d -s tmux-config-test 'exit' 2>/dev/null; then
                tmux kill-session -t tmux-config-test 2>/dev/null || true
                log_substep "Configuration syntax validated"
            fi
        fi
    fi
}

# ============================================================================
# CONFIGURATION SYMLINKS
# ============================================================================
setup_config_symlinks() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Terminal Configuration" "$WRENCH"
    fi
    
    # Define configuration files managed by this script
    # These are for tools installed by terminal.sh
    declare -A TERMINAL_CONFIGS=(
        ["$DOTFILES_DIR/config/.zshrc"]="$HOME/.zshrc"
        ["$DOTFILES_DIR/config/.zprofile"]="$HOME/.zprofile"
        ["$DOTFILES_DIR/config/functions.zsh"]="$HOME/.zsh_functions"
        ["$DOTFILES_DIR/config/starship.toml"]="$HOME/.config/starship.toml"
        ["$DOTFILES_DIR/config/fastfetch.jsonc"]="$HOME/.config/fastfetch/config.jsonc"
    )
    
    local created=0
    local skipped=0
    
    for source in "${!TERMINAL_CONFIGS[@]}"; do
        target="${TERMINAL_CONFIGS[$source]}"
        
        # Create parent directory if needed
        target_dir=$(dirname "$target")
        if [[ ! -d "$target_dir" ]]; then
            mkdir -p "$target_dir"
        fi
        
        # Check if target already exists and points to correct location
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            log_substep "$(basename "$target") - already linked"
            skipped=$((skipped + 1))
        else
            # Backup existing file if present
            if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
                local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
                mv "$target" "$backup"
                log_substep "$(basename "$target") - backed up existing file"
            fi
            
            # Create/update symlink
            ln -sf "$source" "$target"
            log_substep "$(basename "$target") - linked"
            created=$((created + 1))
        fi
    done
    
    if [ $created -gt 0 ]; then
        log_success "Linked $created configuration file(s)"
    fi
    if [ $skipped -gt 0 ] && [[ "$QUIET_MODE" != "true" ]]; then
        log_info "Skipped $skipped existing symlink(s)"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
main() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Terminal Utilities Installation" "$ROCKET"
    fi
    
    # Check if apt is available
    if ! command -v apt &> /dev/null; then
        log_warning "apt not found - skipping all apt-based installations"
        return 0
    fi
    
    # Run all installations
    install_zsh
    install_fzf
    install_zoxide
    install_fd
    install_direnv
    install_eza
    install_fastfetch
    install_starship
    install_nerd_font
    install_emoji_fonts
    install_tmux
    
    # Setup configuration symlinks for all installed tools
    setup_config_symlinks
    
    # Print summary only in verbose mode
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_plain ""
        log_section "Installation Summary" "$PARTY"
        log_success "Success: ${INSTALLS_SUCCESS}"
        log_warning "Skipped: ${INSTALLS_SKIPPED}"
        if [ $INSTALLS_FAILED -gt 0 ]; then
            log_error "Failed:  ${INSTALLS_FAILED}"
        fi
        log_plain ""
        
        if [ $INSTALLS_FAILED -gt 0 ]; then
            log_warning "Some installations failed but the system is functional"
            log_info "Re-run install.sh to retry failed installations"
        else
            log_success "All terminal utilities installed successfully!"
        fi
    elif [ $INSTALLS_FAILED -gt 0 ]; then
        # In quiet mode, only show failures
        log_warning "${INSTALLS_FAILED} terminal utilities failed to install"
    fi
}

# Run main function if sourced or executed
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
else
    # If sourced, still run main but don't exit
    main
fi
