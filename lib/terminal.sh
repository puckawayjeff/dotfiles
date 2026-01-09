#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
else
    echo "Error: utils.sh not found"
    return 1 2>/dev/null || exit 1
fi

if [ -f "$SCRIPT_DIR/os.sh" ]; then
    source "$SCRIPT_DIR/os.sh"
else
    echo "Error: os.sh not found"
    return 1 2>/dev/null || exit 1
fi

INSTALLS_SUCCESS=0
INSTALLS_FAILED=0
INSTALLS_SKIPPED=0

track_success() { INSTALLS_SUCCESS=$((INSTALLS_SUCCESS + 1)); }
track_failure() { INSTALLS_FAILED=$((INSTALLS_FAILED + 1)); }
track_skip() { INSTALLS_SKIPPED=$((INSTALLS_SKIPPED + 1)); }

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
        if pkg_install zsh; then
            log_success "Zsh installed successfully"
            track_success
            
            if [[ "$(basename "$SHELL")" != "zsh" ]]; then
                log_info "Changing default shell to zsh..."
                ZSH_PATH=$(which zsh)
                
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

install_fzf() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "FZF (Fuzzy Finder)" "$COMPUTER"
    fi
    
    if command -v fzf &> /dev/null; then
        log_success "FZF already installed"
        track_skip
    else
        log_info "Installing fzf..."
        if pkg_install fzf; then
            log_success "FZF installed via package manager"
            track_success
        else
            log_info "Building FZF from source..."
            if git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all; then
                log_success "FZF installed from source"
                track_success
            else
                log_warning "FZF installation failed"
                track_failure
            fi
        fi
    fi
}

install_zoxide() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Zoxide (Smart cd)" "$COMPUTER"
    fi
    
    if command -v zoxide &> /dev/null; then
        log_success "Zoxide already installed"
        track_skip
    else
        log_info "Installing zoxide..."
        if pkg_install zoxide; then
            log_success "Zoxide installed via package manager"
            track_success
        elif curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh 2>/dev/null | bash; then
            log_success "Zoxide installed via curl"
            track_success
        else
            log_warning "Zoxide installation failed"
            track_failure
        fi
    fi
}

install_fd() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "fd (Fast find)" "$COMPUTER"
    fi
    
    if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
        log_success "fd already installed"
        track_skip
    else
        log_info "Installing fd..."
        local pkg_name="fd"
        [ "$PKG_MANAGER" = "apt" ] && pkg_name="fd-find"
        
        if pkg_install "$pkg_name"; then
            if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
                mkdir -p ~/.local/bin
                ln -sf $(which fdfind) ~/.local/bin/fd 2>/dev/null
            fi
            log_success "fd installed successfully"
            track_success
        else
            log_info "Installing fd from release (npm fallback)..."
             if command -v npm &> /dev/null; then
                 npm install -g fd-find
                 track_success
             else
                 log_warning "fd installation failed"
                 track_failure
             fi
        fi
    fi
}

install_direnv() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "direnv" "$COMPUTER"
    fi
    
    if command -v direnv &> /dev/null; then
        log_success "direnv already installed"
        track_skip
    else
        log_info "Installing direnv..."
        if pkg_install direnv; then
            log_success "direnv installed"
            track_success
        elif curl -sfL https://direnv.net/install.sh | bash; then
            log_success "direnv installed via script"
            track_success
        else
            log_warning "direnv installation failed"
            track_failure
        fi
    fi
}

install_ripgrep() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "ripgrep" "$COMPUTER"
    fi
    
    if command -v rg &> /dev/null; then
        RG_VERSION=$(rg --version | head -n1)
        log_success "ripgrep already installed: $RG_VERSION"
        track_skip
    else
        log_info "Installing ripgrep..."
        if pkg_install ripgrep; then
            log_success "ripgrep installed"
            track_success
        elif curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_linux_amd64.tar.gz && \
             tar xzvf ripgrep_13.0.0_linux_amd64.tar.gz && \
             sudo cp ripgrep_13.0.0_linux_amd64/rg /usr/local/bin/; then
             rm -rf ripgrep_13.0.0_linux_amd64*
             log_success "ripgrep installed from release"
             track_success
        else
            log_warning "ripgrep installation failed"
            track_failure
        fi
    fi
}

install_eza() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "eza" "$COMPUTER"
    fi
    
    if command -v eza &> /dev/null; then
        log_success "eza already installed"
        track_skip
        return 0
    fi
    
    log_info "Installing eza..."
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        if [ ! -f /etc/apt/sources.list.d/gierens.list ]; then
            sudo mkdir -p /etc/apt/keyrings 2>/dev/null
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
            sudo chmod 644 /etc/apt/sources.list.d/gierens.list
            pkg_update
        fi
    fi
    
    if pkg_install eza; then
        log_success "eza installed via package manager"
        track_success
    else
        log_info "Installing eza from release..."
        EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
        if wget -qO- "$EZA_URL" | tar xz -C /tmp; then
            sudo mv /tmp/eza /usr/local/bin/eza
            sudo chmod +x /usr/local/bin/eza
            log_success "eza installed from release"
            track_success
        else
            log_warning "eza installation failed"
            track_failure
        fi
    fi
}

install_fastfetch() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "fastfetch" "$COMPUTER"
    fi
    
    if command -v fastfetch &> /dev/null; then
        log_success "fastfetch already installed"
        track_skip
        return 0
    fi
    
    log_info "Installing fastfetch..."
    
    if pkg_install fastfetch; then
        log_success "fastfetch installed via package manager"
        track_success
        return 0
    fi
    
    local latest_version=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest 2>/dev/null | grep -oP '"tag_name": "\K[^"]+' | sed 's/^v//' || echo "")
    [ -z "$latest_version" ] && latest_version="2.11.0"
    
    log_info "Building fastfetch v${latest_version} from source..."
    pkg_install git cmake build-essential
    
    cd /tmp
    rm -rf fastfetch 2>/dev/null
    
    if git clone --depth 1 --branch "${latest_version}" https://github.com/fastfetch-cli/fastfetch.git 2>/dev/null; then
        cd fastfetch
        mkdir -p build
        cd build
        cmake .. && make -j$(nproc)
        if [ -f fastfetch ]; then
            sudo cp fastfetch /usr/local/bin/
            log_success "fastfetch installed from source"
            track_success
        else
            log_warning "fastfetch build failed"
            track_failure
        fi
        cd ~
        rm -rf /tmp/fastfetch
    else
        log_warning "fastfetch clone failed"
        track_failure
    fi
}

install_starship() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "starship" "$COMPUTER"
    fi
    
    if command -v starship &> /dev/null; then
        log_success "starship already installed"
        track_skip
    else
        log_info "Installing starship..."
        if curl -sS https://starship.rs/install.sh 2>/dev/null | sh -s -- --yes > /dev/null 2>&1; then
            log_success "starship installed successfully"
            track_success
        else
            log_warning "starship installation failed"
            track_failure
        fi
    fi
}

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
    
    if wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -O /tmp/FiraCode.zip; then
        unzip -q -o /tmp/FiraCode.zip -d "$FONT_DIR"
        rm -f /tmp/FiraCode.zip
        if command -v fc-cache &> /dev/null; then
            fc-cache -f "$FONT_DIR" 2>/dev/null
        fi
        log_success "FiraCode Nerd Font installed"
        track_success
    else
        log_warning "Font download failed"
        track_failure
    fi
}

install_emoji_fonts() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Emoji Font Support" "$COMPUTER"
    fi
    
    if pkg_install fonts-noto-color-emoji; then
        log_success "Emoji fonts installed"
        track_success
    else
        log_warning "Emoji font installation failed (package not found?)"
        track_skip
    fi
}

install_tmux() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "tmux" "$COMPUTER"
    fi
    
    if command -v tmux &> /dev/null; then
        log_success "tmux already installed"
        track_skip
    else
        log_info "Installing tmux..."
        if pkg_install tmux; then
            log_success "tmux installed"
            track_success
        else
            log_warning "tmux installation failed"
            track_failure
        fi
    fi
}

install_micro() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "micro" "$COMPUTER"
    fi
    
    if command -v micro &> /dev/null; then
        log_success "micro already installed"
        track_skip
    else
        log_info "Installing micro..."
        if curl https://getmic.ro | bash; then
            sudo mv micro /usr/local/bin/
            log_success "micro installed via script"
            track_success
        elif pkg_install micro; then
            log_success "micro installed via package manager"
            track_success
        else
            log_warning "micro installation failed"
            track_failure
        fi
    fi
}

main() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_section "Terminal Utilities Installation" "$ROCKET"
    fi
    
    pkg_update
    
    install_zsh
    install_fzf
    install_zoxide
    install_fd
    install_direnv
    install_ripgrep
    install_eza
    install_fastfetch
    install_starship
    install_nerd_font
    install_emoji_fonts
    install_tmux
    install_micro
    
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_plain ""
        log_section "Installation Summary" "$PARTY"
        log_success "Success: ${INSTALLS_SUCCESS}"
        log_warning "Skipped: ${INSTALLS_SKIPPED}"
        if [ $INSTALLS_FAILED -gt 0 ]; then
            log_error "Failed:  ${INSTALLS_FAILED}"
        fi
    fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
else
    main
fi
