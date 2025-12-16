#!/usr/bin/env bash
# ============================================================================
# ADLee's Dotfiles Installation Script
# ============================================================================
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main/install.sh | bash
# Or:
#   git clone https://github.com/adlee-was-taken/dotfiles.git && cd dotfiles && ./install.sh
#
# Options:
#   --skip-deps    Skip dependency installation (for re-runs)
#   --deps-only    Only install dependencies, then exit
#   --uninstall    Remove symlinks and optionally restore backups
#   --help         Show help
#
# Fork this repo? Edit dotfiles.conf with your settings.
# ============================================================================

set -e

# ============================================================================
# Command Line Options
# ============================================================================

SKIP_DEPS=false
DEPS_ONLY=false
UNINSTALL=false
UNINSTALL_PURGE=false

for arg in "$@"; do
    case "$arg" in
        --skip-deps)
            SKIP_DEPS=true
            ;;
        --deps-only)
            DEPS_ONLY=true
            ;;
        --uninstall)
            UNINSTALL=true
            ;;
        --purge)
            UNINSTALL_PURGE=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --skip-deps    Skip dependency installation (useful for re-runs)"
            echo "  --deps-only    Only install dependencies, then exit"
            echo "  --uninstall    Remove symlinks and restore backups"
            echo "  --purge        With --uninstall, also remove ~/.dotfiles directory"
            echo "  --help         Show this help message"
            echo
            echo "Configuration:"
            echo "  Edit dotfiles.conf to customize installation behavior"
            echo "  Set INSTALL_DEPS=\"false\" to always skip dependencies"
            echo
            echo "Examples:"
            echo "  ./install.sh                    # Full install"
            echo "  ./install.sh --skip-deps        # Re-run without checking deps"
            echo "  ./install.sh --uninstall        # Remove symlinks"
            echo "  ./install.sh --uninstall --purge # Remove everything"
            echo
            exit 0
            ;;
    esac
done

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
        DOTFILES_VERSION="${DOTFILES_VERSION:-1.0.0}"
        DOTFILES_GITHUB_USER="${DOTFILES_GITHUB_USER:-adlee-was-taken}"
        DOTFILES_REPO_NAME="${DOTFILES_REPO_NAME:-dotfiles}"
        DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
        DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
        DOTFILES_BACKUP_PREFIX="${DOTFILES_BACKUP_PREFIX:-$HOME/.dotfiles_backup}"
        DOTFILES_REPO_URL="https://github.com/${DOTFILES_GITHUB_USER}/${DOTFILES_REPO_NAME}.git"

        # Feature toggles
        INSTALL_DEPS="${INSTALL_DEPS:-auto}"
        INSTALL_ZSH_PLUGINS="${INSTALL_ZSH_PLUGINS:-true}"
        INSTALL_ESPANSO="${INSTALL_ESPANSO:-ask}"
        INSTALL_FZF="${INSTALL_FZF:-ask}"
        INSTALL_BAT="${INSTALL_BAT:-ask}"
        INSTALL_EZA="${INSTALL_EZA:-ask}"
        SET_ZSH_DEFAULT="${SET_ZSH_DEFAULT:-ask}"

        # Theme settings
        ZSH_THEME_NAME="${ZSH_THEME_NAME:-adlee}"

        # Git settings
        GIT_USER_NAME="${GIT_USER_NAME:-}"
        GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
        GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-master}"
        GIT_CREDENTIAL_HELPER="${GIT_CREDENTIAL_HELPER:-store}"
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
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Dotfiles Installation  ${CYAN}v${DOTFILES_VERSION}${NC}                          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  Repo: ${DOTFILES_GITHUB_USER}/${DOTFILES_REPO_NAME}                        ${BLUE}║${NC}"
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
# Uninstall Function
# ============================================================================

do_uninstall() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Dotfiles Uninstallation                                   ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

    print_step "Removing symlinks"

    local symlinks=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.tmux.conf"
        "$HOME/.oh-my-zsh/themes/${ZSH_THEME_NAME:-adlee}.zsh-theme"
        "$HOME/.config/espanso"
    )

    for link in "${symlinks[@]}"; do
        if [[ -L "$link" ]]; then
            rm "$link"
            print_success "Removed: $link"
        elif [[ -e "$link" ]]; then
            print_warning "Not a symlink (skipped): $link"
        fi
    done

    # Remove bin symlinks
    if [[ -d "$HOME/.local/bin" ]]; then
        for script in "$HOME/.local/bin"/*; do
            if [[ -L "$script" ]] && [[ "$(readlink "$script")" == *".dotfiles"* ]]; then
                rm "$script"
                print_success "Removed: $script"
            fi
        done
    fi

    # Find and offer to restore backups
    print_step "Looking for backups"

    local backup_dirs=($(ls -d ${DOTFILES_BACKUP_PREFIX}_* 2>/dev/null || true))

    if [[ ${#backup_dirs[@]} -gt 0 ]]; then
        echo "Found ${#backup_dirs[@]} backup(s):"
        for i in "${!backup_dirs[@]}"; do
            echo "  $((i+1)). ${backup_dirs[$i]}"
        done
        echo

        if ask_yes_no "Restore from most recent backup?"; then
            local latest_backup="${backup_dirs[-1]}"
            print_step "Restoring from: $latest_backup"

            for file in "$latest_backup"/*; do
                if [[ -f "$file" ]]; then
                    local filename=$(basename "$file")
                    cp "$file" "$HOME/.$filename" 2>/dev/null || cp "$file" "$HOME/$filename"
                    print_success "Restored: $filename"
                fi
            done
        fi
    else
        print_warning "No backups found"
    fi

    # Purge dotfiles directory if requested
    if [[ "$UNINSTALL_PURGE" == true ]]; then
        print_step "Purging dotfiles directory"

        if [[ -d "$DOTFILES_DIR" ]]; then
            if ask_yes_no "Delete $DOTFILES_DIR?" "n"; then
                rm -rf "$DOTFILES_DIR"
                print_success "Removed: $DOTFILES_DIR"
            else
                print_warning "Kept: $DOTFILES_DIR"
            fi
        fi
    fi

    echo
    print_success "Uninstallation complete!"
    echo
    echo "You may also want to:"
    echo "  - Remove oh-my-zsh: rm -rf ~/.oh-my-zsh"
    echo "  - Change shell back: chsh -s /bin/bash"
    echo
    exit 0
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

# Check if core dependencies are already installed
check_core_deps() {
    command -v git &>/dev/null && command -v curl &>/dev/null && command -v zsh &>/dev/null
}

install_dependencies() {
    # Skip if --skip-deps flag
    if [[ "$SKIP_DEPS" == true ]]; then
        print_step "Skipping dependencies (--skip-deps)"
        return 0
    fi

    # Skip if INSTALL_DEPS=false in config
    if [[ "${INSTALL_DEPS}" == "false" || "${INSTALL_DEPS}" == "no" || "${INSTALL_DEPS}" == "0" ]]; then
        print_step "Skipping dependencies (INSTALL_DEPS=false in config)"
        return 0
    fi

    # Auto-detect: skip if deps already installed (default behavior)
    if [[ "${INSTALL_DEPS}" == "auto" ]] && check_core_deps; then
        print_step "Dependencies check"
        print_success "Core dependencies already installed (git, curl, zsh)"
        return 0
    fi

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
        print_success "No backups needed (files already symlinked or don't exist)"
    fi
}

install_oh_my_zsh() {
    print_step "Checking oh-my-zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "oh-my-zsh already installed"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "oh-my-zsh installed"
    fi
}

install_zsh_plugins() {
    print_step "Installing zsh plugins"

    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    mkdir -p "$custom_dir"

    # zsh-autosuggestions
    if [[ ! -d "$custom_dir/zsh-autosuggestions" ]]; then
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/zsh-autosuggestions"
        print_success "Installed: zsh-autosuggestions"
    else
        print_success "Already installed: zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$custom_dir/zsh-syntax-highlighting" ]]; then
        git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$custom_dir/zsh-syntax-highlighting"
        print_success "Installed: zsh-syntax-highlighting"
    else
        print_success "Already installed: zsh-syntax-highlighting"
    fi
}

configure_git() {
    print_step "Configuring git"

    # Determine git user info (config > user identity > prompt)
    local git_name="${GIT_USER_NAME:-$USER_FULLNAME}"
    local git_email="${GIT_USER_EMAIL:-$USER_EMAIL}"

    # Prompt if still empty
    if [[ -z "$git_name" ]]; then
        local current_name=$(git config --global user.name 2>/dev/null || echo "")
        if [[ -n "$current_name" ]]; then
            print_success "Git name already set: $current_name"
        else
            read -p "Git user name: " git_name
        fi
    fi

    if [[ -z "$git_email" ]]; then
        local current_email=$(git config --global user.email 2>/dev/null || echo "")
        if [[ -n "$current_email" ]]; then
            print_success "Git email already set: $current_email"
        else
            read -p "Git email: " git_email
        fi
    fi

    # Generate .gitconfig
    local gitconfig_path="$DOTFILES_DIR/git/.gitconfig"
    mkdir -p "$DOTFILES_DIR/git"

    cat > "$gitconfig_path" << EOF
[init]
	defaultBranch = ${GIT_DEFAULT_BRANCH:-master}
[user]
	email = ${git_email}
	name = ${git_name}
[credential]
	helper = ${GIT_CREDENTIAL_HELPER:-store}
[core]
	editor = vim
	autocrlf = input
[pull]
	rebase = false
[push]
	default = current
[alias]
	st = status
	co = checkout
	br = branch
	ci = commit
	lg = log --oneline --graph --decorate --all
EOF

    print_success "Generated: .gitconfig"

    # Also set git config directly (in case symlink isn't in place yet)
    [[ -n "$git_name" ]] && git config --global user.name "$git_name"
    [[ -n "$git_email" ]] && git config --global user.email "$git_email"
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
    print_step "Checking default shell"

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
    if command -v espanso &> /dev/null; then
        print_success "espanso already installed"
        return 0
    fi

    print_step "Installing espanso (text expander)"

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
    else
        print_success "espanso already installed"
    fi

    # fzf
    if ! command -v fzf &> /dev/null; then
        if should_install "$INSTALL_FZF" "fzf (fuzzy finder)"; then
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all
            print_success "fzf installed"
        fi
    else
        print_success "fzf already installed"
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
    else
        print_success "bat already installed"
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
    else
        print_success "eza already installed"
    fi
}

install_password_managers() {
    print_step "Password manager CLI tools"

    # 1Password CLI
    if ! command -v op &> /dev/null; then
        if should_install "$INSTALL_1PASSWORD" "1Password CLI (op)"; then
            case "$OS" in
                ubuntu|debian)
                    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list
                    sudo apt update && sudo apt install -y 1password-cli
                    ;;
                fedora|rhel|centos)
                    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
                    sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc" > /etc/yum.repos.d/1password.repo'
                    sudo dnf install -y 1password-cli
                    ;;
                arch|cachyos)
                    if command -v paru &>/dev/null; then
                        paru -S --noconfirm 1password-cli
                    elif command -v yay &>/dev/null; then
                        yay -S --noconfirm 1password-cli
                    else
                        print_warning "Install 1password-cli from AUR manually"
                    fi
                    ;;
                macos)
                    brew install --cask 1password-cli
                    ;;
            esac
            command -v op &>/dev/null && print_success "1Password CLI installed"
        fi
    else
        print_success "1Password CLI already installed"
    fi

    # LastPass CLI
    if ! command -v lpass &> /dev/null; then
        if should_install "$INSTALL_LASTPASS" "LastPass CLI (lpass)"; then
            case "$OS" in
                ubuntu|debian)
                    sudo apt-get install -y lastpass-cli
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y lastpass-cli
                    ;;
                arch|cachyos)
                    sudo pacman -S --noconfirm lastpass-cli
                    ;;
                macos)
                    brew install lastpass-cli
                    ;;
            esac
            command -v lpass &>/dev/null && print_success "LastPass CLI installed"
        fi
    else
        print_success "LastPass CLI already installed"
    fi

    # Bitwarden CLI
    if ! command -v bw &> /dev/null; then
        if should_install "$INSTALL_BITWARDEN" "Bitwarden CLI (bw)"; then
            case "$OS" in
                ubuntu|debian|fedora|rhel|centos)
                    if command -v npm &>/dev/null; then
                        sudo npm install -g @bitwarden/cli
                    else
                        print_warning "Bitwarden CLI requires npm. Install Node.js first."
                    fi
                    ;;
                arch|cachyos)
                    if command -v paru &>/dev/null; then
                        paru -S --noconfirm bitwarden-cli
                    elif command -v yay &>/dev/null; then
                        yay -S --noconfirm bitwarden-cli
                    else
                        sudo pacman -S --noconfirm bitwarden-cli 2>/dev/null || {
                            [[ -x "$(command -v npm)" ]] && sudo npm install -g @bitwarden/cli
                        }
                    fi
                    ;;
                macos)
                    brew install bitwarden-cli
                    ;;
            esac
            command -v bw &>/dev/null && print_success "Bitwarden CLI installed"
        fi
    else
        print_success "Bitwarden CLI already installed"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Handle uninstall mode
    if [[ "$UNINSTALL" == true ]]; then
        load_config
        do_uninstall
    fi

    print_header

    detect_os

    # Handle --deps-only
    if [[ "$DEPS_ONLY" == true ]]; then
        install_dependencies
        echo
        print_success "Dependencies installed. Run without --deps-only to continue."
        exit 0
    fi

    if ask_yes_no "Install/update dotfiles?"; then
        install_dependencies
        clone_or_update_dotfiles
        backup_existing_configs
        install_oh_my_zsh

        # Install zsh plugins if enabled
        if [[ "${INSTALL_ZSH_PLUGINS}" == "true" || "${INSTALL_ZSH_PLUGINS}" == "yes" || "${INSTALL_ZSH_PLUGINS}" == "1" ]]; then
            install_zsh_plugins
        fi

        configure_git
        link_dotfiles
        link_espanso_config
        set_zsh_default
        install_optional_tools
        install_password_managers

        echo
        print_success "Installation complete!"
        echo
        echo -e "${BLUE}Next steps:${NC}"
        echo "  1. Restart your terminal or run: exec zsh"
        echo "  2. Your old configs are backed up in: $BACKUP_DIR"
        echo "  3. Customize settings in: $DOTFILES_DIR/dotfiles.conf"
        echo "  4. Run 'dfd' or 'dotfiles-doctor.sh' to verify installation"
        echo
        echo -e "${BLUE}Useful commands:${NC}"
        echo "  dfd / doctor      - Health check"
        echo "  dfs / dfsync      - Sync dotfiles"
        echo "  dfu / dfupdate    - Update dotfiles"
        echo "  dfstats / stats   - Shell analytics"
        echo "  vault             - Secrets manager"
        echo
        echo -e "${BLUE}To uninstall:${NC}"
        echo "  ./install.sh --uninstall"
        echo
    else
        print_warning "Installation cancelled"
        exit 0
    fi
}

main "$@"
