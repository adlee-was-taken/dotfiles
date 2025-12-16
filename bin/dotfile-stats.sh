#!/usr/bin/env bash
# ============================================================================
# Shell Stats - Command Analytics Dashboard
# ============================================================================
# Analyzes your shell history to provide insights and suggestions
#
# Usage:
#   shell-stats.sh                # Show dashboard
#   shell-stats.sh --top [n]      # Top N commands
#   shell-stats.sh --suggest      # Suggest aliases
#   shell-stats.sh --hours        # Commands by hour
#   shell-stats.sh --dirs         # Most used directories
#   shell-stats.sh --export       # Export stats as JSON
# ============================================================================

set -e

# ============================================================================
# Configuration
# ============================================================================

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
BASH_HISTFILE="$HOME/.bash_history"
STATS_CACHE="$HOME/.cache/shell-stats"
STATS_FILE="$STATS_CACHE/stats.json"

mkdir -p "$STATS_CACHE"

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# History Parsing
# ============================================================================

get_history_file() {
    if [[ -f "$HISTFILE" ]]; then
        echo "$HISTFILE"
    elif [[ -f "$BASH_HISTFILE" ]]; then
        echo "$BASH_HISTFILE"
    else
        echo ""
    fi
}

parse_zsh_history() {
    # Zsh extended history format: : timestamp:0;command
    local histfile=$(get_history_file)
    [[ -z "$histfile" ]] && return
    
    if [[ "$histfile" == *"zsh"* ]]; then
        # Zsh format
        cat "$histfile" 2>/dev/null | sed 's/^: [0-9]*:[0-9]*;//' | grep -v '^$'
    else
        # Bash format
        cat "$histfile" 2>/dev/null | grep -v '^#' | grep -v '^$'
    fi
}

get_command_count() {
    parse_zsh_history | wc -l | tr -d ' '
}

get_unique_commands() {
    parse_zsh_history | awk '{print $1}' | sort -u | wc -l | tr -d ' '
}

# ============================================================================
# Analysis Functions
# ============================================================================

top_commands() {
    local count="${1:-15}"
    
    parse_zsh_history | \
        awk '{print $1}' | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -n "$count"
}

top_full_commands() {
    local count="${1:-10}"
    
    parse_zsh_history | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -n "$count"
}

commands_by_hour() {
    local histfile=$(get_history_file)
    [[ -z "$histfile" ]] && return
    
    # Try to extract timestamps from zsh history
    if [[ "$histfile" == *"zsh"* ]]; then
        grep '^:' "$histfile" 2>/dev/null | \
            sed 's/^: \([0-9]*\):.*/\1/' | \
            while read -r ts; do
                date -d "@$ts" '+%H' 2>/dev/null || date -r "$ts" '+%H' 2>/dev/null
            done | \
            sort | \
            uniq -c | \
            sort -k2 -n
    else
        echo "Timestamp analysis requires zsh extended history"
    fi
}

most_used_dirs() {
    parse_zsh_history | \
        grep -E '^cd ' | \
        sed 's/^cd //' | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -15
}

git_commands() {
    parse_zsh_history | \
        grep -E '^git ' | \
        awk '{print $1" "$2}' | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -15
}

docker_commands() {
    parse_zsh_history | \
        grep -E '^docker ' | \
        awk '{print $1" "$2}' | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -10
}

# ============================================================================
# Suggestion Engine
# ============================================================================

suggest_aliases() {
    echo -e "${CYAN}Suggested Aliases${NC}"
    echo -e "${DIM}Based on your most-typed commands${NC}"
    echo
    
    # Get commands typed more than 10 times that are longer than 5 chars
    parse_zsh_history | \
        awk 'length($0) > 8' | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -20 | \
        while read -r count cmd; do
            # Skip if count is too low
            [[ $count -lt 5 ]] && continue
            
            # Skip single-word commands that are likely already short
            local words=$(echo "$cmd" | wc -w | tr -d ' ')
            [[ $words -lt 2 && ${#cmd} -lt 6 ]] && continue
            
            # Generate alias suggestion
            local alias_name=""
            
            # Common patterns
            case "$cmd" in
                "git status")
                    alias_name="gs"
                    ;;
                "git add .")
                    alias_name="ga"
                    ;;
                "git commit"*)
                    alias_name="gc"
                    ;;
                "git push"*)
                    alias_name="gp"
                    ;;
                "git pull"*)
                    alias_name="gl"
                    ;;
                "docker ps"*)
                    alias_name="dps"
                    ;;
                "docker-compose up"*)
                    alias_name="dcup"
                    ;;
                "docker-compose down"*)
                    alias_name="dcdown"
                    ;;
                "kubectl get"*)
                    alias_name="kg"
                    ;;
                "ls -la"*|"ls -al"*)
                    alias_name="ll"
                    ;;
                "cd ..")
                    alias_name=".."
                    ;;
                *)
                    # Generate from first letters
                    alias_name=$(echo "$cmd" | awk '{for(i=1;i<=NF && i<=3;i++) printf substr($i,1,1)}')
                    ;;
            esac
            
            # Check if alias already exists
            if alias "$alias_name" &>/dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} ${DIM}$alias_name${NC} already defined (used $count times)"
            else
                local saved_chars=$(( (${#cmd} - ${#alias_name}) * count ))
                echo -e "  ${YELLOW}→${NC} alias ${CYAN}$alias_name${NC}='$cmd'"
                echo -e "    ${DIM}Used $count times, would save ~$saved_chars keystrokes${NC}"
            fi
        done
}

# ============================================================================
# Dashboard
# ============================================================================

draw_bar() {
    local value=$1
    local max=$2
    local width=${3:-30}
    local filled=$((value * width / max))
    local empty=$((width - filled))
    
    printf "${GREEN}"
    printf "%${filled}s" | tr ' ' '█'
    printf "${DIM}"
    printf "%${empty}s" | tr ' ' '░'
    printf "${NC}"
}

show_dashboard() {
    clear
    
    local total=$(get_command_count)
    local unique=$(get_unique_commands)
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}Shell Analytics Dashboard${NC}                                       ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Summary stats
    echo -e "${CYAN}Overview${NC}"
    echo -e "  Total commands:  ${GREEN}${total}${NC}"
    echo -e "  Unique commands: ${GREEN}${unique}${NC}"
    echo -e "  History file:    ${DIM}$(get_history_file)${NC}"
    echo
    
    # Top commands
    echo -e "${CYAN}Top Commands${NC}"
    echo
    
    local max_count=$(top_commands 1 | awk '{print $1}')
    
    top_commands 10 | while read -r count cmd; do
        printf "  %-12s %5d  " "$cmd" "$count"
        draw_bar "$count" "$max_count" 25
        echo
    done
    
    echo
    
    # Git breakdown (if git is in top commands)
    if parse_zsh_history | grep -q '^git '; then
        echo -e "${CYAN}Git Commands${NC}"
        echo
        
        git_commands | head -5 | while read -r count cmd; do
            printf "  %-20s %5d\n" "$cmd" "$count"
        done
        echo
    fi
    
    # Directory usage
    echo -e "${CYAN}Most Visited Directories${NC}"
    echo
    
    most_used_dirs | head -5 | while read -r count dir; do
        printf "  %-35s %5d\n" "$dir" "$count"
    done
    echo
    
    # Quick suggestions
    echo -e "${CYAN}💡 Quick Tips${NC}"
    echo
    
    # Find most-typed long command
    local long_cmd=$(parse_zsh_history | awk 'length($0) > 15' | sort | uniq -c | sort -rn | head -1)
    local long_count=$(echo "$long_cmd" | awk '{print $1}')
    local long_text=$(echo "$long_cmd" | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    
    if [[ $long_count -gt 10 ]]; then
        echo -e "  ${YELLOW}→${NC} You've typed '${CYAN}$long_text${NC}' $long_count times"
        echo -e "    Consider creating an alias for it!"
    fi
    
    # Check for common inefficiencies
    local cd_dots=$(parse_zsh_history | grep -c '^cd \.\.' || echo 0)
    if [[ $cd_dots -gt 50 ]]; then
        echo -e "  ${YELLOW}→${NC} You use 'cd ..' a lot ($cd_dots times)"
        echo -e "    Tip: alias ..='cd ..' and ...='cd ../..'"
    fi
    
    echo
    echo -e "${DIM}Run 'shell-stats.sh --suggest' for detailed alias suggestions${NC}"
}

# ============================================================================
# Export
# ============================================================================

export_stats() {
    local output="${1:-$STATS_FILE}"
    
    echo "{"
    echo "  \"generated\": \"$(date -Iseconds)\","
    echo "  \"total_commands\": $(get_command_count),"
    echo "  \"unique_commands\": $(get_unique_commands),"
    echo "  \"top_commands\": ["
    
    top_commands 20 | awk 'BEGIN{first=1} {
        if (!first) printf ",\n"
        printf "    {\"command\": \"%s\", \"count\": %d}", $2, $1
        first=0
    }'
    
    echo
    echo "  ]"
    echo "}"
}

# ============================================================================
# Activity Heatmap
# ============================================================================

show_heatmap() {
    echo -e "${CYAN}Activity by Hour${NC}"
    echo
    
    # Create array for 24 hours
    declare -a hours
    for i in {0..23}; do
        hours[$i]=0
    done
    
    # Count commands per hour
    local histfile=$(get_history_file)
    if [[ "$histfile" == *"zsh"* && -f "$histfile" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^:\ ([0-9]+): ]]; then
                local ts="${BASH_REMATCH[1]}"
                local hour=$(date -d "@$ts" '+%H' 2>/dev/null || date -r "$ts" '+%H' 2>/dev/null)
                hour=${hour#0}  # Remove leading zero
                ((hours[$hour]++)) || true
            fi
        done < "$histfile"
        
        # Find max for scaling
        local max=1
        for count in "${hours[@]}"; do
            [[ $count -gt $max ]] && max=$count
        done
        
        # Draw heatmap
        echo -n "  "
        for i in {0..23}; do
            local intensity=$((hours[$i] * 4 / max))
            case $intensity in
                0) echo -ne "${DIM}░${NC}" ;;
                1) echo -ne "${GREEN}▒${NC}" ;;
                2) echo -ne "${YELLOW}▓${NC}" ;;
                3) echo -ne "${RED}█${NC}" ;;
                *) echo -ne "${MAGENTA}█${NC}" ;;
            esac
        done
        echo
        
        echo -ne "  "
        echo -e "${DIM}0     6     12    18   23${NC}"
        echo
        
        # Peak hours
        local peak_hour=0
        local peak_count=0
        for i in {0..23}; do
            if [[ ${hours[$i]} -gt $peak_count ]]; then
                peak_count=${hours[$i]}
                peak_hour=$i
            fi
        done
        
        echo -e "  Peak activity: ${GREEN}${peak_hour}:00${NC} ($peak_count commands)"
    else
        echo -e "  ${YELLOW}⚠${NC} Heatmap requires zsh with extended history"
    fi
}

# ============================================================================
# Main
# ============================================================================

show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  (none)        Show dashboard"
    echo "  --top [n]     Top N commands (default: 15)"
    echo "  --full [n]    Top N full command lines"
    echo "  --suggest     Suggest aliases based on usage"
    echo "  --hours       Show activity by hour"
    echo "  --heatmap     Show activity heatmap"
    echo "  --dirs        Most visited directories"
    echo "  --git         Git command breakdown"
    echo "  --docker      Docker command breakdown"
    echo "  --export      Export stats as JSON"
    echo "  --help        Show this help"
    echo
}

main() {
    local histfile=$(get_history_file)
    
    if [[ -z "$histfile" || ! -f "$histfile" ]]; then
        echo -e "${RED}✗${NC} No history file found"
        echo "  Checked: $HISTFILE"
        echo "  Checked: $BASH_HISTFILE"
        exit 1
    fi
    
    case "${1:-}" in
        --top|-t)
            echo -e "${CYAN}Top Commands${NC}"
            echo
            top_commands "${2:-15}" | while read -r count cmd; do
                printf "  %5d  %s\n" "$count" "$cmd"
            done
            ;;
        --full|-f)
            echo -e "${CYAN}Top Full Commands${NC}"
            echo
            top_full_commands "${2:-10}" | while read -r count cmd; do
                printf "  %5d  %s\n" "$count" "$cmd"
            done
            ;;
        --suggest|-s)
            suggest_aliases
            ;;
        --hours)
            commands_by_hour
            ;;
        --heatmap|-m)
            show_heatmap
            ;;
        --dirs|-d)
            echo -e "${CYAN}Most Visited Directories${NC}"
            echo
            most_used_dirs | while read -r count dir; do
                printf "  %5d  %s\n" "$count" "$dir"
            done
            ;;
        --git|-g)
            echo -e "${CYAN}Git Commands${NC}"
            echo
            git_commands | while read -r count cmd; do
                printf "  %5d  %s\n" "$count" "$cmd"
            done
            ;;
        --docker)
            echo -e "${CYAN}Docker Commands${NC}"
            echo
            docker_commands | while read -r count cmd; do
                printf "  %5d  %s\n" "$count" "$cmd"
            done
            ;;
        --export|-e)
            export_stats "${2:-}"
            ;;
        --help|-h)
            show_help
            ;;
        "")
            show_dashboard
            ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
