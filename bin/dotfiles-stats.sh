#!/usr/bin/env bash
# ============================================================================
# Dotfiles Shell Analytics (Arch/CachyOS)
# ============================================================================

set -e

readonly DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"

# Source shared colors and utils (provides DF_WIDTH)
source "$DOTFILES_HOME/zsh/lib/utils.zsh" 2>/dev/null || \
source "$DOTFILES_HOME/zsh/lib/colors.zsh" 2>/dev/null || {
    DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_MAGENTA=$'\033[0;35m'
    DF_NC=$'\033[0m' DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m' DF_LIGHT_GREEN=$'\033[38;5;82m'
}

# Use DF_WIDTH from utils.zsh or default to 66
readonly WIDTH="${DF_WIDTH:-66}"

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
        local hline="" && for ((i=0; i<WIDTH; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}      ${DF_LIGHT_GREEN}dotfiles-stats${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

print_section() {
    echo ""
    echo -e "${DF_BLUE}▶${DF_NC} $1"
    echo -e "${DF_CYAN}─────────────────────────────────────────────────────────────${DF_NC}"
}

get_history() {
    if [[ -f "$HOME/.zsh_history" ]]; then
        grep -I "^:" "$HOME/.zsh_history" | cut -d';' -f2 || cat "$HOME/.zsh_history"
    elif [[ -f "$HOME/.bash_history" ]]; then
        cat "$HOME/.bash_history"
    fi
}

show_dashboard() {
    print_section "Command History Dashboard"
    local total=$(get_history | wc -l)
    local unique=$(get_history | sort | uniq | wc -l)
    echo -e "  ${DF_CYAN}Total Commands:${DF_NC}  $total"
    echo -e "  ${DF_CYAN}Unique Commands:${DF_NC} $unique"
    echo ""
    print_section "Top 15 Commands"
    get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -15 | while read count cmd; do
        printf "  %-20s ${DF_GREEN}%5d${DF_NC}\n" "$cmd" "$count"
    done
    echo ""
}

main() {
    print_header
    case "${1:-dashboard}" in
        dashboard) show_dashboard ;;
        top) get_history | awk '{print $1}' | sort | uniq -c | sort -rn | head -"${2:-20}" ;;
        *) echo "Usage: $0 {dashboard|top [n]}"; exit 1 ;;
    esac
}

main "$@"
