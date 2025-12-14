#!/usr/bin/env bash
# ============================================================================
# ADLee's Dotfiles Installation Script
# ============================================================================
# Quick install: curl -fsSL https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main/install.sh | bash
# Or: git clone https://github.com/adlee-was-taken/dotfiles.git && cd dotfiles && ./install.sh

set -e

# ============================================================================
# Configuration
# ============================================================================

DOTFILES_REPO="https://github.com/adlee-was-taken/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ADLee's Dotfiles Installation                           ${BLUE}║${NC}"
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
            #git pull origin main
            print_success "Dotfiles updated"
        fi
    else
        #git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        print_success "Dotfiles cloned to $DOTFILES_DIR"
    fi
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

    # Link adlee theme
    if [ -f "$DOTFILES_DIR/zsh/themes/adlee.zsh-theme" ]; then
        ln -sf "$DOTFILES_DIR/zsh/themes/adlee.zsh-theme" "$HOME/.oh-my-zsh/themes/adlee.zsh-theme"
        print_success "Linked: adlee.zsh-theme"
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
        if ask_yes_no "Set zsh as your default shell?"; then
            chsh -s "$(which zsh)"
            print_success "Default shell changed to zsh (restart required)"
        fi
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
            # Install required dependencies
            sudo apt-get install -y wget

            # Download and install espanso
            ESPANSO_VERSION="2.2.1"
            wget "https://github.com/espanso/espanso/releases/download/v${ESPANSO_VERSION}/espanso-debian-x11-amd64.deb" -O /tmp/espanso.deb
            sudo apt install /tmp/espanso.deb
            rm /tmp/espanso.deb

            # Register espanso as a systemd service
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
        arch)
            # Check if paru is installed, if not try to install it
            if ! command -v paru &> /dev/null; then
                print_warning "paru not found, attempting to install..."

                # Install dependencies for building paru
                sudo pacman -S --needed --noconfirm base-devel git

                # Clone and build paru
                cd /tmp
                git clone https://aur.archlinux.org/paru.git
                cd paru
                makepkg -si --noconfirm
                cd ~
                rm -rf /tmp/paru

                print_success "paru installed"
            fi

            # Install espanso using paru
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
        # Backup existing espanso config if it exists and is not a symlink
        if [ -d "$HOME/.config/espanso" ] && [ ! -L "$HOME/.config/espanso" ]; then
            if [ "$backup_needed" = false ]; then
                mkdir -p "$BACKUP_DIR"
            fi
            mv "$HOME/.config/espanso" "$BACKUP_DIR/espanso"
            print_success "Backed up existing espanso config"
        fi

        # Remove old symlink if it exists
        [ -L "$HOME/.config/espanso" ] && rm "$HOME/.config/espanso"

        # Create .config directory if it doesn't exist
        mkdir -p "$HOME/.config"

        # Create symlink
        ln -sf "$DOTFILES_DIR/espanso" "$HOME/.config/espanso"
        print_success "Linked: espanso config"

        # Restart espanso if it's running
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

    # espanso - text expander
    if ! command -v espanso &> /dev/null; then
        if ask_yes_no "Install espanso (text expander)?"; then
            install_espanso
        fi
    fi

    # fzf - fuzzy finder
    if ! command -v fzf &> /dev/null; then
        if ask_yes_no "Install fzf (fuzzy finder)?"; then
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all
            print_success "fzf installed"
        fi
    fi

    # bat - better cat
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        if ask_yes_no "Install bat (better cat)?"; then
            case "$OS" in
                ubuntu|debian)
                    sudo apt-get install -y bat
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y bat
                    ;;
                arch)
                    sudo pacman -S --noconfirm bat
                    ;;
                macos)
                    brew install bat
                    ;;
            esac
            print_success "bat installed"
        fi
    fi

    # eza - better ls
    if ! command -v eza &> /dev/null; then
        if ask_yes_no "Install eza (better ls)?"; then
            case "$OS" in
                ubuntu|debian)
                    sudo apt-get install -y eza
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y eza
                    ;;
                arch)
                    sudo pacman -S --noconfirm eza
                    ;;
                macos)
                    brew install eza
                    ;;
            esac
            print_success "eza installed"
        fi
    fi
}

# ============================================================================
# Main Installation Flow
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
        echo "  3. Customize ~/.zshrc as needed"
        echo
        echo -e "${BLUE}To update dotfiles in the future:${NC}"
        echo "  cd ~/.dotfiles && git pull && ./install.sh"
        echo
    else
        print_warning "Installation cancelled"
        exit 0
    fi
}

# Run main function
main "$@"
