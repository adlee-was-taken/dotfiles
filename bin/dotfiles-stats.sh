#!/usr/bin/env bash
# ============================================================================
# Dotfiles Shell Analytics (Arch/CachyOS)
# ============================================================================

set -e

readonly DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"

# Source shared colors
source "$DOTFILES_HOME/zsh/lib/colors.zsh" 2>/dev/null || {
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_MAGENTA=$'\033[0;35m'
    DF_NC=$'\033[0m' DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
}

# Source utils.zsh
source "$DOTFILES_HOME/zsh/lib/utils.zsh" 2>/dev/null

# ============================================================================
# MOTD-style header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-stats "
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width=66
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}      ${DF_DIM}dotfiles-stats!${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

# ============================================================================
# Helper functions
# ============================================================================

print_section() {
    echo ""
    echo -e "${DF_BLUE}▶${DF_NC} $1"
    echo -e "${DF_CYAN}─────────────────────────────────────────────────────────────${DF_NC}"
}

# Get command history
get_history() {
    if [[ -f "$HOME/.bash_history" ]]; then
        cat "$HOME/.bash_history"
    elif [[ -f "$HOME/.zsh_history" ]]; then
        grep -I "^:" "$HOME/.zsh_history" | cut -d';' -f2 || cat "$HOME/.zsh_history"
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
    echo -e "  ${DF_CYAN}Total Commands:${DF_NC}  $total"
    echo -e "  ${DF_CYAN}Unique Commands:${DF_NC} $unique"
    echo ""

    print_section "Top 15 Commands"

    get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -15 | while read count cmd; do
        local percent=$((count * 100 / total))
        local bar_length=$((percent / 5))
        local bar=$(printf '█%.0s' $(seq 1 $bar_length))
        printf "  %-20s ${DF_GREEN}%5d${DF_NC} ${DF_MAGENTA}%3d%%${DF_NC} ${bar}\n" "$cmd" "$count" "$percent"
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
        printf "  ${DF_YELLOW}%4d${DF_NC}  %-30s  ${DF_CYAN}%3d%%${DF_NC}\n" "$count" "$cmd" "$percent"
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
            printf "  ${DF_YELLOW}Suggestion:${DF_NC} ${DF_GREEN}alias ${cmd:0:2}='$cmd'${DF_NC}  (used $count times)\n"
        fi
    done

    echo ""
}

show_breakdown() {
    print_section "Command Breakdown"

    echo ""
    echo -e "  ${DF_CYAN}Git Commands:${DF_NC}"
    get_history | grep -I "^git" | wc -l | xargs printf "    %d\n"

    echo -e "  ${DF_CYAN}Navigation (cd):${DF_NC}"
    get_history | grep -I "^cd" | wc -l | xargs printf "    %d\n"

    echo -e "  ${DF_CYAN}File Operations (ls):${DF_NC}"
    get_history | grep -I "^ls" | wc -l | xargs printf "    %d\n"

    echo -e "  ${DF_CYAN}Package Management (pacman/paru/yay):${DF_NC}"
    get_history | grep -I -E "^(pacman|paru|yay)" | wc -l | xargs printf "    %d\n"

    echo -e "  ${DF_CYAN}Editing (vim/nvim):${DF_NC}"
    get_history | grep -I -E "^(vim|nvim)" | wc -l | xargs printf "    %d\n"

    echo -e "  ${DF_CYAN}Dotfiles Commands (dotfiles-):${DF_NC}"
    get_history | grep -I "^dotfiles-" | wc -l | xargs printf "    %d\n"

    echo ""
}

show_heatmap() {
    print_section "Activity by Hour"

    echo ""
    if [[ -f "$HOME/.zsh_history" ]]; then
        grep -I "^:" "$HOME/.zsh_history" | awk -F'[: ]' '{print $2}' | \
        date -f - "+%H" 2>/dev/null | sort | uniq -c | sort -k2n | while read count hour; do
            local bar_length=$((count / 5))
            local bar=$(printf '█%.0s' $(seq 1 $bar_length))
            printf "  ${DF_CYAN}%02d:00${DF_NC}  ${DF_MAGENTA}%5d${DF_NC}  ${DF_GREEN}${bar}${DF_NC}\n" "$hour" "$count"
        done
    else
        echo "  ${DF_YELLOW}⚠${DF_NC} Zsh history file required for hourly breakdown"
    fi

    echo ""
}

show_dirs() {
    print_section "Most Visited Directories"

    echo ""
    if [[ -f "$HOME/.zsh_history" ]]; then
        grep -I "cd " "$HOME/.zsh_history" | awk '{print $NF}' | sort | uniq -c | \
        sort -rn | head -15 | while read count dir; do
            printf "  ${DF_CYAN}%4d${DF_NC}  ${DF_YELLOW}%s${DF_NC}\n" "$count" "$dir"
        done
    else
        echo "  ${DF_YELLOW}⚠${DF_NC} Zsh history file required"
    fi

    echo ""
}

show_git_breakdown() {
    print_section "Git Command Breakdown"

    echo ""
    local total=$(get_history | grep -I "^git" | wc -l)

    if [[ $total -eq 0 ]]; then
        echo "  ${DF_YELLOW}No git commands found${DF_NC}"
        return
    fi

    get_history | grep -I "^git " | awk '{print $2}' | sort | uniq -c | sort -rn | \
    head -10 | while read count subcmd; do
        local percent=$((count * 100 / total))
        printf "  ${DF_YELLOW}git %-15s${DF_NC}  ${DF_CYAN}%4d${DF_NC} (${DF_MAGENTA}%3d%%${DF_NC})\n" \
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
