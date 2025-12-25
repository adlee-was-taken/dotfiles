#!/usr/bin/env bash
# ============================================================================
# Espanso Setup and Configuration Script
# ============================================================================

set -e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
    df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
    df_print_step() { echo -e "${DF_GREEN}==>${DF_NC} $1"; }
}

# ============================================================================
# Helper Functions
# ============================================================================

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local yn_prompt="[Y/n]"
    [[ "$default" == "n" ]] && yn_prompt="[y/N]"
    
    read -p "$prompt $yn_prompt: " response
    response=${response:-$default}
    [[ "$response" =~ ^[Yy]$ ]]
}

# ============================================================================
# Espanso Functions
# ============================================================================

check_espanso() {
    if ! command -v espanso &>/dev/null; then
        df_print_error "espanso is not installed"
        echo "Install with: paru -S espanso-wayland  # or espanso-x11"
        exit 1
    fi
    df_print_success "espanso installed: $(espanso --version)"
}

show_espanso_status() {
    df_print_step "Checking espanso status"
    
    if espanso status 2>/dev/null | grep -q "running"; then
        df_print_success "espanso service is running"
    else
        df_print_warning "espanso service is not running"
        if ask_yes_no "Start espanso service?"; then
            espanso service start
            df_print_success "espanso service started"
        fi
    fi
}

personalize_config() {
    df_print_step "Personalizing espanso configuration"
    
    local personal_file="$HOME/.config/espanso/match/personal.yml"
    
    if [[ ! -f "$personal_file" ]]; then
        df_print_warning "Personal config not found, creating from template..."
        mkdir -p "$(dirname "$personal_file")"
        
        cat > "$personal_file" << 'EOF'
# ============================================================================
# Personal Espanso Snippets
# ============================================================================

matches:
  - trigger: "..myemail"
    replace: "your.email@example.com"

  - trigger: "..myname"
    replace: "Your Full Name"

  - trigger: "..myphone"
    replace: "+1 (555) 123-4567"

  - trigger: "..myweb"
    replace: "https://yourwebsite.com"

  - trigger: "..mygithub"
    replace: "https://github.com/yourusername"

  - trigger: "..sig"
    replace: |
      Best regards,
      Your Full Name
      your.email@example.com
EOF
        df_print_success "Created personal.yml template"
    fi
    
    echo ""
    echo "Personalizing your espanso configuration"
    echo "(Press Enter to keep existing values)"
    echo ""
    
    # Get current values or use config defaults
    local fullname="${USER_FULLNAME:-}"
    local email="${USER_EMAIL:-}"
    local phone="${USER_PHONE:-}"
    local website="${USER_WEBSITE:-}"
    local github="${USER_GITHUB:-}"
    
    [[ -z "$fullname" ]] && read -p "Your full name: " fullname
    [[ -z "$email" ]] && read -p "Your email: " email
    [[ -z "$phone" ]] && read -p "Your phone (optional): " phone
    [[ -z "$website" ]] && read -p "Your website (optional): " website
    [[ -z "$github" ]] && read -p "Your GitHub username (optional): " github
    
    # Create backup
    cp "$personal_file" "$personal_file.backup"
    
    # Update values if provided
    [[ -n "$email" ]] && sed -i "s/your.email@example.com/$email/g" "$personal_file"
    [[ -n "$fullname" ]] && sed -i "s/Your Full Name/$fullname/g" "$personal_file"
    [[ -n "$phone" ]] && sed -i "s/+1 (555) 123-4567/$phone/g" "$personal_file"
    [[ -n "$website" ]] && sed -i "s|https://yourwebsite.com|$website|g" "$personal_file"
    [[ -n "$github" ]] && sed -i "s/yourusername/$github/g" "$personal_file"
    
    df_print_success "Personal configuration updated!"
    df_print_warning "Backup saved to: $personal_file.backup"
}

install_packages() {
    df_print_step "Installing espanso packages"
    
    echo ""
    echo "Available packages:"
    echo "  1. emoji - Emoji snippets (:smile: → 😊)"
    echo "  2. greek-letters - Greek letters (:alpha: → α)"
    echo "  3. math - Math symbols (:sum: → ∑)"
    echo ""
    
    ask_yes_no "Install emoji package?" && {
        espanso install emoji --force 2>/dev/null
        df_print_success "Emoji package installed"
    }
    
    ask_yes_no "Install greek-letters package?" && {
        espanso install greek-letters --force 2>/dev/null
        df_print_success "Greek letters package installed"
    }
    
    ask_yes_no "Install math package?" && {
        espanso install math --force 2>/dev/null
        df_print_success "Math package installed"
    }
}

show_usage_tips() {
    df_print_step "Usage tips"
    
    cat << EOF

${DF_GREEN}Espanso Quick Start:${DF_NC}

${DF_YELLOW}Toggle on/off:${DF_NC}  ALT+SHIFT+E
${DF_YELLOW}Search menu:${DF_NC}    ALT+SPACE

${DF_YELLOW}Basic triggers:${DF_NC}
  ..date      → Current date (YYYY-MM-DD)
  ..time      → Current time (HH:MM:SS)
  ..shrug     → ¯\\_(ツ)_/¯
  ..myemail   → Your email

${DF_YELLOW}Commands:${DF_NC}
  espanso status    Check if running
  espanso restart   Restart service
  espanso log       View logs

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    df_print_header "setup-espanso"
    
    check_espanso
    show_espanso_status
    
    echo ""
    ask_yes_no "Personalize your configuration?" && personalize_config
    
    echo ""
    ask_yes_no "Install additional packages?" && install_packages
    
    echo ""
    show_usage_tips
    
    echo ""
    df_print_success "Espanso setup complete!"
    echo ""
    echo "Try typing ${DF_YELLOW}..date${DF_NC} in any application to test!"
}

main "$@"
