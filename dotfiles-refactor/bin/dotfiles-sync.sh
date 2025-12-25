#!/usr/bin/env bash
# ============================================================================
# Dotfiles Synchronization (Arch/CachyOS)
# ============================================================================

set -e

# Source bootstrap (provides colors, config, and utility functions)
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
    df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
}

# ============================================================================
# Helper Functions
# ============================================================================

print_status() { echo -e "${DF_CYAN}⎯${DF_NC} $1"; }
print_section() { echo ""; echo -e "${DF_BLUE}▶${DF_NC} $1"; }

# ============================================================================
# Sync Functions
# ============================================================================

check_git_repo() {
    if ! git -C "$DOTFILES_HOME" rev-parse --git-dir > /dev/null 2>&1; then
        df_print_error "Not a git repository: $DOTFILES_HOME"
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
    
    local status=$(get_sync_status)
    local local_commits="${status%:*}"
    local remote_commits="${status#*:}"
    
    echo ""
    [[ $local_commits -gt 0 ]] && df_print_warning "$local_commits commit(s) ahead of remote"
    [[ $remote_commits -gt 0 ]] && df_print_warning "$remote_commits commit(s) behind remote"
    [[ $local_commits -eq 0 && $remote_commits -eq 0 ]] && df_print_success "In sync with remote"
}

show_status_short() {
    cd "$DOTFILES_HOME"
    local changes=$(git status --porcelain | wc -l)
    local status=$(get_sync_status)
    local local_commits="${status%:*}"
    local remote_commits="${status#*:}"

    if [[ $changes -gt 0 ]]; then
        echo -e "  ${DF_YELLOW}⚠${DF_NC} Dotfiles: ${changes} local change(s) not pushed"
    elif [[ $local_commits -gt 0 ]]; then
        echo -e "  ${DF_YELLOW}⚠${DF_NC} Dotfiles: ${local_commits} commit(s) not pushed"
    elif [[ $remote_commits -gt 0 ]]; then
        echo -e "  ${DF_YELLOW}⚠${DF_NC} Dotfiles: ${remote_commits} commit(s) behind remote"
    fi
}

pull_changes() {
    print_section "Pulling Changes"
    cd "$DOTFILES_HOME"
    
    print_status "Fetching from remote..."
    git fetch origin
    
    if git pull origin; then
        df_print_success "Changes pulled"
    else
        df_print_success "Already up to date"
    fi
}

push_changes() {
    local commit_msg="$1"
    print_section "Pushing Changes"
    cd "$DOTFILES_HOME"
    
    if ! git status --porcelain | grep -q .; then
        df_print_warning "No local changes to push"
        return
    fi
    
    print_status "Staging changes..."
    git add -A
    
    if [[ -z "$commit_msg" ]]; then
        read -p "Commit message: " commit_msg
        [[ -z "$commit_msg" ]] && { df_print_error "Commit cancelled"; return 1; }
    fi
    
    git commit -m "$commit_msg"
    git push origin
    df_print_success "Changes pushed"
}

# ============================================================================
# Main
# ============================================================================

main() {
    check_git_repo
    
    case "${1:-status}" in
        status)
            if [[ "$2" == "-s" || "$2" == "--short" ]]; then
                show_status_short
            else
                df_print_header "dotfiles-sync"
                show_status
            fi
            ;;
        push)
            df_print_header "dotfiles-sync"
            shift
            push_changes "$*"
            ;;
        pull)
            df_print_header "dotfiles-sync"
            pull_changes
            ;;
        -s|--short)
            show_status_short
            ;;
        --help|-h)
            echo "Usage: dotfiles-sync.sh [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  status [-s]     Show sync status (default)"
            echo "  push [message]  Push changes to remote"
            echo "  pull            Pull changes from remote"
            echo ""
            echo "Options:"
            echo "  -s, --short     Short status output"
            echo "  --help          Show this help"
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
