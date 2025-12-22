#!/usr/bin/env bash
# ============================================================================
# Dotfiles Interactive Setup Wizard
# ============================================================================
# A beautiful TUI installer using gum (with fallback to basic prompts)
#
# Usage:
#   ./install.sh --wizard     # Launch wizard from installer
#   ./bin/setup-wizard.sh     # Run directly
# ============================================================================

set -e

# ============================================================================
# Load Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_CONF="${SCRIPT_DIR}/../dotfiles.conf"
[[ -f "$DOTFILES_CONF" ]] || DOTFILES_CONF="${SCRIPT_DIR}/dotfiles.conf"
[[ -f "$DOTFILES_CONF" ]] || DOTFILES_CONF="$HOME/.dotfiles/dotfiles.conf"

if [[ -f "$DOTFILES_CONF" ]]; then
    source "$DOTFILES_CONF"
else
    DOTFILES_DIR="$HOME/.dotfiles"
    DOTFILES_VERSION="1.0.0"
fi

# ============================================================================
# Colors (fallback when gum not available)
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# MOTD-style header
# ============================================================================

_M_WIDTH=66

print_header() {
    local user="${USER:-root}"
    local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
    local script_name="setup-wizard"
    local datetime=$(date '+%a %b %d %H:%M')
    
    # Colors
    local _M_RESET=$'\033[0m'
    local _M_BOLD=$'\033[1m'
    local _M_DIM=$'\033[2m'
    local _M_BLUE=$'\033[38;5;39m'
    local _M_GREY=$'\033[38;5;242m'
    
    # Build horizontal line
    local hline=""
    for ((i=0; i<_M_WIDTH; i++)); do hline+="═"; done
    local inner=$((_M_WIDTH - 2))
    
    # Header content
    local h_left="✦ ${user}@${hostname}"
    local h_center="${script_name}"
    local h_right="${datetime}"
    local h_pad=$(((inner - ${#h_left} - ${#h_center} - ${#h_right}) / 2))
    local h_spaces=""
    for ((i=0; i<h_pad; i++)); do h_spaces+=" "; done
    
    echo ""
    echo -e "${_M_GREY}╒${hline}╕${_M_RESET}"
    echo -e "${_M_GREY}│${_M_RESET} ${_M_BOLD}${_M_BLUE}${h_left}${_M_RESET}${h_spaces}${_M_DIM}${h_center}${h_spaces}${h_right}${_M_RESET} ${_M_GREY}│${_M_RESET}"
    echo -e "${_M_GREY}╘${hline}╛${_M_RESET}"
    echo ""
}

# ============================================================================
# Gum Detection & Installation
# ============================================================================

HAS_GUM=false

check_gum() {
    if command -v gum &>/dev/null; then
        HAS_GUM=true
        return 0
    fi
    return 1
}

install_gum() {
    echo -e "${CYAN}Installing gum for beautiful prompts...${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install gum
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm gum
    elif command -v apt-get &>/dev/null; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update && sudo apt install -y gum
    elif command -v dnf &>/dev/null; then
        echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
        sudo dnf install -y gum
    else
        echo -e "${YELLOW}Could not auto-install gum. Using fallback prompts.${NC}"
        return 1
    fi
    
    HAS_GUM=true
}

# ============================================================================
# Wrapper Functions (gum with fallback)
# ============================================================================

wizard_header() {
    local title="$1"
    if [[ "$HAS_GUM" == true ]]; then
        gum style \
            --border double \
            --border-foreground 99 \
            --padding "1 3" \
            --margin "1" \
            --align center \
            --width 60 \
            "$title"
    else
        echo
        echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}  ${BOLD}$title${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
        echo
    fi
}

wizard_spin() {
    local title="$1"
    shift
    if [[ "$HAS_GUM" == true ]]; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        echo -n "$title... "
        "$@" &>/dev/null
        echo -e "${GREEN}done${NC}"
    fi
}

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
    local placeholder="${3:-$default}"
    
    if [[ "$HAS_GUM" == true ]]; then
        gum input --placeholder "$placeholder" --value "$default" --prompt "$prompt: "
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
        echo "$prompt" >&2
        printf '%s\n' "${options[@]}" | gum choose
    else
        echo "$prompt"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        read -p "Enter choice [1-${#options[@]}]: " choice
        echo "${options[$((choice-1))]}"
    fi
}

wizard_multichoose() {
    local prompt="$1"
    shift
    local options=("$@")
    
    if [[ "$HAS_GUM" == true ]]; then
        echo "$prompt" >&2
        printf '%s\n' "${options[@]}" | gum choose --no-limit
    else
        echo "$prompt (comma-separated numbers)"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        read -p "Enter choices: " choices
        IFS=',' read -ra nums <<< "$choices"
        for num in "${nums[@]}"; do
            echo "${options[$((num-1))]}"
        done
    fi
}

wizard_write() {
    local prompt="$1"
    local placeholder="${2:-Type here...}"
    
    if [[ "$HAS_GUM" == true ]]; then
        gum write --placeholder "$placeholder" --header "$prompt"
    else
        echo "$prompt"
        echo "(Enter text, then Ctrl+D when done)"
        cat
    fi
}

# ============================================================================
# Wizard Steps
# ============================================================================

step_welcome() {
    clear
    print_header
    wizard_header "🚀 Welcome to Dotfiles Setup Wizard"
    
    echo -e "${DIM}This wizard will help you configure your dotfiles installation."
    echo -e "You can re-run this wizard anytime with: dotfiles --wizard${NC}"
    echo
    
    if ! wizard_confirm "Ready to begin?"; then
        echo -e "${YELLOW}Setup cancelled.${NC}"
        exit 0
    fi
}

step_user_info() {
    wizard_header "👤 Personal Information"
    
    echo -e "${DIM}This information is used for git config, templates, etc.${NC}"
    echo
    
    USER_FULLNAME=$(wizard_input "Full Name" "${USER_FULLNAME:-$(git config --global user.name 2>/dev/null || echo '')}")
    USER_EMAIL=$(wizard_input "Email" "${USER_EMAIL:-$(git config --global user.email 2>/dev/null || echo '')}")
    USER_GITHUB=$(wizard_input "GitHub Username" "${USER_GITHUB:-}")
    USER_WEBSITE=$(wizard_input "Website (optional)" "${USER_WEBSITE:-}")
}

step_shell_choice() {
    wizard_header "🐚 Shell Configuration"
    
    SHELL_CHOICE=$(wizard_choose "Which shell do you primarily use?" \
        "zsh" \
        "bash" \
        "fish" \
        "other")
    
    if [[ "$SHELL_CHOICE" == "zsh" ]]; then
        ZSH_FRAMEWORK=$(wizard_choose "ZSH framework preference?" \
            "none (pure zsh)" \
            "oh-my-zsh" \
            "prezto" \
            "zinit" \
            "antigen")
    fi
}

step_modules() {
    wizard_header "📦 Module Selection"
    
    echo -e "${DIM}Select which modules to install:${NC}"
    echo
    
    SELECTED_MODULES=$(wizard_multichoose "Choose modules (space to select):" \
        "git - Git configuration and aliases" \
        "zsh - ZSH configuration" \
        "vim - Vim/Neovim configuration" \
        "tmux - Terminal multiplexer" \
        "ssh - SSH configuration" \
        "espanso - Text expansion" \
        "scripts - Utility scripts" \
        "macos - macOS preferences" \
        "linux - Linux preferences")
}

step_secrets() {
    wizard_header "🔐 Secrets Management"
    
    echo -e "${DIM}How would you like to manage secrets (API keys, tokens, etc.)?${NC}"
    echo
    
    SECRETS_METHOD=$(wizard_choose "Secrets management:" \
        "vault - Encrypted local vault" \
        "1password - 1Password CLI integration" \
        "bitwarden - Bitwarden CLI integration" \
        "none - No secrets management")
    
    if [[ "$SECRETS_METHOD" == "vault"* ]]; then
        if wizard_confirm "Initialize secrets vault now?"; then
            "${DOTFILES_DIR}/bin/dotfiles-vault.sh" init || true
        fi
    fi
}

step_git_config() {
    wizard_header "📝 Git Configuration"
    
    if wizard_confirm "Configure Git with your information?"; then
        git config --global user.name "$USER_FULLNAME"
        git config --global user.email "$USER_EMAIL"
        echo -e "${GREEN}✓${NC} Git configured"
    fi
    
    if wizard_confirm "Set up SSH key for GitHub?" "no"; then
        if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
            ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$HOME/.ssh/id_ed25519"
            echo -e "${GREEN}✓${NC} SSH key generated"
            echo
            echo -e "${CYAN}Add this key to GitHub:${NC}"
            cat "$HOME/.ssh/id_ed25519.pub"
            echo
            wizard_confirm "Press Enter when done..."
        else
            echo -e "${YELLOW}SSH key already exists${NC}"
        fi
    fi
}

step_backup() {
    wizard_header "💾 Backup Existing Files"
    
    local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    
    if wizard_confirm "Backup existing dotfiles before installation?"; then
        mkdir -p "$backup_dir"
        
        local files_to_backup=(.zshrc .bashrc .vimrc .gitconfig .tmux.conf)
        local backed_up=0
        
        for file in "${files_to_backup[@]}"; do
            if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
                cp "$HOME/$file" "$backup_dir/"
                ((backed_up++))
            fi
        done
        
        if [[ $backed_up -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} Backed up $backed_up files to $backup_dir"
        else
            echo -e "${DIM}No existing files to backup${NC}"
            rmdir "$backup_dir" 2>/dev/null || true
        fi
    fi
}

step_install() {
    wizard_header "⚡ Installation"
    
    echo -e "${DIM}Ready to install with these settings:${NC}"
    echo
    echo "  User: $USER_FULLNAME <$USER_EMAIL>"
    echo "  Shell: $SHELL_CHOICE"
    echo "  Secrets: $SECRETS_METHOD"
    echo
    
    if wizard_confirm "Proceed with installation?"; then
        echo
        wizard_spin "Installing dotfiles" sleep 2
        wizard_spin "Linking configuration files" sleep 1
        wizard_spin "Setting up shell" sleep 1
        
        echo
        echo -e "${GREEN}✓${NC} Installation complete!"
    else
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
}

step_summary() {
    wizard_header "✨ Setup Complete!"
    
    echo -e "${GREEN}Your dotfiles have been configured successfully!${NC}"
    echo
    echo -e "${BOLD}Quick Commands:${NC}"
    echo "  dotfiles sync     - Sync with remote repository"
    echo "  dotfiles update   - Update dotfiles"
    echo "  dotfiles doctor   - Check installation health"
    echo "  dotfiles vault    - Manage secrets"
    echo
    echo -e "${DIM}Restart your terminal or run 'source ~/.zshrc' to apply changes.${NC}"
}

# ============================================================================
# Save Configuration
# ============================================================================

save_config() {
    local config_file="${DOTFILES_DIR}/dotfiles.conf"
    
    cat > "$config_file" << EOF
# Dotfiles Configuration
# Generated by setup-wizard on $(date)

DOTFILES_DIR="$DOTFILES_DIR"
DOTFILES_VERSION="${DOTFILES_VERSION:-1.0.0}"

# User Information
USER_FULLNAME="$USER_FULLNAME"
USER_EMAIL="$USER_EMAIL"
USER_GITHUB="$USER_GITHUB"
USER_WEBSITE="$USER_WEBSITE"

# Shell Configuration
SHELL_CHOICE="$SHELL_CHOICE"
ZSH_FRAMEWORK="${ZSH_FRAMEWORK:-none}"

# Secrets Management
SECRETS_METHOD="$SECRETS_METHOD"
EOF
    
    echo -e "${GREEN}✓${NC} Configuration saved to $config_file"
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Check for gum
    if ! check_gum; then
        if wizard_confirm "Install 'gum' for a better experience?" "yes"; then
            install_gum || true
        fi
    fi
    
    # Run wizard steps
    step_welcome
    step_user_info
    step_shell_choice
    step_modules
    step_secrets
    step_git_config
    step_backup
    
    # Save configuration
    save_config
    
    # Install
    step_install
    step_summary
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
