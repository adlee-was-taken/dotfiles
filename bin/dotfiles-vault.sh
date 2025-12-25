#!/usr/bin/env bash
# ============================================================================
# Dotfiles Secrets Vault (Arch/CachyOS)
# ============================================================================

set -e

readonly DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
readonly VAULT_DIR="${HOME}/.dotfiles/vault"
readonly VAULT_FILE="${VAULT_DIR}/secrets.enc"

# Source shared colors
source "$DOTFILES_HOME/zsh/lib/colors.zsh" 2>/dev/null || {
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
}

# Source utils.zsh
source "$DOTFILES_HOME/zsh/lib/utils.zsh" 2>/dev/null

# ============================================================================
# MOTD-style header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-vault "
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width=66
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}      ${DF_DIM}dotfiles-vault${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

# ============================================================================
# Helper functions
# ============================================================================

print_success() {
    echo -e "${DF_GREEN}✓${DF_NC} $1"
}

print_error() {
    echo -e "${DF_RED}✗${DF_NC} $1" >&2
}

print_section() {
    echo ""
    echo -e "${DF_BLUE}▶${DF_NC} $1"
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

    if [[ -z "$value" ]]; then
        read -s -p "Enter value for $key: " value
        echo ""
    fi

    local current=$(decrypt_vault)

    if command -v jq &> /dev/null; then
        local updated=$(echo "$current" | jq --arg k "$key" --arg v "$value" '.[$k] = $v')
    else
        local updated="{\"$key\": \"$value\"}"
    fi

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
        echo "$vault" | grep "\"$key\"" | cut -d'"' -f4
    fi
}

vault_list() {
    print_section "Secrets"

    local vault=$(decrypt_vault)

    if command -v jq &> /dev/null; then
        echo "$vault" | jq -r 'keys[]' | while read key; do
            echo -e "  ${DF_CYAN}•${DF_NC} $key"
        done
    else
        echo "$vault" | grep -o '"[^"]*":' | sed 's/"//g' | sed 's/:$//' | while read key; do
            echo -e "  ${DF_CYAN}•${DF_NC} $key"
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
        echo -e "  ${DF_YELLOW}⚠${DF_NC} Vault not initialized"
        return
    fi

    if [[ ! -f "$VAULT_FILE" ]]; then
        echo -e "  ${DF_YELLOW}⚠${DF_NC} Vault file not found"
        return
    fi

    local size=$(du -h "$VAULT_FILE" | cut -f1)
    local modified=$(stat -c %y "$VAULT_FILE" 2>/dev/null | cut -d' ' -f1 || stat -f '%Sm' "$VAULT_FILE" 2>/dev/null)

    echo -e "  ${DF_CYAN}Location:${DF_NC}     $VAULT_FILE"
    echo -e "  ${DF_CYAN}Size:${DF_NC}         $size"
    echo -e "  ${DF_CYAN}Modified:${DF_NC}     $modified"
    echo -e "  ${DF_CYAN}Encryption:${DF_NC}   $(get_cipher)"
    echo -e "  ${DF_CYAN}Permissions:${DF_NC}  $(stat -c '%a' $VAULT_FILE 2>/dev/null || stat -f '%a' "$VAULT_FILE")"

    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header

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
