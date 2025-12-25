#!/usr/bin/env bash
# ============================================================================
# Dotfiles Shell Analytics (Arch/CachyOS)
# ============================================================================

set -e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_MAGENTA=$'\033[0;35m'
    DF_NC=$'\033[0m'
    df_print_header() { echo "=== $1 ==="; }
}

# ============================================================================
# Helper Functions
# ============================================================================

print_section() {
    echo ""
    echo -e "${DF_BLUE}▶${DF_NC} $1"
    echo -e "${DF_CYAN}─────────────────────────────────────────────────────────────${DF_NC}"
}

get_history() {
    if [[ -f "$HOME/.zsh_history" ]]; then
        # Handle zsh extended history format
        grep -I "^:" "$HOME/.zsh_history" 2>/dev/null | cut -d';' -f2 || cat "$HOME/.zsh_history"
    elif [[ -f "$HOME/.bash_history" ]]; then
        cat "$HOME/.bash_history"
    fi
}

# ============================================================================
# Analytics Functions
# ============================================================================

show_dashboard() {
    print_section "Command History Dashboard"
    
    local total=$(get_history | wc -l)
    local unique=$(get_history | sort -u | wc -l)
    
    echo -e "  ${DF_CYAN}Total Commands:${DF_NC}  $total"
    echo -e "  ${DF_CYAN}Unique Commands:${DF_NC} $unique"
    echo ""
    
    print_section "Top 15 Commands"
    get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -15 | while read count cmd; do
        printf "  %-25s ${DF_GREEN}%5d${DF_NC}\n" "$cmd" "$count"
    done
    echo ""
}

show_top() {
    local count="${1:-20}"
    print_section "Top $count Commands"
    get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -"$count" | while read cnt cmd; do
        printf "  %-25s ${DF_GREEN}%5d${DF_NC}\n" "$cmd" "$cnt"
    done
}

show_git_stats() {
    print_section "Git Command Breakdown"
    get_history | grep "^git " | awk '{print $2}' | sort | uniq -c | sort -rn | head -10 | while read count subcmd; do
        printf "  git %-20s ${DF_GREEN}%5d${DF_NC}\n" "$subcmd" "$count"
    done
}

show_dirs() {
    print_section "Most Visited Directories"
    get_history | grep "^cd " | awk '{print $2}' | sort | uniq -c | sort -rn | head -10 | while read count dir; do
        printf "  %-30s ${DF_GREEN}%5d${DF_NC}\n" "$dir" "$count"
    done
}

show_help() {
    echo "Usage: dotfiles-stats.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  dashboard    Full analytics dashboard (default)"
    echo "  top [n]      Top N commands (default: 20)"
    echo "  git          Git command breakdown"
    echo "  dirs         Most visited directories"
    echo "  help         Show this help"
}

# ============================================================================
# Main
# ============================================================================

main() {
    df_print_header "dotfiles-stats"
    
    case "${1:-dashboard}" in
        dashboard) show_dashboard ;;
        top) show_top "${2:-20}" ;;
        git) show_git_stats ;;
        dirs) show_dirs ;;
        help|--help|-h) show_help ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
