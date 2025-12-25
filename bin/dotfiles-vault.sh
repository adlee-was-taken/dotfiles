#!/usr/bin/env bash
# ============================================================================
# Dotfiles Secrets Vault (Arch/CachyOS)
# ============================================================================

set -e

readonly DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
readonly VAULT_DIR="${HOME}/.dotfiles/vault"
readonly VAULT_FILE="${VAULT_DIR}/secrets.enc"

# Source shared colors and utils (provides DF_WIDTH)
source "$DOTFILES_HOME/zsh/lib/utils.zsh" 2>/dev/null || \
source "$DOTFILES_HOME/zsh/lib/colors.zsh" 2>/dev/null || {
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m' DF_LIGHT_GREEN=$'\033[38;5;82m'
}

# Use DF_WIDTH from utils.zsh or default to 66
readonly WIDTH="${DF_WIDTH:-66}"

# ============================================================================
# MOTD-style header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-vault"
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local hline="" && for ((i=0; i<WIDTH; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}      ${DF_LIGHT_GREEN}dotfiles-vault${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
print_section() { echo ""; echo -e "${DF_BLUE}▶${DF_NC} $1"; }

get_cipher() {
    command -v age &> /dev/null && echo "age" || \
    command -v gpg &> /dev/null && echo "gpg" || \
    { print_error "No encryption tool available"; exit 1; }
}

init_vault() {
    print_section "Initializing Vault"
    mkdir -p "$VAULT_DIR"
    chmod 700 "$VAULT_DIR"
    [[ ! -f "$VAULT_FILE" ]] && { echo "{}" > "$VAULT_FILE"; print_success "Vault initialized"; } || print_success "Vault exists"
}

vault_list() {
    print_section "Secrets"
    [[ -f "$VAULT_FILE" ]] && cat "$VAULT_FILE" | grep -o '"[^"]*":' | sed 's/"//g;s/:$//' | while read key; do
        echo -e "  ${DF_CYAN}•${DF_NC} $key"
    done || print_error "No vault file"
    echo ""
}

vault_status() {
    print_section "Vault Status"
    [[ -d "$VAULT_DIR" ]] || { echo -e "  ${DF_YELLOW}⚠${DF_NC} Vault not initialized"; return; }
    [[ -f "$VAULT_FILE" ]] || { echo -e "  ${DF_YELLOW}⚠${DF_NC} Vault file not found"; return; }
    echo -e "  ${DF_CYAN}Location:${DF_NC}   $VAULT_FILE"
    echo -e "  ${DF_CYAN}Encryption:${DF_NC} $(get_cipher)"
    echo ""
}

main() {
    print_header
    [[ ! -d "$VAULT_DIR" ]] && init_vault
    case "${1:-list}" in
        init) init_vault ;;
        list|ls) vault_list ;;
        status) vault_status ;;
        *) echo "Usage: $0 {init|list|status}"; exit 1 ;;
    esac
}

main "$@"
