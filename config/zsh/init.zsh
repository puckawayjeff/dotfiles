# config/zsh/init.zsh
# Zinit Plugin Manager Configuration

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Install zinit if not present
if [[ ! -d "$ZINIT_HOME" ]]; then
    if [[ -f "$HOME/dotfiles/lib/utils.sh" ]]; then
        source "$HOME/dotfiles/lib/utils.sh"
        log_action "Installing Zinit plugin manager..." "$PACKAGE"
    else
        print -P "%F{33}Installing Zinit plugin manager...%f"
    fi
    
    command mkdir -p "$(dirname $ZINIT_HOME)"
    if command git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" 2>/dev/null; then
        [[ -n "$log_success" ]] && log_success "Zinit installed successfully" || print -P "%F{34}Installation successful.%f"
    else
        [[ -n "$log_error" ]] && log_error "Zinit installation failed" || print -P "%F{160}Installation failed.%f"
    fi
fi

source "${ZINIT_HOME}/zinit.zsh"

# ===== Plugins =====

# Completion & History
zinit ice wait lucid blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey '^@' autosuggest-accept

zinit ice wait lucid
zinit light zdharma-continuum/history-search-multi-word

zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# Syntax Highlighting (Must be last)
zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# OMZ Snippets
zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit snippet OMZ::plugins/docker/docker.plugin.zsh
zinit snippet OMZ::plugins/extract/extract.plugin.zsh
zinit snippet OMZ::plugins/command-not-found/command-not-found.plugin.zsh

command_not_found_handler() {
    local red='\e[1;31m'
    local yellow='\e[1;33m'
    local green='\e[1;32m'
    local cyan='\e[1;36m'
    local bold='\e[0;1m'
    local reset='\e[0m'
    
    printf "${red}zsh: command not found:${reset} ${bold}%s${reset}\n" "$1" >&2
    
    local found_suggestions=false
    if [[ -x /usr/lib/command-not-found ]]; then
        local suggestions=$(/usr/lib/command-not-found -- "$1" 2>&1)
        if [[ -n "$suggestions" ]]; then
            echo "$suggestions" >&2
            found_suggestions=true
        fi
    elif [[ -x /usr/share/command-not-found/command-not-found ]]; then
        local suggestions=$(/usr/share/command-not-found/command-not-found -- "$1" 2>&1)
        if [[ -n "$suggestions" ]]; then
            echo "$suggestions" >&2
            found_suggestions=true
        fi
    fi
    
    printf "\n${cyan}💡 Tip:${reset} Type ${yellow}${bold}dothelp${reset} to see all available commands\n" >&2
    return 127
}

zinit snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh
zinit snippet OMZ::plugins/copypath/copypath.plugin.zsh
zinit snippet OMZ::plugins/copyfile/copyfile.plugin.zsh

zinit ice wait lucid
zinit light paulirish/git-open

zinit ice wait lucid
zinit light Freed-Wu/zsh-help

zinit ice wait lucid
zinit light elvitin/printdocker-zsh-plugin

zinit ice wait lucid
zinit light se-jaeger/zsh-activate-py-environment

zinit ice wait lucid
zinit light MichaelAquilina/zsh-you-should-use
