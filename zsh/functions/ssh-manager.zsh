# ============================================================================
# SSH Session Manager with Tmux Integration
# ============================================================================
# Manage SSH connections with automatic tmux session handling
# ============================================================================

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_GREEN=$'\033[0;32m' DF_BLUE=$'\033[0;34m'
    typeset -g DF_YELLOW=$'\033[1;33m' DF_CYAN=$'\033[0;36m'
    typeset -g DF_RED=$'\033[0;31m' DF_NC=$'\033[0m'
}

# ============================================================================
# Configuration
# ============================================================================

typeset -g SSH_PROFILES_FILE="${SSH_PROFILES_FILE:-$HOME/.dotfiles/.ssh-profiles}"
typeset -g SSH_AUTO_TMUX="${SSH_AUTO_TMUX:-true}"
typeset -g SSH_TMUX_SESSION_PREFIX="${SSH_TMUX_SESSION_PREFIX:-ssh}"
typeset -g SSH_SYNC_DOTFILES="${SSH_SYNC_DOTFILES:-ask}"

# ============================================================================
# Helper Functions
# ============================================================================

_ssh_print_step() { echo -e "${DF_BLUE}==>${DF_NC} $1"; }
_ssh_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
_ssh_print_error() { echo -e "${DF_RED}✗${DF_NC} $1"; }
_ssh_print_info() { echo -e "${DF_CYAN}ℹ${DF_NC} $1"; }

_ssh_init_profiles() {
    if [[ ! -f "$SSH_PROFILES_FILE" ]]; then
        mkdir -p "$(dirname "$SSH_PROFILES_FILE")"
        cat > "$SSH_PROFILES_FILE" << 'EOF'
# SSH Connection Profiles
# Format: name|user@host|port|key_file|options|description
EOF
        _ssh_print_success "Created SSH profiles file: $SSH_PROFILES_FILE"
    fi
}

_ssh_parse_profile() {
    local name="$1"
    local line=$(grep "^${name}|" "$SSH_PROFILES_FILE" 2>/dev/null | head -1)
    [[ -z "$line" ]] && return 1
    IFS='|' read -r profile_name connection port key_file ssh_opts description <<< "$line"
    echo "$connection|$port|$key_file|$ssh_opts|$description"
}

# ============================================================================
# SSH Profile Management
# ============================================================================

ssh-save() {
    local name="$1" connection="$2" port="${3:-22}" key_file="${4:-}" options="${5:-}" description="${6:-}"
    
    _ssh_init_profiles
    
    [[ -z "$name" || -z "$connection" ]] && {
        echo "Usage: ssh-save <name> <user@host> [port] [key_file] [options] [description]"
        return 1
    }
    
    if grep -q "^${name}|" "$SSH_PROFILES_FILE" 2>/dev/null; then
        echo -e "${DF_YELLOW}⚠${DF_NC} Profile '$name' already exists"
        read -q "REPLY?Overwrite? [y/N]: "; echo
        [[ ! "$REPLY" =~ ^[Yy]$ ]] && return 1
        grep -v "^${name}|" "$SSH_PROFILES_FILE" > "${SSH_PROFILES_FILE}.tmp"
        mv "${SSH_PROFILES_FILE}.tmp" "$SSH_PROFILES_FILE"
    fi
    
    echo "${name}|${connection}|${port}|${key_file}|${options}|${description}" >> "$SSH_PROFILES_FILE"
    
    _ssh_print_success "Saved SSH profile: $name"
    echo "  Connection: $connection"
    [[ "$port" != "22" ]] && echo "  Port: $port"
    [[ -n "$key_file" ]] && echo "  Key: $key_file"
}

ssh-list() {
    _ssh_init_profiles
    
    echo -e "${DF_BLUE}╔════════════════════════════════════════════════════════════╗${DF_NC}"
    echo -e "${DF_BLUE}║${DF_NC}  SSH Connection Profiles                                   ${DF_BLUE}║${DF_NC}"
    echo -e "${DF_BLUE}╚════════════════════════════════════════════════════════════╝${DF_NC}"
    echo
    
    local has_profiles=false
    while IFS='|' read -r name connection port key options description; do
        [[ "$name" =~ ^# ]] && continue
        [[ -z "$name" ]] && continue
        has_profiles=true
        
        echo -e "${DF_GREEN}●${DF_NC} ${DF_CYAN}$name${DF_NC}"
        echo "  Connection: $connection"
        [[ "$port" != "22" && -n "$port" ]] && echo "  Port: $port"
        [[ -n "$key" ]] && echo "  Key: $key"
        [[ -n "$description" ]] && echo "  Description: $description"
        echo
    done < "$SSH_PROFILES_FILE"
    
    [[ "$has_profiles" != true ]] && {
        _ssh_print_info "No profiles saved yet"
        echo "Create a profile with: ssh-save myserver user@example.com"
    }
}

ssh-delete() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: ssh-delete <name>"; return 1; }
    
    _ssh_init_profiles
    
    if ! grep -q "^${name}|" "$SSH_PROFILES_FILE" 2>/dev/null; then
        _ssh_print_error "Profile '$name' not found"
        return 1
    fi
    
    grep -v "^${name}|" "$SSH_PROFILES_FILE" > "${SSH_PROFILES_FILE}.tmp"
    mv "${SSH_PROFILES_FILE}.tmp" "$SSH_PROFILES_FILE"
    _ssh_print_success "Deleted profile: $name"
}

ssh-connect() {
    local name="$1"
    local session_name="${2:-${SSH_TMUX_SESSION_PREFIX}-${name}}"
    
    [[ -z "$name" ]] && { echo "Usage: ssh-connect <profile_name>"; ssh-list; return 1; }
    
    _ssh_init_profiles
    
    local profile_data=$(_ssh_parse_profile "$name")
    [[ -z "$profile_data" ]] && { _ssh_print_error "Profile '$name' not found"; return 1; }
    
    IFS='|' read -r connection port key_file ssh_opts description <<< "$profile_data"
    
    _ssh_print_step "Connecting to: $name"
    [[ -n "$description" ]] && echo "  $description"
    
    local ssh_cmd="ssh"
    [[ -n "$port" && "$port" != "22" ]] && ssh_cmd="$ssh_cmd -p $port"
    [[ -n "$key_file" ]] && ssh_cmd="$ssh_cmd -i $key_file"
    [[ -n "$ssh_opts" ]] && ssh_cmd="$ssh_cmd $ssh_opts"
    ssh_cmd="$ssh_cmd $connection"
    
    if [[ "$SSH_AUTO_TMUX" == "true" ]]; then
        _ssh_print_info "Attaching to tmux session: $session_name"
        local tmux_cmd="tmux attach-session -t $session_name 2>/dev/null || tmux new-session -s $session_name"
        eval "$ssh_cmd -t '$tmux_cmd'"
    else
        eval "$ssh_cmd"
    fi
}

sshf() {
    if ! command -v fzf &>/dev/null; then
        _ssh_print_error "fzf not installed"
        return 1
    fi
    
    _ssh_init_profiles
    
    local profiles=()
    while IFS='|' read -r name connection port key options description; do
        [[ "$name" =~ ^# ]] && continue
        [[ -z "$name" ]] && continue
        local display="$name → $connection"
        [[ -n "$description" ]] && display="$display  ($description)"
        profiles+=("$name|$display")
    done < "$SSH_PROFILES_FILE"
    
    [[ ${#profiles[@]} -eq 0 ]] && { _ssh_print_info "No profiles saved"; return 1; }
    
    local selection=$(printf '%s\n' "${profiles[@]}" | \
        fzf --height=50% --layout=reverse --border=rounded --prompt='SSH > ' \
            --delimiter='|' --with-nth=2)
    
    [[ -n "$selection" ]] && ssh-connect "${selection%%|*}"
}

ssh-reconnect() {
    local name="${1:-last}"
    
    if [[ "$name" == "last" ]]; then
        local last_profile=$(grep "ssh-connect" "$HISTFILE" 2>/dev/null | tail -1 | awk '{print $2}')
        [[ -z "$last_profile" ]] && { _ssh_print_error "No previous connection found"; return 1; }
        name="$last_profile"
    fi
    
    _ssh_print_info "Reconnecting to: $name"
    ssh-connect "$name"
}

ssh-sync-dotfiles() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: ssh-sync-dotfiles <profile_name>"; return 1; }
    
    local profile_data=$(_ssh_parse_profile "$name")
    [[ -z "$profile_data" ]] && { _ssh_print_error "Profile '$name' not found"; return 1; }
    
    IFS='|' read -r connection port key_file ssh_opts description <<< "$profile_data"
    
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    [[ ! -d "$dotfiles_dir" ]] && { _ssh_print_error "Dotfiles directory not found"; return 1; }
    
    _ssh_print_step "Syncing dotfiles to: $connection"
    
    local rsync_cmd="rsync -avz --exclude='.git' --exclude='*.local'"
    [[ -n "$port" && "$port" != "22" ]] && rsync_cmd="$rsync_cmd -e 'ssh -p $port'"
    [[ -n "$key_file" ]] && rsync_cmd="$rsync_cmd -e 'ssh -i $key_file'"
    rsync_cmd="$rsync_cmd $dotfiles_dir/ $connection:.dotfiles/"
    
    _ssh_print_info "Running: $rsync_cmd"
    
    if eval "$rsync_cmd"; then
        _ssh_print_success "Dotfiles synced successfully"
    else
        _ssh_print_error "Failed to sync dotfiles"
        return 1
    fi
}

# ============================================================================
# Aliases
# ============================================================================

alias sshl='ssh-list'
alias sshs='ssh-save'
alias sshc='ssh-connect'
alias sshd='ssh-delete'
alias sshr='ssh-reconnect'
alias sshsync='ssh-sync-dotfiles'

# ============================================================================
# Initialization
# ============================================================================

_ssh_init_profiles
