# ~/.zshrc - Zsh configuration with Zinit plugin manager
# Optimized for speed and power-user features

# ===== Early Setup =====
# Skip all this for non-interactive shells
[[ $- != *i* ]] && return

# ===== History Configuration =====
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY          # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming
setopt HIST_IGNORE_DUPS          # Don't record duplicate entries
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_VERIFY               # Don't execute immediately upon history expansion
setopt SHARE_HISTORY             # Share history between all sessions

# ===== Directory Navigation =====
setopt AUTO_CD                   # Type directory name to cd
setopt AUTO_PUSHD                # Push directories onto stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicates
setopt PUSHD_SILENT              # Don't print directory stack

# ===== Completion System =====
setopt COMPLETE_IN_WORD          # Complete from cursor position
setopt ALWAYS_TO_END             # Move cursor to end after completion
setopt AUTO_MENU                 # Show completion menu on tab
setopt AUTO_LIST                 # List choices on ambiguous completion

# ===== Zinit Installation and Setup =====
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Install zinit if not present
if [[ ! -d "$ZINIT_HOME" ]]; then
    print -P "%F{33}▓▒░ Installing Zinit plugin manager...%f"
    command mkdir -p "$(dirname $ZINIT_HOME)"
    command git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" && \
        print -P "%F{34}▓▒░ Installation successful.%f" || \
        print -P "%F{160}▓▒░ Installation failed.%f"
fi

# Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# ===== Zinit Plugins =====

# 1. zsh-completions - Additional completion definitions (load early)
zinit ice wait lucid blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

# 2. zsh-autosuggestions - Fish-like autosuggestions
zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
# Bind Ctrl+Space to accept autosuggestion
bindkey '^@' autosuggest-accept

# 3. zsh-history-substring-search - MUST load before syntax-highlighting
zinit ice wait lucid atload'
    bindkey "^[[A" history-substring-search-up
    bindkey "^[[B" history-substring-search-down
    bindkey -M emacs "^P" history-substring-search-up
    bindkey -M emacs "^N" history-substring-search-down
'
zinit light zsh-users/zsh-history-substring-search

# 4. Fast-syntax-highlighting - MUST load after history-substring-search
zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# Initialize completion system
autoload -Uz compinit
# Only regenerate .zcompdump once a day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# ===== Completion Styling =====
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # Case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"  # Colored completion
zstyle ':completion:*' menu select                       # Menu-driven completion
zstyle ':completion:*' group-name ''                     # Group completions
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# ===== Color Support =====
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ===== Aliases =====
# Standard aliases
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias bat='batcat --color=auto'

# ls/eza aliases (conditional on eza installation)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza --icons -lag --group-directories-first --git'
    alias la='eza --icons -a --group-directories-first'
    alias l='eza --icons -1 --group-directories-first'
    alias lt='eza --icons --tree --level=2 --group-directories-first'
else
    alias ll='ls -alh'
    alias la='ls -A'
    alias l='ls -CF'
fi

# Load additional aliases if present
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# ===== Fastfetch Integration =====
if command -v fastfetch >/dev/null 2>&1; then
    # Compatibility aliases
    alias neofetch="fastfetch -c neofetch"
    alias screenfetch="fastfetch -c screenfetch"
    # Launch fastfetch on terminal start
    fastfetch
fi

# ===== Tool Integrations =====

# User Binaries
if [[ -d "$HOME/bin" ]]; then
    export PATH="$HOME/bin:$PATH"
fi

if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Deno
if [[ -d "$HOME/.deno" ]]; then
    export DENO_INSTALL="$HOME/.deno"
    export PATH="$DENO_INSTALL/bin:$PATH"
fi

# .NET
if [[ -d "$HOME/.dotnet" ]]; then
    export DOTNET_ROOT="$HOME/.dotnet"
    export PATH="$PATH:$DOTNET_ROOT"
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# FZF (Fuzzy Finder)
if command -v fzf >/dev/null 2>&1; then
    # Set up fzf key bindings and fuzzy completion
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    fi
    if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
        source /usr/share/doc/fzf/examples/completion.zsh
    fi
    
    # FZF configuration
    export FZF_DEFAULT_OPTS='
        --height 40% 
        --layout=reverse 
        --border 
        --inline-info
        --color=fg:#d8d8d8,bg:#181818,hl:#bd93f9
        --color=fg+:#f8f8f2,bg+:#282828,hl+:#ff79c6
        --color=info:#8be9fd,prompt:#50fa7b,pointer:#ff79c6
        --color=marker:#50fa7b,spinner:#8be9fd,header:#6272a4'
    
    # Use fd if available for faster file finding
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# Zoxide (smart cd - use 'z' command)
# Rename to avoid 'zi' alias conflict with Zinit
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd j zsh)"
fi

# Direnv (auto-load directory environments)
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ===== Custom Functions =====
# Load functions from separate file
if [[ -f ~/.zsh_functions ]]; then
    source ~/.zsh_functions
fi

# ===== Performance Optimization =====
# Compile zcompdump for faster startup
{
    zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
    if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
        zcompile "$zcompdump"
    fi
} &!

# ===== End of Configuration =====
