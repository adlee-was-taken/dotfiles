#!/usr/bin/env bash
# ============================================================================
# Dotfiles Secrets Vault (Arch/CachyOS)
# ============================================================================

set -e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
}

# ============================================================================
# Configuration
# ============================================================================

readonly VAULT_DIR="${DOTFILES_HOME}/vault"
readonly VAULT_FILE="${VAULT_DIR}/secrets.enc"

# ============================================================================
# Helper Functions
# ============================================================================

print_section() { echo ""; echo -e "${DF_BLUE}▶${DF_NC} $1"; }

get_cipher() {
    if command -v age &>/dev/null; then
        echo "age"
    elif command -v gpg &>/dev/null; then
        echo "gpg"
    else
        df_print_error "No encryption tool available (install 'age' or 'gpg')"
        exit 1
    fi
}

# ============================================================================
# Vault Functions
# ============================================================================

init_vault() {
    print_section "Initializing Vault"
    
    mkdir -p "$VAULT_DIR"
    chmod 700 "$VAULT_DIR"
    
    if [[ ! -f "$VAULT_FILE" ]]; then
        echo "{}" > "$VAULT_FILE"
        df_print_success "Vault initialized at $VAULT_DIR"
    else
        df_print_success "Vault already exists"
    fi
}

vault_list() {
    print_section "Stored Secrets"
    
    if [[ ! -f "$VAULT_FILE" ]]; then
        df_print_error "No vault file found. Run: vault init"
        return 1
    fi
    
    local keys=$(cat "$VAULT_FILE" | grep -o '"[^"]*":' | sed 's/"//g;s/:$//')
    
    if [[ -z "$keys" ]]; then
        echo "  (no secrets stored)"
    else
        echo "$keys" | while read key; do
            echo -e "  ${DF_CYAN}•${DF_NC} $key"
        done
    fi
    echo ""
}

vault_status() {
    print_section "Vault Status"
    
    if [[ ! -d "$VAULT_DIR" ]]; then
        echo -e "  ${DF_YELLOW}⚠${DF_NC} Vault not initialized"
        echo "  Run: vault init"
        return
    fi
    
    if [[ ! -f "$VAULT_FILE" ]]; then
        echo -e "  ${DF_YELLOW}⚠${DF_NC} Vault file not found"
        return
    fi
    
    local cipher=$(get_cipher)
    local key_count=$(cat "$VAULT_FILE" | grep -o '"[^"]*":' | wc -l)
    
    echo -e "  ${DF_CYAN}Location:${DF_NC}   $VAULT_FILE"
    echo -e "  ${DF_CYAN}Encryption:${DF_NC} $cipher"
    echo -e "  ${DF_CYAN}Secrets:${DF_NC}    $key_count"
    echo ""
}

show_help() {
    echo "Usage: dotfiles-vault.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  init       Initialize the vault"
    echo "  list, ls   List all secret keys"
    echo "  status     Show vault status"
    echo "  help       Show this help"
    echo ""
    echo "The vault uses 'age' or 'gpg' for encryption."
}

# ============================================================================
# Main
# ============================================================================

main() {
    df_print_header "dotfiles-vault"
    
    # Auto-init if vault doesn't exist
    [[ ! -d "$VAULT_DIR" ]] && init_vault
    
    case "${1:-list}" in
        init) init_vault ;;
        list|ls) vault_list ;;
        status) vault_status ;;
        help|--help|-h) show_help ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
