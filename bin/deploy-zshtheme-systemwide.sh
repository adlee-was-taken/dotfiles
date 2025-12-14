#!/usr/bin/env bash
# ============================================================================
# ADLee Theme System-wide Deployment Script
# ============================================================================
# Deploys the zsh theme system-wide via symlinks
#
# Usage:
#   sudo ./deploy-zshtheme-systemwide.sh              # Interactive mode
#   sudo ./deploy-zshtheme-systemwide.sh --all        # All users with oh-my-zsh
#   sudo ./deploy-zshtheme-systemwide.sh --current    # Current user + root only
#   sudo ./deploy-zshtheme-systemwide.sh --status     # Show deployment status
#   sudo ./deploy-zshtheme-systemwide.sh --force      # Force replace existing links

set -euo pipefail

# ============================================================================
# Load Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_CONF="${SCRIPT_DIR}/../dotfiles.conf"
[[ -f "$DOTFILES_CONF" ]] || DOTFILES_CONF="$HOME/.dotfiles/dotfiles.conf"

if [[ -f "$DOTFILES_CONF" ]]; then
    source "$DOTFILES_CONF"
else
    DOTFILES_DIR="$HOME/.dotfiles"
    ZSH_THEME_NAME="adlee"
fi

# ============================================================================
# Configuration
# ============================================================================

MASTER_THEME_DIR="/usr/local/share/zsh/themes"
THEME_FILE="${ZSH_THEME_NAME}.zsh-theme"
MASTER_THEME_PATH="${MASTER_THEME_DIR}/${THEME_FILE}"
SOURCE_THEME="${DOTFILES_DIR}/zsh/themes/${THEME_FILE}"
FORCE_REPLACE=false

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }
print_step() { echo -e "\n${GREEN}==>${NC} $1"; }

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${ZSH_THEME_NAME} Theme System-wide Deployment                       ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        echo "Usage: sudo $0 [--all|--current|--status]"
        exit 1
    fi
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

is_system_symlink() {
    local path="$1"
    [[ -L "$path" ]] && [[ "$(readlink -f "$path")" == "$MASTER_THEME_PATH" ]]
}

is_local_symlink() {
    local path="$1"
    if [[ -L "$path" ]]; then
        local target=$(readlink -f "$path")
        [[ "$target" == *"/.dotfiles/"* ]]
    else
        return 1
    fi
}

get_link_status() {
    local path="$1"

    if [[ ! -e "$path" ]] && [[ ! -L "$path" ]]; then
        echo "not_present"
    elif is_system_symlink "$path"; then
        echo "system_link"
    elif is_local_symlink "$path"; then
        echo "local_link"
    elif [[ -f "$path" ]] && [[ ! -L "$path" ]]; then
        echo "regular_file"
    elif [[ -L "$path" ]]; then
        echo "other_link"
    else
        echo "unknown"
    fi
}

# ============================================================================
# Setup Functions
# ============================================================================

setup_master_location() {
    print_step "Setting up master theme location"

    [[ ! -d "$MASTER_THEME_DIR" ]] && mkdir -p "$MASTER_THEME_DIR" && print_success "Created: $MASTER_THEME_DIR"

    local source_file=""
    [[ -f "$SOURCE_THEME" ]] && source_file="$SOURCE_THEME"
    [[ -z "$source_file" && -f "$THEME_FILE" ]] && source_file="$THEME_FILE"
    [[ -z "$source_file" && -f "$HOME/.oh-my-zsh/themes/$THEME_FILE" ]] && source_file="$HOME/.oh-my-zsh/themes/$THEME_FILE"

    if [[ -f "$MASTER_THEME_PATH" ]]; then
        print_info "Master theme exists: $MASTER_THEME_PATH"
        if [[ -n "$source_file" ]] && ! diff -q "$source_file" "$MASTER_THEME_PATH" &>/dev/null; then
            print_warning "Source differs from master"
            if ask_yes_no "Update master theme?"; then
                cp "$source_file" "$MASTER_THEME_PATH"
                chmod 644 "$MASTER_THEME_PATH"
                print_success "Master theme updated"
            fi
        fi
    else
        if [[ -z "$source_file" ]]; then
            print_error "Theme file not found. Check these locations:"
            echo "  - $SOURCE_THEME"
            echo "  - ./$THEME_FILE"
            exit 1
        fi
        cp "$source_file" "$MASTER_THEME_PATH"
        chmod 644 "$MASTER_THEME_PATH"
        print_success "Copied theme to master location"
    fi
}

get_users_with_tty() {
    local users=()
    [[ -d "/root/.oh-my-zsh" ]] && users+=("root")

    while IFS=: read -r username _ uid _ _ home_dir _; do
        [[ $uid -lt 1000 ]] && continue
        [[ -d "$home_dir/.oh-my-zsh" ]] && users+=("$username")
    done < /etc/passwd

    echo "${users[@]}"
}

get_current_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    else
        while IFS=: read -r username _ uid _ _ home_dir _; do
            if [[ $uid -ge 1000 ]] && [[ -d "$home_dir/.oh-my-zsh" ]]; then
                echo "$username"
                return
            fi
        done < /etc/passwd
    fi
}

select_users() {
    local mode="$1"
    local users=()

    case "$mode" in
        all)
            users=($(get_users_with_tty))
            ;;
        current)
            local current_user=$(get_current_user)
            [[ -n "$current_user" ]] && users=("$current_user")
            [[ -d "/root/.oh-my-zsh" ]] && users+=("root")
            ;;
        interactive)
            local all_users=($(get_users_with_tty))
            [[ ${#all_users[@]} -eq 0 ]] && { print_error "No users with oh-my-zsh found"; exit 1; }

            echo "Users with oh-my-zsh:"
            for i in "${!all_users[@]}"; do
                echo "  $((i+1)). ${all_users[$i]}"
            done
            echo

            if ask_yes_no "Deploy to all users?"; then
                users=("${all_users[@]}")
            else
                local current_user=$(get_current_user)
                [[ -n "$current_user" ]] && users=("$current_user") && print_info "Selected: $current_user"
                [[ -d "/root/.oh-my-zsh" ]] && ask_yes_no "Include root?" && users+=("root")
            fi
            ;;
    esac

    echo "${users[@]}"
}

deploy_for_user() {
    local username="$1"
    local home_dir=$([[ "$username" == "root" ]] && echo "/root" || eval echo "~$username")

    [[ ! -d "$home_dir" ]] && { print_warning "Home not found: $username"; return 1; }
    [[ ! -d "$home_dir/.oh-my-zsh" ]] && { print_warning "oh-my-zsh not installed: $username"; return 1; }

    local theme_link="$home_dir/.oh-my-zsh/themes/$THEME_FILE"
    local status=$(get_link_status "$theme_link")

    case "$status" in
        system_link)
            [[ "$FORCE_REPLACE" != true ]] && { print_success "Already system-wide: $username"; return 0; }
            print_info "Recreating link: $username"
            ;;
        local_link) print_info "Converting local → system: $username" ;;
        regular_file) print_warning "Replacing file → system: $username" ;;
        *) print_info "Creating link: $username" ;;
    esac

    mkdir -p "$home_dir/.oh-my-zsh/themes"
    rm -f "$theme_link"
    ln -sf "$MASTER_THEME_PATH" "$theme_link"

    [[ "$username" != "root" ]] && chown -h "$username:$(id -gn "$username" 2>/dev/null || echo "$username")" "$theme_link" 2>/dev/null || true

    is_system_symlink "$theme_link" && print_success "Deployed: $username" || { print_error "Failed: $username"; return 1; }
}

show_deployment_status() {
    print_step "Deployment status"

    local users=($(get_users_with_tty))
    [[ ${#users[@]} -eq 0 ]] && { print_warning "No users with oh-my-zsh"; return; }

    echo
    printf "%-20s %-20s %s\n" "User" "Status" "Details"
    printf "%-20s %-20s %s\n" "----" "------" "-------"

    for user in "${users[@]}"; do
        local home_dir=$([[ "$user" == "root" ]] && echo "/root" || eval echo "~$user")
        local theme_path="$home_dir/.oh-my-zsh/themes/$THEME_FILE"
        local status=$(get_link_status "$theme_path")

        case "$status" in
            system_link) printf "%-20s ${GREEN}%-20s${NC} %s\n" "$user" "System-wide ✓" "→ $MASTER_THEME_PATH" ;;
            local_link) printf "%-20s ${YELLOW}%-20s${NC} %s\n" "$user" "Local symlink" "→ $(readlink "$theme_path")" ;;
            regular_file) printf "%-20s ${CYAN}%-20s${NC} %s\n" "$user" "Regular file" "(standalone)" ;;
            not_present) printf "%-20s ${RED}%-20s${NC}\n" "$user" "Not installed" ;;
            *) printf "%-20s ${RED}%-20s${NC}\n" "$user" "Unknown" ;;
        esac
    done
    echo
}

show_summary() {
    echo
    echo "============================================================================"
    echo "Master theme: $MASTER_THEME_PATH"
    echo
    echo "To update theme globally:"
    echo "  sudo cp $SOURCE_THEME $MASTER_THEME_PATH"
    echo
    echo "Check status: sudo $0 --status"
    echo "============================================================================"
}

# ============================================================================
# Main
# ============================================================================

main() {
    local mode="interactive"
    local status_only=false

    for arg in "$@"; do
        case "$arg" in
            --all) mode="all" ;;
            --current) mode="current" ;;
            --force) FORCE_REPLACE=true ;;
            --status|-s) status_only=true ;;
            --help|-h)
                echo "Usage: sudo $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --all      Deploy to all users with oh-my-zsh"
                echo "  --current  Deploy to current user and root"
                echo "  --force    Force replacement of existing links"
                echo "  --status   Show current deployment status"
                echo "  --help     Show this help"
                exit 0
                ;;
            *) print_error "Unknown option: $arg"; exit 1 ;;
        esac
    done

    print_header
    check_root

    if [[ "$status_only" == true ]]; then
        show_deployment_status
        exit 0
    fi

    show_deployment_status
    setup_master_location

    local users=($(select_users "$mode"))
    [[ ${#users[@]} -eq 0 ]] && { print_error "No users selected"; exit 1; }

    print_step "Deploying to ${#users[@]} user(s): ${users[*]}"
    [[ "$FORCE_REPLACE" == true ]] && print_warning "Force mode enabled"

    ask_yes_no "Proceed?" || { print_warning "Cancelled"; exit 0; }

    echo
    local ok=0 fail=0
    for user in "${users[@]}"; do
        deploy_for_user "$user" && ((ok++)) || ((fail++))
    done

    echo
    [[ $fail -eq 0 ]] && print_success "Complete! ($ok/${#users[@]})" || print_warning "Done with errors ($ok ok, $fail failed)"

    show_deployment_status
    show_summary
}

main "$@"
