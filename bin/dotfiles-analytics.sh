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
#   dotfiles-analytics.sh complexity   # Command complexity analysis
#   dotfiles-analytics.sh tools        # Tool usage breakdown
#   dotfiles-analytics.sh suggestions  # Alias suggestions
# ============================================================================

# Don't exit on error - we handle errors ourselves
set +e

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
        grep "^:" "$HISTORY_FILE" 2>/dev/null | cut -d';' -f2- || cat "$HISTORY_FILE" 2>/dev/null
    elif [[ -f "$BASH_HISTORY_FILE" ]]; then
        cat "$BASH_HISTORY_FILE" 2>/dev/null
    fi
}

# Safe count function - handles grep errors gracefully
safe_count() {
    local pattern="$1"
    local result
    result=$(get_history | awk '{print $1}' | grep -c "^${pattern}$" 2>/dev/null) || result=0
    # Ensure we return a valid number
    if [[ "$result" =~ ^[0-9]+$ ]]; then
        echo "$result"
    else
        echo "0"
    fi
}

# ============================================================================
# Analytics Functions
# ============================================================================

# Commands by hour of day
show_hourly() {
    df_print_section "Command Usage by Hour of Day"
    echo ""
    
    get_zsh_history_with_time | while IFS='|' read -r timestamp cmd; do
        if [[ -n "$timestamp" && "$timestamp" =~ ^[0-9]+$ ]]; then
            local hour
            hour=$(date -d "@$timestamp" '+%H' 2>/dev/null || date -r "$timestamp" '+%H' 2>/dev/null)
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
    
    get_zsh_history_with_time | while IFS='|' read -r timestamp cmd; do
        if [[ -n "$timestamp" && "$timestamp" =~ ^[0-9]+$ ]]; then
            local dow
            dow=$(date -d "@$timestamp" '+%a' 2>/dev/null || date -r "$timestamp" '+%a' 2>/dev/null)
            if [[ -n "$dow" ]]; then
                echo "$dow"
            fi
        fi
    done | sort | uniq -c | while read -r count day; do
        local bar=""
        local bar_len=$((count / 100 + 1))
        for ((i=0; i<bar_len && i<40; i++)); do bar+="█"; done
        printf "  %-3s  %5d  ${DF_GREEN}%s${DF_NC}\n" "$day" "$count" "$bar"
    done
    
    echo ""
}

# Commands grouped by project/directory
show_projects() {
    df_print_section "Command Usage by Directory"
    echo ""
    
    # This requires that history records include directory info
    # For now, show most common directory references
    echo -e "  ${DF_DIM}Analyzing directory patterns in commands...${DF_NC}"
    echo ""
    
    get_history | grep -oE '(~/[^ ]+|/home/[^ /]+/[^ ]+)' 2>/dev/null | \
        sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -10 | \
        while read -r count dir; do
            local short_dir="$dir"
            if [[ ${#dir} -gt 40 ]]; then
                short_dir="...${dir: -37}"
            fi
            printf "  %5d  ${DF_CYAN}%s${DF_NC}\n" "$count" "$short_dir"
        done
    
    echo ""
}

# Usage trends over time (last 30 days)
show_trends() {
    df_print_section "Usage Trends (Last 30 Days)"
    echo ""
    
    local thirty_days_ago=$(($(date +%s) - 30*24*60*60))
    
    get_zsh_history_with_time | while IFS='|' read -r timestamp cmd; do
        if [[ -n "$timestamp" && "$timestamp" =~ ^[0-9]+$ && "$timestamp" -ge "$thirty_days_ago" ]]; then
            local date_str
            date_str=$(date -d "@$timestamp" '+%Y-%m-%d' 2>/dev/null || date -r "$timestamp" '+%Y-%m-%d' 2>/dev/null)
            if [[ -n "$date_str" ]]; then
                echo "$date_str"
            fi
        fi
    done | sort | uniq -c | tail -30 | while read -r count date; do
        local bar=""
        local bar_len=$((count / 20 + 1))
        for ((i=0; i<bar_len && i<30; i++)); do bar+="▪"; done
        printf "  %s  %4d  ${DF_BLUE}%s${DF_NC}\n" "$date" "$count" "$bar"
    done
    
    echo ""
}

# Command complexity analysis
show_complexity() {
    df_print_section "Command Complexity Analysis"
    echo ""
    
    local total=0
    local simple=0
    local piped=0
    local redirected=0
    local subshell=0
    
    while read -r cmd; do
        ((total++)) || true
        
        if [[ "$cmd" == *"|"* ]]; then
            ((piped++)) || true
        elif [[ "$cmd" == *">"* || "$cmd" == *"<"* ]]; then
            ((redirected++)) || true
        elif [[ "$cmd" == *'$('* || "$cmd" == *'`'* ]]; then
            ((subshell++)) || true
        else
            ((simple++)) || true
        fi
    done < <(get_history)
    
    if [[ $total -gt 0 ]]; then
        echo -e "  Simple commands:     ${DF_GREEN}$simple${DF_NC} ($((simple * 100 / total))%)"
        echo -e "  Piped commands:      ${DF_YELLOW}$piped${DF_NC} ($((piped * 100 / total))%)"
        echo -e "  With redirection:    ${DF_CYAN}$redirected${DF_NC} ($((redirected * 100 / total))%)"
        echo -e "  With subshells:      ${DF_MAGENTA}$subshell${DF_NC} ($((subshell * 100 / total))%)"
    else
        echo "  No history data available"
    fi
    
    echo ""
    
    # Most complex commands (by pipe count)
    df_print_indent "Most Complex Pipelines:"
    echo ""
    
    get_history | awk -F'|' 'NF > 3 {print NF-1, $0}' | sort -rn | head -5 | \
        while read -r pipes cmd; do
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
    
    # Cache history to avoid repeated reads
    local history_cache
    history_cache=$(get_history | awk '{print $1}')
    
    for category in "${categories[@]}"; do
        local name="${category%%:*}"
        local tools="${category#*:}"
        local total=0
        
        for tool in $tools; do
            local count
            count=$(echo "$history_cache" | grep -c "^${tool}$" 2>/dev/null) || count=0
            # Validate count is a number
            if [[ "$count" =~ ^[0-9]+$ ]]; then
                total=$((total + count))
            fi
        done
        
        if [[ $total -gt 0 ]]; then
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
        if [[ "$count" =~ ^[0-9]+$ ]] && [[ $count -ge 5 ]]; then
            local short_cmd="${cmd:0:50}"
            [[ ${#cmd} -gt 50 ]] && short_cmd="${short_cmd}..."
            echo -e "    ${DF_YELLOW}${count}×${DF_NC} $short_cmd"
        fi
    done
    
    echo ""
    
    # Check for common mistakes
    df_print_indent "Common typos detected:"
    echo ""
    
    local typos=("gti:git" "sl:ls" "cta:cat" "grpe:grep" "suod:sudo")
    local found_typos=0
    
    # Cache history
    local history_cache
    history_cache=$(get_history | awk '{print $1}')
    
    for typo_pair in "${typos[@]}"; do
        local typo="${typo_pair%%:*}"
        local correct="${typo_pair#*:}"
        local count
        count=$(echo "$history_cache" | grep -c "^${typo}$" 2>/dev/null) || count=0
        
        if [[ "$count" =~ ^[0-9]+$ ]] && [[ $count -gt 0 ]]; then
            echo -e "    ${DF_RED}$typo${DF_NC} → ${DF_GREEN}$correct${DF_NC} (${count}×)"
            found_typos=1
        fi
    done
    
    if [[ $found_typos -eq 0 ]]; then
        echo -e "    ${DF_GREEN}No common typos detected!${DF_NC}"
    fi
    
    echo ""
}

# Dashboard view
show_dashboard() {
    df_print_section "Shell Analytics Dashboard"
    echo ""
    
    # Basic stats
    local total
    total=$(get_history | wc -l 2>/dev/null) || total=0
    local unique
    unique=$(get_history | sort -u | wc -l 2>/dev/null) || unique=0
    
    # Ensure we have valid numbers
    [[ ! "$total" =~ ^[0-9]+$ ]] && total=0
    [[ ! "$unique" =~ ^[0-9]+$ ]] && unique=0
    
    # Trim whitespace
    total=$(echo "$total" | tr -d ' ')
    unique=$(echo "$unique" | tr -d ' ')
    
    echo -e "  Total commands:    ${DF_GREEN}$total${DF_NC}"
    echo -e "  Unique commands:   ${DF_CYAN}$unique${DF_NC}"
    
    if [[ $total -gt 0 ]]; then
        local efficiency=$((unique * 100 / total))
        echo -e "  Efficiency ratio:  ${DF_YELLOW}${efficiency}%${DF_NC}"
    fi
    
    echo ""
    
    # Top commands
    df_print_section "Top 15 Commands"
    echo ""
    
    get_history | awk '{print $1}' | sort 2>/dev/null | uniq -c 2>/dev/null | sort -rn 2>/dev/null | head -15 | \
        while read -r count cmd; do
            if [[ "$count" =~ ^[0-9]+$ ]] && [[ -n "$cmd" ]]; then
                printf "  ${DF_GREEN}%-20s${DF_NC} %5d\n" "$cmd" "$count"
            fi
        done
    
    echo ""
    
    # Tool usage
    show_tools
}

# Help
show_help() {
    cat << 'EOF'
Enhanced Shell Analytics

Usage: dotfiles-analytics.sh [COMMAND]

Commands:
  (none)         Show dashboard with overview
  hourly         Command usage by hour of day
  weekly         Command usage by day of week
  projects       Commands grouped by directory
  trends         Usage trends over last 30 days
  complexity     Analyze command complexity
  tools          Tool/category usage breakdown
  suggestions    Alias and optimization suggestions
  all            Show all analytics

Examples:
  dotfiles-analytics.sh              # Dashboard
  dotfiles-analytics.sh hourly       # When do you code most?
  dotfiles-analytics.sh suggestions  # Get optimization tips

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    df_print_header "dotfiles-analytics"
    
    case "${1:-dashboard}" in
        dashboard|dash)
            show_dashboard
            ;;
        hourly|hour|h)
            show_hourly
            ;;
        weekly|week|w)
            show_weekly
            ;;
        projects|proj|p)
            show_projects
            ;;
        trends|trend|t)
            show_trends
            ;;
        complexity|complex|c)
            show_complexity
            ;;
        tools|tool)
            show_tools
            ;;
        suggestions|suggest|s)
            show_suggestions
            ;;
        all|a)
            show_dashboard
            echo ""
            show_hourly
            echo ""
            show_weekly
            echo ""
            show_complexity
            echo ""
            show_suggestions
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
}

main "$@"
