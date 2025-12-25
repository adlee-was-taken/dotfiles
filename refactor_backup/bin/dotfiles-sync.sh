#!/usr/bin/env bash
# ============================================================================
# Dotfiles Synchronization (Arch/CachyOS)
# ============================================================================

set -e

# ============================================================================
# Source Configuration
# ============================================================================

_df_source_config() {
    local locations=(
        "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/utils.zsh"
        "$HOME/.dotfiles/zsh/lib/utils.zsh"
    )
    for loc in "${locations[@]}"; do
        [[ -f "$loc" ]] && { source "$loc"; return 0; }
    done
    
    # Fallback defaults
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_LIGHT_GREEN=$'\033[38;5;82m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    DF_WIDTH="${DF_WIDTH:-66}"
}

_df_source_config

# ============================================================================
# Header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-sync"
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width="${DF_WIDTH:-66}"
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}    ${DF_LIGHT_GREEN}dotfiles-sync${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

# ============================================================================
# Helper Functions
# ============================================================================

print_status() { echo -e "${DF_CYAN}⎯${DF_NC} $1"; }
print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
print_section() { echo ""; echo -e "${DF_BLUE}▶${DF_NC} $1"; }

# ============================================================================
# Sync Functions
# ============================================================================

check_git_repo() {
    git -C "$DOTFILES_HOME" rev-parse --git-dir > /dev/null 2>&1 || { print_error "Not a git repository: $DOTFILES_HOME"; exit 1; }
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
    [[ $local_commits -gt 0 ]] && print_warning "$local_commits commit(s) ahead of remote"
    [[ $remote_commits -gt 0 ]] && print_warning "$remote_commits commit(s) behind remote"
    [[ $local_commits -eq 0 && $remote_commits -eq 0 ]] && print_success "In sync with remote"
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
    git pull origin && print_success "Changes pulled" || print_success "Already up to date"
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
    
    if [[ -z "$commit_msg" ]]; then
        read -p "Commit message: " commit_msg
        [[ -z "$commit_msg" ]] && { print_error "Commit cancelled"; return 1; }
    fi
    
    git commit -m "$commit_msg"
    git push origin
    print_success "Changes pushed"
}

# ============================================================================
# Main
# ============================================================================

main() {
    check_git_repo
    
    case "${1:-status}" in
        status)
            [[ "$2" == "-s" || "$2" == "--short" ]] && show_status_short || { print_header; show_status; }
            ;;
        push)
            print_header; shift; push_changes "$*"
            ;;
        pull)
            print_header; pull_changes
            ;;
        -s|--short)
            show_status_short
            ;;
        *)
            echo "Usage: $0 {status [-s]|push [message]|pull}"
            exit 1
            ;;
    esac
}

main "$@"
