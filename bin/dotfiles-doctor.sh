#!/usr/bin/env bash
# ============================================================================
# Dotfiles Health Check (Arch/CachyOS)
# ============================================================================
# Usage:
#   dotfiles-doctor.sh          # Run all checks
#   dotfiles-doctor.sh --fix    # Attempt automatic fixes
#   dotfiles-doctor.sh --quick  # Quick essential checks only
# ============================================================================

# ============================================================================
# Source Configuration
# ============================================================================
# utils.zsh sources config.zsh which sources dotfiles.conf
# This gives us access to all settings including DF_WIDTH, DOTFILES_VERSION, etc.

_df_source_config() {
    local locations=(
        "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/utils.zsh"
        "$HOME/.dotfiles/zsh/lib/utils.zsh"
    )
    for loc in "${locations[@]}"; do
        [[ -f "$loc" ]] && { source "$loc"; return 0; }
    done
    
    # Fallback defaults if utils.zsh not found
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m' DF_LIGHT_GREEN=$'\033[38;5;82m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    DOTFILES_VERSION="${DOTFILES_VERSION:-unknown}"
    DF_WIDTH="${DF_WIDTH:-66}"
}

_df_source_config

# ============================================================================
# Parse Arguments
# ============================================================================

DO_FIX=false
QUICK_MODE=false
for arg in "$@"; do
    case "$arg" in
        --fix) DO_FIX=true ;;
        --quick) QUICK_MODE=true ;;
        --help|-h)
            echo "Usage: dotfiles-doctor.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --fix     Attempt automatic fixes for issues"
            echo "  --quick   Run quick essential checks only"
            echo "  --help    Show this help"
            exit 0
            ;;
    esac
done

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0
FIXED_CHECKS=0

# ============================================================================
# Header (uses DF_WIDTH from config)
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-doctor"
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width="${DF_WIDTH:-66}"
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}    ${DF_LIGHT_GREEN}dotfiles-doctor${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

# ============================================================================
# Check Functions
# ============================================================================

print_section() { echo -e "\n${DF_BLUE}▶${DF_NC} $1"; }
check_pass() { PASSED_CHECKS=$((PASSED_CHECKS + 1)); TOTAL_CHECKS=$((TOTAL_CHECKS + 1)); echo -e "  ${DF_GREEN}✓${DF_NC} $1"; }
check_fail() { FAILED_CHECKS=$((FAILED_CHECKS + 1)); TOTAL_CHECKS=$((TOTAL_CHECKS + 1)); echo -e "  ${DF_RED}✗${DF_NC} $1"; }
check_warn() { WARNING_CHECKS=$((WARNING_CHECKS + 1)); TOTAL_CHECKS=$((TOTAL_CHECKS + 1)); echo -e "  ${DF_YELLOW}⚠${DF_NC} $1"; }
check_fixed() { FIXED_CHECKS=$((FIXED_CHECKS + 1)); echo -e "  ${DF_CYAN}⚙${DF_NC} Fixed: $1"; }

check_os() {
    print_section "Operating System"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi "cachyos" /etc/os-release 2>/dev/null; then
            check_pass "Running CachyOS"
        elif grep -qi "arch" /etc/os-release 2>/dev/null; then
            check_pass "Running Arch Linux"
        else
            check_fail "Not running on Arch/CachyOS"
        fi
    else
        check_fail "Not running on Linux"
    fi
    check_pass "Kernel: $(uname -r)"
}

check_shell() {
    print_section "Shell Configuration"
    [[ -f "$HOME/.zshrc" ]] && check_pass "Zsh configuration exists" || check_fail "Zsh configuration missing"
    [[ "$SHELL" == *"zsh"* ]] && check_pass "Zsh is default shell" || check_warn "Zsh is not default shell"
    command -v zsh &>/dev/null && check_pass "Zsh version: $(zsh --version | awk '{print $2}')"
}

check_symlinks() {
    print_section "Symlinks"
    for symlink in ~/.zshrc ~/.gitconfig ~/.vimrc ~/.tmux.conf; do
        if [[ -L "$symlink" ]]; then
            [[ -e "$symlink" ]] && check_pass "$(basename $symlink) → $(readlink $symlink)" || check_fail "$(basename $symlink) is broken"
        elif [[ -f "$symlink" ]]; then
            check_warn "$(basename $symlink) is regular file (not symlink)"
        fi
    done
}

check_pacman() {
    print_section "Package Manager"
    command -v pacman &>/dev/null && check_pass "Pacman available" || { check_fail "Pacman not found"; return; }
    command -v paru &>/dev/null && check_pass "AUR helper: paru" || \
    command -v yay &>/dev/null && check_pass "AUR helper: yay" || check_warn "No AUR helper installed"
}

check_optional_tools() {
    print_section "Optional Tools"
    command -v fzf &>/dev/null && check_pass "fzf" || check_warn "fzf not installed"
    command -v bat &>/dev/null && check_pass "bat" || check_warn "bat not installed"
    command -v eza &>/dev/null && check_pass "eza" || check_warn "eza not installed"
    command -v tmux &>/dev/null && check_pass "tmux" || check_warn "tmux not installed"
}

check_dotfiles_dir() {
    print_section "Dotfiles Directory"
    [[ -d "$DOTFILES_HOME" ]] && check_pass "Dotfiles: $DOTFILES_HOME" || { check_fail "Dotfiles not found"; return; }
    [[ -f "$DOTFILES_HOME/dotfiles.conf" ]] && check_pass "Config file exists" || check_warn "Config file missing"
    [[ -d "$DOTFILES_HOME/.git" ]] && check_pass "Git repo initialized" || check_warn "Not a git repository"
    check_pass "Version: $DOTFILES_VERSION"
    check_pass "Display width: $DF_WIDTH"
}

print_summary() {
    local width="${DF_WIDTH:-66}"
    echo ""
    printf "${DF_CYAN}─%.0s${DF_NC}" $(seq 1 $width); echo ""
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${DF_GREEN}✓${DF_NC} All checks passed ($PASSED_CHECKS/$TOTAL_CHECKS)"
    else
        echo -e "${DF_RED}✗${DF_NC} Issues found: $FAILED_CHECKS failed, $WARNING_CHECKS warnings"
    fi
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header
    check_os
    check_pacman
    check_shell
    check_dotfiles_dir
    check_symlinks
    [[ "$QUICK_MODE" != true ]] && check_optional_tools
    print_summary
}

main "$@"
