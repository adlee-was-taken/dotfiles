#!/usr/bin/env bash
# ============================================================================
# Dotfiles Shell Analytics (Arch/CachyOS)
# ============================================================================

set -e

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# ============================================================================
# Print MOTD-style header
# ============================================================================

print_header() {
    local user="${USER:-root}"
    local hostname="${HOSTNAME:-localhost}"
    local timestamp=$(date '+%a %b %d %H:%M')
    
    echo ""
    printf "${CYAN}+ ${NC}%-20s %30s %25s\n" "$user@$hostname" "dotfiles-stats" "$timestamp"
    echo ""
}

# ============================================================================
# Helper functions
# ============================================================================

print_section() {
    echo ""
    echo -e "${BLUE}▶${NC} $1"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
}

# Get command history
get_history() {
    if [[ -f "$HOME/.bash_history" ]]; then
        cat "$HOME/.bash_history"
    elif [[ -f "$HOME/.zsh_history" ]]; then
        grep "^:" "$HOME/.zsh_history" | cut -d';' -f2 || cat "$HOME/.zsh_history"
    fi
}

# ============================================================================
# Statistics functions
# ============================================================================

show_dashboard() {
    print_section "Command History Dashboard"
    
    local total=$(get_history | wc -l)
    local unique=$(get_history | sort | uniq | wc -l)
    
    echo ""
    echo -e "  ${CYAN}Total Commands:${NC}  $total"
    echo -e "  ${CYAN}Unique Commands:${NC} $unique"
    echo ""
    
    print_section "Top 15 Commands"
    
    get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -15 | while read count cmd; do
        local percent=$((count * 100 / total))
        local bar_length=$((percent / 5))
        local bar=$(printf '█%.0s' $(seq 1 $bar_length))
        printf "  %-20s ${GREEN}%5d${NC} ${MAGENTA}%3d%%${NC} ${bar}\n" "$cmd" "$count" "$percent"
    done
    
    echo ""
}

show_top_n() {
    local n="${1:-20}"
    
    print_section "Top $n Commands"
    
    local total=$(get_history | wc -l)
    
    get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -"$n" | \
    while read count cmd; do
        local percent=$((count * 100 / total))
        printf "  ${YELLOW}%4d${NC}  %-30s  ${CYAN}%3d%%${NC}\n" "$count" "$cmd" "$percent"
    done
    
    echo ""
}

show_suggestions() {
    print_section "Suggested Aliases"
    
    local total=$(get_history | wc -l)
    
    echo ""
    get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -20 | \
    while read count cmd; do
        if [[ $count -gt 50 ]]; then
            printf "  ${YELLOW}Suggestion:${NC} ${GREEN}alias ${cmd:0:2}='$cmd'${NC}  (used $count times)\n"
        fi
    done
    
    echo ""
}

show_breakdown() {
    print_section "Command Breakdown"
    
    echo ""
    echo -e "  ${CYAN}Git Commands:${NC}"
    get_history | grep "^git" | wc -l | xargs printf "    %d\n"
    
    echo -e "  ${CYAN}Navigation (cd):${NC}"
    get_history | grep "^cd" | wc -l | xargs printf "    %d\n"
    
    echo -e "  ${CYAN}File Operations (ls):${NC}"
    get_history | grep "^ls" | wc -l | xargs printf "    %d\n"
    
    echo -e "  ${CYAN}Package Management (pacman/paru/yay):${NC}"
    get_history | grep -E "^(pacman|paru|yay)" | wc -l | xargs printf "    %d\n"
    
    echo -e "  ${CYAN}Editing (vim/nvim):${NC}"
    get_history | grep -E "^(vim|nvim)" | wc -l | xargs printf "    %d\n"
    
    echo -e "  ${CYAN}Dotfiles Commands (dotfiles-):${NC}"
    get_history | grep "^dotfiles-" | wc -l | xargs printf "    %d\n"
    
    echo ""
}

show_heatmap() {
    print_section "Activity by Hour"
    
    echo ""
    if [[ -f "$HOME/.zsh_history" ]]; then
        # Extract hour from zsh history timestamp
        grep "^:" "$HOME/.zsh_history" | awk -F'[: ]' '{print $2}' | \
        date -f - "+%H" 2>/dev/null | sort | uniq -c | sort -k2n | while read count hour; do
            local bar_length=$((count / 5))
            local bar=$(printf '█%.0s' $(seq 1 $bar_length))
            printf "  ${CYAN}%02d:00${NC}  ${MAGENTA}%5d${NC}  ${GREEN}${bar}${NC}\n" "$hour" "$count"
        done
    else
        echo "  ${YELLOW}⚠${NC} Zsh history file required for hourly breakdown"
    fi
    
    echo ""
}

show_dirs() {
    print_section "Most Visited Directories"
    
    echo ""
    if [[ -f "$HOME/.zsh_history" ]]; then
        grep "cd " "$HOME/.zsh_history" | awk '{print $NF}' | sort | uniq -c | \
        sort -rn | head -15 | while read count dir; do
            printf "  ${CYAN}%4d${NC}  ${YELLOW}%s${NC}\n" "$count" "$dir"
        done
    else
        echo "  ${YELLOW}⚠${NC} Zsh history file required"
    fi
    
    echo ""
}

show_git_breakdown() {
    print_section "Git Command Breakdown"
    
    echo ""
    local total=$(get_history | grep "^git" | wc -l)
    
    if [[ $total -eq 0 ]]; then
        echo "  ${YELLOW}No git commands found${NC}"
        return
    fi
    
    get_history | grep "^git " | awk '{print $2}' | sort | uniq -c | sort -rn | \
    head -10 | while read count subcmd; do
        local percent=$((count * 100 / total))
        printf "  ${YELLOW}git %-15s${NC}  ${CYAN}%4d${NC} (${MAGENTA}%3d%%${NC})\n" \
            "$subcmd" "$count" "$percent"
    done
    
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header
    
    case "${1:-dashboard}" in
        dashboard)
            show_dashboard
            ;;
        top)
            show_top_n "${2:-20}"
            ;;
        suggest)
            show_suggestions
            ;;
        breakdown)
            show_breakdown
            ;;
        heatmap)
            show_heatmap
            ;;
        dirs)
            show_dirs
            ;;
        git)
            show_git_breakdown
            ;;
        export)
            # Export as JSON
            echo "{"
            echo "  \"total_commands\": $(get_history | wc -l),"
            echo "  \"unique_commands\": $(get_history | sort | uniq | wc -l),"
            echo "  \"timestamp\": \"$(date -Iseconds)\""
            echo "}"
            ;;
        *)
            echo "Usage: $0 {dashboard|top [n]|suggest|breakdown|heatmap|dirs|git|export}"
            echo ""
            echo "Commands:"
            echo "  dashboard     Show full dashboard (default)"
            echo "  top [n]       Show top N commands (default: 20)"
            echo "  suggest       Suggest aliases"
            echo "  breakdown     Command category breakdown"
            echo "  heatmap       Activity by hour"
            echo "  dirs          Most visited directories"
            echo "  git           Git command breakdown"
            echo "  export        Export as JSON"
            exit 1
            ;;
    esac
}

main "$@"
