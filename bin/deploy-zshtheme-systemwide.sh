#!/usr/bin/env bash
# ============================================================================
# ADLee Theme System-wide Deployment Script (Enhanced)
# ============================================================================
# This script deploys the adlee.zsh-theme system-wide via symlinks
# Usage:
#   sudo ./deploy-theme-systemwide.sh              # Interactive mode
#   sudo ./deploy-theme-systemwide.sh --all        # All users with TTY
#   sudo ./deploy-theme-systemwide.sh --current    # Current user + root only
#   sudo ./deploy-theme-systemwide.sh --force      # Force replace all links

set -euo pipefail

# Configuration
MASTER_THEME_DIR="/usr/local/share/zsh/themes"
MASTER_THEME_PATH="${MASTER_THEME_DIR}/adlee.zsh-theme"
THEME_NAME="adlee.zsh-theme"
SOURCE_THEME="${HOME}/.dotfiles/zsh/themes/${THEME_NAME}"
FORCE_REPLACE=false

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_step() {
    echo -e "\n${GREEN}==>${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ADLee Theme System-wide Deployment                      ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        echo "Usage: sudo $0 [--all|--current]"
        exit 1
    fi
}

# Ask yes/no question
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

# Check if a path is a symlink pointing to master theme
is_system_symlink() {
    local path="$1"
    [[ -L "$path" ]] && [[ "$(readlink -f "$path")" == "$MASTER_THEME_PATH" ]]
}

# Check if a path is a local symlink (from dotfiles)
is_local_symlink() {
    local path="$1"
    if [[ -L "$path" ]]; then
        local target=$(readlink -f "$path")
        [[ "$target" == *"/.dotfiles/"* ]]
    else
        return 1
    fi
}

# Check if a path is a regular file
is_regular_file() {
    local path="$1"
    [[ -f "$path" ]] && [[ ! -L "$path" ]]
}

# Get link status description
get_link_status() {
    local path="$1"

    if [[ ! -e "$path" ]] && [[ ! -L "$path" ]]; then
        echo "not_present"
    elif is_system_symlink "$path"; then
        echo "system_link"
    elif is_local_symlink "$path"; then
        echo "local_link"
    elif is_regular_file "$path"; then
        echo "regular_file"
    elif [[ -L "$path" ]]; then
        echo "other_link"
    else
        echo "unknown"
    fi
}

# ============================================================================
# Master Theme Setup
# ============================================================================

setup_master_location() {
    print_step "Setting up master theme location"

    # Create directory if it doesn't exist
    if [[ ! -d "$MASTER_THEME_DIR" ]]; then
        mkdir -p "$MASTER_THEME_DIR"
        print_success "Created directory: $MASTER_THEME_DIR"
    fi

    # Determine source file
    local source_file=""

    if [[ -f "$SOURCE_THEME" ]]; then
        source_file="$SOURCE_THEME"
    elif [[ -f "$THEME_NAME" ]]; then
        source_file="$THEME_NAME"
    elif [[ -f "$HOME/.oh-my-zsh/themes/$THEME_NAME" ]]; then
        source_file="$HOME/.oh-my-zsh/themes/$THEME_NAME"
    fi

    # Copy or verify master theme
    if [[ -f "$MASTER_THEME_PATH" ]]; then
        print_info "Master theme already exists: $MASTER_THEME_PATH"

        if [[ -n "$source_file" ]]; then
            # Check if update is needed
            if ! diff -q "$source_file" "$MASTER_THEME_PATH" &>/dev/null; then
                print_warning "Source theme differs from master"
                if ask_yes_no "Update master theme from source?"; then
                    cp "$source_file" "$MASTER_THEME_PATH"
                    chmod 644 "$MASTER_THEME_PATH"
                    print_success "Master theme updated"
                fi
            else
                print_success "Master theme is up to date"
            fi
        fi
    else
        if [[ -z "$source_file" ]]; then
            print_error "Theme file not found. Please ensure $THEME_NAME exists in:"
            echo "  - $SOURCE_THEME"
            echo "  - ./$THEME_NAME"
            echo "  - ~/.oh-my-zsh/themes/$THEME_NAME"
            exit 1
        fi

        cp "$source_file" "$MASTER_THEME_PATH"
        chmod 644 "$MASTER_THEME_PATH"
        print_success "Copied theme to master location"
    fi
}

# ============================================================================
# User Detection and Selection
# ============================================================================

get_users_with_tty() {
    local users=()

    # Add root if oh-my-zsh is installed
    if [[ -d "/root/.oh-my-zsh" ]]; then
        users+=("root")
    fi

    # Find regular users with oh-my-zsh
    while IFS=: read -r username _ uid _ _ home_dir shell; do
        # Skip system users (UID < 1000)
        [[ $uid -lt 1000 ]] && continue

        # Check if user has oh-my-zsh
        if [[ -d "$home_dir/.oh-my-zsh" ]]; then
            users+=("$username")
        fi
    done < /etc/passwd

    echo "${users[@]}"
}

get_current_user() {
    # Get the user who invoked sudo
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    else
        # Fallback to first non-root user with oh-my-zsh
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
            if [[ -n "$current_user" ]]; then
                users=("$current_user")
            fi
            if [[ -d "/root/.oh-my-zsh" ]]; then
                users+=("root")
            fi
            ;;
        interactive)
            local all_users=($(get_users_with_tty))

            if [[ ${#all_users[@]} -eq 0 ]]; then
                print_error "No users with oh-my-zsh found"
                exit 1
            fi

            echo "Users with oh-my-zsh detected:"
            for i in "${!all_users[@]}"; do
                echo "  $((i+1)). ${all_users[$i]}"
            done
            echo

            if ask_yes_no "Deploy to all users?"; then
                users=("${all_users[@]}")
            else
                local current_user=$(get_current_user)
                if [[ -n "$current_user" ]]; then
                    users=("$current_user")
                    print_info "Selected: $current_user"
                fi

                if [[ -d "/root/.oh-my-zsh" ]]; then
                    if ask_yes_no "Include root user?"; then
                        users+=("root")
                    fi
                fi
            fi
            ;;
    esac

    echo "${users[@]}"
}

# ============================================================================
# Deployment Functions
# ============================================================================

analyze_user_theme() {
    local username="$1"
    local home_dir

    if [[ "$username" == "root" ]]; then
        home_dir="/root"
    else
        home_dir=$(eval echo "~$username")
    fi

    local theme_path="$home_dir/.oh-my-zsh/themes/$THEME_NAME"
    local status=$(get_link_status "$theme_path")

    echo "$status"
}

deploy_for_user() {
    local username="$1"
    local home_dir

    # Get home directory
    if [[ "$username" == "root" ]]; then
        home_dir="/root"
    else
        home_dir=$(eval echo "~$username")
    fi

    # Check if user's home directory exists
    if [[ ! -d "$home_dir" ]]; then
        print_warning "Home directory not found for user: $username"
        return 1
    fi

    local oh_my_zsh_themes="$home_dir/.oh-my-zsh/themes"
    local theme_link="$oh_my_zsh_themes/$THEME_NAME"

    # Check if oh-my-zsh is installed
    if [[ ! -d "$home_dir/.oh-my-zsh" ]]; then
        print_warning "oh-my-zsh not installed for user: $username"
        return 1
    fi

    # Analyze current status
    local status=$(get_link_status "$theme_link")

    case "$status" in
        system_link)
            if [[ "$FORCE_REPLACE" == true ]]; then
                print_info "Recreating system-wide link for: $username"
            else
                print_success "✓ Already using system-wide theme: $username"
                return 0
            fi
            ;;
        local_link)
            print_info "Converting local symlink → system-wide for: $username"
            ;;
        regular_file)
            print_warning "Replacing regular file → system-wide for: $username"
            ;;
        other_link)
            print_warning "Replacing unknown symlink → system-wide for: $username"
            ;;
        not_present)
            print_info "Creating new system-wide link for: $username"
            ;;
    esac

    # Create themes directory if it doesn't exist
    if [[ ! -d "$oh_my_zsh_themes" ]]; then
        mkdir -p "$oh_my_zsh_themes"
        if [[ "$username" != "root" ]]; then
            chown "$username:$(id -gn "$username" 2>/dev/null || echo "$username")" "$oh_my_zsh_themes"
        fi
    fi

    # Remove existing file/link (this is the key fix!)
    if [[ -e "$theme_link" ]] || [[ -L "$theme_link" ]]; then
        rm -f "$theme_link"
    fi

    # Create symlink to master theme
    ln -sf "$MASTER_THEME_PATH" "$theme_link"

    # Fix ownership
    if [[ "$username" != "root" ]]; then
        chown -h "$username:$(id -gn "$username" 2>/dev/null || echo "$username")" "$theme_link" 2>/dev/null || true
    fi

    # Verify the symlink was created correctly
    if is_system_symlink "$theme_link"; then
        print_success "✓ Deployed system-wide theme for: $username"
    else
        print_error "✗ Failed to create system-wide link for: $username"
        return 1
    fi
}

# ============================================================================
# Status and Reporting
# ============================================================================

show_deployment_status() {
    print_step "Current deployment status"

    local users=($(get_users_with_tty))

    if [[ ${#users[@]} -eq 0 ]]; then
        print_warning "No users with oh-my-zsh found"
        return
    fi

    echo
    printf "%-20s %-20s %s\n" "User" "Status" "Details"
    printf "%-20s %-20s %s\n" "----" "------" "-------"

    for user in "${users[@]}"; do
        local status=$(analyze_user_theme "$user")
        local home_dir

        if [[ "$user" == "root" ]]; then
            home_dir="/root"
        else
            home_dir=$(eval echo "~$user")
        fi

        local theme_path="$home_dir/.oh-my-zsh/themes/$THEME_NAME"

        case "$status" in
            system_link)
                printf "%-20s ${GREEN}%-20s${NC} %s\n" "$user" "System-wide ✓" "→ $MASTER_THEME_PATH"
                ;;
            local_link)
                local target=$(readlink "$theme_path")
                printf "%-20s ${YELLOW}%-20s${NC} %s\n" "$user" "Local symlink" "→ $target"
                ;;
            regular_file)
                printf "%-20s ${CYAN}%-20s${NC} %s\n" "$user" "Regular file" "(standalone copy)"
                ;;
            other_link)
                local target=$(readlink "$theme_path" 2>/dev/null || echo "broken")
                printf "%-20s ${YELLOW}%-20s${NC} %s\n" "$user" "Other symlink" "→ $target"
                ;;
            not_present)
                printf "%-20s ${RED}%-20s${NC} %s\n" "$user" "Not installed" ""
                ;;
            *)
                printf "%-20s ${RED}%-20s${NC} %s\n" "$user" "Unknown" ""
                ;;
        esac
    done
    echo
}

# ============================================================================
# Main Execution
# ============================================================================

show_summary() {
    echo
    echo "============================================================================"
    echo "Deployment Summary"
    echo "============================================================================"
    echo "Master theme location: $MASTER_THEME_PATH"
    echo
    echo "To update the theme in the future:"
    echo "  1. Edit: $MASTER_THEME_PATH"
    echo "  2. All users will get updates automatically (via symlinks)"
    echo
    echo "Alternatively, update from your dotfiles:"
    echo "  sudo cp ~/.dotfiles/zsh/themes/$THEME_NAME $MASTER_THEME_PATH"
    echo
    echo "To check deployment status:"
    echo "  sudo $0 --status"
    echo "============================================================================"
}

main() {
    local mode="interactive"
    local status_only=false

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --all)
                mode="all"
                ;;
            --current)
                mode="current"
                ;;
            --force)
                FORCE_REPLACE=true
                ;;
            --status|-s)
                status_only=true
                ;;
            --help|-h)
                echo "Usage: sudo $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --all        Deploy to all users with oh-my-zsh"
                echo "  --current    Deploy to current user and root only"
                echo "  --force      Force replacement even if system-wide link exists"
                echo "  --status     Show current deployment status"
                echo "  --help       Show this help message"
                echo
                echo "Examples:"
                echo "  sudo $0                    # Interactive mode"
                echo "  sudo $0 --all              # Deploy to all users"
                echo "  sudo $0 --current --force  # Force update for current user + root"
                echo
                exit 0
                ;;
            *)
                print_error "Unknown option: $arg"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    print_header
    check_root

    # Status only mode
    if [[ "$status_only" == true ]]; then
        show_deployment_status
        exit 0
    fi

    # Show current status first
    show_deployment_status

    # Setup master location
    setup_master_location

    # Select users
    local users=($(select_users "$mode"))

    if [[ ${#users[@]} -eq 0 ]]; then
        print_error "No users selected for deployment"
        exit 1
    fi

    # Print info about selected mode
    case "$mode" in
        all)
            print_info "Deploying to all users with oh-my-zsh"
            ;;
        current)
            print_info "Deploying to current user and root"
            ;;
    esac

    echo
    print_step "Deploying to ${#users[@]} user(s): ${users[*]}"

    if [[ "$FORCE_REPLACE" == true ]]; then
        print_warning "Force mode: will replace ALL existing links"
    fi

    echo

    # Interactive confirmation for converting local links
    if [[ "$mode" == "interactive" ]]; then
        local has_local_links=false
        for user in "${users[@]}"; do
            local status=$(analyze_user_theme "$user")
            if [[ "$status" == "local_link" ]]; then
                has_local_links=true
                break
            fi
        done

        if [[ "$has_local_links" == true ]]; then
            echo "⚠ Some users have local dotfiles symlinks."
            echo "This will replace them with system-wide symlinks pointing to:"
            echo "  $MASTER_THEME_PATH"
            echo
            if ! ask_yes_no "Convert local symlinks to system-wide?"; then
                print_warning "Deployment cancelled"
                exit 0
            fi
        fi
    fi

    if ! ask_yes_no "Proceed with deployment?"; then
        print_warning "Deployment cancelled"
        exit 0
    fi

    # Deploy to each user
    echo
    local deployed_count=0
    local failed_count=0
    for user in "${users[@]}"; do
        if deploy_for_user "$user"; then
            ((deployed_count++))
        else
            ((failed_count++))
        fi
    done

    echo
    if [[ $failed_count -eq 0 ]]; then
        print_success "Deployment complete! ($deployed_count/${#users[@]} users)"
    else
        print_warning "Deployment finished with errors ($deployed_count succeeded, $failed_count failed)"
    fi

    # Show updated status
    echo
    show_deployment_status
    show_summary
}

main "$@"
