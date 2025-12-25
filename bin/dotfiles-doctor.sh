#!/usr/bin/env bash
# ============================================================================
# Dotfiles Health Check (Arch/CachyOS)
# ============================================================================
# Comprehensive health check with Arch-specific diagnostics
#
# Usage:
#   dotfiles-doctor.sh          # Run all checks
#   dotfiles-doctor.sh --fix    # Attempt automatic fixes
#   dotfiles-doctor.sh --quick  # Quick essential checks only
# ============================================================================

# Note: Not using set -e because arithmetic operations can return non-zero

readonly DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
readonly DOTFILES_VERSION="3.1.0"

# Parse arguments
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

# Source shared colors
source "$DOTFILES_HOME/zsh/lib/colors.zsh" 2>/dev/null || {
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
}

# Source utils.zsh
source "$DOTFILES_HOME/zsh/lib/utils.zsh" 2>/dev/null

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0
FIXED_CHECKS=0

# ============================================================================
# MOTD-style header
# ============================================================================

print_header() {
    local user="${USER:-root}"
    local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
    local datetime=$(date '+%a %b %d %H:%M')
    local width=66
    local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

    echo ""
    echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
    echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}    ${DF_LIGHT_GREEN}dotfiles-doctor${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
    echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
    echo ""
}

# ============================================================================
# Health check functions
# ============================================================================

print_section() {
    echo -e "\n${DF_BLUE}▶${DF_NC} $1"
}

check_pass() {
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "  ${DF_GREEN}✓${DF_NC} $1"
}

check_fail() {
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "  ${DF_RED}✗${DF_NC} $1"
}

check_warn() {
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "  ${DF_YELLOW}⚠${DF_NC} $1"
}

check_fixed() {
    FIXED_CHECKS=$((FIXED_CHECKS + 1))
    echo -e "  ${DF_CYAN}⚙${DF_NC} Fixed: $1"
}

# ============================================================================
# Core Health Checks
# ============================================================================

check_os() {
    print_section "Operating System"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi "cachyos" /etc/os-release 2>/dev/null; then
            local version=$(grep "VERSION_ID" /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
            check_pass "Running CachyOS ${version}"
        elif grep -qi "arch" /etc/os-release 2>/dev/null; then
            check_pass "Running Arch Linux"
        else
            check_fail "Not running on Arch/CachyOS"
        fi
    else
        check_fail "Not running on Linux"
    fi

    # Kernel check
    local kernel=$(uname -r)
    if [[ "$kernel" == *"cachyos"* ]]; then
        check_pass "CachyOS kernel: $kernel"
    elif [[ "$kernel" == *"zen"* ]]; then
        check_pass "Zen kernel: $kernel"
    elif [[ "$kernel" == *"lts"* ]]; then
        check_pass "LTS kernel: $kernel"
    else
        check_pass "Kernel: $kernel"
    fi
}

check_shell() {
    print_section "Shell Configuration"

    if [[ -f "$HOME/.zshrc" ]]; then
        check_pass "Zsh configuration exists"
    else
        check_fail "Zsh configuration missing"
        if [[ "$DO_FIX" == true ]]; then
            ln -sf "$DOTFILES_HOME/zsh/.zshrc" "$HOME/.zshrc" 2>/dev/null && check_fixed ".zshrc symlink created"
        fi
    fi

    if [[ "$SHELL" == *"zsh"* ]]; then
        check_pass "Zsh is default shell"
    else
        check_warn "Zsh is not default shell (current: $SHELL)"
        if [[ "$DO_FIX" == true ]]; then
            echo "  Run: chsh -s \$(which zsh)"
        fi
    fi

    # Check if zsh is recent version
    if command -v zsh &>/dev/null; then
        local zsh_version=$(zsh --version | awk '{print $2}')
        check_pass "Zsh version: $zsh_version"
    fi
}

check_symlinks() {
    print_section "Symlinks"

    local symlink_count=0
    local broken_count=0

    for symlink in ~/.zshrc ~/.gitconfig ~/.vimrc ~/.tmux.conf; do
        if [[ -L "$symlink" ]]; then
            symlink_count=$((symlink_count + 1))
            if [[ -e "$symlink" ]]; then
                check_pass "$(basename $symlink) → $(readlink $symlink)"
            else
                broken_count=$((broken_count + 1))
                check_fail "$(basename $symlink) is broken"
            fi
        elif [[ -f "$symlink" ]]; then
            check_warn "$(basename $symlink) is regular file (not symlink)"
        fi
    done

    if [[ $symlink_count -eq 0 ]]; then
        check_warn "No symlinks found (may not be installed yet)"
    fi
}

check_vim() {
    print_section "Editor Configuration"

    if command -v vim &>/dev/null; then
        local vim_version=$(vim --version | head -1 | awk '{print $5}')
        check_pass "Vim installed: $vim_version"
    else
        check_fail "Vim not installed"
    fi

    if command -v nvim &>/dev/null; then
        local nvim_version=$(nvim --version | head -1 | awk '{print $2}')
        check_pass "Neovim installed: $nvim_version"
    else
        check_warn "Neovim not installed (optional)"
    fi
}

check_git() {
    print_section "Git Configuration"

    if command -v git &>/dev/null; then
        check_pass "Git installed"

        if git config --global user.name &>/dev/null; then
            local git_user=$(git config --global user.name)
            check_pass "Git user: $git_user"
        else
            check_fail "Git user not configured"
        fi

        if git config --global user.email &>/dev/null; then
            check_pass "Git email configured"
        else
            check_fail "Git email not configured"
        fi
    else
        check_fail "Git not installed"
    fi
}

# ============================================================================
# Arch-Specific Checks
# ============================================================================

check_pacman() {
    print_section "Package Manager"

    if command -v pacman &>/dev/null; then
        check_pass "Pacman available"
    else
        check_fail "Pacman not found"
        return
    fi

    # Check for AUR helper
    if command -v paru &>/dev/null; then
        check_pass "AUR helper: paru"
    elif command -v yay &>/dev/null; then
        check_pass "AUR helper: yay"
    else
        check_warn "No AUR helper installed (recommend: paru)"
    fi
}

check_pacman_health() {
    [[ "$QUICK_MODE" == true ]] && return

    print_section "Pacman Health"

    # Check for orphaned packages
    local orphans=$(pacman -Qtdq 2>/dev/null | wc -l)
    if [[ $orphans -eq 0 ]]; then
        check_pass "No orphaned packages"
    else
        check_warn "$orphans orphaned package(s)"
        if [[ "$DO_FIX" == true ]]; then
            echo "  Clean: pacman -Qtdq | sudo pacman -Rns -"
        fi
    fi

    # Check package cache size
    if [[ -d /var/cache/pacman/pkg ]]; then
        local cache_size=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
        local pkg_count=$(ls /var/cache/pacman/pkg 2>/dev/null | wc -l)

        if [[ $pkg_count -gt 500 ]]; then
            check_warn "Package cache: $cache_size ($pkg_count files)"
            if [[ "$DO_FIX" == true ]]; then
                echo "  Clean: sudo paccache -rk2"
            fi
        else
            check_pass "Package cache: $cache_size"
        fi
    fi

    # Check for available updates
    if command -v checkupdates &>/dev/null; then
        local updates=$(checkupdates 2>/dev/null | wc -l)
        if [[ $updates -eq 0 ]]; then
            check_pass "System up to date"
        else
            check_warn "$updates update(s) available"
        fi
    fi
}

check_systemd() {
    [[ "$QUICK_MODE" == true ]] && return

    print_section "Systemd Services"

    # Check for failed services
    local failed_count=$(systemctl --failed --no-pager --no-legend 2>/dev/null | wc -l)

    if [[ $failed_count -eq 0 ]]; then
        check_pass "No failed system services"
    else
        check_fail "$failed_count failed service(s)"
        systemctl --failed --no-pager --no-legend 2>/dev/null | head -3 | while read -r line; do
            local svc=$(echo "$line" | awk '{print $1}')
            echo -e "    ${DF_DIM}• $svc${DF_NC}"
        done
    fi

    # Check user services
    local user_failed=$(systemctl --user --failed --no-pager --no-legend 2>/dev/null | wc -l)
    if [[ $user_failed -eq 0 ]]; then
        check_pass "No failed user services"
    else
        check_warn "$user_failed failed user service(s)"
    fi
}

check_btrfs() {
    [[ "$QUICK_MODE" == true ]] && return

    # Only check if root is btrfs
    local fstype=$(df -T / 2>/dev/null | awk 'NR==2 {print $2}')
    [[ "$fstype" != "btrfs" ]] && return

    print_section "Btrfs Filesystem"

    check_pass "Root filesystem: btrfs"

    # Check for device errors
    local stats=$(sudo btrfs device stats / 2>/dev/null)
    local errors=$(echo "$stats" | grep -v " 0$" | grep -v "^$")

    if [[ -z "$errors" ]]; then
        check_pass "No btrfs device errors"
    else
        check_fail "Btrfs errors detected!"
        echo "$errors" | head -3 | while read -r line; do
            echo -e "    ${DF_DIM}$line${DF_NC}"
        done
    fi

    # Check last scrub
    local scrub_info=$(sudo btrfs scrub status / 2>/dev/null)
    if echo "$scrub_info" | grep -q "running"; then
        check_pass "Scrub currently running"
    elif echo "$scrub_info" | grep -q "finished"; then
        local scrub_date=$(echo "$scrub_info" | grep "Scrub started" | awk '{print $3, $4}')
        check_pass "Last scrub: $scrub_date"
    else
        check_warn "No scrub history (recommend monthly)"
    fi

    # Check snapper
    if command -v snapper &>/dev/null && [[ -d "/.snapshots" ]]; then
        local snap_count=$(sudo snapper -c root list 2>/dev/null | tail -n +3 | wc -l)
        check_pass "Snapper: $snap_count snapshot(s)"
    fi
}

# ============================================================================
# Standard Checks
# ============================================================================

check_optional_tools() {
    print_section "Optional Tools"

    if command -v fzf &>/dev/null; then
        check_pass "fzf (fuzzy finder)"
    else
        check_warn "fzf not installed (command palette needs this)"
    fi

    if command -v bat &>/dev/null; then
        check_pass "bat (syntax highlighting)"
    else
        check_warn "bat not installed"
    fi

    if command -v eza &>/dev/null; then
        check_pass "eza (modern ls)"
    else
        check_warn "eza not installed"
    fi

    if command -v tmux &>/dev/null; then
        check_pass "tmux (terminal multiplexer)"
    else
        check_warn "tmux not installed"
    fi

    if command -v age &>/dev/null || command -v gpg &>/dev/null; then
        check_pass "Encryption available (age/gpg)"
    else
        check_warn "No encryption tool (vault needs age/gpg)"
    fi
}

check_permissions() {
    print_section "File Permissions"

    if [[ -f "$DOTFILES_HOME/install.sh" ]]; then
        if [[ -x "$DOTFILES_HOME/install.sh" ]]; then
            check_pass "install.sh is executable"
        else
            check_fail "install.sh is not executable"
            if [[ "$DO_FIX" == true ]]; then
                chmod +x "$DOTFILES_HOME/install.sh"
                check_fixed "install.sh permissions"
            fi
        fi
    fi

    if [[ -d "$DOTFILES_HOME/bin" ]]; then
        local non_exec=$(find "$DOTFILES_HOME/bin" -type f ! -perm /u+x 2>/dev/null | wc -l)
        if [[ $non_exec -eq 0 ]]; then
            check_pass "All bin/ scripts executable"
        else
            check_fail "$non_exec bin/ scripts not executable"
            if [[ "$DO_FIX" == true ]]; then
                find "$DOTFILES_HOME/bin" -type f ! -perm /u+x -exec chmod +x {} \;
                check_fixed "bin/ permissions"
            fi
        fi
    fi
}

check_zsh_plugins() {
    print_section "Zsh Plugins"

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        check_pass "Oh My Zsh installed"

        if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
            check_pass "zsh-autosuggestions"
        else
            check_warn "zsh-autosuggestions not installed"
        fi

        if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
            check_pass "zsh-syntax-highlighting"
        else
            check_warn "zsh-syntax-highlighting not installed"
        fi

        if [[ -f "$HOME/.oh-my-zsh/themes/adlee.zsh-theme" ]]; then
            check_pass "adlee theme"
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
        check_pass "Dotfiles: $DOTFILES_HOME"
    else
        check_fail "Dotfiles not found: $DOTFILES_HOME"
        return
    fi

    if [[ -f "$DOTFILES_HOME/dotfiles.conf" ]]; then
        check_pass "Config file exists"
    else
        check_warn "Config file missing"
    fi

    if [[ -d "$DOTFILES_HOME/.git" ]]; then
        check_pass "Git repo initialized"

        # Check for uncommitted changes
        local changes=$(cd "$DOTFILES_HOME" && git status --porcelain 2>/dev/null | wc -l)
        if [[ $changes -gt 0 ]]; then
            check_warn "$changes uncommitted change(s)"
        fi
    else
        check_warn "Not a git repository"
    fi
}

# ============================================================================
# Print Summary
# ============================================================================

print_summary() {
    echo ""
    printf "${DF_CYAN}─%.0s${DF_NC}" {1..70}; echo ""

    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${DF_GREEN}✓${DF_NC} All checks passed ($PASSED_CHECKS/$TOTAL_CHECKS)"
    else
        echo -e "${DF_RED}✗${DF_NC} Issues found"
        echo -e "  ${DF_GREEN}Passed:${DF_NC}   $PASSED_CHECKS"
        echo -e "  ${DF_RED}Failed:${DF_NC}   $FAILED_CHECKS"
        if [[ $WARNING_CHECKS -gt 0 ]]; then
            echo -e "  ${DF_YELLOW}Warnings:${DF_NC} $WARNING_CHECKS"
        fi
        if [[ $FIXED_CHECKS -gt 0 ]]; then
            echo -e "  ${DF_CYAN}Fixed:${DF_NC}    $FIXED_CHECKS"
        fi
    fi

    echo ""

    if [[ $FAILED_CHECKS -gt 0 && "$DO_FIX" != true ]]; then
        echo -e "${DF_YELLOW}💡${DF_NC} Run with --fix to attempt automatic fixes"
        echo ""
        return 1
    fi

    if [[ $FIXED_CHECKS -gt 0 ]]; then
        echo -e "${DF_CYAN}ℹ${DF_NC} Fixed $FIXED_CHECKS issue(s). Run again to verify."
        echo ""
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header

    # Essential checks (always run)
    check_os
    check_pacman
    check_shell
    check_dotfiles_dir
    check_symlinks

    # Additional checks (skip in quick mode)
    if [[ "$QUICK_MODE" != true ]]; then
        check_vim
        check_git
        check_zsh_plugins
        check_optional_tools
        check_permissions
        check_pacman_health
        check_systemd
        check_btrfs
    fi

    print_summary
}

main "$@"
