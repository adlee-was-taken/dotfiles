#!/usr/bin/env bash
# ============================================================================
# ADLee's Dotfiles Installation Script
# ============================================================================
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main/install.sh | bash
# Or:
#   git clone https://github.com/adlee-was-taken/dotfiles.git && cd dotfiles && ./install.sh
#
# Fork this repo? Edit dotfiles.conf with your settings.
# ============================================================================

set -e

# ============================================================================
# Load Configuration
# ============================================================================

load_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local conf_file="${script_dir}/dotfiles.conf"

    if [[ -f "$conf_file" ]]; then
        source "$conf_file"
    else
        # Fallback defaults for curl|bash install (before clone)
        DOTFILES_GITHUB_USER="${DOTFILES_GITHUB_USER:-adlee-was-taken}"
        DOTFILES_REPO_NAME="${DOTFILES_REPO_NAME:-dotfiles}"
        DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
        DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
        DOTFILES_BACKUP_PREFIX="${DOTFILES_BACKUP_PREFIX:-$HOME/.dotfiles_backup}"
        DOTFILES_REPO_URL="https://github.com/${DOTFILES_GITHUB_USER}/${DOTFILES_REPO_NAME}.git"

        # Feature toggles
        INSTALL_ESPANSO="${INSTALL_ESPANSO:-ask}"
        INSTALL_FZF="${INSTALL_FZF:-ask}"
        INSTALL_BAT="${INSTALL_BAT:-ask}"
        INSTALL_EZA="${INSTALL_EZA:-ask}"
        SET_ZSH_DEFAULT="${SET_ZSH_DEFAULT:-ask}"

        # Theme settings
        ZSH_THEME_NAME="${ZSH_THEME_NAME:-adlee}"
    fi
}

load_config

BACKUP_DIR="${DOTFILES_BACKUP_PREFIX}_$(date +%Y%m%d_%H%M%S)"

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Dotfiles Installation                                     ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  Repo: ${DOTFILES_GITHUB_USER}/${DOTFILES_REPO_NAME}${BLUE}║${NC}"
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

# Check feature toggle setting
should_install() {
    local setting="$1"
    local name="$2"

    case "$setting" in
        true|yes|1)
            return 0
            ;;
        false|no|0)
            return 1
            ;;
        *)
            ask_yes_no "Install $name?"
            return $?
            ;;
    esac
}

# ============================================================================
# Installation Functions
# ============================================================================

detect_os() {
    print_step "Detecting operating system"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        fi
        print_success "Detected: Linux ($OS)"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "Detected: macOS"
    else
        OS="unknown"
        print_warning "Unknown OS: $OSTYPE"
    fi
}

install_dependencies() {
    print_step "Installing dependencies"

    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y git curl zsh
            ;;
        fedora|rhel|centos)
            sudo dnf install -y git curl zsh
            ;;
        arch|cachyos)
            sudo pacman -Sy --noconfirm git curl zsh
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                print_warning "Homebrew not found. Installing..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install git curl zsh
            ;;
        *)
            print_warning "Please install git, curl, and zsh manually"
            ;;
    esac

    print_success "Dependencies installed"
}

clone_or_update_dotfiles() {
    print_step "Setting up dotfiles repository"

    if [ -d "$DOTFILES_DIR" ]; then
        print_warning "Dotfiles directory already exists"
        if ask_yes_no "Update existing dotfiles?"; then
            cd "$DOTFILES_DIR"
            git pull origin "$DOTFILES_BRANCH"
            print_success "Dotfiles updated"
        fi
    else
        git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
        print_success "Dotfiles cloned to $DOTFILES_DIR"
    fi

    # Reload config after clone (now we have dotfiles.conf)
    load_config
}

backup_existing_configs() {
    print_step "Backing up existing configurations"

    local files_to_backup=(
        ".zshrc"
        ".bashrc"
        ".gitconfig"
        ".vimrc"
        ".tmux.conf"
    )

    local backup_needed=false

    for file in "${files_to_backup[@]}"; do
        if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
            if [ "$backup_needed" = false ]; then
                mkdir -p "$BACKUP_DIR"
                backup_needed=true
            fi
            cp "$HOME/$file" "$BACKUP_DIR/"
            print_success "Backed up: $file"
        fi
    done

    if [ "$backup_needed" = true ]; then
        print_success "Backups saved to: $BACKUP_DIR"
    else
        print_success "No backups needed"
    fi
}

install_oh_my_zsh() {
    print_step "Installing oh-my-zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_warning "oh-my-zsh already installed"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "oh-my-zsh installed"
    fi
}

link_dotfiles() {
    print_step "Linking dotfiles"

    # Link zshrc
    if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
        ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
        print_success "Linked: .zshrc"
    fi

    # Link theme
    if [ -f "$DOTFILES_DIR/zsh/themes/${ZSH_THEME_NAME}.zsh-theme" ]; then
        ln -sf "$DOTFILES_DIR/zsh/themes/${ZSH_THEME_NAME}.zsh-theme" "$HOME/.oh-my-zsh/themes/${ZSH_THEME_NAME}.zsh-theme"
        print_success "Linked: ${ZSH_THEME_NAME}.zsh-theme"
    fi

    # Link gitconfig
    if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
        ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
        print_success "Linked: .gitconfig"
    fi

    # Link vimrc
    if [ -f "$DOTFILES_DIR/vim/.vimrc" ]; then
        ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
        print_success "Linked: .vimrc"
    fi

    # Link tmux.conf
    if [ -f "$DOTFILES_DIR/tmux/.tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
        print_success "Linked: .tmux.conf"
    fi

    # Link bin scripts
    if [ -d "$DOTFILES_DIR/bin" ]; then
        mkdir -p "$HOME/.local/bin"
        for script in "$DOTFILES_DIR/bin"/*; do
            if [ -f "$script" ]; then
                ln -sf "$script" "$HOME/.local/bin/$(basename "$script")"
                chmod +x "$HOME/.local/bin/$(basename "$script")"
            fi
        done
        print_success "Linked: bin scripts"
    fi
}

set_zsh_default() {
    print_step "Setting zsh as default shell"

    if [ "$SHELL" != "$(which zsh)" ]; then
        case "$SET_ZSH_DEFAULT" in
            true|yes|1)
                chsh -s "$(which zsh)"
                print_success "Default shell changed to zsh (restart required)"
                ;;
            false|no|0)
                print_warning "Skipping shell change (disabled in config)"
                ;;
            *)
                if ask_yes_no "Set zsh as your default shell?"; then
                    chsh -s "$(which zsh)"
                    print_success "Default shell changed to zsh (restart required)"
                fi
                ;;
        esac
    else
        print_success "zsh is already your default shell"
    fi
}

install_espanso() {
    print_step "Installing espanso (text expander)"

    if command -v espanso &> /dev/null; then
        print_warning "espanso already installed"
        return 0
    fi

    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y wget
            ESPANSO_VERSION="2.2.1"
            wget "https://github.com/espanso/espanso/releases/download/v${ESPANSO_VERSION}/espanso-debian-x11-amd64.deb" -O /tmp/espanso.deb
            sudo apt install /tmp/espanso.deb
            rm /tmp/espanso.deb
            espanso service register
            print_success "espanso installed (X11 version)"
            ;;
        fedora|rhel|centos)
            sudo dnf install -y wget
            ESPANSO_VERSION="2.2.1"
            wget "https://github.com/espanso/espanso/releases/download/v${ESPANSO_VERSION}/espanso-fedora-x11-amd64.rpm" -O /tmp/espanso.rpm
            sudo dnf install /tmp/espanso.rpm
            rm /tmp/espanso.rpm
            espanso service register
            print_success "espanso installed"
            ;;
        arch|cachyos)
            if ! command -v paru &> /dev/null; then
                print_warning "paru not found, attempting to install..."
                sudo pacman -S --needed --noconfirm base-devel git
                cd /tmp
                git clone https://aur.archlinux.org/paru.git
                cd paru
                makepkg -si --noconfirm
                cd ~
                rm -rf /tmp/paru
                print_success "paru installed"
            fi
            paru -S --noconfirm espanso-bin
            espanso service register
            print_success "espanso installed"
            ;;
        macos)
            brew tap espanso/espanso
            brew install espanso
            espanso service register
            print_success "espanso installed"
            ;;
        *)
            print_warning "Please install espanso manually from: https://espanso.org/install/"
            return 1
            ;;
    esac
}

link_espanso_config() {
    print_step "Linking espanso configuration"

    if [ -d "$DOTFILES_DIR/espanso" ]; then
        if [ -d "$HOME/.config/espanso" ] && [ ! -L "$HOME/.config/espanso" ]; then
            mkdir -p "$BACKUP_DIR"
            mv "$HOME/.config/espanso" "$BACKUP_DIR/espanso"
            print_success "Backed up existing espanso config"
        fi

        [ -L "$HOME/.config/espanso" ] && rm "$HOME/.config/espanso"
        mkdir -p "$HOME/.config"
        ln -sf "$DOTFILES_DIR/espanso" "$HOME/.config/espanso"
        print_success "Linked: espanso config"

        if command -v espanso &> /dev/null; then
            espanso restart 2>/dev/null || true
            print_success "Restarted espanso service"
        fi
    else
        print_warning "No espanso config found in dotfiles"
    fi
}

install_optional_tools() {
    print_step "Optional tools"

    # espanso
    if ! command -v espanso &> /dev/null; then
        if should_install "$INSTALL_ESPANSO" "espanso (text expander)"; then
            install_espanso
        fi
    fi

    # fzf
    if ! command -v fzf &> /dev/null; then
        if should_install "$INSTALL_FZF" "fzf (fuzzy finder)"; then
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all
            print_success "fzf installed"
        fi
    fi

    # bat
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        if should_install "$INSTALL_BAT" "bat (better cat)"; then
            case "$OS" in
                ubuntu|debian) sudo apt-get install -y bat ;;
                fedora|rhel|centos) sudo dnf install -y bat ;;
                arch|cachyos) sudo pacman -S --noconfirm bat ;;
                macos) brew install bat ;;
            esac
            print_success "bat installed"
        fi
    fi

    # eza
    if ! command -v eza &> /dev/null; then
        if should_install "$INSTALL_EZA" "eza (better ls)"; then
            case "$OS" in
                ubuntu|debian) sudo apt-get install -y eza ;;
                fedora|rhel|centos) sudo dnf install -y eza ;;
                arch|cachyos) sudo pacman -S --noconfirm eza ;;
                macos) brew install eza ;;
            esac
            print_success "eza installed"
        fi
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header

    detect_os

    if ask_yes_no "Install/update dotfiles?"; then
        install_dependencies
        clone_or_update_dotfiles
        backup_existing_configs
        install_oh_my_zsh
        link_dotfiles
        link_espanso_config
        set_zsh_default
        install_optional_tools

        echo
        print_success "Installation complete!"
        echo
        echo -e "${BLUE}Next steps:${NC}"
        echo "  1. Restart your terminal or run: exec zsh"
        echo "  2. Your old configs are backed up in: $BACKUP_DIR"
        echo "  3. Customize settings in: $DOTFILES_DIR/dotfiles.conf"
        echo
        echo -e "${BLUE}To update dotfiles in the future:${NC}"
        echo "  cd ~/.dotfiles && git pull && ./install.sh"
        echo
    else
        print_warning "Installation cancelled"
        exit 0
    fi
}

main "$@"
