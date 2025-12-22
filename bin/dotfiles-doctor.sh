#!/usr/bin/env bash
# ============================================================================
# Dotfiles Health Check (Arch/CachyOS)
# ============================================================================

set -e

readonly DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
readonly DOTFILES_VERSION="3.0.0"

# Source shared colors
source "$DOTFILES_HOME/zsh/lib/colors.zsh" 2>/dev/null || {
    # Fallback if colors.zsh not found
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
}

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# ============================================================================
# MOTD-style header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-doctor"
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width=66
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}      ${DF_DIM}dotfiles-doctor${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

# ============================================================================
# Health check functions
# ============================================================================

print_section() {
    echo -e "\n${DF_BLUE}▶${DF_NC} $1"
}

check_pass() {
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
    echo -e "  ${DF_GREEN}✓${DF_NC} $1"
}

check_fail() {
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
    echo -e "  ${DF_RED}✗${DF_NC} $1"
}

check_warn() {
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
    echo -e "  ${DF_YELLOW}⚠${DF_NC} $1"
}

# ============================================================================
# Health checks
# ============================================================================

check_os() {
    print_section "Operating System"

    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        if grep -qiI "arch\|cachyos" /etc/os-release 2>/dev/null; then
            check_pass "Running on Arch/CachyOS"
        else
            check_fail "Not running on Arch/CachyOS"
        fi
    else
        check_fail "Not running on Linux"
    fi
}

check_shell() {
    print_section "Shell Configuration"

    if [[ -f "$HOME/.zshrc" ]]; then
        check_pass "Zsh configuration exists"
    else
        check_fail "Zsh configuration missing"
    fi

    if [[ "$SHELL" == *"zsh"* ]]; then
        check_pass "Zsh is default shell"
    else
        check_warn "Zsh is not default shell (current: $SHELL)"
    fi
}

check_symlinks() {
    print_section "Symlinks"

    local symlink_count=0
    local broken_count=0

    for symlink in ~/.zshrc ~/.gitconfig ~/.vimrc ~/.tmux.conf; do
        if [[ -L "$symlink" ]]; then
            ((symlink_count++))
            if [[ -e "$symlink" ]]; then
                check_pass "$(basename $symlink) → $(readlink $symlink)"
            else
                ((broken_count++))
                check_fail "$(basename $symlink) is broken"
            fi
        fi
    done

    if [[ $symlink_count -eq 0 ]]; then
        check_warn "No symlinks found (may not be installed yet)"
    fi
}

check_vim() {
    print_section "Editor Configuration"

    if command -v vim &> /dev/null; then
        local vim_version=$(vim --version | head -1)
        check_pass "Vim installed: $vim_version"
    else
        check_fail "Vim not installed"
    fi

    if command -v nvim &> /dev/null; then
        local nvim_version=$(nvim --version | head -1)
        check_pass "Neovim installed: $nvim_version"
    else
        check_warn "Neovim not installed (optional)"
    fi
}

check_git() {
    print_section "Git Configuration"

    if command -v git &> /dev/null; then
        check_pass "Git installed"

        if git config --global user.name &> /dev/null; then
            local git_user=$(git config --global user.name)
            check_pass "Git user configured: $git_user"
        else
            check_fail "Git user not configured"
        fi

        if git config --global user.email &> /dev/null; then
            local git_email=$(git config --global user.email)
            check_pass "Git email configured: $git_email"
        else
            check_fail "Git email not configured"
        fi
    else
        check_fail "Git not installed"
    fi
}

check_optional_tools() {
    print_section "Optional Tools"

    if command -v fzf &> /dev/null; then
        check_pass "fzf installed (fuzzy finder)"
    else
        check_warn "fzf not installed (command palette requires this)"
    fi

    if command -v lastpass-cli &> /dev/null || command -v lpass &> /dev/null; then
        check_pass "LastPass CLI installed"
    else
        check_warn "LastPass CLI not installed (password manager)"
    fi

    if command -v tmux &> /dev/null; then
        check_pass "Tmux installed"
    else
        check_warn "Tmux not installed (workspaces require this)"
    fi

    if command -v age &> /dev/null || command -v gpg &> /dev/null; then
        check_pass "Encryption tool available (age or gpg)"
    else
        check_warn "No encryption tool (vault requires age or gpg)"
    fi

    if command -v bat &> /dev/null; then
        check_pass "bat installed (syntax highlighting)"
    else
        check_warn "bat not installed (optional enhancement)"
    fi

    if command -v eza &> /dev/null; then
        check_pass "eza installed (ls replacement)"
    else
        check_warn "eza not installed (optional enhancement)"
    fi
}

check_pacman() {
    print_section "Package Manager"

    if command -v pacman &> /dev/null; then
        check_pass "Pacman available"
    else
        check_fail "Pacman not found (this is Arch/CachyOS only)"
    fi
}

check_permissions() {
    print_section "File Permissions"

    if [[ -f "$DOTFILES_HOME/install.sh" ]]; then
        if [[ -x "$DOTFILES_HOME/install.sh" ]]; then
            check_pass "install.sh is executable"
        else
            check_fail "install.sh is not executable"
        fi
    fi

    if [[ -d "$DOTFILES_HOME/bin" ]]; then
        local non_exec=$(find "$DOTFILES_HOME/bin" -type f ! -perm /u+x 2>/dev/null | wc -l)
        if [[ $non_exec -eq 0 ]]; then
            check_pass "All scripts in bin/ are executable"
        else
            check_fail "$non_exec scripts in bin/ are not executable"
        fi
    fi
}

check_zsh_plugins() {
    print_section "Zsh Plugins"

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        check_pass "Oh My Zsh installed"

        if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
            check_pass "zsh-autosuggestions installed"
        else
            check_warn "zsh-autosuggestions not installed"
        fi

        if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
            check_pass "zsh-syntax-highlighting installed"
        else
            check_warn "zsh-syntax-highlighting not installed"
        fi

        if [[ -f "$HOME/.oh-my-zsh/themes/adlee.zsh-theme" ]]; then
            check_pass "adlee theme installed"
        else
            check_warn "adlee theme not installed"
        fi
    else
        check_warn "Oh My Zsh not installed"
    fi
}

check_dotfiles_dir() {
    print_section "Dotfiles Directory"

    if [[ -d "$DOTFILES_HOME" ]]; then
        check_pass "Dotfiles directory found: $DOTFILES_HOME"
    else
        check_fail "Dotfiles directory not found: $DOTFILES_HOME"
        return
    fi

    if [[ -f "$DOTFILES_HOME/dotfiles.conf" ]]; then
        check_pass "Configuration file exists"
    else
        check_warn "Configuration file missing"
    fi

    if [[ -d "$DOTFILES_HOME/.git" ]]; then
        check_pass "Git repository initialized"
    else
        check_warn "Not a git repository"
    fi
}

# ============================================================================
# Print summary
# ============================================================================

print_summary() {
    echo ""
    printf "${DF_CYAN}─%.0s${DF_NC}" {1..70}; echo ""

    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${DF_GREEN}✓${DF_NC} All checks passed ($PASSED_CHECKS/$TOTAL_CHECKS)"
    else
        echo -e "${DF_RED}✗${DF_NC} Some checks failed"
        echo -e "  ${DF_GREEN}Passed:${DF_NC} $PASSED_CHECKS"
        echo -e "  ${DF_RED}Failed:${DF_NC} $FAILED_CHECKS"
        if [[ $WARNING_CHECKS -gt 0 ]]; then
            echo -e "  ${DF_YELLOW}Warnings:${DF_NC} $WARNING_CHECKS"
        fi
    fi

    echo ""

    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo -e "${DF_YELLOW}💡 Tip:${DF_NC} Run 'dotfiles-doctor.sh --fix' to attempt automatic fixes"
        echo ""
        return 1
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header

    check_os
    check_pacman
    check_shell
    check_vim
    check_git
    check_dotfiles_dir
    check_symlinks
    check_zsh_plugins
    check_optional_tools
    check_permissions

    print_summary
}

main "$@"
