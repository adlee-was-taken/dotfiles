#!/usr/bin/env bash
# ============================================================================
# Update Dotfiles Script
# ============================================================================
# Updates dotfiles from the git repository and relinks files

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
    # Fallback defaults
    DOTFILES_DIR="$HOME/.dotfiles"
    DOTFILES_BRANCH="main"
    DOTFILES_GITHUB_USER="adlee-was-taken"
    DOTFILES_REPO_NAME="dotfiles"
    DOTFILES_RAW_URL="https://raw.githubusercontent.com/${DOTFILES_GITHUB_USER}/${DOTFILES_REPO_NAME}/${DOTFILES_BRANCH}"
fi

# ============================================================================
# Colors
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# ============================================================================
# Main
# ============================================================================

if [ ! -d "$DOTFILES_DIR" ]; then
    print_error "Dotfiles directory not found: $DOTFILES_DIR"
    echo "Run the installation script first:"
    echo "  curl -fsSL ${DOTFILES_RAW_URL}/install.sh | bash"
    exit 1
fi

cd "$DOTFILES_DIR"

echo "Updating dotfiles from repository..."
git pull origin "$DOTFILES_BRANCH"

if [ $? -eq 0 ]; then
    print_success "Dotfiles updated successfully"

    if [ -f "$DOTFILES_DIR/install.sh" ]; then
        echo
        read -p "Run install script to update links? [Y/n]: " response
        response=${response:-y}

        if [[ "$response" =~ ^[Yy]$ ]]; then
            "$DOTFILES_DIR/install.sh"
        fi
    fi

    echo
    print_success "Update complete!"
    echo "Reload your shell with: source ~/.zshrc"
else
    print_error "Failed to update dotfiles"
    exit 1
fi
