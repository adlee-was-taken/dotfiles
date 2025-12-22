#!/usr/bin/env bash
# ============================================================================
# ADLee's Dotfiles Installation Script (Arch/CachyOS)
# ============================================================================
# Quick install:
#   git clone https://github.com/adlee-was-taken/dotfiles.git && cd dotfiles && ./install.sh
#
# Options:
#   --skip-deps    Skip dependency installation (for re-runs)
#   --deps-only    Only install dependencies, then exit
#   --uninstall    Remove symlinks and optionally restore backups
#   --help         Show help
#
# Note: This version is Arch/CachyOS only
# ============================================================================

set -e

# ============================================================================
# Command Line Options
# ============================================================================

SKIP_DEPS=false
DEPS_ONLY=false
UNINSTALL=false
UNINSTALL_PURGE=false
RUN_WIZARD=false

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
        --wizard)
            RUN_WIZARD=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --wizard       Run interactive setup wizard (recommended)"
            echo "  --skip-deps    Skip dependency installation (useful for re-runs)"
            echo "  --deps-only    Only install dependencies, then exit"
            echo "  --uninstall    Remove symlinks and restore backups"
            echo "  --purge        With --uninstall, also remove ~/.dotfiles directory"
            echo "  --help         Show this help message"
            echo
            echo "Configuration:"
            echo "  Edit dotfiles.conf to customize installation behavior"
            echo
            echo "Examples:"
            echo "  ./install.sh                    # Full install"
            echo "  ./install.sh --wizard           # Interactive wizard"
            echo "  ./install.sh --skip-deps        # Re-run without checking deps"
            echo "  ./install.sh --uninstall        # Remove symlinks"
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
        # Fallback defaults
        DOTFILES_VERSION="${DOTFILES_VERSION:-1.2.0}"
        DOTFILES_GITHUB_USER="${DOTFILES_GITHUB_USER:-adlee-was-taken}"
        DOTFILES_REPO_NAME="${DOTFILES_REPO_NAME:-dotfiles}"
        DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
        DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
        DOTFILES_BACKUP_PREFIX="${DOTFILES_BACKUP_PREFIX:-$HOME/.dotfiles_backup}"
        DOTFILES_REPO_URL="https://github.com/${DOTFILES_GITHUB_USER}/${DOTFILES_REPO_NAME}.git"

        # Feature toggles
        INSTALL_DEPS="${INSTALL_DEPS:-auto}"
        INSTALL_ZSH_PLUGINS="${INSTALL_ZSH_PLUGINS:-true}"
        INSTALL_FZF="${INSTALL_FZF:-ask}"
        INSTALL_BAT="${INSTALL_BAT:-ask}"
        INSTALL_EZA="${INSTALL_EZA:-ask}"
        INSTALL_NEOVIM="${INSTALL_NEOVIM:-ask}"
        SET_ZSH_DEFAULT="${SET_ZSH_DEFAULT:-ask}"

        # Theme settings
        ZSH_THEME_NAME="${ZSH_THEME_NAME:-adlee}"

        # Git settings
        GIT_USER_NAME="${GIT_USER_NAME:-}"
        GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
        GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-main}"
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
    echo -e "${BLUE}║${NC}  Dotfiles Installation  ${CYAN}v${DOTFILES_VERSION}${NC} (Arch/CachyOS)         ${BLUE}║${NC}"
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
# OS Detection - Arch/CachyOS Only
# ============================================================================

detect_os() {
    print_step "Detecting operating system"

    if [[ ! "$OSTYPE" =~ linux-gnu ]]; then
        print_error "This dotfiles requires Arch or CachyOS on Linux"
        exit 1
    fi

    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine Linux distribution"
        exit 1
    fi

    source /etc/os-release
    
    if [[ "$ID" != "arch" && "$ID" != "cachyos" ]]; then
        print_error "This dotfiles is configured for Arch/CachyOS only"
        print_error "Detected: $ID $VERSION_ID"
        exit 1
    fi

    OS="$ID"
    print_success "Detected: $OS"
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
        "$HOME/.config/nvim"
        "$HOME/.tmux.conf"
        "$HOME/.oh-my-zsh/themes/${ZSH_THEME_NAME:-adlee}.zsh-theme"
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
    exit 0
}

# ============================================================================
# Installation Functions
# ============================================================================

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
    if [[ "${INSTALL_DEPS}" == "false" || "${INSTALL_DEPS}" == "no" ]]; then
        print_step "Skipping dependencies (INSTALL_DEPS=false in config)"
        return 0
    fi

    # Auto-detect: skip if deps already installed
    if [[ "${INSTALL_DEPS}" == "auto" ]] && check_core_deps; then
        print_step "Dependencies check"
        print_success "Core dependencies already installed (git, curl, zsh)"
        return 0
    fi

    print_step "Installing dependencies"

    # Arch/CachyOS only
    sudo pacman -Sy --noconfirm git curl zsh

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

    # Reload config after clone
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

    local git_name="${GIT_USER_NAME:-$USER_FULLNAME}"
    local git_email="${GIT_USER_EMAIL:-$USER_EMAIL}"

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
	defaultBranch = ${GIT_DEFAULT_BRANCH:-main}
[user]
	email = ${git_email}
	name = ${git_name}
[credential]
	helper = store
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

    # Also set git config directly
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

    # Link neovim config (if it exists)
    if [ -d "$DOTFILES_DIR/nvim" ]; then
        mkdir -p "$HOME/.config"
        ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
        print_success "Linked: nvim config"
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

install_optional_tools() {
    print_step "Optional tools"

    # fzf
    if ! command -v fzf &>/dev/null; then
        if should_install "$INSTALL_FZF" "fzf (fuzzy finder)"; then
            sudo pacman -S --noconfirm fzf
            print_success "fzf installed"
        fi
    else
        print_success "fzf already installed"
    fi

    # bat
    if ! command -v bat &>/dev/null; then
        if should_install "$INSTALL_BAT" "bat (better cat)"; then
            sudo pacman -S --noconfirm bat
            print_success "bat installed"
        fi
    else
        print_success "bat already installed"
    fi

    # eza
    if ! command -v eza &>/dev/null; then
        if should_install "$INSTALL_EZA" "eza (better ls)"; then
            sudo pacman -S --noconfirm eza
            print_success "eza installed"
        fi
    else
        print_success "eza already installed"
    fi

    # neovim
    if ! command -v nvim &>/dev/null; then
        if should_install "$INSTALL_NEOVIM" "neovim"; then
            sudo pacman -S --noconfirm neovim
            print_success "neovim installed"
        fi
    else
        print_success "neovim already installed"
    fi
}

install_lastpass() {
    if command -v lpass &>/dev/null; then
        print_success "LastPass CLI already installed"
        return 0
    fi

    # Try AUR first
    if command -v paru &>/dev/null; then
        paru -S --noconfirm lastpass-cli
        print_success "LastPass CLI installed via paru"
        return 0
    fi

    if command -v yay &>/dev/null; then
        yay -S --noconfirm lastpass-cli
        print_success "LastPass CLI installed via yay"
        return 0
    fi

    # Fallback to pacman (may not have lastpass-cli)
    if sudo pacman -S --noconfirm lastpass-cli 2>/dev/null; then
        print_success "LastPass CLI installed"
    else
        print_warning "LastPass CLI not found in repositories"
        print_warning "Install manually: yay -S lastpass-cli"
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

        if [[ "${INSTALL_ZSH_PLUGINS}" == "true" ]]; then
            install_zsh_plugins
        fi

        configure_git
        link_dotfiles
        set_zsh_default
        install_optional_tools
        install_lastpass

        echo
        print_success "Installation complete!"
        echo
        echo -e "${BLUE}Next steps:${NC}"
        echo "  1. Restart your terminal or run: exec zsh"
        echo "  2. Customize settings in: $DOTFILES_DIR/dotfiles.conf"
        echo "  3. Run 'dfd' or 'dotfiles-doctor.sh' to verify installation"
        echo
        echo -e "${BLUE}Useful commands:${NC}"
        echo "  dfd / doctor      - Health check"
        echo "  dfs / dfsync      - Sync dotfiles"
        echo "  dfu / dfupdate    - Update dotfiles"
        echo "  dfstats / stats   - Shell analytics"
        echo "  vault             - Secrets manager"
        echo
    else
        print_warning "Installation cancelled"
        exit 0
    fi
}

main "$@"
