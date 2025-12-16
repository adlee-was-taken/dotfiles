#!/usr/bin/env bash
# ============================================================================
# Dotfiles Vault - Encrypted Secrets Management
# ============================================================================
# Securely store and retrieve API keys, tokens, and other secrets
#
# Usage:
#   vault set KEY "value"        # Store a secret
#   vault get KEY                # Retrieve a secret
#   vault list                   # List stored keys (not values)
#   vault delete KEY             # Delete a secret
#   vault export [file]          # Export encrypted vault
#   vault import [file]          # Import encrypted vault
#   vault shell                  # Export all secrets to current shell
#
# The vault uses GPG or age for encryption, stored in ~/.dotfiles/vault/
# ============================================================================

set -e

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_CONF="${SCRIPT_DIR}/../dotfiles.conf"
[[ -f "$DOTFILES_CONF" ]] || DOTFILES_CONF="$HOME/.dotfiles/dotfiles.conf"

if [[ -f "$DOTFILES_CONF" ]]; then
    source "$DOTFILES_CONF"
else
    DOTFILES_DIR="$HOME/.dotfiles"
fi

VAULT_DIR="$DOTFILES_DIR/vault"
VAULT_FILE="$VAULT_DIR/secrets.enc"
VAULT_KEYS="$VAULT_DIR/keys.txt"
VAULT_CONFIG="$VAULT_DIR/config"
VAULT_TMP="/tmp/.vault_$$"

# Encryption backend: gpg or age
VAULT_BACKEND="${VAULT_BACKEND:-auto}"

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
    [[ -f "$VAULT_TMP" ]] && rm -f "$VAULT_TMP"
    [[ -f "${VAULT_TMP}.dec" ]] && rm -f "${VAULT_TMP}.dec"
}

trap cleanup EXIT

# ============================================================================
# Backend Detection
# ============================================================================

detect_backend() {
    if [[ "$VAULT_BACKEND" == "auto" ]]; then
        if command -v age &>/dev/null; then
            echo "age"
        elif command -v gpg &>/dev/null; then
            echo "gpg"
        else
            echo ""
        fi
    else
        echo "$VAULT_BACKEND"
    fi
}

check_backend() {
    local backend=$(detect_backend)
    
    if [[ -z "$backend" ]]; then
        echo -e "${RED}✗${NC} No encryption backend found"
        echo
        echo "Install one of:"
        echo "  - age: https://github.com/FiloSottile/age"
        echo "  - gpg: usually pre-installed"
        echo
        echo "On macOS:  brew install age"
        echo "On Arch:   pacman -S age"
        echo "On Ubuntu: apt install age"
        exit 1
    fi
    
    echo "$backend"
}

# ============================================================================
# Initialization
# ============================================================================

init_vault() {
    mkdir -p "$VAULT_DIR"
    chmod 700 "$VAULT_DIR"
    
    local backend=$(check_backend)
    
    # Save config
    echo "VAULT_BACKEND=$backend" > "$VAULT_CONFIG"
    
    if [[ "$backend" == "age" ]]; then
        # Generate age key if not exists
        if [[ ! -f "$VAULT_DIR/key.txt" ]]; then
            echo -e "${BLUE}==>${NC} Generating age encryption key..."
            age-keygen -o "$VAULT_DIR/key.txt" 2>/dev/null
            chmod 600 "$VAULT_DIR/key.txt"
            echo -e "${GREEN}✓${NC} Key generated: $VAULT_DIR/key.txt"
            echo -e "${YELLOW}⚠${NC} Back up this key! Without it, you cannot decrypt your secrets."
        fi
    fi
    
    # Create empty vault if not exists
    if [[ ! -f "$VAULT_FILE" ]]; then
        echo "{}" > "$VAULT_TMP"
        encrypt_vault "$VAULT_TMP"
        rm -f "$VAULT_TMP"
        echo -e "${GREEN}✓${NC} Vault initialized"
    fi
}

# ============================================================================
# Encryption/Decryption
# ============================================================================

encrypt_vault() {
    local input="$1"
    local backend=$(detect_backend)
    
    case "$backend" in
        age)
            age -e -i "$VAULT_DIR/key.txt" -o "$VAULT_FILE" "$input"
            ;;
        gpg)
            gpg --symmetric --cipher-algo AES256 --batch --yes -o "$VAULT_FILE" "$input"
            ;;
    esac
    
    chmod 600 "$VAULT_FILE"
}

decrypt_vault() {
    local output="$1"
    local backend=$(detect_backend)
    
    if [[ ! -f "$VAULT_FILE" ]]; then
        echo "{}" > "$output"
        return 0
    fi
    
    case "$backend" in
        age)
            age -d -i "$VAULT_DIR/key.txt" -o "$output" "$VAULT_FILE" 2>/dev/null || {
                echo "{}" > "$output"
            }
            ;;
        gpg)
            gpg --decrypt --batch --quiet -o "$output" "$VAULT_FILE" 2>/dev/null || {
                echo "{}" > "$output"
            }
            ;;
    esac
}

# ============================================================================
# JSON Helpers (using pure bash for portability)
# ============================================================================

# Simple JSON get - works for flat key-value
json_get() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*: *"\([^"]*\)".*/\1/'
}

# Simple JSON set
json_set() {
    local json="$1"
    local key="$2"
    local value="$3"
    
    # Escape special characters in value
    value=$(echo "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')
    
    if echo "$json" | grep -q "\"$key\""; then
        # Update existing
        echo "$json" | sed "s|\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"$key\": \"$value\"|"
    else
        # Add new (simple approach for flat JSON)
        if [[ "$json" == "{}" ]]; then
            echo "{\"$key\": \"$value\"}"
        else
            echo "$json" | sed "s/}$/,\"$key\": \"$value\"}/"
        fi
    fi
}

# Simple JSON delete
json_delete() {
    local json="$1"
    local key="$2"
    echo "$json" | sed "s/,*\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"//g" | sed 's/{,/{/; s/,}/}/'
}

# List JSON keys
json_keys() {
    local json="$1"
    echo "$json" | grep -o '"[^"]*":' | sed 's/"//g; s/://' | sort
}

# ============================================================================
# Vault Commands
# ============================================================================

vault_set() {
    local key="$1"
    local value="$2"
    
    [[ -z "$key" ]] && { echo -e "${RED}✗${NC} Key required"; exit 1; }
    
    # If no value provided, prompt for it (hidden input)
    if [[ -z "$value" ]]; then
        echo -n "Enter value for $key: "
        read -s value
        echo
    fi
    
    [[ -z "$value" ]] && { echo -e "${RED}✗${NC} Value required"; exit 1; }
    
    init_vault
    
    # Decrypt, modify, encrypt
    decrypt_vault "${VAULT_TMP}.dec"
    local json=$(cat "${VAULT_TMP}.dec")
    json=$(json_set "$json" "$key" "$value")
    echo "$json" > "${VAULT_TMP}.dec"
    encrypt_vault "${VAULT_TMP}.dec"
    
    echo -e "${GREEN}✓${NC} Stored: $key"
}

vault_get() {
    local key="$1"
    local silent="${2:-false}"
    
    [[ -z "$key" ]] && { echo -e "${RED}✗${NC} Key required"; exit 1; }
    
    [[ ! -f "$VAULT_FILE" ]] && { 
        [[ "$silent" != true ]] && echo -e "${RED}✗${NC} Vault not initialized"
        exit 1
    }
    
    decrypt_vault "${VAULT_TMP}.dec"
    local json=$(cat "${VAULT_TMP}.dec")
    local value=$(json_get "$json" "$key")
    
    if [[ -n "$value" ]]; then
        echo "$value"
    else
        [[ "$silent" != true ]] && echo -e "${RED}✗${NC} Key not found: $key" >&2
        exit 1
    fi
}

vault_list() {
    [[ ! -f "$VAULT_FILE" ]] && { echo "Vault is empty"; return 0; }
    
    decrypt_vault "${VAULT_TMP}.dec"
    local json=$(cat "${VAULT_TMP}.dec")
    local keys=$(json_keys "$json")
    
    if [[ -z "$keys" ]]; then
        echo "Vault is empty"
        return 0
    fi
    
    echo -e "${CYAN}Stored secrets:${NC}"
    echo
    
    while read -r key; do
        [[ -n "$key" ]] && echo -e "  ${GREEN}●${NC} $key"
    done <<< "$keys"
    
    echo
    local count=$(echo "$keys" | grep -c . || echo 0)
    echo -e "${DIM}$count secret(s) stored${NC}"
}

vault_delete() {
    local key="$1"
    
    [[ -z "$key" ]] && { echo -e "${RED}✗${NC} Key required"; exit 1; }
    [[ ! -f "$VAULT_FILE" ]] && { echo -e "${RED}✗${NC} Vault not initialized"; exit 1; }
    
    decrypt_vault "${VAULT_TMP}.dec"
    local json=$(cat "${VAULT_TMP}.dec")
    
    if ! echo "$json" | grep -q "\"$key\""; then
        echo -e "${RED}✗${NC} Key not found: $key"
        exit 1
    fi
    
    read -p "Delete secret '$key'? [y/N]: " confirm
    [[ ! "$confirm" =~ ^[Yy] ]] && { echo "Cancelled"; exit 0; }
    
    json=$(json_delete "$json" "$key")
    echo "$json" > "${VAULT_TMP}.dec"
    encrypt_vault "${VAULT_TMP}.dec"
    
    echo -e "${GREEN}✓${NC} Deleted: $key"
}

vault_export() {
    local output="${1:-vault-export.enc}"
    
    [[ ! -f "$VAULT_FILE" ]] && { echo -e "${RED}✗${NC} Vault not initialized"; exit 1; }
    
    cp "$VAULT_FILE" "$output"
    
    echo -e "${GREEN}✓${NC} Exported to: $output"
    echo -e "${YELLOW}⚠${NC} This file is encrypted. Keep your key to decrypt it."
}

vault_import() {
    local input="${1:-vault-export.enc}"
    
    [[ ! -f "$input" ]] && { echo -e "${RED}✗${NC} File not found: $input"; exit 1; }
    
    init_vault
    
    # Test if we can decrypt the import
    local backend=$(detect_backend)
    case "$backend" in
        age)
            if ! age -d -i "$VAULT_DIR/key.txt" -o /dev/null "$input" 2>/dev/null; then
                echo -e "${RED}✗${NC} Cannot decrypt import file with current key"
                exit 1
            fi
            ;;
        gpg)
            if ! gpg --decrypt --batch --quiet -o /dev/null "$input" 2>/dev/null; then
                echo -e "${RED}✗${NC} Cannot decrypt import file"
                exit 1
            fi
            ;;
    esac
    
    read -p "This will overwrite existing vault. Continue? [y/N]: " confirm
    [[ ! "$confirm" =~ ^[Yy] ]] && { echo "Cancelled"; exit 0; }
    
    cp "$input" "$VAULT_FILE"
    chmod 600 "$VAULT_FILE"
    
    echo -e "${GREEN}✓${NC} Imported vault"
}

vault_shell() {
    [[ ! -f "$VAULT_FILE" ]] && { echo -e "${RED}✗${NC} Vault not initialized"; exit 1; }
    
    decrypt_vault "${VAULT_TMP}.dec"
    local json=$(cat "${VAULT_TMP}.dec")
    local keys=$(json_keys "$json")
    
    echo "# Add this to your shell or source it:"
    echo "# eval \$(vault shell)"
    echo
    
    while read -r key; do
        if [[ -n "$key" ]]; then
            local value=$(json_get "$json" "$key")
            echo "export $key=\"$value\""
        fi
    done <<< "$keys"
}

vault_env() {
    # Source secrets into current environment (for use in scripts)
    [[ ! -f "$VAULT_FILE" ]] && return 0
    
    decrypt_vault "${VAULT_TMP}.dec"
    local json=$(cat "${VAULT_TMP}.dec")
    local keys=$(json_keys "$json")
    
    while read -r key; do
        if [[ -n "$key" ]]; then
            local value=$(json_get "$json" "$key")
            export "$key"="$value"
        fi
    done <<< "$keys"
}

vault_status() {
    echo -e "${CYAN}Vault Status${NC}"
    echo
    
    local backend=$(detect_backend)
    echo -e "  Backend:   ${GREEN}$backend${NC}"
    echo -e "  Location:  $VAULT_DIR"
    
    if [[ -f "$VAULT_FILE" ]]; then
        local size=$(du -h "$VAULT_FILE" | cut -f1)
        echo -e "  Vault:     ${GREEN}exists${NC} ($size)"
        
        decrypt_vault "${VAULT_TMP}.dec"
        local json=$(cat "${VAULT_TMP}.dec")
        local count=$(json_keys "$json" | grep -c . || echo 0)
        echo -e "  Secrets:   $count"
    else
        echo -e "  Vault:     ${YELLOW}not initialized${NC}"
    fi
    
    if [[ "$backend" == "age" && -f "$VAULT_DIR/key.txt" ]]; then
        echo -e "  Key:       ${GREEN}present${NC}"
    fi
}

# ============================================================================
# Main
# ============================================================================

show_help() {
    echo "Usage: vault <command> [args]"
    echo
    echo "Commands:"
    echo "  set <key> [value]    Store a secret (prompts for value if not given)"
    echo "  get <key>            Retrieve a secret"
    echo "  list                 List all keys (not values)"
    echo "  delete <key>         Delete a secret"
    echo "  export [file]        Export encrypted vault"
    echo "  import <file>        Import encrypted vault"
    echo "  shell                Print secrets as export statements"
    echo "  status               Show vault status"
    echo "  init                 Initialize vault"
    echo "  help                 Show this help"
    echo
    echo "Examples:"
    echo "  vault set GITHUB_TOKEN ghp_xxxxxxxxxxxx"
    echo "  vault set AWS_SECRET_KEY   # Will prompt for value"
    echo "  vault get GITHUB_TOKEN"
    echo "  eval \$(vault shell)       # Export all to current shell"
    echo
    echo "The vault uses ${CYAN}age${NC} or ${CYAN}gpg${NC} for encryption."
    echo "Secrets are stored in: $VAULT_DIR"
}

main() {
    case "${1:-}" in
        set|s)
            vault_set "$2" "$3"
            ;;
        get|g)
            vault_get "$2"
            ;;
        list|ls|l)
            vault_list
            ;;
        delete|del|rm)
            vault_delete "$2"
            ;;
        export)
            vault_export "$2"
            ;;
        import)
            vault_import "$2"
            ;;
        shell|env)
            vault_shell
            ;;
        status|st)
            vault_status
            ;;
        init)
            init_vault
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'vault help' for usage"
            exit 1
            ;;
    esac
}

main "$@"
