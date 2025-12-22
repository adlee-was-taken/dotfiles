#!/usr/bin/env bash
# ============================================================================
# Dotfiles Secrets Vault (Arch/CachyOS)
# ============================================================================

set -e

readonly VAULT_DIR="${HOME}/.dotfiles/vault"
readonly VAULT_FILE="${VAULT_DIR}/secrets.enc"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ============================================================================
# Print MOTD-style header
# ============================================================================

print_header() {
    local user="${USER:-root}"
    local hostname="${HOSTNAME:-localhost}"
    local timestamp=$(date '+%a %b %d %H:%M')
    
    echo ""
    printf "${CYAN}+ ${NC}%-20s %30s %25s\n" "$user@$hostname" "dotfiles-vault" "$timestamp"
    echo ""
}

# ============================================================================
# Helper functions
# ============================================================================

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_section() {
    echo ""
    echo -e "${BLUE}▶${NC} $1"
}

# ============================================================================
# Encryption/Decryption
# ============================================================================

get_cipher() {
    if command -v age &> /dev/null; then
        echo "age"
    elif command -v gpg &> /dev/null; then
        echo "gpg"
    else
        print_error "No encryption tool available (install age or gpg)"
        exit 1
    fi
}

init_vault() {
    print_section "Initializing Vault"
    
    mkdir -p "$VAULT_DIR"
    chmod 700 "$VAULT_DIR"
    
    if [[ ! -f "$VAULT_FILE" ]]; then
        # Create empty encrypted file
        echo "{}" | $(get_cipher) > "$VAULT_FILE"
        print_success "Vault initialized"
    else
        print_success "Vault already exists"
    fi
}

decrypt_vault() {
    if [[ ! -f "$VAULT_FILE" ]]; then
        echo "{}"
        return
    fi
    
    local cipher=$(get_cipher)
    
    case "$cipher" in
        age)
            age -d -i "$HOME/.age/keys.txt" "$VAULT_FILE" 2>/dev/null || echo "{}"
            ;;
        gpg)
            gpg --decrypt "$VAULT_FILE" 2>/dev/null || echo "{}"
            ;;
    esac
}

encrypt_vault() {
    local data="$1"
    local cipher=$(get_cipher)
    
    case "$cipher" in
        age)
            echo "$data" | age -R "$HOME/.age/keys.txt" > "$VAULT_FILE"
            ;;
        gpg)
            echo "$data" | gpg --encrypt --armor > "$VAULT_FILE"
            ;;
    esac
}

# ============================================================================
# Vault operations
# ============================================================================

vault_set() {
    local key="$1"
    local value="${2:-}"
    
    if [[ -z "$key" ]]; then
        print_error "Usage: vault set <key> [value]"
        exit 1
    fi
    
    # Get value from stdin if not provided
    if [[ -z "$value" ]]; then
        read -s -p "Enter value for $key: " value
        echo ""
    fi
    
    # Decrypt current vault
    local current=$(decrypt_vault)
    
    # Add new key-value pair (using jq if available, otherwise simple replacement)
    if command -v jq &> /dev/null; then
        local updated=$(echo "$current" | jq --arg k "$key" --arg v "$value" '.[$k] = $v')
    else
        # Simple fallback without jq
        local updated="{\"$key\": \"$value\"}"
    fi
    
    # Encrypt and save
    encrypt_vault "$updated"
    print_success "Secret stored: $key"
}

vault_get() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        print_error "Usage: vault get <key>"
        exit 1
    fi
    
    local vault=$(decrypt_vault)
    
    if command -v jq &> /dev/null; then
        echo "$vault" | jq -r ".\"$key\" // \"\"" | grep -v "^$"
    else
        # Simple grep fallback
        echo "$vault" | grep "\"$key\"" | cut -d'"' -f4
    fi
}

vault_list() {
    print_section "Secrets"
    
    local vault=$(decrypt_vault)
    
    if command -v jq &> /dev/null; then
        echo "$vault" | jq -r 'keys[]' | while read key; do
            echo -e "  ${CYAN}•${NC} $key"
        done
    else
        # Simple fallback
        echo "$vault" | grep -o '"[^"]*":' | sed 's/"//g' | sed 's/:$//' | while read key; do
            echo -e "  ${CYAN}•${NC} $key"
        done
    fi
    
    echo ""
}

vault_delete() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        print_error "Usage: vault delete <key>"
        exit 1
    fi
    
    local vault=$(decrypt_vault)
    
    if command -v jq &> /dev/null; then
        local updated=$(echo "$vault" | jq "del(.\"$key\")")
    else
        print_error "jq required for delete operation"
        exit 1
    fi
    
    encrypt_vault "$updated"
    print_success "Secret deleted: $key"
}

vault_shell() {
    print_section "Loading secrets into environment"
    
    local vault=$(decrypt_vault)
    
    if command -v jq &> /dev/null; then
        echo "$vault" | jq -r 'to_entries[] | "export \(.key)=\"\(.value)\""'
    else
        print_error "jq required for shell export"
        exit 1
    fi
}

vault_export() {
    local dest="${1:-.}"
    
    if [[ -z "$dest" ]]; then
        print_error "Usage: vault export <filename>"
        exit 1
    fi
    
    if [[ -f "$dest" ]]; then
        print_error "File already exists: $dest"
        exit 1
    fi
    
    cp "$VAULT_FILE" "$dest"
    chmod 600 "$dest"
    print_success "Vault exported to: $dest"
}

vault_import() {
    local src="${1:-}"
    
    if [[ -z "$src" ]]; then
        print_error "Usage: vault import <filename>"
        exit 1
    fi
    
    if [[ ! -f "$src" ]]; then
        print_error "File not found: $src"
        exit 1
    fi
    
    cp "$src" "$VAULT_FILE"
    chmod 600 "$VAULT_FILE"
    print_success "Vault imported from: $src"
}

vault_status() {
    print_section "Vault Status"
    
    if [[ ! -d "$VAULT_DIR" ]]; then
        echo -e "  ${YELLOW}⚠${NC} Vault not initialized"
        return
    fi
    
    if [[ ! -f "$VAULT_FILE" ]]; then
        echo -e "  ${YELLOW}⚠${NC} Vault file not found"
        return
    fi
    
    local size=$(du -h "$VAULT_FILE" | cut -f1)
    local modified=$(stat -c %y "$VAULT_FILE" 2>/dev/null | cut -d' ' -f1 || stat -f '%Sm' "$VAULT_FILE" 2>/dev/null)
    
    echo -e "  ${CYAN}Location:${NC}     $VAULT_FILE"
    echo -e "  ${CYAN}Size:${NC}         $size"
    echo -e "  ${CYAN}Modified:${NC}     $modified"
    echo -e "  ${CYAN}Encryption:${NC}   $(get_cipher)"
    echo -e "  ${CYAN}Permissions:${NC}  $(stat -c '%a' $VAULT_FILE 2>/dev/null || stat -f '%a' "$VAULT_FILE")"
    
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header
    
    # Initialize vault if not exists
    if [[ ! -d "$VAULT_DIR" ]]; then
        init_vault
    fi
    
    case "${1:-list}" in
        init)
            init_vault
            ;;
        set)
            vault_set "$2" "${3:-}"
            ;;
        get)
            vault_get "$2"
            ;;
        list|ls)
            vault_list
            ;;
        delete|rm)
            vault_delete "$2"
            ;;
        shell)
            vault_shell
            ;;
        export)
            vault_export "$2"
            ;;
        import)
            vault_import "$2"
            ;;
        status)
            vault_status
            ;;
        *)
            echo "Usage: $0 {init|set|get|list|delete|shell|export|import|status}"
            echo ""
            echo "Commands:"
            echo "  init                Initialize vault"
            echo "  set <key> [value]   Store secret (prompts if value omitted)"
            echo "  get <key>           Retrieve secret"
            echo "  list                List all keys"
            echo "  delete <key>        Delete secret"
            echo "  shell               Print secrets as export statements"
            echo "  export <file>       Backup vault (encrypted)"
            echo "  import <file>       Restore vault from backup"
            echo "  status              Show vault information"
            exit 1
            ;;
    esac
}

main "$@"
