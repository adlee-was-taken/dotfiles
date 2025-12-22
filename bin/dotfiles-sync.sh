#!/usr/bin/env bash
# ============================================================================
# Dotfiles Synchronization (Arch/CachyOS)
# ============================================================================

set -e

readonly DOTFILES_HOME="${DOTFILES_HOME:-.}"
readonly DOTFILES_VERSION="3.0.0"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# ============================================================================
# MOTD-style header
# ============================================================================

_M_WIDTH=66

print_header() {
    local user="${USER:-root}"
    local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
    local script_name="dotfiles-sync"
    local datetime=$(date '+%a %b %d %H:%M')

    # Colors
    local _M_RESET=$'\033[0m'
    local _M_BOLD=$'\033[1m'
    local _M_DIM=$'\033[2m'
    local _M_BLUE=$'\033[38;5;39m'
    local _M_GREY=$'\033[38;5;242m'
    local _M_MAGENTA='\033[0;35m'
    local _M_GREEN='\033[0;32m'

    # Build horizontal line
    local hline=""
    for ((i=0; i<_M_WIDTH; i++)); do hline+="═"; done
    local inner=$((_M_WIDTH - 2))

    # Header content
    local h_left="✦ ${user}@${hostname}"
    local h_center="${script_name}"
    local h_right="${datetime}"
    local h_pad=$(((inner - ${#h_left} - ${#h_center} - ${#h_right}) / 2))
    local h_spaces=""
    for ((i=0; i<h_pad; i++)); do h_spaces+=" "; done

    echo ""
    echo -e "${_M_GREY}╒${hline}╕${_M_RESET}"
    echo -e "${_M_GREY}│${_M_RESET} ${_M_BOLD}${_M_BLUE}${h_left}${_M_RESET}${h_spaces}${_M_GREEN}${h_center}${h_spaces}${_M_RESET}${_M_BOLD}${h_right}${_M_RESET} ${_M_GREY}│${_M_RESET}"
    echo -e "${_M_GREY}╘${hline}╛${_M_RESET}"
    echo ""
}

# ============================================================================
# Helper functions
# ============================================================================

print_status() {
    echo -e "${CYAN}⎯${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}▶${NC} $1"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
}

# ============================================================================
# Sync functions
# ============================================================================

check_git_repo() {
    if ! git -C "$DOTFILES_HOME" rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not a git repository: $DOTFILES_HOME"
        exit 1
    fi
}

check_git_config() {
    if ! git config --global user.name > /dev/null 2>&1; then
        print_error "Git user.name not configured"
        exit 1
    fi

    if ! git config --global user.email > /dev/null 2>&1; then
        print_error "Git user.email not configured"
        exit 1
    fi
}

get_sync_status() {
    cd "$DOTFILES_HOME"

    local local_commits=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    local remote_commits=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

    echo "$local_commits:$remote_commits"
}

show_status() {
    print_section "Sync Status"

    cd "$DOTFILES_HOME"

    print_status "Local branch: $(git rev-parse --abbrev-ref HEAD)"
    print_status "Last commit: $(git log -1 --pretty=format:'%h - %s' 2>/dev/null || echo 'N/A')"
    print_status "Last update: $(git log -1 --pretty=format:'%ar' 2>/dev/null || echo 'N/A')"

    local status=$(get_sync_status)
    local local_commits="${status%:*}"
    local remote_commits="${status#*:}"

    echo ""
    if [[ $local_commits -gt 0 ]]; then
        print_warning "$local_commits commit(s) ahead of remote"
    fi

    if [[ $remote_commits -gt 0 ]]; then
        print_warning "$remote_commits commit(s) behind remote"
    fi

    if [[ $local_commits -eq 0 ]] && [[ $remote_commits -eq 0 ]]; then
        print_success "In sync with remote"
    fi
}

show_status_short() {
    cd "$DOTFILES_HOME"

    # Count local changes
    local changes=$(git status --porcelain | wc -l)

    # Check commits ahead/behind
    local status=$(get_sync_status)
    local local_commits="${status%:*}"
    local remote_commits="${status#*:}"

    if [[ $changes -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} Dotfiles: ${changes} local change(s) not pushed"
        echo -e "    Run: ${CYAN}dfpush${NC} or ${CYAN}dotfiles-sync.sh push${NC}"
    elif [[ $local_commits -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} Dotfiles: ${local_commits} commit(s) not pushed"
        echo -e "    Run: ${CYAN}git push${NC} in ~/.dotfiles"
    elif [[ $remote_commits -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} Dotfiles: ${remote_commits} commit(s) behind remote"
        echo -e "    Run: ${CYAN}dfpull${NC} or ${CYAN}dotfiles-sync.sh pull${NC}"
    else
        echo -e "  ${GREEN}✓${NC} Dotfiles: in sync"
    fi
    echo -e ""
}

show_diff() {
    print_section "Local Changes"

    cd "$DOTFILES_HOME"

    if git status --porcelain | grep -q .; then
        print_status "Modified files:"
        git status --porcelain | sed 's/^/  /'
    else
        print_success "No local changes"
    fi
}

pull_changes() {
    print_section "Pulling Changes"

    cd "$DOTFILES_HOME"

    print_status "Fetching from remote..."
    git fetch origin

    local status=$(get_sync_status)
    local remote_commits="${status#*:}"

    if [[ $remote_commits -gt 0 ]]; then
        print_status "Pulling $remote_commits remote commit(s)..."
        git pull origin
        print_success "Changes pulled"
    else
        print_success "Already up to date"
    fi
}

push_changes() {
    local commit_msg="$1"

    print_section "Pushing Changes"

    cd "$DOTFILES_HOME"

    if ! git status --porcelain | grep -q .; then
        print_warning "No local changes to push"
        return
    fi

    print_status "Staging changes..."
    git add -A

    # If no commit message provided, prompt for one
    if [[ -z "$commit_msg" ]]; then
        print_status "Enter commit message (or press Ctrl+C to cancel):"
        read -p "  > " commit_msg

        if [[ -z "$commit_msg" ]]; then
            print_error "Commit cancelled"
            return 1
        fi
    fi

    print_status "Committing: $commit_msg"
    git commit -m "$commit_msg"

    print_status "Pushing to remote..."
    git push origin

    print_success "Changes pushed"
}

auto_sync() {
    print_section "Auto-Sync"

    cd "$DOTFILES_HOME"

    # Pull remote changes
    print_status "Pulling from remote..."
    git fetch origin

    if git status --porcelain | grep -q .; then
        print_status "Resolving conflicts automatically..."
        git pull --strategy=ours
    else
        git pull origin
    fi

    print_success "Auto-sync complete"
}

watch_sync() {
    local interval="${1:-300}"

    print_section "Watch Mode"
    print_status "Auto-syncing every $interval seconds"
    print_status "Press Ctrl+C to stop"

    while true; do
        auto_sync
        sleep "$interval"
    done
}

# ============================================================================
# Main
# ============================================================================

main() {
    check_git_repo
    check_git_config

    case "${1:-status}" in
        status)
            if [[ "$2" == "-s" || "$2" == "--short" ]]; then
                show_status_short
            else
                print_header
                show_status
                show_diff
            fi
            ;;
        push)
            print_header
            shift
            push_changes "$*"
            ;;
        pull)
            print_header
            pull_changes
            ;;
        diff)
            print_header
            show_diff
            ;;
        auto)
            auto_sync
            ;;
        watch)
            print_header
            watch_sync "${2:-300}"
            ;;
        -s|--short)
            show_status_short
            ;;
        *)
            echo "Usage: $0 {status [-s]|push [message]|pull|diff|auto|watch [interval]}"
            echo ""
            echo "Commands:"
            echo "  status            Show sync status (default)"
            echo "  status -s         Show abbreviated one-line status"
            echo "  push [message]    Push local changes (prompts if no message)"
            echo "  pull              Pull remote changes"
            echo "  diff              Show local changes"
            echo "  auto              Automatically sync (pull remote)"
            echo "  watch [sec]       Auto-sync every N seconds (default: 300)"
            echo ""
            echo "Options:"
            echo "  -s, --short       Abbreviated output (one line)"
            echo ""
            echo "Examples:"
            echo "  $0 push \"Updated aliases\""
            echo "  $0 push                      # Will prompt for message"
            echo "  $0 status -s                 # Quick status check"
            exit 1
            ;;
    esac
}

main "$@"
