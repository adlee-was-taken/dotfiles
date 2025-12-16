#!/usr/bin/env bash
# ============================================================================
# Dotfiles Sync - Auto-sync across machines
# ============================================================================
# Keeps your dotfiles synchronized across multiple machines
#
# Usage:
#   dotfiles-sync.sh                  # Interactive sync
#   dotfiles-sync.sh --push           # Push local changes
#   dotfiles-sync.sh --pull           # Pull remote changes
#   dotfiles-sync.sh --status         # Show sync status
#   dotfiles-sync.sh --watch          # Watch for changes (daemon mode)
#   dotfiles-sync.sh --auto           # Auto-sync on shell start
# ============================================================================

set -e

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
    DOTFILES_BRANCH="main"
fi

SYNC_STATE_FILE="$DOTFILES_DIR/.sync_state"
SYNC_LOG_FILE="$DOTFILES_DIR/.sync_log"
HOSTNAME=$(hostname -s)

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Dotfiles Sync                                             ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

log_sync() {
    local action="$1"
    local details="$2"
    echo "$(date -Iseconds) | $HOSTNAME | $action | $details" >> "$SYNC_LOG_FILE"
}

get_local_status() {
    cd "$DOTFILES_DIR"
    
    local status=""
    local ahead=0
    local behind=0
    local modified=0
    local untracked=0
    
    # Fetch quietly
    git fetch origin --quiet 2>/dev/null || true
    
    # Count commits ahead/behind
    ahead=$(git rev-list HEAD..origin/${DOTFILES_BRANCH} --count 2>/dev/null || echo 0)
    behind=$(git rev-list origin/${DOTFILES_BRANCH}..HEAD --count 2>/dev/null || echo 0)
    
    # Count modified and untracked
    modified=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    
    echo "$ahead|$behind|$modified|$untracked"
}

has_local_changes() {
    cd "$DOTFILES_DIR"
    ! git diff --quiet 2>/dev/null || [[ -n $(git ls-files --others --exclude-standard) ]]
}

has_remote_changes() {
    cd "$DOTFILES_DIR"
    git fetch origin --quiet 2>/dev/null || true
    local behind=$(git rev-list HEAD..origin/${DOTFILES_BRANCH} --count 2>/dev/null || echo 0)
    [[ $behind -gt 0 ]]
}

# ============================================================================
# Sync Functions
# ============================================================================

show_status() {
    print_header
    
    echo -e "${CYAN}Machine:${NC} $HOSTNAME"
    echo -e "${CYAN}Branch:${NC}  $DOTFILES_BRANCH"
    echo -e "${CYAN}Path:${NC}    $DOTFILES_DIR"
    echo
    
    cd "$DOTFILES_DIR"
    
    IFS='|' read -r behind ahead modified untracked <<< "$(get_local_status)"
    
    echo -e "${CYAN}Status:${NC}"
    
    # Remote status
    if [[ $behind -gt 0 ]]; then
        echo -e "  ${YELLOW}↓${NC} $behind commit(s) behind remote"
    elif [[ $ahead -gt 0 ]]; then
        echo -e "  ${GREEN}↑${NC} $ahead commit(s) ahead of remote"
    else
        echo -e "  ${GREEN}✓${NC} In sync with remote"
    fi
    
    # Local changes
    if [[ $modified -gt 0 ]]; then
        echo -e "  ${YELLOW}●${NC} $modified modified file(s)"
    fi
    
    if [[ $untracked -gt 0 ]]; then
        echo -e "  ${YELLOW}+${NC} $untracked untracked file(s)"
    fi
    
    if [[ $modified -eq 0 && $untracked -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} Working directory clean"
    fi
    
    # Show recent changes
    echo
    echo -e "${CYAN}Recent changes:${NC}"
    git log --oneline -5 2>/dev/null | while read -r line; do
        echo -e "  ${DIM}$line${NC}"
    done
    
    # Show modified files
    if [[ $modified -gt 0 || $untracked -gt 0 ]]; then
        echo
        echo -e "${CYAN}Changed files:${NC}"
        git status --short 2>/dev/null | head -10 | while read -r line; do
            echo -e "  $line"
        done
        local total=$((modified + untracked))
        [[ $total -gt 10 ]] && echo -e "  ${DIM}... and $((total - 10)) more${NC}"
    fi
    
    # Show last sync
    if [[ -f "$SYNC_STATE_FILE" ]]; then
        echo
        local last_sync=$(cat "$SYNC_STATE_FILE")
        echo -e "${CYAN}Last sync:${NC} $last_sync"
    fi
}

do_push() {
    local message="${1:-Auto-sync from $HOSTNAME}"
    
    cd "$DOTFILES_DIR"
    
    if ! has_local_changes; then
        echo -e "${GREEN}✓${NC} No local changes to push"
        return 0
    fi
    
    echo -e "${BLUE}==>${NC} Pushing local changes..."
    
    # Stage all changes
    git add -A
    
    # Show what we're committing
    echo -e "${CYAN}Changes:${NC}"
    git diff --cached --stat | head -10
    
    echo
    
    # Commit
    git commit -m "$message" || {
        echo -e "${YELLOW}⚠${NC} Nothing to commit"
        return 0
    }
    
    # Push
    if git push origin "$DOTFILES_BRANCH"; then
        echo -e "${GREEN}✓${NC} Changes pushed successfully"
        log_sync "push" "$message"
        date -Iseconds > "$SYNC_STATE_FILE"
    else
        echo -e "${RED}✗${NC} Failed to push changes"
        return 1
    fi
}

do_pull() {
    cd "$DOTFILES_DIR"
    
    echo -e "${BLUE}==>${NC} Pulling remote changes..."
    
    # Stash local changes if any
    local had_changes=false
    if has_local_changes; then
        echo -e "${YELLOW}⚠${NC} Stashing local changes..."
        git stash push -m "Auto-stash before pull"
        had_changes=true
    fi
    
    # Pull
    if git pull origin "$DOTFILES_BRANCH"; then
        echo -e "${GREEN}✓${NC} Changes pulled successfully"
        log_sync "pull" "from origin/$DOTFILES_BRANCH"
        date -Iseconds > "$SYNC_STATE_FILE"
        
        # Show what changed
        echo -e "${CYAN}Updates:${NC}"
        git log --oneline ORIG_HEAD..HEAD 2>/dev/null | while read -r line; do
            echo -e "  ${GREEN}+${NC} $line"
        done
    else
        echo -e "${RED}✗${NC} Failed to pull changes"
        
        # Restore stash on failure
        if [[ "$had_changes" == true ]]; then
            git stash pop
        fi
        return 1
    fi
    
    # Restore stash
    if [[ "$had_changes" == true ]]; then
        echo -e "${BLUE}==>${NC} Restoring local changes..."
        if git stash pop; then
            echo -e "${GREEN}✓${NC} Local changes restored"
        else
            echo -e "${YELLOW}⚠${NC} Conflict restoring local changes"
            echo "  Resolve conflicts and run: git stash drop"
        fi
    fi
}

do_sync() {
    print_header
    
    cd "$DOTFILES_DIR"
    
    local has_local=$(has_local_changes && echo "yes" || echo "no")
    local has_remote=$(has_remote_changes && echo "yes" || echo "no")
    
    if [[ "$has_local" == "no" && "$has_remote" == "no" ]]; then
        echo -e "${GREEN}✓${NC} Everything is in sync!"
        return 0
    fi
    
    if [[ "$has_remote" == "yes" ]]; then
        echo -e "${CYAN}Remote changes available${NC}"
        do_pull
        echo
    fi
    
    if [[ "$has_local" == "yes" ]]; then
        echo -e "${CYAN}Local changes detected${NC}"
        
        # Show changes
        git status --short
        echo
        
        read -p "Push these changes? [Y/n]: " confirm
        if [[ "${confirm:-y}" =~ ^[Yy] ]]; then
            read -p "Commit message [Auto-sync from $HOSTNAME]: " msg
            do_push "${msg:-Auto-sync from $HOSTNAME}"
        fi
    fi
}

do_watch() {
    echo -e "${BLUE}==>${NC} Starting sync daemon..."
    echo -e "${DIM}Press Ctrl+C to stop${NC}"
    echo
    
    local interval="${1:-300}"  # Default 5 minutes
    
    log_sync "watch_start" "interval=${interval}s"
    
    while true; do
        local timestamp=$(date '+%H:%M:%S')
        
        if has_remote_changes; then
            echo -e "[$timestamp] ${YELLOW}↓${NC} Remote changes detected, pulling..."
            do_pull
        fi
        
        if has_local_changes; then
            echo -e "[$timestamp] ${YELLOW}↑${NC} Local changes detected"
            # In watch mode, auto-commit with timestamp
            do_push "Auto-sync: $(date '+%Y-%m-%d %H:%M') from $HOSTNAME"
        fi
        
        echo -e "[$timestamp] ${DIM}Sleeping ${interval}s...${NC}"
        sleep "$interval"
    done
}

do_auto() {
    # Quick check for shell startup - minimal output
    cd "$DOTFILES_DIR" 2>/dev/null || return 0
    
    git fetch origin --quiet 2>/dev/null || return 0
    
    local behind=$(git rev-list HEAD..origin/${DOTFILES_BRANCH} --count 2>/dev/null || echo 0)
    
    if [[ $behind -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Dotfiles: $behind update(s) available${NC}"
        echo -e "  Run: ${CYAN}dfpull${NC} or ${CYAN}dotfiles-sync.sh --pull${NC}"
    fi
    
    if has_local_changes; then
        local changed=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${YELLOW}⚠ Dotfiles: $changed local change(s) not pushed${NC}"
        echo -e "  Run: ${CYAN}dfpush${NC} or ${CYAN}dotfiles-sync.sh --push${NC}"
    fi
}

show_diff() {
    cd "$DOTFILES_DIR"
    
    echo -e "${CYAN}Local changes:${NC}"
    echo
    
    if command -v delta &>/dev/null; then
        git diff | delta
    elif command -v diff-so-fancy &>/dev/null; then
        git diff | diff-so-fancy
    else
        git diff --color
    fi
}

show_log() {
    local count="${1:-20}"
    
    if [[ -f "$SYNC_LOG_FILE" ]]; then
        echo -e "${CYAN}Sync history (last $count entries):${NC}"
        echo
        tail -n "$count" "$SYNC_LOG_FILE" | while IFS='|' read -r timestamp host action details; do
            echo -e "${DIM}$timestamp${NC} ${CYAN}$host${NC} ${GREEN}$action${NC} $details"
        done
    else
        echo "No sync history yet."
    fi
}

show_conflicts() {
    cd "$DOTFILES_DIR"
    
    local conflicts=$(git diff --name-only --diff-filter=U 2>/dev/null)
    
    if [[ -n "$conflicts" ]]; then
        echo -e "${RED}Merge conflicts:${NC}"
        echo "$conflicts" | while read -r file; do
            echo -e "  ${RED}✗${NC} $file"
        done
        echo
        echo "Resolve conflicts, then run:"
        echo "  git add <file>"
        echo "  git commit"
    else
        echo -e "${GREEN}✓${NC} No merge conflicts"
    fi
}

# ============================================================================
# Main
# ============================================================================

show_help() {
    echo "Usage: dotfiles-sync.sh [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  (none)        Interactive sync"
    echo "  --status      Show sync status"
    echo "  --push [msg]  Push local changes"
    echo "  --pull        Pull remote changes"
    echo "  --watch [sec] Watch and auto-sync (default: 300s)"
    echo "  --auto        Quick check for shell startup"
    echo "  --diff        Show local changes diff"
    echo "  --log [n]     Show sync history"
    echo "  --conflicts   Show merge conflicts"
    echo "  --help        Show this help"
    echo
    echo "Aliases:"
    echo "  dfs, dfsync   Interactive sync"
    echo "  dfpush        Push local changes"
    echo "  dfpull        Pull remote changes"
    echo "  dfstatus      Show sync status"
    echo
    echo "Examples:"
    echo "  dfs                           # Interactive sync"
    echo "  dfpush                        # Push changes"
    echo "  dotfiles-sync.sh --push 'Added aliases'"
    echo "  dotfiles-sync.sh --watch 60   # Sync every 60 seconds"
    echo
}

main() {
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        echo -e "${RED}✗${NC} Dotfiles directory is not a git repository: $DOTFILES_DIR"
        exit 1
    fi
    
    case "${1:-}" in
        --status|-s)
            show_status
            ;;
        --push|-p)
            do_push "${2:-}"
            ;;
        --pull|-l)
            do_pull
            ;;
        --watch|-w)
            do_watch "${2:-300}"
            ;;
        --auto|-a)
            do_auto
            ;;
        --diff|-d)
            show_diff
            ;;
        --log)
            show_log "${2:-20}"
            ;;
        --conflicts|-c)
            show_conflicts
            ;;
        --help|-h)
            show_help
            ;;
        "")
            do_sync
            ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
