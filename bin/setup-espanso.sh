#!/usr/bin/env bash
# ============================================================================
# Espanso Setup and Configuration Script
# ============================================================================
# This script helps set up espanso with custom configurations

set -e

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
        print_error "Personal config file not found: $personal_file"
        return 1
    fi

    echo
    echo "Let's personalize your espanso configuration!"
    echo

    read -p "Your full name: " fullname
    read -p "Your email: " email
    read -p "Your phone (optional): " phone
    read -p "Your website (optional): " website
    read -p "Your GitHub username (optional): " github

    # Create a backup
    cp "$personal_file" "$personal_file.backup"

    # Update the personal.yml file
    sed -i "s/your.email@example.com/$email/g" "$personal_file"
    sed -i "s/Your Full Name/$fullname/g" "$personal_file"

    if [ -n "$phone" ]; then
        sed -i "s/+1 (555) 123-4567/$phone/g" "$personal_file"
    fi

    if [ -n "$website" ]; then
        sed -i "s|https://yourwebsite.com|$website|g" "$personal_file"
    fi

    if [ -n "$github" ]; then
        sed -i "s/yourusername/$github/g" "$personal_file"
    fi

    print_success "Personal configuration updated!"
    print_warning "Backup saved to: $personal_file.backup"
}

install_packages() {
    print_step "Installing espanso packages"

    echo
    echo "Available packages to install:"
    echo "  1. emoji - Emoji snippets (e.g., :smile: → 😊)"
    echo "  2. greek-letters - Greek letters (e.g., :alpha: → α)"
    echo "  3. math - Math symbols (e.g., :sum: → ∑)"
    echo "  4. accents - Accented characters"
    echo "  5. all-emojis - Complete emoji collection"
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

${YELLOW}Basic triggers (from base.yml):${NC}
  :date       → Current date (YYYY-MM-DD)
  :time       → Current time (HH:MM:SS)
  :datetime   → Full datetime
  :shrug      → ¯\\_(ツ)_/¯
  :flip       → (╯°□°)╯︵ ┻━┻

${YELLOW}Code snippets:${NC}
  :bash       → Bash script template
  :python     → Python script template
  :mdcode     → Markdown code block

${YELLOW}Git shortcuts:${NC}
  :gst        → git status
  :gco        → git checkout
  :gcm        → git commit -m ""

${YELLOW}Personal (customize in personal.yml):${NC}
  :myemail    → Your email
  :myname     → Your name
  :sig        → Email signature

${YELLOW}Espanso commands:${NC}
  espanso status              - Check if running
  espanso restart             - Restart service
  espanso edit                - Edit config
  espanso log                 - View logs
  espanso package list        - List installed packages
  espanso package install X   - Install package

${YELLOW}Configuration files:${NC}
  ~/.config/espanso/config/default.yml   - Main config
  ~/.config/espanso/match/base.yml       - Base snippets
  ~/.config/espanso/match/personal.yml   - Personal snippets

${GREEN}Create your own snippets!${NC}
Edit the YAML files above to add custom triggers.

EOF
}

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
    echo "Try typing ${YELLOW}:date${NC} in any application to test it!"
}

main "$@"
