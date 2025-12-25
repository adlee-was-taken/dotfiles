# ============================================================================
# Password Manager Integration for Zsh (LastPass Only)
# ============================================================================
# Unified interface for LastPass CLI
#
# Usage:
#   pw list                    # List all items
#   pw get <item>              # Get password
#   pw otp <item>              # Get OTP/TOTP code
#   pw search <query>          # Search items
#   pw copy <item>             # Copy password to clipboard
# ============================================================================

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_GREEN=$'\033[0;32m' DF_BLUE=$'\033[0;34m'
    typeset -g DF_YELLOW=$'\033[1;33m' DF_CYAN=$'\033[0;36m'
    typeset -g DF_RED=$'\033[0;31m' DF_NC=$'\033[0m'
}

# ============================================================================
# LastPass Functions
# ============================================================================

_lp_ensure_session() {
    if ! lpass status -q 2>/dev/null; then
        echo "Signing into LastPass..." >&2
        lpass login "${LASTPASS_EMAIL:-}"
    fi
}

_lp_list() {
    _lp_ensure_session
    lpass ls --format="%an\t%ag" 2>/dev/null
}

_lp_get() {
    local item="$1"
    local field="${2:-password}"
    _lp_ensure_session
    
    case "$field" in
        password) lpass show --password "$item" 2>/dev/null ;;
        username) lpass show --username "$item" 2>/dev/null ;;
        url)      lpass show --url "$item" 2>/dev/null ;;
        notes)    lpass show --notes "$item" 2>/dev/null ;;
        *)        lpass show --field="$field" "$item" 2>/dev/null ;;
    esac
}

_lp_otp() {
    local item="$1"
    _lp_ensure_session
    lpass show --otp "$item" 2>/dev/null
}

_lp_search() {
    local query="$1"
    _lp_ensure_session
    lpass ls 2>/dev/null | grep -i "$query"
}

# ============================================================================
# Unified Interface
# ============================================================================

pw() {
    local cmd="${1:-help}"
    shift
    
    if ! command -v lpass &>/dev/null; then
        echo -e "${DF_RED}✗${DF_NC} LastPass CLI (lpass) not installed"
        echo "Install with: yay -S lastpass-cli"
        return 1
    fi
    
    case "$cmd" in
        list|ls|l)
            df_print_func_name "LastPass Vault"
            _lp_list
            ;;
        
        get|g|show)
            local item="$1"
            local field="${2:-password}"
            [[ -z "$item" ]] && { echo "Usage: pw get <item> [field]"; return 1; }
            _lp_get "$item" "$field"
            ;;
        
        otp|totp|2fa)
            local item="$1"
            [[ -z "$item" ]] && { echo "Usage: pw otp <item>"; return 1; }
            _lp_otp "$item"
            ;;
        
        search|find|s)
            local query="$1"
            [[ -z "$query" ]] && { echo "Usage: pw search <query>"; return 1; }
            df_print_func_name "LastPass Search: $query"
            _lp_search "$query"
            ;;
        
        copy|cp|c)
            local item="$1"
            local field="${2:-password}"
            [[ -z "$item" ]] && { echo "Usage: pw copy <item> [field]"; return 1; }
            
            local value=$(_lp_get "$item" "$field")
            
            if [[ -n "$value" ]]; then
                echo -n "$value" | xclip -selection clipboard 2>/dev/null || \
                echo -n "$value" | xsel --clipboard 2>/dev/null || \
                { echo "Could not copy to clipboard"; return 1; }
                echo -e "${DF_GREEN}✓${DF_NC} Copied to clipboard"
            else
                echo -e "${DF_RED}✗${DF_NC} Item not found or empty"
                return 1
            fi
            ;;
        
        lock)
            lpass logout -f 2>/dev/null
            echo -e "${DF_GREEN}✓${DF_NC} Logged out of LastPass"
            ;;
        
        help|--help|-h|*)
            df_print_func_name "Password Manager CLI"
            echo "Usage: pw <command> [args]"
            echo
            echo "Commands:"
            echo "  list              List all items"
            echo "  get <item> [field] Get field (default: password)"
            echo "  otp <item>        Get OTP/TOTP code"
            echo "  search <query>    Search items"
            echo "  copy <item> [field] Copy to clipboard"
            echo "  lock              Logout/lock session"
            echo "  help              Show this help"
            echo
            echo "Fields: password, username, url, notes, or custom field name"
            echo
            echo "Examples:"
            echo "  pw get github"
            echo "  pw get github username"
            echo "  pw otp github"
            echo "  pw copy aws"
            echo "  pw search mail"
            echo
            echo "Install: yay -S lastpass-cli"
            ;;
    esac
}

# ============================================================================
# Aliases
# ============================================================================

alias pwl='pw list'
alias pwg='pw get'
alias pwc='pw copy'
alias pws='pw search'

# ============================================================================
# FZF Integration (if available)
# ============================================================================

if command -v fzf &>/dev/null; then
    pwf() {
        if ! command -v lpass &>/dev/null; then
            echo "LastPass CLI not installed"
            return 1
        fi
        
        local item=$(_lp_list | fzf --height=40% --reverse | cut -f1)
        
        if [[ -n "$item" ]]; then
            pw copy "$item"
        fi
    }
    
    pwof() {
        if ! command -v lpass &>/dev/null; then
            echo "LastPass CLI not installed"
            return 1
        fi
        
        local item=$(_lp_list | fzf --height=40% --reverse | cut -f1)
        
        if [[ -n "$item" ]]; then
            local otp=$(pw otp "$item")
            if [[ -n "$otp" ]]; then
                echo -n "$otp" | xclip -selection clipboard 2>/dev/null || \
                echo -n "$otp" | xsel --clipboard 2>/dev/null
                echo -e "${DF_GREEN}✓${DF_NC} OTP copied: $otp"
            fi
        fi
    }
fi
