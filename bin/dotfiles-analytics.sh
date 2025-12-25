#!/usr/bin/env bash
# ============================================================================
# Enhanced Shell Analytics
# ============================================================================
# Advanced command history analysis with time-based patterns, project grouping,
# and actionable insights.
#
# Usage:
#   dotfiles-analytics.sh              # Dashboard
#   dotfiles-analytics.sh hourly       # Commands by hour
#   dotfiles-analytics.sh weekly       # Usage by day of week
#   dotfiles-analytics.sh projects     # Group by directory
#   dotfiles-analytics.sh trends       # Usage trends over time
# ============================================================================

set -e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_CYAN=$'\033[0;36m' DF_BLUE=$'\033[0;34m' DF_MAGENTA=$'\033[0;35m'
    DF_NC=$'\033[0m' DF_DIM=$'\033[2m'
    df_print_header() { echo "=== $1 ==="; }
    df_print_section() { echo -e "${DF_CYAN}$1:${DF_NC}"; }
    df_print_indent() { echo "  $1"; }
}

# ============================================================================
# Configuration
# ============================================================================

HISTORY_FILE="${HISTFILE:-$HOME/.zsh_history}"
BASH_HISTORY_FILE="$HOME/.bash_history"

# ============================================================================
# History Parsing
# ============================================================================

# Get zsh history with timestamps
get_zsh_history_with_time() {
    if [[ -f "$HISTORY_FILE" ]]; then
        # Zsh extended history format: : timestamp:0;command
        grep "^:" "$HISTORY_FILE" 2>/dev/null | while read -r line; do
            local timestamp=$(echo "$line" | cut -d':' -f2)
            local cmd=$(echo "$line" | cut -d';' -f2-)
            echo "${timestamp}|${cmd}"
        done
    fi
}

# Get plain history (command only)
get_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        grep "^:" "$HISTORY_FILE" 2>/dev/null | cut -d';' -f2- || cat "$HISTORY_FILE"
    elif [[ -f "$BASH_HISTORY_FILE" ]]; then
        cat "$BASH_HISTORY_FILE"
    fi
}

# ============================================================================
# Analytics Functions
# ============================================================================

# Commands by hour of day
show_hourly() {
    df_print_section "Command Usage by Hour of Day"
    echo ""
    
    declare -A hour_counts
    
    get_zsh_history_with_time | while IFS='|' read -r timestamp cmd; do
        if [[ -n "$timestamp" && "$timestamp" =~ ^[0-9]+$ ]]; then
            local hour=$(date -d "@$timestamp" '+%H' 2>/dev/null || date -r "$timestamp" '+%H' 2>/dev/null)
            if [[ -n "$hour" ]]; then
                echo "$hour"
            fi
        fi
    done | sort | uniq -c | sort -k2 -n | while read -r count hour; do
        local bar=""
        local bar_len=$((count / 50 + 1))
        for ((i=0; i<bar_len && i<40; i++)); do bar+="█"; done
        printf "  %s:00  %5d  ${DF_CYAN}%s${DF_NC}\n" "$hour" "$count" "$bar"
    done
    
    echo ""
    echo -e "${DF_DIM}Peak hours indicate your most active coding times${DF_NC}"
}

# Commands by day of week
show_weekly() {
    df_print_section "Command Usage by Day of Week"
    echo ""
    
    local days=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
    declare -A day_counts
    
    # Initialize
    for day in "${days[@]}"; do
        day_counts[$day]=0
    done
    
    get_zsh_history_with_time | while IFS='|' read -r timestamp cmd; do
        if [[ -n "$timestamp" && "$timestamp" =~ ^[0-9]+$ ]]; then
            local dow=$(date -d "@$timestamp" '+%a' 2>/dev/null || date -r "$timestamp" '+%a' 2>/dev/null)
            if [[ -n "$dow" ]]; then
                echo "$dow"
            fi
        fi
    done | sort | uniq -c | while read -r count day; do
        local bar=""
        local bar_len=$((count / 100 + 1))
        for ((i=0; i<bar_len && i<40; i++)); do bar+="█"; done
        printf "  %-3s  %6d  ${DF_CYAN}%s${DF_NC}\n" "$day" "$count" "$bar"
    done
    
    echo ""
}

# Commands grouped by working directory
show_projects() {
    df_print_section "Command Usage by Project/Directory"
    echo ""
    
    # This requires shell integration that saves PWD with commands
    # We'll analyze cd commands as a proxy
    
    df_print_indent "Most visited directories:"
    echo ""
    
    get_history | grep "^cd " | awk '{print $2}' | \
        sed 's|^~|'"$HOME"'|' | \
        sort | uniq -c | sort -rn | head -15 | while read -r count dir; do
        # Shorten home paths
        local short_dir="${dir/#$HOME/~}"
        printf "  %5d  ${DF_CYAN}%s${DF_NC}\n" "$count" "$short_dir"
    done
    
    echo ""
    df_print_indent "Git repositories worked on:"
    echo ""
    
    get_history | grep -E "^(git|g) " | grep -v "^git config" | \
        awk '{print $1, $2}' | sort | uniq -c | sort -rn | head -10 | while read -r count cmd subcmd; do
        printf "  %5d  ${DF_GREEN}%s %s${DF_NC}\n" "$count" "$cmd" "$subcmd"
    done
}

# Usage trends over time
show_trends() {
    df_print_section "Usage Trends (Last 30 Days)"
    echo ""
    
    local today=$(date +%s)
    local thirty_days_ago=$((today - 30*24*60*60))
    
    df_print_indent "Commands per day:"
    echo ""
    
    get_zsh_history_with_time | while IFS='|' read -r timestamp cmd; do
        if [[ -n "$timestamp" && "$timestamp" =~ ^[0-9]+$ ]]; then
            if (( timestamp >= thirty_days_ago )); then
                date -d "@$timestamp" '+%Y-%m-%d' 2>/dev/null || date -r "$timestamp" '+%Y-%m-%d' 2>/dev/null
            fi
        fi
    done | sort | uniq -c | tail -30 | while read -r count date; do
        local bar=""
        local bar_len=$((count / 20 + 1))
        for ((i=0; i<bar_len && i<30; i++)); do bar+="▪"; done
        printf "  %s  %4d  ${DF_CYAN}%s${DF_NC}\n" "$date" "$count" "$bar"
    done
}

# Command complexity analysis
show_complexity() {
    df_print_section "Command Complexity Analysis"
    echo ""
    
    df_print_indent "Simple commands (single word):"
    local simple=$(get_history | awk 'NF==1' | wc -l)
    echo "    $simple"
    
    df_print_indent "Piped commands:"
    local piped=$(get_history | grep -c '|' || echo 0)
    echo "    $piped"
    
    df_print_indent "Commands with redirects:"
    local redirects=$(get_history | grep -cE '[<>]' || echo 0)
    echo "    $redirects"
    
    df_print_indent "Commands with subshells:"
    local subshell=$(get_history | grep -cE '\$\(' || echo 0)
    echo "    $subshell"
    
    echo ""
    df_print_section "Most Complex Commands (by pipe count)"
    echo ""
    
    get_history | awk -F'|' 'NF>2 {print NF-1, $0}' | sort -rn | head -5 | while read -r pipes cmd; do
        local short_cmd="${cmd:0:60}"
        [[ ${#cmd} -gt 60 ]] && short_cmd="${short_cmd}..."
        echo -e "  ${DF_MAGENTA}$pipes pipes:${DF_NC} $short_cmd"
    done
}

# Tool usage breakdown
show_tools() {
    df_print_section "Tool Usage Breakdown"
    echo ""
    
    local categories=(
        "Git:git g"
        "Docker:docker docker-compose d dc"
        "Package:pacman paru yay npm pip cargo"
        "Editor:vim nvim vi nano code"
        "Navigation:cd ls ll la cat less"
        "System:sudo systemctl journalctl"
        "Network:curl wget ssh scp"
    )
    
    for category in "${categories[@]}"; do
        local name="${category%%:*}"
        local tools="${category#*:}"
        local total=0
        
        for tool in $tools; do
            local count=$(get_history | awk '{print $1}' | grep -c "^${tool}$" 2>/dev/null || echo 0)
            total=$((total + count))
        done
        
        if (( total > 0 )); then
            printf "  %-12s ${DF_GREEN}%6d${DF_NC}\n" "$name:" "$total"
        fi
    done
}

# Suggestions based on usage
show_suggestions() {
    df_print_section "Optimization Suggestions"
    echo ""
    
    # Find frequently typed long commands
    df_print_indent "Consider creating aliases for:"
    echo ""
    
    get_history | awk 'length > 20' | sort | uniq -c | sort -rn | head -5 | while read -r count cmd; do
        if (( count >= 5 )); then
            local short_cmd="${cmd:0:50}"
            [[ ${#cmd} -gt 50 ]] && short_cmd="${short_cmd}..."
            echo -e "    ${DF_YELLOW}$count×${DF_NC} $short_cmd"
        fi
    done
    
    echo ""
    
    # Check for common mistakes
    df_print_indent "Common typos detected:"
    echo ""
    
    local typos=("gti:git" "sl:ls" "cta:cat" "grpe:grep" "suod:sudo")
    for typo_pair in "${typos[@]}"; do
        local typo="${typo_pair%%:*}"
        local correct="${typo_pair#*:}"
        local count=$(get_history | grep -c "^${typo} " 2>/dev/null || echo 0)
        if (( count > 0 )); then
            echo -e "    ${DF_RED}$typo${DF_NC} → $correct (${count}×)"
        fi
    done
}

# Full dashboard
show_dashboard() {
    local total=$(get_history | wc -l)
    local unique=$(get_history | sort -u | wc -l)
    
    df_print_section "Shell Analytics Dashboard"
    echo ""
    echo -e "  Total commands:    ${DF_GREEN}$total${DF_NC}"
    echo -e "  Unique commands:   ${DF_GREEN}$unique${DF_NC}"
    echo -e "  Efficiency ratio:  ${DF_CYAN}$(( unique * 100 / (total + 1) ))%${DF_NC}"
    echo ""
    
    df_print_section "Top 15 Commands"
    echo ""
    
    get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -15 | while read -r count cmd; do
        printf "  %-20s ${DF_GREEN}%5d${DF_NC}\n" "$cmd" "$count"
    done
    
    echo ""
    show_tools
}

# ============================================================================
# Help
# ============================================================================

show_help() {
    cat << 'EOF'
Enhanced Shell Analytics

Usage: dotfiles-analytics.sh [COMMAND]

Commands:
  dashboard      Full analytics dashboard (default)
  hourly         Command usage by hour of day
  weekly         Command usage by day of week
  projects       Commands grouped by directory
  trends         Usage trends over last 30 days
  complexity     Command complexity analysis
  tools          Tool usage breakdown
  suggestions    Optimization suggestions
  help           Show this help

Examples:
  dotfiles-analytics.sh              # Full dashboard
  dotfiles-analytics.sh hourly       # See peak coding hours
  dotfiles-analytics.sh suggestions  # Get alias suggestions

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    df_print_header "dotfiles-analytics"
    
    if [[ ! -f "$HISTORY_FILE" && ! -f "$BASH_HISTORY_FILE" ]]; then
        echo "No history file found"
        exit 1
    fi
    
    case "${1:-dashboard}" in
        dashboard|d)   show_dashboard ;;
        hourly|h)      show_hourly ;;
        weekly|w)      show_weekly ;;
        projects|p)    show_projects ;;
        trends|t)      show_trends ;;
        complexity|c)  show_complexity ;;
        tools)         show_tools ;;
        suggestions|s) show_suggestions ;;
        help|--help|-h) show_help ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
