# config/zsh/completion.zsh

autoload -Uz compinit
# Only regenerate .zcompdump once a day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

autoload -U colors && colors

# ===== Styling =====
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' verbose yes
zstyle -d ':completion:*' format
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format '%F{magenta}-- %d --%f'
zstyle ':completion:*:warnings' format '%B%F{red}[ no matches found ]%f%b'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# ===== FZF-Tab =====
zstyle ':fzf-tab:*' show-group full
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:*' fzf-preview 'if [[ -f $realpath ]]; then bat --color=always --line-range :50 $realpath 2>/dev/null || cat $realpath 2>/dev/null; elif [[ -d $realpath ]]; then eza --tree --level=1 --color=always $realpath 2>/dev/null || ls -la $realpath; fi'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=1 --color=always $realpath 2>/dev/null || ls -la $realpath'

zstyle ':fzf-tab:complete:ssh:*' disabled-on any
zstyle ':fzf-tab:complete:scp:*' disabled-on any
zstyle ':fzf-tab:complete:sftp:*' disabled-on any

# ===== SSH Completion =====
zstyle ':completion:*:ssh:*' hosts off
zstyle ':completion:*:ssh:*' users off

function _ssh_hosts() {
    local -a ssh_hosts
    if [[ -f ~/.ssh/config ]]; then
        ssh_hosts+=(${${${${${(@M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#*[*?]*}:#*/*}:#github.com})
    fi
    _describe 'ssh hosts' ssh_hosts
}

compdef _ssh_hosts ssh
compdef _ssh_hosts scp
compdef _ssh_hosts sftp
