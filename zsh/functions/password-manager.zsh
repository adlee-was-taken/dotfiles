# ============================================================================
# Password Manager Integration (LastPass CLI)
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

typeset -g PW_CLIP_TIME="${PW_CLIP_TIME:-45}"

_pw_check() {
    df_require_cmd lpass lastpass-cli || return 1
    if ! lpass status -q 2>/dev/null; then
        df_print_warning "Not logged in"
        df_print_step "Logging in..."
        lpass login --trust "${LPASS_USER:-}" || { df_print_error "Login failed"; return 1; }
    fi
}

_pw_copy() {
    local text="$1" label="${2:-Password}"
    if df_cmd_exists wl-copy; then
        echo -n "$text" | wl-copy
    elif df_cmd_exists xclip; then
        echo -n "$text" | xclip -selection clipboard
    else
        df_print_error "No clipboard tool (install wl-clipboard or xclip)"
        return 1
    fi
    df_print_success "$label copied (clears in ${PW_CLIP_TIME}s)"
    (sleep "$PW_CLIP_TIME" && { wl-copy "" 2>/dev/null || xclip -selection clipboard < /dev/null 2>/dev/null; }) &
}

pw() {
    local cmd="${1:-search}"
    case "$cmd" in
        login) lpass login --trust "${LPASS_USER:-}" ;;
        logout) lpass logout -f; df_print_success "Logged out" ;;
        sync) _pw_check || return 1; df_print_step "Syncing..."; lpass sync; df_print_success "Synced" ;;
        show) _pw_check || return 1; [[ -z "$2" ]] && { echo "Usage: pw show <entry>"; return 1; }; lpass show "$2" ;;
        gen|generate)
            local len="${2:-20}"
            local pass=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c "$len")
            _pw_copy "$pass" "Generated password"
            ;;
        list|ls) _pw_check || return 1; df_print_func_name "Password Entries"; lpass ls --long ;;
        search|*)
            _pw_check || return 1
            local query="$1"; [[ "$cmd" == "search" ]] && query="$2"
            if df_cmd_exists fzf && [[ -z "$query" ]]; then
                local entry=$(lpass ls --format "%an (%au) [%ai]" 2>/dev/null | fzf $(df_fzf_opts) --prompt='Password > ')
                [[ -z "$entry" ]] && return
                local id=$(echo "$entry" | grep -oP '\[\K[^\]]+(?=\]$)')
                local pass=$(lpass show --password "$id" 2>/dev/null)
                [[ -n "$pass" ]] && _pw_copy "$pass" || df_print_error "Could not retrieve"
            else
                [[ -z "$query" ]] && { echo "Usage: pw <search-term>"; return 1; }
                local results=$(lpass ls --format "%an [%ai]" 2>/dev/null | grep -i "$query")
                local count=$(echo "$results" | grep -c . 2>/dev/null || echo 0)
                if (( count == 0 )); then
                    df_print_warning "No entries for: $query"
                elif (( count == 1 )); then
                    local id=$(echo "$results" | grep -oP '\[\K[^\]]+(?=\]$)')
                    _pw_copy "$(lpass show --password "$id" 2>/dev/null)"
                else
                    df_print_warning "Multiple entries:"
                    echo "$results" | while read -r l; do df_print_indent "$l"; done
                fi
            fi
            ;;
        help|--help|-h)
            df_print_func_name "Password Manager"
            cat << 'EOF'
  pw <search>       Search and copy password
  pw show <n>       Show entry details
  pw list           List all entries
  pw gen [len]      Generate password (default: 20)
  pw sync           Sync vault
  pw login/logout   Auth commands
EOF
            ;;
    esac
}

alias pwc='pw' pws='pw show' pwg='pw gen' pwl='pw list'
