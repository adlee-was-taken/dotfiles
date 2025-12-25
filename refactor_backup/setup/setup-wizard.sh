#!/usr/bin/env bash
# ============================================================================
# Dotfiles Interactive Setup Wizard
# ============================================================================

set -e

# ============================================================================
# Source Configuration
# ============================================================================

_df_source_config() {
    local locations=(
        "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/utils.zsh"
        "$HOME/.dotfiles/zsh/lib/utils.zsh"
    )
    for loc in "${locations[@]}"; do
        [[ -f "$loc" ]] && { source "$loc"; return 0; }
    done
    
    # Fallback defaults
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m' DF_LIGHT_GREEN=$'\033[38;5;82m'
    DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
    DOTFILES_VERSION="${DOTFILES_VERSION:-1.0.0}"
    DF_WIDTH="${DF_WIDTH:-66}"
}

_df_source_config

# ============================================================================
# Header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "setup-wizard"
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width="${DF_WIDTH:-66}"
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}    ${DF_LIGHT_GREEN}setup-wizard${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

# ============================================================================
# Gum Detection
# ============================================================================

HAS_GUM=false
command -v gum &>/dev/null && HAS_GUM=true

wizard_confirm() {
    local prompt="$1"
    local default="${2:-yes}"
    if [[ "$HAS_GUM" == true ]]; then
        [[ "$default" == "yes" ]] && gum confirm --default=yes "$prompt" || gum confirm --default=no "$prompt"
    else
        local yn_prompt="[Y/n]"
        [[ "$default" == "no" ]] && yn_prompt="[y/N]"
        read -p "$prompt $yn_prompt: " response
        response=${response:-${default:0:1}}
        [[ "$response" =~ ^[Yy] ]]
    fi
}

wizard_input() {
    local prompt="$1"
    local default="$2"
    if [[ "$HAS_GUM" == true ]]; then
        gum input --placeholder "$default" --value "$default" --prompt "$prompt: "
    else
        read -p "$prompt [$default]: " response
        echo "${response:-$default}"
    fi
}

# ============================================================================
# Wizard Steps
# ============================================================================

step_welcome() {
    clear
    print_header
    echo -e "${DF_BOLD}Welcome to Dotfiles Setup Wizard${DF_NC}"
    echo -e "${DF_DIM}Version: $DOTFILES_VERSION | Width: $DF_WIDTH${DF_NC}"
    echo
    wizard_confirm "Ready to begin?" || { echo "Cancelled."; exit 0; }
}

step_user_info() {
    echo -e "\n${DF_BLUE}▶${DF_NC} Personal Information"
    USER_FULLNAME=$(wizard_input "Full Name" "${USER_FULLNAME:-}")
    USER_EMAIL=$(wizard_input "Email" "${USER_EMAIL:-}")
    USER_GITHUB=$(wizard_input "GitHub Username" "${USER_GITHUB:-}")
}

step_summary() {
    echo -e "\n${DF_GREEN}✓${DF_NC} Setup Complete!"
    echo
    echo "  Name:   $USER_FULLNAME"
    echo "  Email:  $USER_EMAIL"
    echo "  GitHub: $USER_GITHUB"
    echo
    echo -e "${DF_DIM}Run 'source ~/.zshrc' to apply changes.${DF_NC}"
}

# ============================================================================
# Main
# ============================================================================

main() {
    step_welcome
    step_user_info
    step_summary
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
