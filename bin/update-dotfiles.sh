#!/usr/bin/env bash
# ============================================================================
# Update Dotfiles Script
# ============================================================================
# Updates dotfiles from the git repository and relinks files

set -e

DOTFILES_DIR="$HOME/.dotfiles"
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

if [ ! -d "$DOTFILES_DIR" ]; then
    print_error "Dotfiles directory not found: $DOTFILES_DIR"
    echo "Run the installation script first:"
    echo "  curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh | bash"
    exit 1
fi

cd "$DOTFILES_DIR"

echo "Updating dotfiles from repository..."
git pull origin main

if [ $? -eq 0 ]; then
    print_success "Dotfiles updated successfully"

    # Check if install script exists and run it
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
