#!/usr/bin/env bash
# ============================================================================
# Dotfiles Interactive Setup Wizard
# ============================================================================

set -e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    DOTFILES_VERSION="${DOTFILES_VERSION:-1.0.0}"
    DF_WIDTH="${DF_WIDTH:-66}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
}

# ============================================================================
# Gum Detection (for prettier TUI)
# ============================================================================

HAS_GUM=false
command -v gum &>/dev/null && HAS_GUM=true

wizard_confirm() {
    local prompt="$1"
    local default="${2:-yes}"
    
    if [[ "$HAS_GUM" == true ]]; then
        if [[ "$default" == "yes" ]]; then
            gum confirm --default=yes "$prompt"
        else
            gum confirm --default=no "$prompt"
        fi
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

wizard_choose() {
    local prompt="$1"
    shift
    local options=("$@")
    
    if [[ "$HAS_GUM" == true ]]; then
        printf '%s\n' "${options[@]}" | gum choose --header "$prompt"
    else
        echo "$prompt"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        read -p "Choice [1]: " choice
        choice=${choice:-1}
        echo "${options[$((choice-1))]}"
    fi
}

# ============================================================================
# Wizard Steps
# ============================================================================

step_welcome() {
    clear
    df_print_header "setup-wizard"
    
    echo -e "${DF_BOLD}Welcome to Dotfiles Setup Wizard${DF_NC}"
    echo -e "${DF_DIM}Version: $DOTFILES_VERSION | Display Width: $DF_WIDTH${DF_NC}"
    echo ""
    
    wizard_confirm "Ready to begin?" || {
        echo "Setup cancelled."
        exit 0
    }
}

step_user_info() {
    echo ""
    echo -e "${DF_BLUE}▶${DF_NC} Personal Information"
    echo ""
    
    USER_FULLNAME=$(wizard_input "Full Name" "${USER_FULLNAME:-}")
    USER_EMAIL=$(wizard_input "Email" "${USER_EMAIL:-}")
    USER_GITHUB=$(wizard_input "GitHub Username" "${USER_GITHUB:-}")
}

step_features() {
    echo ""
    echo -e "${DF_BLUE}▶${DF_NC} Feature Selection"
    echo ""
    
    MOTD_STYLE=$(wizard_choose "MOTD Style:" "compact" "mini" "full" "none")
    
    wizard_confirm "Enable smart suggestions (typo correction)?" && ENABLE_SMART_SUGGESTIONS="true" || ENABLE_SMART_SUGGESTIONS="false"
    wizard_confirm "Enable command palette (Ctrl+Space)?" && ENABLE_COMMAND_PALETTE="true" || ENABLE_COMMAND_PALETTE="false"
}

step_summary() {
    echo ""
    echo -e "${DF_GREEN}✓${DF_NC} Configuration Summary"
    echo ""
    echo "  Name:              $USER_FULLNAME"
    echo "  Email:             $USER_EMAIL"
    echo "  GitHub:            $USER_GITHUB"
    echo "  MOTD Style:        $MOTD_STYLE"
    echo "  Smart Suggestions: $ENABLE_SMART_SUGGESTIONS"
    echo "  Command Palette:   $ENABLE_COMMAND_PALETTE"
    echo ""
    
    if wizard_confirm "Save this configuration?"; then
        save_config
        df_print_success "Configuration saved!"
    else
        echo "Configuration not saved."
    fi
}

save_config() {
    local config_file="$DOTFILES_HOME/dotfiles.conf"
    
    # Update values in config file
    if [[ -f "$config_file" ]]; then
        sed -i "s/^USER_FULLNAME=.*/USER_FULLNAME=\"$USER_FULLNAME\"/" "$config_file"
        sed -i "s/^USER_EMAIL=.*/USER_EMAIL=\"$USER_EMAIL\"/" "$config_file"
        sed -i "s/^USER_GITHUB=.*/USER_GITHUB=\"$USER_GITHUB\"/" "$config_file"
        sed -i "s/^MOTD_STYLE=.*/MOTD_STYLE=\"$MOTD_STYLE\"/" "$config_file"
        sed -i "s/^ENABLE_SMART_SUGGESTIONS=.*/ENABLE_SMART_SUGGESTIONS=\"$ENABLE_SMART_SUGGESTIONS\"/" "$config_file"
        sed -i "s/^ENABLE_COMMAND_PALETTE=.*/ENABLE_COMMAND_PALETTE=\"$ENABLE_COMMAND_PALETTE\"/" "$config_file"
    fi
}

step_next() {
    echo ""
    df_print_success "Setup Complete!"
    echo ""
    echo -e "${DF_DIM}Next steps:${DF_NC}"
    echo "  1. Reload your shell: source ~/.zshrc"
    echo "  2. Run health check:  dfd"
    echo "  3. Explore commands:  dotfiles-cli help"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    step_welcome
    step_user_info
    step_features
    step_summary
    step_next
}

# Only run if executed directly (not sourced)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
