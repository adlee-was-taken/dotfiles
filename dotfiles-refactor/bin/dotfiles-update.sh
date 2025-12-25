#!/usr/bin/env bash
# ============================================================================
# Update Dotfiles Script
# ============================================================================

set -e

# ============================================================================
# Parse Arguments First (before sourcing, in case we need --help)
# ============================================================================

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

# ============================================================================
# Source Bootstrap
# ============================================================================

source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
    df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
    df_print_step() { echo -e "${DF_GREEN}==>${DF_NC} $1"; }
}

# ============================================================================
# Main
# ============================================================================

df_print_header "dotfiles-update"

if [[ ! -d "$DOTFILES_HOME" ]]; then
    df_print_error "Dotfiles directory not found: $DOTFILES_HOME"
    exit 1
fi

cd "$DOTFILES_HOME"

df_print_step "Updating dotfiles from repository..."

if git pull origin "${DOTFILES_BRANCH:-main}"; then
    df_print_success "Dotfiles updated successfully"
    
    if [[ "$PULL_ONLY" == true ]]; then
        echo ""
        df_print_success "Pull complete (--pull-only mode)"
        exit 0
    fi
    
    echo ""
    df_print_success "Update complete!"
    echo -e "Reload your shell: ${DF_CYAN}reload${DF_NC} or ${DF_CYAN}source ~/.zshrc${DF_NC}"
else
    df_print_error "Failed to update dotfiles"
    exit 1
fi
