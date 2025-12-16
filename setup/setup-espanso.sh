#!/usr/bin/env bash
# ============================================================================
# Espanso Setup and Configuration Script
# ============================================================================

set -e

# ============================================================================
# Load Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_CONF="${SCRIPT_DIR}/../dotfiles.conf"
[[ -f "$DOTFILES_CONF" ]] || DOTFILES_CONF="$HOME/.dotfiles/dotfiles.conf"

if [[ -f "$DOTFILES_CONF" ]]; then
    source "$DOTFILES_CONF"
else
    DOTFILES_DIR="$HOME/.dotfiles"
    USER_FULLNAME=""
    USER_EMAIL=""
    USER_PHONE=""
    USER_WEBSITE=""
    USER_GITHUB=""
fi

# ============================================================================
# Colors
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Espanso Setup Script                                     ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${GREEN}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" response
    response=${response:-$default}
    [[ "$response" =~ ^[Yy]$ ]]
}

# ============================================================================
# Functions
# ============================================================================

check_espanso() {
    if ! command -v espanso &> /dev/null; then
        print_error "espanso is not installed"
        echo "Install it from: https://espanso.org/install/"
        echo "Or run the main dotfiles install script"
        exit 1
    fi
    print_success "espanso is installed: $(espanso --version)"
}

show_espanso_status() {
    print_step "Checking espanso status"

    if espanso status | grep -q "running"; then
        print_success "espanso service is running"
    else
        print_warning "espanso service is not running"
        if ask_yes_no "Start espanso service?"; then
            espanso service start
            print_success "espanso service started"
        fi
    fi
}

personalize_config() {
    print_step "Personalizing espanso configuration"

    local personal_file="$HOME/.config/espanso/match/personal.yml"

    if [ ! -f "$personal_file" ]; then
        print_warning "Personal config file not found, creating from template..."
        mkdir -p "$(dirname "$personal_file")"
        cat > "$personal_file" << 'EOF'
# ============================================================================
# Personal Espanso Snippets
# ============================================================================
# Edit these with your own information

matches:
  # Personal info
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

  # Email signature
  - trigger: "..sig"
    replace: |
      Best regards,
      Your Full Name
      your.email@example.com

  # Address (customize as needed)
  - trigger: "..myaddr"
    replace: |
      123 Main Street
      City, ST 12345
EOF
        print_success "Created personal.yml template"
    fi

    echo
    echo "Let's personalize your espanso configuration!"
    echo "(Press Enter to keep existing/default values)"
    echo

    # Use config values as defaults, prompt for any missing
    local fullname="${USER_FULLNAME}"
    local email="${USER_EMAIL}"
    local phone="${USER_PHONE}"
    local website="${USER_WEBSITE}"
    local github="${USER_GITHUB}"

    [[ -z "$fullname" ]] && read -p "Your full name: " fullname
    [[ -z "$email" ]] && read -p "Your email: " email
    [[ -z "$phone" ]] && read -p "Your phone (optional): " phone
    [[ -z "$website" ]] && read -p "Your website (optional): " website
    [[ -z "$github" ]] && read -p "Your GitHub username (optional): " github

    # Create backup
    cp "$personal_file" "$personal_file.backup"

    # Update values
    [[ -n "$email" ]] && sed -i "s/your.email@example.com/$email/g" "$personal_file"
    [[ -n "$fullname" ]] && sed -i "s/Your Full Name/$fullname/g" "$personal_file"
    [[ -n "$phone" ]] && sed -i "s/+1 (555) 123-4567/$phone/g" "$personal_file"
    [[ -n "$website" ]] && sed -i "s|https://yourwebsite.com|$website|g" "$personal_file"
    [[ -n "$github" ]] && sed -i "s/yourusername/$github/g" "$personal_file"

    print_success "Personal configuration updated!"
    print_warning "Backup saved to: $personal_file.backup"

    # Suggest updating dotfiles.conf for future installs
    echo
    echo -e "${BLUE}Tip:${NC} Add these to dotfiles.conf for future installs:"
    echo "  USER_FULLNAME=\"$fullname\""
    echo "  USER_EMAIL=\"$email\""
    [[ -n "$github" ]] && echo "  USER_GITHUB=\"$github\""
}

install_packages() {
    print_step "Installing espanso packages"

    echo
    echo "Available packages to install:"
    echo "  1. emoji - Emoji snippets (e.g., :smile: → 😊)"
    echo "  2. greek-letters - Greek letters (e.g., :alpha: → α)"
    echo "  3. math - Math symbols (e.g., :sum: → ∑)"
    echo

    if ask_yes_no "Install emoji package?"; then
        espanso install emoji --force
        print_success "Emoji package installed"
    fi

    if ask_yes_no "Install greek-letters package?"; then
        espanso install greek-letters --force
        print_success "Greek letters package installed"
    fi

    if ask_yes_no "Install math package?"; then
        espanso install math --force
        print_success "Math package installed"
    fi
}

list_installed_packages() {
    print_step "Installed espanso packages"
    echo
    espanso package list
    echo
}

show_usage_tips() {
    print_step "Usage tips"

    cat << EOF

${GREEN}Espanso Quick Start:${NC}

${YELLOW}Toggle espanso on/off:${NC}
  ALT+SHIFT+E

${YELLOW}Open search menu:${NC}
  ALT+SPACE

${YELLOW}Basic triggers:${NC}
  ..date      → Current date (YYYY-MM-DD)
  ..time      → Current time (HH:MM:SS)
  ..shrug     → ¯\\_(ツ)_/¯
  ..gstat     → git status
  ..myemail   → Your email

${YELLOW}Espanso commands:${NC}
  espanso status    - Check if running
  espanso restart   - Restart service
  espanso log       - View logs

${YELLOW}Configuration files:${NC}
  ~/.config/espanso/match/base.yml       - Main snippets
  ~/.config/espanso/match/personal.yml   - Your personal snippets

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header

    check_espanso
    show_espanso_status

    echo
    if ask_yes_no "Personalize your configuration?"; then
        personalize_config
    fi

    echo
    if ask_yes_no "Install additional espanso packages?"; then
        install_packages
    fi

    echo
    list_installed_packages

    echo
    show_usage_tips

    echo
    print_success "Espanso setup complete!"
    echo
    echo "Try typing ${YELLOW}..date${NC} in any application to test it!"
}

main "$@"
