# ============================================================================
# Password Manager Integration for Zsh
# ============================================================================
# Unified interface for 1Password, LastPass, and Bitwarden CLIs
#
# Usage:
#   pw list                    # List items (auto-detects provider)
#   pw get <item>              # Get password
#   pw otp <item>              # Get OTP/TOTP code
#   pw search <query>          # Search items
#   pw copy <item>             # Copy password to clipboard
#
# Supported: 1Password (op), LastPass (lpass), Bitwarden (bw)
#
# Add to .zshrc:
#   source ~/.dotfiles/zsh/functions/password-manager.zsh
# ============================================================================

# ============================================================================
# Configuration
# ============================================================================

# Auto-detect preferred password manager (override in dotfiles.conf)
typeset -g PASSWORD_MANAGER="${PASSWORD_MANAGER:-auto}"

# Session timeout (seconds) - for managers that support it
typeset -g PW_SESSION_TIMEOUT=1800

# ============================================================================
# Provider Detection
# ============================================================================

_pw_detect_provider() {
    if [[ "$PASSWORD_MANAGER" != "auto" ]]; then
        echo "$PASSWORD_MANAGER"
        return
    fi
    
    # Auto-detect based on installed CLI
    if command -v op &>/dev/null; then
        echo "1password"
    elif command -v lpass &>/dev/null; then
        echo "lastpass"
    elif command -v bw &>/dev/null; then
        echo "bitwarden"
    else
        echo "none"
    fi
}

_pw_check_provider() {
    local provider=$(_pw_detect_provider)
    
    if [[ "$provider" == "none" ]]; then
        echo "Error: No password manager CLI found" >&2
        echo "Install one of: op (1Password), lpass (LastPass), bw (Bitwarden)" >&2
        return 1
    fi
    
    echo "$provider"
}

# ============================================================================
# 1Password Functions
# ============================================================================

_1p_ensure_session() {
    # Check if signed in
    if ! op account list &>/dev/null 2>&1; then
        echo "Signing into 1Password..." >&2
        eval $(op signin)
    fi
}

_1p_list() {
    _1p_ensure_session
    op item list --format=json | jq -r '.[] | "\(.title)\t\(.category)"' 2>/dev/null || \
    op item list 2>/dev/null
}

_1p_get() {
    local item="$1"
    local field="${2:-password}"
    _1p_ensure_session
    op item get "$item" --fields "$field" 2>/dev/null
}

_1p_otp() {
    local item="$1"
    _1p_ensure_session
    op item get "$item" --otp 2>/dev/null
}

_1p_search() {
    local query="$1"
    _1p_ensure_session
    op item list --format=json | jq -r ".[] | select(.title | test(\"$query\"; \"i\")) | .title" 2>/dev/null
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
# Bitwarden Functions
# ============================================================================

_bw_ensure_session() {
    # Check if locked
    if [[ -z "$BW_SESSION" ]]; then
        if bw status 2>/dev/null | grep -q '"status":"locked"'; then
            echo "Unlocking Bitwarden..." >&2
            export BW_SESSION=$(bw unlock --raw)
        elif bw status 2>/dev/null | grep -q '"status":"unauthenticated"'; then
            echo "Signing into Bitwarden..." >&2
            bw login
            export BW_SESSION=$(bw unlock --raw)
        fi
    fi
}

_bw_list() {
    _bw_ensure_session
    bw list items --session "$BW_SESSION" 2>/dev/null | jq -r '.[] | "\(.name)\t\(.type)"'
}

_bw_get() {
    local item="$1"
    local field="${2:-password}"
    _bw_ensure_session
    
    local item_json=$(bw get item "$item" --session "$BW_SESSION" 2>/dev/null)
    
    case "$field" in
        password) echo "$item_json" | jq -r '.login.password // empty' ;;
        username) echo "$item_json" | jq -r '.login.username // empty' ;;
        url)      echo "$item_json" | jq -r '.login.uris[0].uri // empty' ;;
        notes)    echo "$item_json" | jq -r '.notes // empty' ;;
        *)        echo "$item_json" | jq -r ".fields[]? | select(.name==\"$field\") | .value" ;;
    esac
}

_bw_otp() {
    local item="$1"
    _bw_ensure_session
    bw get totp "$item" --session "$BW_SESSION" 2>/dev/null
}

_bw_search() {
    local query="$1"
    _bw_ensure_session
    bw list items --search "$query" --session "$BW_SESSION" 2>/dev/null | jq -r '.[].name'
}

# ============================================================================
# Unified Interface
# ============================================================================

pw() {
    local cmd="${1:-help}"
    shift
    
    local provider=$(_pw_check_provider) || return 1
    
    case "$cmd" in
        list|ls|l)
            case "$provider" in
                1password) _1p_list ;;
                lastpass)  _lp_list ;;
                bitwarden) _bw_list ;;
            esac
            ;;
        
        get|g|show)
            local item="$1"
            local field="${2:-password}"
            [[ -z "$item" ]] && { echo "Usage: pw get <item> [field]"; return 1; }
            
            case "$provider" in
                1password) _1p_get "$item" "$field" ;;
                lastpass)  _lp_get "$item" "$field" ;;
                bitwarden) _bw_get "$item" "$field" ;;
            esac
            ;;
        
        otp|totp|2fa)
            local item="$1"
            [[ -z "$item" ]] && { echo "Usage: pw otp <item>"; return 1; }
            
            case "$provider" in
                1password) _1p_otp "$item" ;;
                lastpass)  _lp_otp "$item" ;;
                bitwarden) _bw_otp "$item" ;;
            esac
            ;;
        
        search|find|s)
            local query="$1"
            [[ -z "$query" ]] && { echo "Usage: pw search <query>"; return 1; }
            
            case "$provider" in
                1password) _1p_search "$query" ;;
                lastpass)  _lp_search "$query" ;;
                bitwarden) _bw_search "$query" ;;
            esac
            ;;
        
        copy|cp|c)
            local item="$1"
            local field="${2:-password}"
            [[ -z "$item" ]] && { echo "Usage: pw copy <item> [field]"; return 1; }
            
            local value
            case "$provider" in
                1password) value=$(_1p_get "$item" "$field") ;;
                lastpass)  value=$(_lp_get "$item" "$field") ;;
                bitwarden) value=$(_bw_get "$item" "$field") ;;
            esac
            
            if [[ -n "$value" ]]; then
                echo -n "$value" | pbcopy 2>/dev/null || \
                echo -n "$value" | xclip -selection clipboard 2>/dev/null || \
                echo -n "$value" | xsel --clipboard 2>/dev/null || \
                { echo "Could not copy to clipboard"; return 1; }
                echo "Copied to clipboard"
            else
                echo "Item not found or empty"
                return 1
            fi
            ;;
        
        provider|which)
            echo "Using: $provider"
            case "$provider" in
                1password) op --version 2>/dev/null ;;
                lastpass)  lpass --version 2>/dev/null ;;
                bitwarden) bw --version 2>/dev/null ;;
            esac
            ;;
        
        lock)
            case "$provider" in
                1password) op signout 2>/dev/null ;;
                lastpass)  lpass logout -f 2>/dev/null ;;
                bitwarden) bw lock 2>/dev/null; unset BW_SESSION ;;
            esac
            echo "Session locked"
            ;;
        
        help|--help|-h|*)
            echo "Password Manager CLI (using: $provider)"
            echo
            echo "Usage: pw <command> [args]"
            echo
            echo "Commands:"
            echo "  list                List all items"
            echo "  get <item> [field]  Get field (default: password)"
            echo "  otp <item>          Get OTP/TOTP code"
            echo "  search <query>      Search items"
            echo "  copy <item> [field] Copy to clipboard"
            echo "  provider            Show current provider"
            echo "  lock                Lock/sign out"
            echo "  help                Show this help"
            echo
            echo "Fields: password, username, url, notes, or custom field name"
            echo
            echo "Examples:"
            echo "  pw get github"
            echo "  pw get github username"
            echo "  pw otp github"
            echo "  pw copy aws"
            echo "  pw search mail"
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
    # Interactive password selection
    pwf() {
        local provider=$(_pw_check_provider) || return 1
        
        local item
        case "$provider" in
            1password) item=$(_1p_list | fzf --height=40% --reverse | cut -f1) ;;
            lastpass)  item=$(_lp_list | fzf --height=40% --reverse | cut -f1) ;;
            bitwarden) item=$(_bw_list | fzf --height=40% --reverse | cut -f1) ;;
        esac
        
        [[ -n "$item" ]] && pw copy "$item"
    }
    
    # Interactive OTP selection
    pwof() {
        local provider=$(_pw_check_provider) || return 1
        
        local item
        case "$provider" in
            1password) item=$(_1p_list | fzf --height=40% --reverse | cut -f1) ;;
            lastpass)  item=$(_lp_list | fzf --height=40% --reverse | cut -f1) ;;
            bitwarden) item=$(_bw_list | fzf --height=40% --reverse | cut -f1) ;;
        esac
        
        if [[ -n "$item" ]]; then
            local otp=$(pw otp "$item")
            if [[ -n "$otp" ]]; then
                echo -n "$otp" | pbcopy 2>/dev/null || \
                echo -n "$otp" | xclip -selection clipboard 2>/dev/null
                echo "OTP copied: $otp"
            fi
        fi
    }
fi
