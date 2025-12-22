#!/usr/bin/env zsh
# ============================================================================
# MOTD (Message of the Day) - Dynamic System Info
# ============================================================================
# Displays system information on shell startup
#
# Functions:
#   show_motd       - Compact box format
#   show_motd_mini  - Single line format
# ============================================================================

# Only run in interactive shells
[[ -o interactive ]] || return 0

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_RESET=$'\033[0m' DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
    typeset -g DF_BLUE=$'\033[38;5;39m' DF_CYAN=$'\033[38;5;51m'
    typeset -g DF_GREEN=$'\033[38;5;82m' DF_YELLOW=$'\033[38;5;220m'
    typeset -g DF_GREY=$'\033[38;5;242m' DF_NC=$'\033[0m'
}

# ============================================================================
# MOTD Width
# ============================================================================

typeset -g _M_WIDTH=66

# ============================================================================
# Info Gathering
# ============================================================================

_motd_uptime() {
    local up=$(uptime 2>/dev/null)
    if [[ "$up" =~ "up "([^,]+) ]]; then
        echo "${match[1]}" | sed 's/^ *//'
    else
        echo "?"
    fi
}

_motd_load() {
    if [[ -f /proc/loadavg ]]; then
        awk '{print $1}' /proc/loadavg
    else
        uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs
    fi
}

_motd_mem() {
    free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2}' || echo "N/A"
}

_motd_disk() {
    df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $4}' || echo "N/A"
}

# ============================================================================
# Box Drawing - Fixed Width
# ============================================================================

_motd_line() {
    local char="$1"
    local i
    local line=""
    for ((i=0; i<_M_WIDTH; i++)); do
        line+="$char"
    done
    echo "$line"
}

_motd_pad() {
    local str="$1"
    local width="$2"
    local len=${#str}
    if (( len >= width )); then
        echo "${str:0:$width}"
    else
        printf "%-${width}s" "$str"
    fi
}

# ============================================================================
# Main Display Function
# ============================================================================

show_motd() {
    [[ -n "$_MOTD_SHOWN" && "$1" != "--force" ]] && return 0
    typeset -g _MOTD_SHOWN=1

    local hostname="${HOST:-$(hostname -s 2>/dev/null)}"
    local datetime=$(date '+%a %b %d %H:%M')
    local uptime=$(_motd_uptime)
    local load=$(_motd_load)
    local mem=$(_motd_mem)
    local disk=$(_motd_disk)
    local local_ip=$(hostname -i 2>/dev/null | awk -F" " '{print $1}' || echo "N/A")
    local hline=$(_motd_line '═')
    local inner=$((_M_WIDTH - 2))

    echo ""
    
    # Top border
    echo "${DF_GREY}╒${hline}╕${DF_NC}"
    
    # Header: hostname + datetime
    local h_left="✦ ${hostname}"
    local h_center="${local_ip}"
    local h_right="${datetime}"
    local h_pad=$(((inner - ${#h_left} - ${#h_center} - ${#h_right}) / 2 ))
    local h_spaces=""
    for ((i=0; i<h_pad; i++)); do h_spaces+=" "; done
    echo "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_BLUE}${h_left}${DF_NC}${h_spaces}${DF_YELLOW}${h_center}${h_spaces}${DF_NC}${DF_BOLD}${h_right}${DF_NC}${DF_GREY} │${DF_NC}"
    
    # Separator
    echo "${DF_GREY}╘${hline}╛${DF_NC}"
    
    # Stats line
    local s1="${DF_YELLOW}▲ up:${DF_NC}${uptime}"
    local s2="${DF_CYAN}◆ load:${DF_NC}${load}"
    local s3="${DF_GREEN}◇ mem:${DF_NC}${mem}"
    local s4="${DF_BLUE}⊡${DF_NC} ${disk}"
    echo "${DF_GREY}${DF_DIM} 〘${DF_NC}${s1}${DF_GREY}${DF_DIM}〙⎯〘${s2}${DF_GREY}${DF_DIM}〙⎯〘${s3}${DF_GREY}${DF_DIM}〙⎯〘${s4}${DF_GREY}${DF_DIM}〙 ${DF_NC}"
    
    echo ""
}

# ============================================================================
# Mini Format (Single Line)
# ============================================================================

show_motd_mini() {
    [[ -n "$_MOTD_SHOWN" && "$1" != "--force" ]] && return 0
    typeset -g _MOTD_SHOWN=1

    local hostname="${HOST:-$(hostname -s 2>/dev/null)}"
    local uptime=$(_motd_uptime)
    local mem=$(_motd_mem)

    echo "${DF_DIM}──${DF_NC} ${DF_BOLD}${hostname}${DF_NC} ${DF_DIM}│${DF_NC} up:${uptime} ${DF_DIM}│${DF_NC} mem:${mem} ${DF_DIM}──${DF_NC}"
}

# ============================================================================
# Aliases
# ============================================================================

alias motd='show_motd --force'
alias motd-mini='show_motd_mini --force'
