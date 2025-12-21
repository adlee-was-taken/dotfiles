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

# ============================================================================
# MOTD Width, adjust if needed.
# ============================================================================

_M_WIDTH=64

# ============================================================================
# Colors (ANSI escape codes)
# ============================================================================

_M_RESET=$'\033[0m'
_M_BOLD=$'\033[1m'
_M_DIM=$'\033[2m'
_M_BLUE=$'\033[38;5;39m'
_M_CYAN=$'\033[38;5;51m'
_M_GREEN=$'\033[38;5;82m'
_M_YELLOW=$'\033[38;5;220m'
_M_GREY=$'\033[38;5;242m'

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
    # Pad a plain string to exact width
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
    local local_ip=$(hostname -i | awk -F" " '{print $1}')
    local hline=$(_motd_line '═')
    local inner=$((_M_WIDTH - 2))

    echo ""
    
    # Top border
    echo "${_M_GREY}╒${hline}╕${_M_RESET}"
    
    # Header: hostname + datetime
    local h_left="✦ ${hostname}"
    local h_center="${local_ip}"
    local h_right="${datetime}"
    local h_pad=$(((inner - ${#h_left} - ${#h_center} - ${#h_right}) / 2 ))
    local h_spaces=""
    for ((i=0; i<h_pad; i++)); do h_spaces+=" "; done
    echo "${_M_GREY}│${_M_RESET} ${_M_BOLD}${_M_BLUE}${h_left}${_M_RESET}${h_spaces}${_M_DIM}${h_center}${h_spaces}${h_right}${_M_RESET}${_M_GREY} │${_M_RESET}"
    
    # Separator
    echo "${_M_GREY}╘${hline}╛${_M_RESET}"
    
    # Stats line - build with exact spacing
    local s1="${_M_YELLOW}▲ up:${_M_RESET}${uptime}"
    local s2="${_M_CYAN}◆ load:${_M_RESET}${load}"
    local s3="${_M_GREEN}◇ mem:${_M_RESET}${mem}"
    local s4="${_M_BLUE}⊡${_M_RESET} ${disk}"
    echo "${_M_GREY}${_M_DIM} 〘${_M_RESET}${s1}${_M_GREY}${_M_DIM}〙⎯〘${s2}${_M_GREY}${_M_DIM}〙⎯〘${s3}${_M_GREY}${_M_DIM}〙⎯〘${s4}${_M_GREY}${_M_DIM}〙 ${_M_RESET}"

    
    ## Bottom border
    #echo "${_M_GREY}╘${hline}𜲂${_M_RESET}"
    
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

    echo "${_M_DIM}──${_M_RESET} ${_M_BOLD}${hostname}${_M_RESET} ${_M_DIM}│${_M_RESET} up:${uptime} ${_M_DIM}│${_M_RESET} mem:${mem} ${_M_DIM}──${_M_RESET}"
}

# ============================================================================
# Aliases
# ============================================================================

alias motd='show_motd --force'
alias motd-mini='show_motd_mini --force'
