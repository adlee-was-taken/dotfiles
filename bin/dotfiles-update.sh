#!/usr/bin/env bash
# ============================================================================
# Update Dotfiles Script
# ============================================================================

set -e

SKIP_DEPS=true
PULL_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --skip-deps) SKIP_DEPS=true ;;
        --with-deps) SKIP_DEPS=false ;;
        --pull-only) PULL_ONLY=true ;;
        --help|-h)
            echo "Usage: dotfiles-update.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-deps    Skip dependency check (default for updates)"
            echo "  --with-deps    Run full dependency check"
            echo "  --pull-only    Only git pull, don't re-run install script"
            echo "  --help         Show this help message"
            exit 0
            ;;
    esac
done

# Load Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_CONF="${SCRIPT_DIR}/../dotfiles.conf"
[[ -f "$DOTFILES_CONF" ]] || DOTFILES_CONF="$HOME/.dotfiles/dotfiles.conf"

if [[ -f "$DOTFILES_CONF" ]]; then
    source "$DOTFILES_CONF"
else
    DOTFILES_DIR="$HOME/.dotfiles"
    DOTFILES_BRANCH="main"
    DOTFILES_RAW_URL="https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main"
fi

# Source shared colors
source "$DOTFILES_DIR/zsh/lib/colors.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
}

# ============================================================================
# MOTD-style header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-update"
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width=66
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done
        
        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}      ${DF_DIM}dotfiles-update${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

print_success() {
    echo -e "${DF_GREEN}✓${DF_NC} $1"
}

print_warning() {
    echo -e "${DF_YELLOW}⚠${DF_NC} $1"
}

print_error() {
    echo -e "${DF_RED}✗${DF_NC} $1"
}

print_step() {
    echo -e "${DF_GREEN}==>${DF_NC} $1"
}

# ============================================================================
# Main
# ============================================================================

print_header

if [ ! -d "$DOTFILES_DIR" ]; then
    print_error "Dotfiles directory not found: $DOTFILES_DIR"
    echo "Run the installation script first:"
    echo "  curl -fsSL ${DOTFILES_RAW_URL}/install.sh | bash"
    exit 1
fi

cd "$DOTFILES_DIR"

print_step "Updating dotfiles from repository..."
git pull origin "$DOTFILES_BRANCH"

if [ $? -eq 0 ]; then
    print_success "Dotfiles updated successfully"

    if [[ "$PULL_ONLY" == true ]]; then
        echo
        print_success "Pull complete (--pull-only mode)"
        echo "Run ./install.sh manually to re-link files"
        exit 0
    fi

    if [ -f "$DOTFILES_DIR/install.sh" ]; then
        echo
        read -p "Run install script to update links? [Y/n]: " response
        response=${response:-y}

        if [[ "$response" =~ ^[Yy]$ ]]; then
            if [[ "$SKIP_DEPS" == true ]]; then
                "$DOTFILES_DIR/install.sh" --skip-deps
            else
                "$DOTFILES_DIR/install.sh"
            fi
        fi
    fi

    echo
    print_success "Update complete!"
    echo -e "Reload your shell: ${DF_CYAN}reload${DF_NC} or ${DF_CYAN}source ~/.zshrc${DF_NC}"
else
    print_error "Failed to update dotfiles"
    exit 1
fi
