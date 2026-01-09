# config/zsh/exports.zsh

# ===== History Configuration =====
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000

# ===== Default Editor =====
export EDITOR='micro'
export VISUAL='micro'
export PAGER='less'

# ===== Color Support =====
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ===== PATH Configuration =====
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

# NVM
export NVM_DIR="$HOME/.nvm"

# Bun
export BUN_INSTALL="$HOME/.bun"
if [[ -d "$BUN_INSTALL" ]]; then
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Opencode
if [[ -d "/home/jeff/.opencode/bin" ]]; then
    export PATH=/home/jeff/.opencode/bin:$PATH
fi
