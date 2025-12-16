#!/usr/bin/env bash
# ============================================================================
# Dotfiles Doctor - Diagnostic Tool
# ============================================================================
# Checks the health of your dotfiles installation
#
# Usage:
#   dotfiles-doctor.sh           # Run all checks
#   dotfiles-doctor.sh --fix     # Attempt to fix issues
#   dotfiles-doctor.sh --quiet   # Only show errors
# ============================================================================

set -e

# ============================================================================
# Options
# ============================================================================

FIX_MODE=false
QUIET_MODE=false

for arg in "$@"; do
    case "$arg" in
        --fix)
            FIX_MODE=true
            ;;
        --quiet|-q)
            QUIET_MODE=true
            ;;
        --help|-h)
            echo "Usage: dotfiles-doctor.sh [OPTIONS]"
            echo
            echo "Options:"
            echo "  --fix     Attempt to automatically fix issues"
            echo "  --quiet   Only show errors and warnings"
            echo "  --help    Show this help message"
            echo
            echo "Aliases:"
            echo "  dfd, doctor   Run diagnostics"
            echo "  dffix         Run with --fix"
            echo
            exit 0
            ;;
    esac
done

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
    DOTFILES_VERSION="unknown"
    ZSH_THEME_NAME="adlee"
fi

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
# Counters
# ============================================================================

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    if [[ "$QUIET_MODE" != true ]]; then
        echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}  Dotfiles Doctor  ${CYAN}v${DOTFILES_VERSION}${NC}                               ${BLUE}║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
    fi
}

print_section() {
    if [[ "$QUIET_MODE" != true ]]; then
        echo -e "\n${BLUE}━━━ $1 ━━━${NC}"
    fi
}

pass() {
    ((PASS_COUNT++))
    if [[ "$QUIET_MODE" != true ]]; then
        echo -e "${GREEN}✓${NC} $1"
    fi
}

warn() {
    ((WARN_COUNT++))
    echo -e "${YELLOW}⚠${NC} $1"
}

fail() {
    ((FAIL_COUNT++))
    echo -e "${RED}✗${NC} $1"
}

info() {
    if [[ "$QUIET_MODE" != true ]]; then
        echo -e "${CYAN}ℹ${NC} $1"
    fi
}

# ============================================================================
# Check Functions
# ============================================================================

check_dotfiles_dir() {
    print_section "Dotfiles Directory"

    if [[ -d "$DOTFILES_DIR" ]]; then
        pass "Dotfiles directory exists: $DOTFILES_DIR"

        # Check if it's a git repo
        if [[ -d "$DOTFILES_DIR/.git" ]]; then
            pass "Is a git repository"

            # Check for uncommitted changes
            cd "$DOTFILES_DIR"
            if git diff --quiet 2>/dev/null; then
                pass "No uncommitted changes"
            else
                warn "Uncommitted changes in dotfiles"
            fi

            # Check if up to date with remote
            git fetch origin --quiet 2>/dev/null || true
            local local_hash=$(git rev-parse HEAD 2>/dev/null)
            local remote_hash=$(git rev-parse origin/${DOTFILES_BRANCH:-main} 2>/dev/null || echo "")

            if [[ -n "$remote_hash" && "$local_hash" == "$remote_hash" ]]; then
                pass "Up to date with remote"
            elif [[ -n "$remote_hash" ]]; then
                warn "Behind remote (run: cd ~/.dotfiles && git pull)"
            fi
            cd - > /dev/null
        else
            warn "Not a git repository"
        fi

        # Check config file
        if [[ -f "$DOTFILES_DIR/dotfiles.conf" ]]; then
            pass "Config file exists: dotfiles.conf"
        else
            fail "Config file missing: dotfiles.conf"
        fi
    else
        fail "Dotfiles directory not found: $DOTFILES_DIR"
    fi
}

check_symlinks() {
    print_section "Symlinks"

    local symlinks=(
        "$HOME/.zshrc:$DOTFILES_DIR/zsh/.zshrc"
        "$HOME/.gitconfig:$DOTFILES_DIR/git/.gitconfig"
        "$HOME/.vimrc:$DOTFILES_DIR/vim/.vimrc"
        "$HOME/.tmux.conf:$DOTFILES_DIR/tmux/.tmux.conf"
        "$HOME/.oh-my-zsh/themes/${ZSH_THEME_NAME}.zsh-theme:$DOTFILES_DIR/zsh/themes/${ZSH_THEME_NAME}.zsh-theme"
    )

    local valid_count=0
    local total_count=0

    for entry in "${symlinks[@]}"; do
        local link="${entry%%:*}"
        local target="${entry##*:}"
        local name=$(basename "$link")
        ((total_count++))

        if [[ -L "$link" ]]; then
            local actual_target=$(readlink -f "$link" 2>/dev/null)
            local expected_target=$(readlink -f "$target" 2>/dev/null)

            if [[ "$actual_target" == "$expected_target" ]]; then
                pass "Symlink valid: $name"
                ((valid_count++))
            else
                warn "Symlink points elsewhere: $name"
                info "  Expected: $target"
                info "  Actual:   $actual_target"
            fi
        elif [[ -f "$link" ]]; then
            warn "Regular file (not symlink): $name"
            if [[ "$FIX_MODE" == true ]]; then
                if [[ -f "$target" ]]; then
                    mv "$link" "$link.backup"
                    ln -sf "$target" "$link"
                    pass "Fixed: $name (backup saved)"
                    ((valid_count++))
                fi
            fi
        elif [[ -f "$target" ]]; then
            fail "Symlink missing: $name"
            if [[ "$FIX_MODE" == true ]]; then
                ln -sf "$target" "$link"
                pass "Fixed: Created symlink for $name"
                ((valid_count++))
            fi
        else
            info "Source not present: $name (optional)"
        fi
    done

    # Check espanso symlink
    if [[ -L "$HOME/.config/espanso" ]]; then
        pass "Symlink valid: espanso config"
    elif [[ -d "$HOME/.config/espanso" ]]; then
        warn "Espanso config is directory (not symlink)"
    elif [[ -d "$DOTFILES_DIR/espanso" ]]; then
        fail "Espanso symlink missing"
    fi

    info "Symlinks: $valid_count/$total_count valid"
}

check_shell() {
    print_section "Shell"

    # Check current shell
    if [[ "$SHELL" == *"zsh"* ]]; then
        pass "Default shell is zsh"
    else
        warn "Default shell is not zsh: $SHELL"
        info "  Change with: chsh -s \$(which zsh)"
    fi

    # Check oh-my-zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        pass "oh-my-zsh installed"
    else
        fail "oh-my-zsh not installed"
    fi

    # Check theme
    if [[ -f "$HOME/.oh-my-zsh/themes/${ZSH_THEME_NAME}.zsh-theme" ]]; then
        pass "Theme installed: ${ZSH_THEME_NAME}"
    else
        fail "Theme missing: ${ZSH_THEME_NAME}"
    fi

    # Check ZSH_THEME in .zshrc
    if grep -q "ZSH_THEME=\"${ZSH_THEME_NAME}\"" "$HOME/.zshrc" 2>/dev/null; then
        pass "Theme configured in .zshrc"
    else
        warn "Theme may not be configured in .zshrc"
    fi
}

check_zsh_plugins() {
    print_section "Zsh Plugins"

    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # zsh-autosuggestions
    if [[ -d "$custom_dir/zsh-autosuggestions" ]]; then
        pass "Plugin installed: zsh-autosuggestions"
    else
        fail "Plugin missing: zsh-autosuggestions"
        if [[ "$FIX_MODE" == true ]]; then
            git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/zsh-autosuggestions"
            pass "Fixed: Installed zsh-autosuggestions"
        else
            info "  Install: git clone https://github.com/zsh-users/zsh-autosuggestions $custom_dir/zsh-autosuggestions"
        fi
    fi

    # zsh-syntax-highlighting
    if [[ -d "$custom_dir/zsh-syntax-highlighting" ]]; then
        pass "Plugin installed: zsh-syntax-highlighting"
    else
        fail "Plugin missing: zsh-syntax-highlighting"
        if [[ "$FIX_MODE" == true ]]; then
            git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$custom_dir/zsh-syntax-highlighting"
            pass "Fixed: Installed zsh-syntax-highlighting"
        else
            info "  Install: git clone https://github.com/zsh-users/zsh-syntax-highlighting $custom_dir/zsh-syntax-highlighting"
        fi
    fi
}

check_git() {
    print_section "Git Configuration"

    # Check git installed
    if command -v git &>/dev/null; then
        pass "git installed: $(git --version | cut -d' ' -f3)"
    else
        fail "git not installed"
        return
    fi

    # Check user.name
    local git_name=$(git config --global user.name 2>/dev/null)
    if [[ -n "$git_name" ]]; then
        pass "Git user.name: $git_name"
    else
        fail "Git user.name not configured"
        info "  Set with: git config --global user.name \"Your Name\""
    fi

    # Check user.email
    local git_email=$(git config --global user.email 2>/dev/null)
    if [[ -n "$git_email" ]]; then
        pass "Git user.email: $git_email"
    else
        fail "Git user.email not configured"
        info "  Set with: git config --global user.email \"you@example.com\""
    fi

    # Check credential helper
    local cred_helper=$(git config --global credential.helper 2>/dev/null)
    if [[ -n "$cred_helper" ]]; then
        pass "Git credential helper: $cred_helper"
    else
        warn "Git credential helper not configured"
    fi
}

check_espanso() {
    print_section "Espanso"

    if command -v espanso &>/dev/null; then
        pass "espanso installed: $(espanso --version 2>/dev/null | head -1)"

        # Check if running
        if espanso status 2>/dev/null | grep -q "running"; then
            pass "espanso service running"
        else
            warn "espanso service not running"
            info "  Start with: espanso service start"
        fi

        # Check config
        if [[ -f "$HOME/.config/espanso/match/base.yml" ]]; then
            pass "espanso config present"
        else
            warn "espanso base.yml not found"
        fi
    else
        info "espanso not installed (optional)"
    fi
}

check_optional_tools() {
    print_section "Optional Tools"

    # fzf
    if command -v fzf &>/dev/null; then
        pass "fzf installed"
    else
        info "fzf not installed (optional)"
    fi

    # bat/batcat
    if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
        pass "bat installed"
    else
        info "bat not installed (optional)"
    fi

    # eza
    if command -v eza &>/dev/null; then
        pass "eza installed"
    else
        info "eza not installed (optional)"
    fi

    # fd
    if command -v fd &>/dev/null; then
        pass "fd installed"
    else
        info "fd not installed (optional)"
    fi
}

check_bin_scripts() {
    print_section "Bin Scripts"

    local bin_dir="$HOME/.local/bin"

    if [[ -d "$bin_dir" ]]; then
        local script_count=0
        local valid_count=0

        for script in "$DOTFILES_DIR/bin"/*; do
            if [[ -f "$script" ]]; then
                ((script_count++))
                local name=$(basename "$script")
                local link="$bin_dir/$name"

                if [[ -L "$link" ]]; then
                    ((valid_count++))
                elif [[ -f "$link" ]]; then
                    warn "Script is regular file: $name"
                else
                    fail "Script not linked: $name"
                fi
            fi
        done

        if [[ $script_count -gt 0 ]]; then
            pass "Bin scripts: $valid_count/$script_count linked"
        fi

        # Check PATH
        if [[ ":$PATH:" == *":$bin_dir:"* ]]; then
            pass "$bin_dir is in PATH"
        else
            warn "$bin_dir not in PATH"
            info "  Add to .zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
        fi
    else
        warn "~/.local/bin directory doesn't exist"
    fi
}

print_summary() {
    echo
    echo -e "${BLUE}━━━ Summary ━━━${NC}"
    echo
    echo -e "  ${GREEN}Passed:${NC}   $PASS_COUNT"
    echo -e "  ${YELLOW}Warnings:${NC} $WARN_COUNT"
    echo -e "  ${RED}Failed:${NC}   $FAIL_COUNT"
    echo

    if [[ $FAIL_COUNT -eq 0 && $WARN_COUNT -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed! Your dotfiles are healthy.${NC}"
    elif [[ $FAIL_COUNT -eq 0 ]]; then
        echo -e "${YELLOW}⚠ Some warnings, but no critical issues.${NC}"
    else
        echo -e "${RED}✗ Some issues found.${NC}"
        if [[ "$FIX_MODE" != true ]]; then
            echo -e "  Run ${CYAN}dffix${NC} or ${CYAN}dotfiles-doctor.sh --fix${NC} to attempt automatic fixes."
        fi
    fi
    echo
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header

    check_dotfiles_dir
    check_symlinks
    check_shell
    check_zsh_plugins
    check_git
    check_espanso
    check_optional_tools
    check_bin_scripts

    print_summary

    # Exit with error code if there were failures
    [[ $FAIL_COUNT -eq 0 ]]
}

main "$@"
