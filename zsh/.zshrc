# ============================================================================
# ADLee's ZSH Configuration (Optimized)
# ============================================================================
# Optimizations:
#   - Deferred/lazy loading for heavy plugins
#   - Parallel background loading where possible
#   - Compiled zsh files (.zwc) for faster parsing
#   - Minimal command -v checks (cached)
# ============================================================================

# --- Profiling (uncomment to debug slow startup) ---
# zmodload zsh/zprof

# ============================================================================
# Instant Prompt (show prompt immediately while loading continues)
# ============================================================================

# Cache command existence checks
typeset -gA _cmd_cache
_has_cmd() {
    if [[ -z "${_cmd_cache[$1]+x}" ]]; then
        _cmd_cache[$1]=$(command -v "$1" &>/dev/null && echo 1 || echo 0)
    fi
    [[ "${_cmd_cache[$1]}" == "1" ]]
}

# ============================================================================
# Core Settings (fast, no external calls)
# ============================================================================

export ZSH="$HOME/.oh-my-zsh"
export EDITOR='vim'
export VISUAL='vim'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="$HOME/.local/bin:$PATH"

# History (set early)
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY APPEND_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_IGNORE_SPACE

# ============================================================================
# Theme Configuration
# ============================================================================

ZSH_THEME="adlee"

# ============================================================================
# Oh-My-Zsh Settings (before sourcing)
# ============================================================================

zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 13
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

# Disable oh-my-zsh auto-update check on every load (slow)
DISABLE_AUTO_UPDATE="true"

# ============================================================================
# Plugins - Optimized Selection
# ============================================================================
# Removed heavy plugins that aren't always needed
# kubectl, docker-compose loaded on-demand

plugins=(
    git
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Conditionally add plugins only if tools exist
[[ -d "$HOME/.fzf" || -f "/usr/share/fzf/key-bindings.zsh" ]] && plugins+=(fzf)

# ============================================================================
# Load Oh-My-Zsh
# ============================================================================

source $ZSH/oh-my-zsh.sh

# ============================================================================
# Aliases (inline - no external checks during definition)
# ============================================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

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

# System
alias h='history'
alias c='clear'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias myip='curl -s ifconfig.me'
alias ports='netstat -tulanp'

# ============================================================================
# Deferred Alias Setup (runs after prompt displays)
# ============================================================================

_setup_tool_aliases() {
    # eza/ls aliases
    if _has_cmd eza; then
        alias ls='eza --icons'
        alias ll='eza -lah --icons'
        alias la='eza -a --icons'
        alias lt='eza --tree --level=2 --icons'
    else
        alias ll='ls -lah'
        alias la='ls -A'
    fi

    # bat/cat aliases
    if _has_cmd batcat; then
        alias cat='batcat --paging=never'
        alias bat='batcat'
    elif _has_cmd bat; then
        alias cat='bat --paging=never'
    fi
}

# ============================================================================
# Functions
# ============================================================================

push-it() { git add . && git commit -m "$1" && git push origin; }
mkcd() { mkdir -p "$1" && cd "$1"; }
ff() { find . -type f -iname "*$1*"; }
fdir() { find . -type d -iname "*$1*"; }
backup() { cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"; }

extract() {
    [[ ! -f "$1" ]] && { echo "'$1' is not a valid file"; return 1; }
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.rar)     unrar x "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.tar)     tar xf "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.zip)     unzip "$1" ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x "$1" ;;
        *)         echo "'$1' cannot be extracted via extract()" ;;
    esac
}

# ============================================================================
# Key Bindings!
# ============================================================================

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char

# Alt+R to reload
function reload-zsh() { echo "Reloading ~/.zshrc ... "; source ~/.zshrc; zle reset-prompt}
zle -N reload-zsh
bindkey "^[r" reload-zsh

# ============================================================================
# FZF Configuration (deferred)
# ============================================================================

_setup_fzf() {
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    if _has_cmd fd; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
}

# ============================================================================
# Lazy-loaded Tools
# ============================================================================

# NVM
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _load_nvm() {
        unfunction nvm node npm npx 2>/dev/null
        \. "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
    }
    nvm()  { _load_nvm; nvm "$@"; }
    node() { _load_nvm; node "$@"; }
    npm()  { _load_nvm; npm "$@"; }
    npx()  { _load_nvm; npx "$@"; }
fi

# Python virtualenvwrapper
export WORKON_HOME=$HOME/.virtualenvs
if [[ -f /usr/local/bin/virtualenvwrapper.sh ]]; then
    _load_venv() {
        unfunction workon mkvirtualenv rmvirtualenv 2>/dev/null
        export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
        source /usr/local/bin/virtualenvwrapper.sh
    }
    workon() { _load_venv; workon "$@"; }
    mkvirtualenv() { _load_venv; mkvirtualenv "$@"; }
fi

# Rust cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# kubectl (lazy load - it's VERY slow to initialize)
if _has_cmd kubectl; then
    kubectl() {
        unfunction kubectl 2>/dev/null
        source <(command kubectl completion zsh)
        command kubectl "$@"
    }
fi

# ============================================================================
# Dotfiles Functions (deferred loading)
# ============================================================================

_dotfiles_dir="$HOME/.dotfiles"

# Source dotfiles aliases
[[ -f "$_dotfiles_dir/zsh/aliases.zsh" ]] && source "$_dotfiles_dir/zsh/aliases.zsh"

# These are loaded immediately (small files, needed for keybindings)
[[ -f "$_dotfiles_dir/zsh/functions/command-palette.zsh" ]] && \
    source "$_dotfiles_dir/zsh/functions/command-palette.zsh"

# ============================================================================
# Deferred Loading (runs in background after prompt)
# ============================================================================

_deferred_load() {
    # Setup tool aliases
    _setup_tool_aliases
    
    # Setup FZF
    _has_cmd fzf && _setup_fzf
    
    # Source optional function files
    [[ -f "$_dotfiles_dir/zsh/functions/snapper.zsh" ]] && \
        source "$_dotfiles_dir/zsh/functions/snapper.zsh"
    [[ -f "$_dotfiles_dir/zsh/functions/smart-suggest.zsh" ]] && \
        source "$_dotfiles_dir/zsh/functions/smart-suggest.zsh"
    [[ -f "$_dotfiles_dir/zsh/functions/password-manager.zsh" ]] && \
        source "$_dotfiles_dir/zsh/functions/password-manager.zsh"
    
    # Load vault secrets
    local vault_script="$_dotfiles_dir/bin/dotfiles-vault.sh"
    if [[ -f "$_dotfiles_dir/vault/secrets.enc" ]] && [[ -x "$vault_script" ]]; then
        eval "$("$vault_script" shell 2>/dev/null)" || true
    fi
}

# ============================================================================
# Background Tasks (truly async, won't block)
# ============================================================================

_background_tasks() {
    # Check for dotfiles updates
    if [[ "${DOTFILES_AUTO_SYNC_CHECK:-true}" == "true" ]]; then
        # Use full path to avoid command_not_found issues
        local sync_script="$_dotfiles_dir/bin/dotfiles-sync.sh"
        [[ -x "$sync_script" ]] && "$sync_script" --auto 2>/dev/null &!
    fi
}

# ============================================================================
# Initialization Strategy
# ============================================================================

# Method 1: Use zsh-defer if available (best option)
if [[ -f "$_dotfiles_dir/zsh/plugins/zsh-defer/zsh-defer.plugin.zsh" ]]; then
    source "$_dotfiles_dir/zsh/plugins/zsh-defer/zsh-defer.plugin.zsh"
    zsh-defer _deferred_load
    zsh-defer _background_tasks
    zsh-defer -c '[[ -f "$_dotfiles_dir/zsh/functions/motd.zsh" ]] && source "$_dotfiles_dir/zsh/functions/motd.zsh" && show_motd'
else
    # Method 2: Use sched for deferred loading (built-in)
    # Runs after first prompt is displayed
    zmodload zsh/sched 2>/dev/null
    
    _first_prompt_hook() {
        # Remove this hook after first run
        add-zsh-hook -d precmd _first_prompt_hook
        
        # Run deferred loading
        _deferred_load
        
        # Show MOTD after prompt
        if [[ -f "$_dotfiles_dir/zsh/functions/motd.zsh" ]]; then
            source "$_dotfiles_dir/zsh/functions/motd.zsh"
            case "${MOTD_STYLE:-compact}" in
                compact) show_motd ;;
                mini) show_motd_mini ;;
            esac
        fi
        
        # Background tasks
        _background_tasks
    }
    
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _first_prompt_hook
fi

# ============================================================================
# OS-Specific
# ============================================================================

[[ "$(uname -s)" == "Darwin"* ]] && export HOMEBREW_NO_ANALYTICS=1

# ============================================================================
# Local Configuration (always load - user overrides)
# ============================================================================

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# ============================================================================
# End - Profiling output (uncomment zprof at top to use)
# ============================================================================
# zprof
