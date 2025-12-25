# ============================================================================
# SSH Session Manager with Tmux Integration
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

typeset -g SSH_PROFILES_FILE="${SSH_PROFILES_FILE:-$HOME/.dotfiles/.ssh-profiles}"
typeset -g SSH_AUTO_TMUX="${SSH_AUTO_TMUX:-true}"
typeset -g SSH_TMUX_PREFIX="${SSH_TMUX_PREFIX:-ssh}"

_ssh_init() {
    df_ensure_file "$SSH_PROFILES_FILE" "# SSH Profiles: name|user@host|port|key|options|description"
}

_ssh_parse() {
    local line=$(grep "^${1}|" "$SSH_PROFILES_FILE" 2>/dev/null | head -1)
    [[ -z "$line" ]] && return 1
    echo "$line" | cut -d'|' -f2-
}

ssh-save() {
    local name="$1" conn="$2" port="${3:-22}" key="${4:-}" opts="${5:-}" desc="${6:-}"
    [[ -z "$name" || -z "$conn" ]] && { echo "Usage: ssh-save <n> <user@host> [port] [key] [opts] [desc]"; return 1; }
    _ssh_init
    grep -q "^${name}|" "$SSH_PROFILES_FILE" 2>/dev/null && {
        df_confirm "Overwrite '$name'?" || return 1
        grep -v "^${name}|" "$SSH_PROFILES_FILE" > "${SSH_PROFILES_FILE}.tmp"
        mv "${SSH_PROFILES_FILE}.tmp" "$SSH_PROFILES_FILE"
    }
    echo "${name}|${conn}|${port}|${key}|${opts}|${desc}" >> "$SSH_PROFILES_FILE"
    df_print_success "Saved: $name → $conn"
}

ssh-list() {
    _ssh_init
    df_print_func_name "SSH Profiles"
    local found=false
    while IFS='|' read -r name conn port key opts desc; do
        [[ "$name" =~ ^# || -z "$name" ]] && continue
        found=true
        df_print_indent "● $name → $conn"
        [[ "$port" != "22" && -n "$port" ]] && df_print_indent "  Port: $port"
        [[ -n "$desc" ]] && df_print_indent "  $desc"
    done < "$SSH_PROFILES_FILE"
    [[ "$found" != true ]] && df_print_info "No profiles. Use: ssh-save name user@host"
}

ssh-delete() {
    [[ -z "$1" ]] && { echo "Usage: ssh-delete <n>"; return 1; }
    grep -q "^${1}|" "$SSH_PROFILES_FILE" 2>/dev/null || { df_print_error "Not found: $1"; return 1; }
    grep -v "^${1}|" "$SSH_PROFILES_FILE" > "${SSH_PROFILES_FILE}.tmp"
    mv "${SSH_PROFILES_FILE}.tmp" "$SSH_PROFILES_FILE"
    df_print_success "Deleted: $1"
}

ssh-connect() {
    local name="$1" session="${2:-${SSH_TMUX_PREFIX}-${1}}"
    [[ -z "$name" ]] && { ssh-list; return 1; }
    _ssh_init
    local data=$(_ssh_parse "$name")
    [[ -z "$data" ]] && { df_print_error "Not found: $name"; return 1; }
    
    IFS='|' read -r conn port key opts desc <<< "$data"
    df_print_step "Connecting: $name"
    [[ -n "$desc" ]] && df_print_indent "$desc"
    
    local cmd="ssh"
    [[ -n "$port" && "$port" != "22" ]] && cmd="$cmd -p $port"
    [[ -n "$key" ]] && cmd="$cmd -i $key"
    [[ -n "$opts" ]] && cmd="$cmd $opts"
    cmd="$cmd $conn"
    
    if [[ "$SSH_AUTO_TMUX" == "true" ]]; then
        df_print_info "Tmux session: $session"
        eval "$cmd -t 'tmux attach -t $session 2>/dev/null || tmux new -s $session'"
    else
        eval "$cmd"
    fi
}

sshf() {
    df_require_cmd fzf || return 1
    _ssh_init
    local profiles=()
    while IFS='|' read -r name conn port key opts desc; do
        [[ "$name" =~ ^# || -z "$name" ]] && continue
        profiles+=("$name|$name → $conn")
    done < "$SSH_PROFILES_FILE"
    [[ ${#profiles[@]} -eq 0 ]] && { df_print_info "No profiles"; return 1; }
    local sel=$(printf '%s\n' "${profiles[@]}" | fzf $(df_fzf_opts) --delimiter='|' --with-nth=2 --prompt='SSH > ')
    [[ -n "$sel" ]] && ssh-connect "${sel%%|*}"
}

alias sshl='ssh-list' sshs='ssh-save' sshc='ssh-connect' sshd='ssh-delete'
_ssh_init
