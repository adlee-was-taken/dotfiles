#!/usr/bin/env bash
# ============================================================================
# Dotfiles Health Check (Arch/CachyOS)
# ============================================================================
# Usage:
#   dotfiles-doctor.sh          # Run all checks
#   dotfiles-doctor.sh --fix    # Attempt automatic fixes
#   dotfiles-doctor.sh --quick  # Quick essential checks only
# ============================================================================

# Source bootstrap (provides colors, config, and utility functions)
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    echo "Warning: bootstrap.zsh not found, using fallbacks"
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
    df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
}

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

# ============================================================================
# Tracking Variables
# ============================================================================

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0
FIXED_CHECKS=0

# ============================================================================
# Check Helper Functions
# ============================================================================

print_section() { echo -e "\n${DF_BLUE}▶${DF_NC} $1"; }

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

check_fixed() {
    ((FIXED_CHECKS++))
    echo -e "  ${DF_CYAN}⚙${DF_NC} Fixed: $1"
}

# ============================================================================
# Check Functions
# ============================================================================

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

    if command -v zsh &>/dev/null; then
        check_pass "Zsh version: $(zsh --version | awk '{print $2}')"
    fi
}

check_symlinks() {
    print_section "Checking Dotfiles Symlinks"

    local symlinks=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.tmux.conf"
    )

    for symlink in "${symlinks[@]}"; do
        if [[ -L "$symlink" ]]; then
            if [[ -e "$symlink" ]]; then
                check_pass "$(basename "$symlink") → $(readlink "$symlink")"
            else
                check_fail "$(basename "$symlink") is broken symlink"
                if [[ "$DO_FIX" == true ]]; then
                    rm "$symlink"
                    check_fixed "Removed broken symlink: $(basename "$symlink")"
                fi
            fi
        elif [[ -f "$symlink" ]]; then
            check_warn "$(basename "$symlink") is regular file (not symlink)"
        fi
    done
}

check_pacman() {
    print_section "Package Manager"

    if ! command -v pacman &>/dev/null; then
        check_fail "Pacman not found"
        return
    fi

    check_pass "Pacman available"

    if command -v paru &>/dev/null; then
        check_pass "AUR helper: paru"
    elif command -v yay &>/dev/null; then
        check_pass "AUR helper: yay"
    else
        check_warn "No AUR helper installed (paru or yay recommended)"
    fi
}

check_optional_tools() {
    print_section "Optional Tools"

    local tools=("fzf" "bat" "eza" "tmux" "nvim")
    for tool in "${tools[@]}"; do
        command -v "$tool" &>/dev/null && check_pass "$tool" || check_warn "$tool not installed"
    done
}

check_dotfiles_dir() {
    print_section "Dotfiles Directory"

    if [[ ! -d "$DOTFILES_HOME" ]]; then
        check_fail "Dotfiles not found"
        return
    fi

    check_pass "Dotfiles: $DOTFILES_HOME"

    [[ -f "$DOTFILES_HOME/dotfiles.conf" ]] && check_pass "Config file exists" || check_warn "Config file missing"
    [[ -d "$DOTFILES_HOME/.git" ]] && check_pass "Git repo initialized" || check_warn "Not a git repository"

    check_pass "Version: ${DOTFILES_VERSION:-unknown}"
    check_pass "Display width: ${DF_WIDTH:-66}"
}

check_bin_scripts() {
    print_section "Bin Script Symlinks: ${DF_LIGHT_GREY}.local/bin${DF_NC}"

    local scripts=(
        "dotfiles-doctor.sh"
        "dotfiles-sync.sh"
        "dotfiles-update.sh"
        "dotfiles-version.sh"
    )

    for script in "${scripts[@]}"; do
        if [[ -x "$HOME/.local/bin/$script" ]]; then
            check_pass "$script"
        elif [[ -f "$HOME/.local/bin/$script" ]]; then
            check_warn "$script exists but not executable"
            if [[ "$DO_FIX" == true ]]; then
                chmod +x "$HOME/.local/bin/$script"
                check_fixed "Made executable: $script"
            fi
        else
            check_fail "$script not linked"
            if [[ "$DO_FIX" == true ]]; then
                ln -s "$DOTFILES_HOME/bin/$script" "$HOME/.local/bin/$script"
                chmod +x "$HOME/.local/bin/$script"
                check_fixed "Created executable symlink: $script"
            fi
        fi
    done
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
    local width="${DF_WIDTH:-66}"
    echo ""
    printf "${DF_CYAN}─%.0s${DF_NC}" $(seq 1 "$width")
    echo ""

    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${DF_GREEN}✓${DF_NC} All checks passed ($PASSED_CHECKS/$TOTAL_CHECKS)"
    else
        echo -e "${DF_RED}✗${DF_NC} Issues found: $FAILED_CHECKS failed, $WARNING_CHECKS warnings"
    fi

    [[ $FIXED_CHECKS -gt 0 ]] && echo -e "${DF_CYAN}⚙${DF_NC} Auto-fixed: $FIXED_CHECKS issues"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    df_print_header "dotfiles-doctor"

    check_os
    check_pacman
    check_shell
    check_dotfiles_dir
    check_symlinks

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional_tools
        check_bin_scripts
    fi

    print_summary
}

main "$@"
