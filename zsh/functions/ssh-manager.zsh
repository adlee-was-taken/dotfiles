# ============================================================================
# SSH Session Manager with Tmux Integration
# ============================================================================
# Manage SSH connections with automatic tmux session handling
#
# Usage:
#   ssh-save <name> <connection>     # Save SSH connection
#   ssh-connect <name>               # Connect and attach/create tmux session
#   ssh-list                         # List all saved connections
#   ssh-delete <name>                # Delete saved connection
#   ssh-edit <name>                  # Edit connection details
#   sshf                             # Fuzzy search and connect
#
# Features:
#   - Automatic tmux session attach/create on remote host
#   - Named sessions per connection
#   - Connection profiles with SSH options
#   - Auto-reconnect support
#   - Dotfiles sync to remote (optional)
#
# Add to .zshrc:
#   source ~/.dotfiles/zsh/functions/ssh-manager.zsh
# ============================================================================

# ============================================================================
# Configuration
# ============================================================================

typeset -g SSH_PROFILES_FILE="${SSH_PROFILES_FILE:-$HOME/.dotfiles/.ssh-profiles}"
typeset -g SSH_AUTO_TMUX="${SSH_AUTO_TMUX:-true}"
typeset -g SSH_TMUX_SESSION_PREFIX="${SSH_TMUX_SESSION_PREFIX:-ssh}"
typeset -g SSH_SYNC_DOTFILES="${SSH_SYNC_DOTFILES:-ask}"

# Colors
typeset -g SSH_GREEN=$'\033[0;32m'
typeset -g SSH_BLUE=$'\033[0;34m'
typeset -g SSH_YELLOW=$'\033[1;33m'
typeset -g SSH_CYAN=$'\033[0;36m'
typeset -g SSH_RED=$'\033[0;31m'
typeset -g SSH_NC=$'\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

_ssh_print_step() {
    echo -e "${SSH_BLUE}==>${SSH_NC} $1"
}

_ssh_print_success() {
    echo -e "${SSH_GREEN}✓${SSH_NC} $1"
}

_ssh_print_error() {
    echo -e "${SSH_RED}✗${SSH_NC} $1"
}

_ssh_print_info() {
    echo -e "${SSH_CYAN}ℹ${SSH_NC} $1"
}

_ssh_init_profiles() {
    if [[ ! -f "$SSH_PROFILES_FILE" ]]; then
        mkdir -p "$(dirname "$SSH_PROFILES_FILE")"
        cat > "$SSH_PROFILES_FILE" << 'EOF'
# SSH Connection Profiles
# Format: name|user@host|port|key_file|options|description
#
# Example:
# prod|user@prod.example.com|22|~/.ssh/prod_key|-L 8080:localhost:80|Production server
# dev|user@dev.example.com|2222||ForwardAgent=yes|Development server
EOF
        _ssh_print_success "Created SSH profiles file: $SSH_PROFILES_FILE"
    fi
}

_ssh_parse_profile() {
    local name="$1"
    local line=$(grep "^${name}|" "$SSH_PROFILES_FILE" 2>/dev/null | head -1)
    
    if [[ -z "$line" ]]; then
        return 1
    fi
    
    # Parse: name|connection|port|key|options|description
    IFS='|' read -r profile_name connection port key_file ssh_opts description <<< "$line"
    
    echo "$connection|$port|$key_file|$ssh_opts|$description"
}

# ============================================================================
# SSH Profile Management
# ============================================================================

ssh-save() {
    local name="$1"
    local connection="$2"
    local port="${3:-22}"
    local key_file="${4:-}"
    local options="${5:-}"
    local description="${6:-}"
    
    _ssh_init_profiles
    
    if [[ -z "$name" || -z "$connection" ]]; then
        echo "Usage: ssh-save <name> <user@host> [port] [key_file] [options] [description]"
        echo
        echo "Examples:"
        echo "  ssh-save prod user@prod.com"
        echo "  ssh-save dev user@dev.com 2222 ~/.ssh/dev_key"
        echo "  ssh-save vpn user@vpn.com 22 '' '-D 9090' 'VPN server'"
        return 1
    fi
    
    # Check if profile exists
    if grep -q "^${name}|" "$SSH_PROFILES_FILE" 2>/dev/null; then
        echo -e "${SSH_YELLOW}⚠${SSH_NC} Profile '$name' already exists"
        read -q "REPLY?Overwrite? [y/N]: "
        echo
        [[ ! "$REPLY" =~ ^[Yy]$ ]] && return 1
        
        # Remove old entry
        grep -v "^${name}|" "$SSH_PROFILES_FILE" > "${SSH_PROFILES_FILE}.tmp"
        mv "${SSH_PROFILES_FILE}.tmp" "$SSH_PROFILES_FILE"
    fi
    
    # Save new profile
    echo "${name}|${connection}|${port}|${key_file}|${options}|${description}" >> "$SSH_PROFILES_FILE"
    
    _ssh_print_success "Saved SSH profile: $name"
    echo "  Connection: $connection"
    [[ "$port" != "22" ]] && echo "  Port: $port"
    [[ -n "$key_file" ]] && echo "  Key: $key_file"
    [[ -n "$options" ]] && echo "  Options: $options"
    [[ -n "$description" ]] && echo "  Description: $description"
}

ssh-list() {
    _ssh_init_profiles
    
    echo -e "${SSH_BLUE}╔════════════════════════════════════════════════════════════╗${SSH_NC}"
    echo -e "${SSH_BLUE}║${SSH_NC}  SSH Connection Profiles                                   ${SSH_BLUE}║${SSH_NC}"
    echo -e "${SSH_BLUE}╚════════════════════════════════════════════════════════════╝${SSH_NC}"
    echo
    
    local has_profiles=false
    while IFS='|' read -r name connection port key options description; do
        # Skip comments and empty lines
        [[ "$name" =~ ^# ]] && continue
        [[ -z "$name" ]] && continue
        
        has_profiles=true
        
        echo -e "${SSH_GREEN}●${SSH_NC} ${SSH_CYAN}$name${SSH_NC}"
        echo "  Connection: $connection"
        [[ "$port" != "22" && -n "$port" ]] && echo "  Port: $port"
        [[ -n "$key" ]] && echo "  Key: $key"
        [[ -n "$options" ]] && echo "  Options: $options"
        [[ -n "$description" ]] && echo "  Description: $description"
        echo
    done < "$SSH_PROFILES_FILE"
    
    if [[ "$has_profiles" != true ]]; then
        _ssh_print_info "No profiles saved yet"
        echo
        echo "Create a profile with:"
        echo "  ssh-save myserver user@example.com"
    fi
}

ssh-delete() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Usage: ssh-delete <name>"
        return 1
    fi
    
    _ssh_init_profiles
    
    if ! grep -q "^${name}|" "$SSH_PROFILES_FILE" 2>/dev/null; then
        _ssh_print_error "Profile '$name' not found"
        return 1
    fi
    
    # Remove profile
    grep -v "^${name}|" "$SSH_PROFILES_FILE" > "${SSH_PROFILES_FILE}.tmp"
    mv "${SSH_PROFILES_FILE}.tmp" "$SSH_PROFILES_FILE"
    
    _ssh_print_success "Deleted profile: $name"
}

ssh-edit() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        # Edit entire file
        ${EDITOR:-vim} "$SSH_PROFILES_FILE"
        return
    fi
    
    _ssh_init_profiles
    
    local profile_data=$(_ssh_parse_profile "$name")
    if [[ -z "$profile_data" ]]; then
        _ssh_print_error "Profile '$name' not found"
        return 1
    fi
    
    IFS='|' read -r connection port key_file ssh_opts description <<< "$profile_data"
    
    echo -e "${SSH_CYAN}Editing profile: $name${SSH_NC}"
    echo
    
    read "new_connection?Connection [$connection]: "
    new_connection="${new_connection:-$connection}"
    
    read "new_port?Port [$port]: "
    new_port="${new_port:-$port}"
    
    read "new_key?Key file [$key_file]: "
    new_key="${new_key:-$key_file}"
    
    read "new_opts?SSH options [$ssh_opts]: "
    new_opts="${new_opts:-$ssh_opts}"
    
    read "new_desc?Description [$description]: "
    new_desc="${new_desc:-$description}"
    
    # Remove old and add new
    grep -v "^${name}|" "$SSH_PROFILES_FILE" > "${SSH_PROFILES_FILE}.tmp"
    echo "${name}|${new_connection}|${new_port}|${new_key}|${new_opts}|${new_desc}" >> "${SSH_PROFILES_FILE}.tmp"
    mv "${SSH_PROFILES_FILE}.tmp" "$SSH_PROFILES_FILE"
    
    _ssh_print_success "Updated profile: $name"
}

# ============================================================================
# SSH Connection with Tmux Integration
# ============================================================================

ssh-connect() {
    local name="$1"
    local session_name="${2:-${SSH_TMUX_SESSION_PREFIX}-${name}}"
    
    if [[ -z "$name" ]]; then
        echo "Usage: ssh-connect <profile_name> [tmux_session_name]"
        echo
        echo "Saved profiles:"
        ssh-list
        return 1
    fi
    
    _ssh_init_profiles
    
    # Parse profile
    local profile_data=$(_ssh_parse_profile "$name")
    if [[ -z "$profile_data" ]]; then
        _ssh_print_error "Profile '$name' not found"
        echo "Use 'ssh-save $name user@host' to create it"
        return 1
    fi
    
    IFS='|' read -r connection port key_file ssh_opts description <<< "$profile_data"
    
    _ssh_print_step "Connecting to: $name"
    [[ -n "$description" ]] && echo "  $description"
    
    # Build SSH command
    local ssh_cmd="ssh"
    
    # Add port
    [[ -n "$port" && "$port" != "22" ]] && ssh_cmd="$ssh_cmd -p $port"
    
    # Add key file
    [[ -n "$key_file" ]] && ssh_cmd="$ssh_cmd -i $key_file"
    
    # Add custom options
    [[ -n "$ssh_opts" ]] && ssh_cmd="$ssh_cmd $ssh_opts"
    
    # Add connection
    ssh_cmd="$ssh_cmd $connection"
    
    # Tmux integration
    if [[ "$SSH_AUTO_TMUX" == "true" ]]; then
        _ssh_print_info "Attaching to tmux session: $session_name"
        
        # SSH with tmux attach or create
        local tmux_cmd="tmux attach-session -t $session_name 2>/dev/null || tmux new-session -s $session_name"
        
        # Execute
        eval "$ssh_cmd -t '$tmux_cmd'"
    else
        # Direct SSH without tmux
        eval "$ssh_cmd"
    fi
}

# ============================================================================
# Fuzzy Search Integration (requires fzf)
# ============================================================================

sshf() {
    if ! command -v fzf &>/dev/null; then
        _ssh_print_error "fzf not installed"
        echo "Install: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install"
        return 1
    fi
    
    _ssh_init_profiles
    
    # Build selection list
    local profiles=()
    while IFS='|' read -r name connection port key options description; do
        [[ "$name" =~ ^# ]] && continue
        [[ -z "$name" ]] && continue
        
        local display="$name → $connection"
        [[ -n "$description" ]] && display="$display  ($description)"
        
        profiles+=("$name|$display")
    done < "$SSH_PROFILES_FILE"
    
    if [[ ${#profiles[@]} -eq 0 ]]; then
        _ssh_print_info "No profiles saved"
        return 1
    fi
    
    # Fuzzy select
    local selection=$(printf '%s\n' "${profiles[@]}" | \
        fzf --height=50% \
            --layout=reverse \
            --border=rounded \
            --prompt='SSH > ' \
            --preview='echo {}' \
            --preview-window=hidden \
            --delimiter='|' \
            --with-nth=2)
    
    if [[ -n "$selection" ]]; then
        local profile_name="${selection%%|*}"
        ssh-connect "$profile_name"
    fi
}

# ============================================================================
# Quick Reconnect
# ============================================================================

ssh-reconnect() {
    local name="${1:-last}"
    
    if [[ "$name" == "last" ]]; then
        # Get last connected profile from history
        local last_profile=$(grep "ssh-connect" "$HISTFILE" 2>/dev/null | tail -1 | awk '{print $2}')
        
        if [[ -z "$last_profile" ]]; then
            _ssh_print_error "No previous connection found"
            return 1
        fi
        
        name="$last_profile"
    fi
    
    _ssh_print_info "Reconnecting to: $name"
    ssh-connect "$name"
}

# ============================================================================
# Dotfiles Sync to Remote
# ============================================================================

ssh-sync-dotfiles() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Usage: ssh-sync-dotfiles <profile_name>"
        return 1
    fi
    
    local profile_data=$(_ssh_parse_profile "$name")
    if [[ -z "$profile_data" ]]; then
        _ssh_print_error "Profile '$name' not found"
        return 1
    fi
    
    IFS='|' read -r connection port key_file ssh_opts description <<< "$profile_data"
    
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    
    if [[ ! -d "$dotfiles_dir" ]]; then
        _ssh_print_error "Dotfiles directory not found: $dotfiles_dir"
        return 1
    fi
    
    _ssh_print_step "Syncing dotfiles to: $connection"
    
    # Build rsync command
    local rsync_cmd="rsync -avz --exclude='.git' --exclude='*.local'"
    
    [[ -n "$port" && "$port" != "22" ]] && rsync_cmd="$rsync_cmd -e 'ssh -p $port'"
    [[ -n "$key_file" ]] && rsync_cmd="$rsync_cmd -e 'ssh -i $key_file'"
    
    rsync_cmd="$rsync_cmd $dotfiles_dir/ $connection:.dotfiles/"
    
    _ssh_print_info "Running: $rsync_cmd"
    
    if eval "$rsync_cmd"; then
        _ssh_print_success "Dotfiles synced successfully"
        
        # Optionally run install script on remote
        read -q "REPLY?Run install script on remote? [y/N]: "
        echo
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            local ssh_cmd="ssh"
            [[ -n "$port" && "$port" != "22" ]] && ssh_cmd="$ssh_cmd -p $port"
            [[ -n "$key_file" ]] && ssh_cmd="$ssh_cmd -i $key_file"
            
            eval "$ssh_cmd $connection 'cd .dotfiles && ./install.sh --skip-deps'"
        fi
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
# Completion Helper
# ============================================================================

_ssh_manager_profiles() {
    local profiles=()
    while IFS='|' read -r name rest; do
        [[ "$name" =~ ^# ]] && continue
        [[ -z "$name" ]] && continue
        profiles+=("$name")
    done < "$SSH_PROFILES_FILE" 2>/dev/null
    
    echo "${profiles[@]}"
}

# ZSH completion (if you want to add it)
# compdef '_arguments "1:profile:($(_ssh_manager_profiles))"' ssh-connect
# compdef '_arguments "1:profile:($(_ssh_manager_profiles))"' ssh-delete
# compdef '_arguments "1:profile:($(_ssh_manager_profiles))"' ssh-edit

# ============================================================================
# Initialization
# ============================================================================

_ssh_init_profiles
