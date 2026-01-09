# config/zsh/aliases.zsh

# ===== Standard Aliases =====
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias bat='batcat --color=auto'

# ===== ls/eza Aliases =====
if command -v eza >/dev/null 2>&1; then
    export EZA_CONFIG_DIR="$HOME/.config/eza"
    
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

# ===== Python =====
alias link-pyenv='link_py_environment'
alias unlink-pyenv='unlink_py_environment'

# ===== Fastfetch =====
if command -v fastfetch >/dev/null 2>&1; then
    alias neofetch="fastfetch -c neofetch"
    alias screenfetch="fastfetch -c screenfetch"
    alias ff="fastfetch"
fi
