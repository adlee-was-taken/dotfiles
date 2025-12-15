# ============================================================================
# ADLee's ZSH Configuration
# ============================================================================

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ============================================================================
# Theme Configuration
# ============================================================================

ZSH_THEME="adlee"

# ============================================================================
# Oh-My-Zsh Settings
# ============================================================================

# Update behavior
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 13

# Display red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

# History timestamp format
HIST_STAMPS="yyyy-mm-dd"

# ============================================================================
# Plugins
# ============================================================================

plugins=(
    git
    docker
    docker-compose
    kubectl
    sudo
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Note: Install additional plugins with:
# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# ============================================================================
# Load Oh-My-Zsh
# ============================================================================

source $ZSH/oh-my-zsh.sh

# ============================================================================
# User Configuration
# ============================================================================

# --- Environment Variables ---

export EDITOR='vim'
export VISUAL='vim'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="$HOME/.local/bin:$PATH"

# --- Aliases ---

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# List files
if command -v eza &> /dev/null; then
    alias ls='eza --icons'
    alias ll='eza -lah --icons'
    alias la='eza -a --icons'
    alias lt='eza --tree --level=2 --icons'
else
    alias ll='ls -lah'
    alias la='ls -A'
fi

# Cat with syntax highlighting
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never'
    alias bat='batcat'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
fi

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate --all'

# Docker shortcuts
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'

# System shortcuts
alias reload='source ~/.zshrc'
alias zshconfig='vim ~/.zshrc'
alias themeconfig='vim ~/.oh-my-zsh/themes/adlee.zsh-theme'
alias h='history'
alias c='clear'

# Safe operations
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Network
alias myip='curl ifconfig.me'
alias ports='netstat -tulanp'

# --- Functions ---

# Juuuust puuush it.
push-it() {
    git add .
    git commit -m "$1"
    git push origin
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick find file
ff() {
    find . -type f -iname "*$1*"
}

# Quick find directory (renamed to avoid conflict with fd tool)
fdir() {
    find . -type d -iname "*$1*"
}

# Quick backup
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# --- FZF Configuration ---

if command -v fzf &> /dev/null; then
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    bindkey '^R' fzf-history-widget
fi

# --- History Configuration ---

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE

# --- Key Bindings ---

bindkey "^[[1;5C" forward-word      # Ctrl+Right
bindkey "^[[1;5D" backward-word     # Ctrl+Left
bindkey "^[[H" beginning-of-line    # Home
bindkey "^[[F" end-of-line          # End
bindkey "^[[3~" delete-char         # Delete

# --- Custom Widgets ---

# Alt+R to reload zsh config
reload-zsh() {
    source ~/.zshrc
    echo "✓ zsh configuration reloaded"
    zle reset-prompt
}
zle -N reload-zsh
bindkey "^[r" reload-zsh

# Alt+G to show git status
git-status-widget() {
    echo
    git status
    zle reset-prompt
}
zle -N git-status-widget
bindkey "^[g" git-status-widget

# ============================================================================
# Lazy-loaded Tools (for faster shell startup)
# ============================================================================

# --- NVM (lazy load) ---
# Only loads when you first use node, npm, nvm, or npx
export NVM_DIR="$HOME/.nvm"

_load_nvm() {
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Create lazy-load wrappers
if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm() {
        unfunction nvm node npm npx 2>/dev/null
        _load_nvm
        nvm "$@"
    }
    node() {
        unfunction nvm node npm npx 2>/dev/null
        _load_nvm
        node "$@"
    }
    npm() {
        unfunction nvm node npm npx 2>/dev/null
        _load_nvm
        npm "$@"
    }
    npx() {
        unfunction nvm node npm npx 2>/dev/null
        _load_nvm
        npx "$@"
    }
fi

# --- Python virtualenvwrapper (lazy load) ---
export WORKON_HOME=$HOME/.virtualenvs

_load_virtualenvwrapper() {
    export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
    [ -f /usr/local/bin/virtualenvwrapper.sh ] && source /usr/local/bin/virtualenvwrapper.sh
}

if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    workon() {
        unfunction workon mkvirtualenv rmvirtualenv 2>/dev/null
        _load_virtualenvwrapper
        workon "$@"
    }
    mkvirtualenv() {
        unfunction workon mkvirtualenv rmvirtualenv 2>/dev/null
        _load_virtualenvwrapper
        mkvirtualenv "$@"
    }
fi

# --- Rust cargo (only if exists) ---
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# --- OS-Specific Configuration ---

case "$(uname -s)" in
    Darwin*)
        export HOMEBREW_NO_ANALYTICS=1
        ;;
esac

# --- Snapper Functions ---

if [[ -f "$HOME/.dotfiles/zsh/functions/snapper.zsh" ]]; then
    source "$HOME/.dotfiles/zsh/functions/snapper.zsh"
fi

# --- Local Configuration ---

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# ============================================================================
# End of Configuration
# ============================================================================
