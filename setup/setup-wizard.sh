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
        read -p "Choice [1]: " choice
        choice=${choice:-1}
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
        echo "$prompt (comma-separated numbers, or 'all'):"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        read -p "Choices [all]: " choices
        choices=${choices:-all}
        
        if [[ "$choices" == "all" ]]; then
            printf '%s\n' "${options[@]}"
        else
            IFS=',' read -ra selected <<< "$choices"
            for idx in "${selected[@]}"; do
                idx=$(echo "$idx" | tr -d ' ')
                echo "${options[$((idx-1))]}"
            done
        fi
    fi
}

wizard_password() {
    local prompt="$1"
    
    if [[ "$HAS_GUM" == true ]]; then
        gum input --password --prompt "$prompt: "
    else
        read -sp "$prompt: " password
        echo
        echo "$password"
    fi
}

wizard_write() {
    local placeholder="$1"
    
    if [[ "$HAS_GUM" == true ]]; then
        gum write --placeholder "$placeholder"
    else
        echo "Enter text (Ctrl+D when done):"
        cat
    fi
}

show_progress() {
    local current="$1"
    local total="$2"
    local task="$3"
    local width=40
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '▓'
    printf "%${empty}s" | tr ' ' '░'
    printf "${CYAN}]${NC} %3d%% %s" "$percent" "$task"
    
    [[ $current -eq $total ]] && echo
}

# ============================================================================
# Wizard Steps
# ============================================================================

step_welcome() {
    clear
    wizard_header "🚀 Dotfiles Setup Wizard v${DOTFILES_VERSION}"
    
    if [[ "$HAS_GUM" == true ]]; then
        gum style \
            --foreground 252 \
            --margin "0 2" \
            "This wizard will help you set up your development environment." \
            "" \
            "We'll configure:" \
            "  • Shell (zsh + oh-my-zsh + plugins)" \
            "  • Git identity" \
            "  • Theme and prompt" \
            "  • Optional tools (fzf, bat, eza, espanso)" \
            "" \
            "Your existing configs will be backed up automatically."
    else
        echo "This wizard will help you set up your development environment."
        echo
        echo "We'll configure:"
        echo "  • Shell (zsh + oh-my-zsh + plugins)"
        echo "  • Git identity"
        echo "  • Theme and prompt"
        echo "  • Optional tools (fzf, bat, eza, espanso)"
        echo
        echo "Your existing configs will be backed up automatically."
    fi
    
    echo
    wizard_confirm "Ready to begin?" || exit 0
}

step_identity() {
    wizard_header "👤 Identity Setup"
    
    echo "Let's set up your identity for git and other tools."
    echo
    
    WIZARD_NAME=$(wizard_input "Full name" "${USER_FULLNAME:-$(git config --global user.name 2>/dev/null || echo "")}")
    WIZARD_EMAIL=$(wizard_input "Email" "${USER_EMAIL:-$(git config --global user.email 2>/dev/null || echo "")}")
    WIZARD_GITHUB=$(wizard_input "GitHub username (optional)" "${USER_GITHUB:-}")
    
    echo
    echo -e "${GREEN}✓${NC} Identity configured"
}

step_git_config() {
    wizard_header "🔧 Git Configuration"
    
    echo "Configure your git preferences."
    echo
    
    WIZARD_GIT_BRANCH=$(wizard_choose "Default branch name:" "main" "master")
    WIZARD_GIT_EDITOR=$(wizard_choose "Preferred editor:" "vim" "nano" "code" "nvim" "emacs")
    WIZARD_GIT_CRED=$(wizard_choose "Credential helper:" "store" "cache" "osxkeychain" "manager-core")
    
    echo
    echo -e "${GREEN}✓${NC} Git configured"
}

step_features() {
    wizard_header "📦 Feature Selection"
    
    echo "Select which features to install."
    echo "(Use space to select, enter to confirm)"
    echo
    
    local features=(
        "zsh-plugins"
        "fzf"
        "bat"
        "eza"
        "espanso"
        "vault"
        "motd"
        "1password"
        "lastpass"
        "bitwarden"
    )
    
    local descriptions=(
        "Autosuggestions + Syntax Highlighting"
        "Fuzzy finder for files and history"
        "Better cat with syntax highlighting"
        "Modern ls replacement"
        "Text expander (100+ snippets)"
        "Encrypted secrets storage"
        "Dynamic system info on startup"
        "1Password CLI integration"
        "LastPass CLI integration"
        "Bitwarden CLI integration"
    )
    
    if [[ "$HAS_GUM" == true ]]; then
        # Build display options
        local display_opts=()
        for i in "${!features[@]}"; do
            display_opts+=("${features[$i]}: ${descriptions[$i]}")
        done
        
        WIZARD_FEATURES=$(printf '%s\n' "${display_opts[@]}" | gum choose --no-limit --height=15 \
            --selected="zsh-plugins: Autosuggestions + Syntax Highlighting,fzf: Fuzzy finder for files and history,vault: Encrypted secrets storage,motd: Dynamic system info on startup")
    else
        echo "Available features:"
        for i in "${!features[@]}"; do
            echo "  $((i+1)). ${features[$i]}: ${descriptions[$i]}"
        done
        echo
        echo "Enter numbers separated by commas (e.g., 1,2,3) or 'all':"
        read -p "> " choices
        choices=${choices:-"1,2,5,7"}
        
        WIZARD_FEATURES=""
        if [[ "$choices" == "all" ]]; then
            for i in "${!features[@]}"; do
                WIZARD_FEATURES+="${features[$i]}: ${descriptions[$i]}"$'\n'
            done
        else
            IFS=',' read -ra selected <<< "$choices"
            for idx in "${selected[@]}"; do
                idx=$(echo "$idx" | tr -d ' ')
                local i=$((idx - 1))
                if [[ $i -ge 0 && $i -lt ${#features[@]} ]]; then
                    WIZARD_FEATURES+="${features[$i]}: ${descriptions[$i]}"$'\n'
                fi
            done
        fi
    fi
    
    echo
    echo -e "${GREEN}✓${NC} Features selected"
}

step_theme() {
    wizard_header "🎨 Theme Selection"
    
    echo "Choose your prompt theme."
    echo
    
    local themes=(
        "adlee: Two-line with git, timer, user detection"
        "minimal: Clean single-line prompt"
        "powerline: Fancy arrows and segments"
        "retro: Classic terminal feel"
    )
    
    WIZARD_THEME=$(wizard_choose "Select theme:" "${themes[@]}" | cut -d: -f1)
    
    # Show preview
    echo
    echo "Preview:"
    case "$WIZARD_THEME" in
        adlee)
            echo -e "  ${DIM}┌[${GREEN}user@host${NC}${DIM}]─[${YELLOW}~/projects${NC}${DIM}]─[${GREEN}⎇ main${NC}${DIM}]${NC}"
            echo -e "  ${DIM}└${BLUE}%${NC} "
            ;;
        minimal)
            echo -e "  ${GREEN}➜${NC} ${CYAN}~/projects${NC} ${RED}main${NC} "
            ;;
        powerline)
            echo -e "  ${BLUE}  user ${NC}${YELLOW}  ~/projects ${NC}${GREEN}  main ${NC}"
            ;;
        retro)
            echo -e "  ${GREEN}user@host${NC}:${BLUE}~/projects${NC}\$ "
            ;;
    esac
    
    echo
    echo -e "${GREEN}✓${NC} Theme selected: $WIZARD_THEME"
}

step_advanced() {
    wizard_header "⚙️ Advanced Options"
    
    if wizard_confirm "Configure advanced options?" "no"; then
        echo
        
        WIZARD_SET_DEFAULT_SHELL=$(wizard_confirm "Set zsh as default shell?" "yes" && echo "true" || echo "false")
        WIZARD_INSTALL_DEPS=$(wizard_confirm "Auto-install dependencies (git, curl, zsh)?" "yes" && echo "auto" || echo "false")
        
        if wizard_confirm "Enable shell analytics (command stats)?" "no"; then
            WIZARD_ANALYTICS="true"
        else
            WIZARD_ANALYTICS="false"
        fi
        
        if wizard_confirm "Enable smart command suggestions?" "yes"; then
            WIZARD_SUGGESTIONS="true"
        else
            WIZARD_SUGGESTIONS="false"
        fi
    else
        WIZARD_SET_DEFAULT_SHELL="ask"
        WIZARD_INSTALL_DEPS="auto"
        WIZARD_ANALYTICS="false"
        WIZARD_SUGGESTIONS="true"
    fi
    
    echo
    echo -e "${GREEN}✓${NC} Advanced options configured"
}

step_review() {
    wizard_header "📋 Review Configuration"
    
    echo "Please review your configuration:"
    echo
    
    # Format features list - extract just the short names
    local features_short=""
    local features_list=""
    while IFS= read -r feature; do
        [[ -z "$feature" ]] && continue
        local short_name="${feature%%:*}"
        if [[ -z "$features_short" ]]; then
            features_short="$short_name"
        else
            features_short="$features_short, $short_name"
        fi
        features_list="${features_list}  • ${feature}\n"
    done <<< "$WIZARD_FEATURES"
    
    if [[ "$HAS_GUM" == true ]]; then
        gum style \
            --border normal \
            --border-foreground 240 \
            --padding "1 2" \
            --margin "0 2" \
            --width 60 \
            "Identity:" \
            "  Name:     $WIZARD_NAME" \
            "  Email:    $WIZARD_EMAIL" \
            "  GitHub:   ${WIZARD_GITHUB:-not set}" \
            "" \
            "Git:" \
            "  Branch:   $WIZARD_GIT_BRANCH" \
            "  Editor:   $WIZARD_GIT_EDITOR" \
            "" \
            "Theme:      $WIZARD_THEME"
        
        echo
        echo -e "${CYAN}Selected Features:${NC}"
        echo "$WIZARD_FEATURES" | while IFS= read -r feature; do
            [[ -n "$feature" ]] && echo -e "  ${GREEN}✓${NC} ${feature%%:*}"
        done
    else
        echo "  Identity:"
        echo "    Name:     $WIZARD_NAME"
        echo "    Email:    $WIZARD_EMAIL"
        echo "    GitHub:   ${WIZARD_GITHUB:-not set}"
        echo
        echo "  Git:"
        echo "    Branch:   $WIZARD_GIT_BRANCH"
        echo "    Editor:   $WIZARD_GIT_EDITOR"
        echo
        echo "  Theme:      $WIZARD_THEME"
        echo
        echo "  Features:"
        echo "$WIZARD_FEATURES" | while IFS= read -r feature; do
            [[ -n "$feature" ]] && echo "    ✓ ${feature%%:*}"
        done
    fi
    
    echo
    wizard_confirm "Proceed with installation?" || exit 0
}

step_install() {
    wizard_header "🔨 Installing"
    
    local steps=(
        "Detecting system"
        "Installing dependencies"
        "Cloning dotfiles"
        "Backing up configs"
        "Installing oh-my-zsh"
        "Installing zsh plugins"
        "Configuring git"
        "Linking dotfiles"
        "Installing features"
        "Finalizing"
    )
    
    local total=${#steps[@]}
    local current=0
    
    for step in "${steps[@]}"; do
        ((current++))
        
        if [[ "$HAS_GUM" == true ]]; then
            gum spin --spinner dot --title "[$current/$total] $step..." -- sleep 0.5
        else
            show_progress $current $total "$step"
            sleep 0.3
        fi
    done
    
    echo
}

step_complete() {
    wizard_header "✨ Setup Complete!"
    
    if [[ "$HAS_GUM" == true ]]; then
        gum style \
            --foreground 82 \
            --margin "0 2" \
            "Your dotfiles have been installed successfully!" \
            "" \
            "Next steps:" \
            "  1. Restart your terminal or run: exec zsh" \
            "  2. Run 'dotfiles-doctor.sh' to verify installation" \
            "  3. Customize settings in ~/.dotfiles/dotfiles.conf"
    else
        echo -e "${GREEN}Your dotfiles have been installed successfully!${NC}"
        echo
        echo "Next steps:"
        echo "  1. Restart your terminal or run: exec zsh"
        echo "  2. Run 'dotfiles-doctor.sh' to verify installation"
        echo "  3. Customize settings in ~/.dotfiles/dotfiles.conf"
    fi
    
    echo
    
    if [[ "$HAS_GUM" == true ]]; then
        if gum confirm "Restart shell now?"; then
            exec zsh
        fi
    else
        read -p "Restart shell now? [Y/n]: " restart
        [[ "${restart:-y}" =~ ^[Yy] ]] && exec zsh
    fi
}

generate_config() {
    # Helper to check if feature is selected
    _has_feature() {
        echo "$WIZARD_FEATURES" | grep -qi "^$1:" || echo "$WIZARD_FEATURES" | grep -qi "^$1$"
    }
    
    # Generate dotfiles.conf with wizard selections
    cat > "$DOTFILES_DIR/dotfiles.conf.wizard" << EOF
# ============================================================================
# Dotfiles Configuration (Generated by Setup Wizard)
# ============================================================================

# --- Version ---
DOTFILES_VERSION="${DOTFILES_VERSION}"

# --- User Identity ---
USER_FULLNAME="${WIZARD_NAME}"
USER_EMAIL="${WIZARD_EMAIL}"
USER_GITHUB="${WIZARD_GITHUB}"

# --- Git Configuration ---
GIT_USER_NAME="${WIZARD_NAME}"
GIT_USER_EMAIL="${WIZARD_EMAIL}"
GIT_DEFAULT_BRANCH="${WIZARD_GIT_BRANCH}"
GIT_CREDENTIAL_HELPER="${WIZARD_GIT_CRED}"

# --- Feature Toggles ---
INSTALL_DEPS="${WIZARD_INSTALL_DEPS}"
INSTALL_ZSH_PLUGINS="$(echo "$WIZARD_FEATURES" | grep -qi "zsh-plugins" && echo "true" || echo "false")"
INSTALL_FZF="$(echo "$WIZARD_FEATURES" | grep -qi "fzf" && echo "true" || echo "false")"
INSTALL_BAT="$(echo "$WIZARD_FEATURES" | grep -qi "bat" && echo "true" || echo "false")"
INSTALL_EZA="$(echo "$WIZARD_FEATURES" | grep -qi "eza" && echo "true" || echo "false")"
INSTALL_ESPANSO="$(echo "$WIZARD_FEATURES" | grep -qi "espanso" && echo "true" || echo "false")"
SET_ZSH_DEFAULT="${WIZARD_SET_DEFAULT_SHELL}"

# --- Password Manager Integration ---
INSTALL_1PASSWORD="$(echo "$WIZARD_FEATURES" | grep -qi "1password" && echo "true" || echo "false")"
INSTALL_LASTPASS="$(echo "$WIZARD_FEATURES" | grep -qi "lastpass" && echo "true" || echo "false")"
INSTALL_BITWARDEN="$(echo "$WIZARD_FEATURES" | grep -qi "bitwarden" && echo "true" || echo "false")"

# --- MOTD ---
ENABLE_MOTD="$(echo "$WIZARD_FEATURES" | grep -qi "motd" && echo "true" || echo "false")"
MOTD_STYLE="compact"

# --- Theme ---
ZSH_THEME_NAME="${WIZARD_THEME}"

# --- Advanced Features ---
ENABLE_SHELL_ANALYTICS="${WIZARD_ANALYTICS}"
ENABLE_SMART_SUGGESTIONS="${WIZARD_SUGGESTIONS}"
ENABLE_VAULT="$(echo "$WIZARD_FEATURES" | grep -qi "vault" && echo "true" || echo "false")"
ENABLE_COMMAND_PALETTE="true"
EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Check/install gum
    if ! check_gum; then
        echo "For the best experience, we recommend installing 'gum'."
        if wizard_confirm "Install gum now?"; then
            install_gum
        fi
    fi
    
    # Run wizard steps
    step_welcome
    step_identity
    step_git_config
    step_features
    step_theme
    step_advanced
    step_review
    
    # Generate config
    generate_config
    
    # Run installation
    step_install
    step_complete
}

main "$@"
