#!/usr/bin/env zsh
# ============================================================================
# MOTD (Message of the Day) - Dynamic System Info
# ============================================================================
# Displays system information on shell startup
# Optimized for Arch/CachyOS with direct /proc access
#
# Functions:
#   show_motd       - Compact box format
#   show_motd_mini  - Single line format
#   show_motd_full  - Extended info
# ============================================================================

# Only run in interactive shells
[[ -o interactive ]] || return 0

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_RESET=$'\033[0m' DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
    typeset -g DF_BLUE=$'\033[38;5;39m' DF_CYAN=$'\033[38;5;51m'
    typeset -g DF_GREEN=$'\033[38;5;82m' DF_YELLOW=$'\033[38;5;220m'
    typeset -g DF_RED=$'\033[38;5;196m' DF_GREY=$'\033[38;5;242m' DF_NC=$'\033[0m'
}

# ============================================================================
# MOTD Width
# ============================================================================

typeset -g _M_WIDTH=66

# ============================================================================
# Optimized Info Gathering (using /proc directly - faster than spawning processes)
# ============================================================================

# Uptime from /proc (no subprocess)
_motd_uptime() {
    local uptime_seconds=$(cut -d. -f1 /proc/uptime 2>/dev/null)
    [[ -z "$uptime_seconds" ]] && { echo "?"; return; }
    
    local days=$((uptime_seconds / 86400))
    local hours=$(((uptime_seconds % 86400) / 3600))
    local mins=$(((uptime_seconds % 3600) / 60))
    
    if (( days > 0 )); then
        echo "${days}d${hours}h"
    elif (( hours > 0 )); then
        echo "${hours}h${mins}m"
    else
        echo "${mins}m"
    fi
}

# Load from /proc (no subprocess)
_motd_load() {
    cut -d' ' -f1 /proc/loadavg 2>/dev/null || echo "?"
}

# Memory from /proc (single awk call)
_motd_mem() {
    awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {
        if (total > 0) {
            used=(total-avail)/1024/1024
            total_gb=total/1024/1024
            printf "%.1fG/%.0fG", used, total_gb
        } else {
            print "N/A"
        }
    }' /proc/meminfo 2>/dev/null || echo "N/A"
}

# Disk usage (single df call)
_motd_disk() {
    df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2}' || echo "N/A"
}

# CPU governor (Arch-specific, direct file read)
_motd_governor() {
    local gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    [[ -n "$gov" ]] && echo "$gov"
}

# Kernel version (simplified)
_motd_kernel() {
    local kernel=$(uname -r)
    # Strip architecture suffix for cleaner display
    echo "${kernel%%-*}"
}

# CachyOS scheduler detection
_motd_scheduler() {
    if grep -q "cachyos" /proc/version 2>/dev/null; then
        if grep -q "bore" /proc/version 2>/dev/null; then
            echo "BORE"
        elif grep -q "eevdf" /proc/version 2>/dev/null; then
            echo "EEVDF"
        else
            echo "CachyOS"
        fi
    fi
}

# Failed systemd services count (cached)
_motd_failed_services() {
    # Use cache to avoid slow systemctl calls on every prompt
    local cache_file="/tmp/.motd-failed-${UID}"
    local cache_age=300  # 5 minutes
    
    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if (( file_age < cache_age )); then
            cat "$cache_file"
            return
        fi
    fi
    
    local count=$(systemctl --failed --no-pager --no-legend 2>/dev/null | wc -l)
    echo "$count" > "$cache_file" 2>/dev/null
    echo "$count"
}

# Package updates (from environment, set by aliases.zsh)
_motd_updates() {
    echo "${UPDATE_PKG_COUNT:-0}"
}

# ============================================================================
# Box Drawing - Fixed Width
# ============================================================================

_motd_line() {
    local char="$1"
    local line=""
    for ((i=0; i<_M_WIDTH; i++)); do line+="$char"; done
    echo "$line"
}

# ============================================================================
# Main Display Function (Compact)
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
    local hline=$(_motd_line '═')
    local inner=$((_M_WIDTH - 2))

    echo ""
    
    # Top border
    echo "${DF_GREY}╒${hline}╕${DF_NC}"
    
    # Header: hostname + datetime
    local h_left="✦ ${hostname}"
    local h_center=$(hostname -i | awk -F" " '{print $1}')
    local h_right="${datetime}"
    local h_pad=$(((inner - ${#h_left} - ${#h_center} - ${#h_right}) / 2))
    local h_spaces=""
    for ((i=0; i<h_pad; i++)); do h_spaces+=" "; done

    if [ "$EUID" -ne 0 ];then 
        echo "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}${h_left}${DF_NC}${h_spaces}${DF_YELLOW}${h_center}${h_spaces}${DF_NC}${DF_BOLD}${h_right}${DF_NC} ${DF_GREY}│${DF_NC}"
    else
        echo "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_RED}${h_left}${DF_NC}${h_spaces}${DF_YELLOW}${h_center}${h_spaces}${DF_NC}${DF_BOLD}${h_right}${DF_NC} ${DF_GREY}│${DF_NC}"
    fi 
    # Separator
    echo "${DF_GREY}╘${hline}╛${DF_NC}"
    
    # Stats line
    local s1="${DF_GREY}｢${DF_YELLOW}▲ ${DF_NC}${uptime}${DF_GREY}｣"
    local s2="${DF_GREY}｢${DF_CYAN}◆ ${DF_NC}${load}${DF_GREY}｣"
    local s3="${DF_GREY}｢${DF_GREEN}◇ ${DF_NC}${mem}${DF_GREY}｣"
    local s4="${DF_GREY}｢${DF_BLUE}⊡ ${DF_NC}${disk}${DF_GREY}｣"
    echo " ${s1}─${s2}─${s3}─${s4}"
    
    # Alerts line (if any issues)
    local alerts=""
    
    # Check for failed services
    local failed=$(_motd_failed_services)
    if (( failed > 0 )); then
        alerts+="${DF_RED}⚠ ${failed} failed service(s)${DF_NC}  "
    fi
    
    # Check for updates
    local updates=$(_motd_updates)
    if (( updates > 0 )); then
        alerts+="${DF_YELLOW}⇑ ${updates} update(s)${DF_NC}"
    fi
    
    [[ -n "$alerts" ]] && echo " $alerts"
    
    #echo ""
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
    local load=$(_motd_load)
    local disk=$(_motd_disk)
    local hline=$(_motd_line '═')
    local failed=$(_motd_failed_services)
    
    local alert=""
    (( failed > 0 )) && alert=" ${DF_RED}[${failed} failed]${DF_NC}"


    # Stats line
    local s1="${DF_GREY}｢${DF_YELLOW}▲ ${DF_NC}${uptime}${DF_GREY}｣"
    local s2="${DF_GREY}｢${DF_CYAN}◆ ${DF_NC}${load}${DF_GREY}｣"
    local s3="${DF_GREY}｢${DF_GREEN}◇ ${DF_NC}${mem}${DF_GREY}｣"
    local s4="${DF_GREY}｢${DF_BLUE}⊡ ${DF_NC}${disk}${DF_GREY}｣"

    if [ "$EUID" -ne 0 ];then 
        echo "${DF_DIM}──${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}${hostname}${DF_NC}${s1}─${s2}─${s3}─${s4}${DF_DIM}──${DF_NC}"
    else
        echo "${DF_DIM}──${DF_NC} ${DF_BOLD}${DF_RED}${hostname}${DF_NC}${s1}─${s2}─${s3}─${s4}${DF_DIM}──${DF_NC}"
    fi 
}

# ============================================================================
# Full Format (Extended Info)
# ============================================================================

show_motd_full() {
    [[ -n "$_MOTD_SHOWN" && "$1" != "--force" ]] && return 0
    typeset -g _MOTD_SHOWN=1

    local hostname="${HOST:-$(hostname -s 2>/dev/null)}"
    local datetime=$(date '+%A, %B %d %Y  %H:%M:%S')
    local uptime=$(_motd_uptime)
    local load=$(_motd_load)
    local mem=$(_motd_mem)
    local disk=$(_motd_disk)
    local kernel=$(_motd_kernel)
    local governor=$(_motd_governor)
    local scheduler=$(_motd_scheduler)
    local hline=$(_motd_line '═')

    # echo ""
    echo "${DF_GREY}╒${hline}╕${DF_NC}"
    echo "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_BLUE}✦ ${hostname}${DF_NC}"
    echo "${DF_GREY}│${DF_NC} ${DF_DIM}${datetime}${DF_NC}"
    echo "${DF_GREY}├$(_motd_line '─')┤${DF_NC}"
    
    # System info
    echo "${DF_GREY}│${DF_NC} ${DF_CYAN}Kernel:${DF_NC}    ${kernel}"
    [[ -n "$scheduler" ]] && echo "${DF_GREY}│${DF_NC} ${DF_CYAN}Scheduler:${DF_NC} ${scheduler}"
    [[ -n "$governor" ]] && echo "${DF_GREY}│${DF_NC} ${DF_CYAN}Governor:${DF_NC}  ${governor}"
    
    echo "${DF_GREY}├$(_motd_line '─')┤${DF_NC}"
    
    # Resources
    echo "${DF_GREY}│${DF_NC} ${DF_YELLOW}▲ Uptime:${DF_NC}  ${uptime}"
    echo "${DF_GREY}│${DF_NC} ${DF_CYAN}◆ Load:${DF_NC}    ${load}"
    echo "${DF_GREY}│${DF_NC} ${DF_GREEN}◇ Memory:${DF_NC}  ${mem}"
    echo "${DF_GREY}│${DF_NC} ${DF_BLUE}⊡ Disk:${DF_NC}    ${disk}"
    
    # Alerts section
    local failed=$(_motd_failed_services)
    local updates=$(_motd_updates)
    
    if (( failed > 0 || updates > 0 )); then
        echo "${DF_GREY}├$(_motd_line '─')┤${DF_NC}"
        (( failed > 0 )) && echo "${DF_GREY}│${DF_NC} ${DF_RED}⚠ ${failed} failed systemd service(s)${DF_NC}"
        (( updates > 0 )) && echo "${DF_GREY}│${DF_NC} ${DF_YELLOW}⇑ ${updates} package update(s) available${DF_NC}"
    fi
    
    echo "${DF_GREY}╘${hline}╛${DF_NC}"
    #echo ""
}

# ============================================================================
# Aliases
# ============================================================================

alias motd='show_motd --force'
alias motd-mini='show_motd_mini --force'
alias motd-full='show_motd_full --force'

# ============================================================================
# Quick System Overview (callable anytime)
# ============================================================================

sysbrief() {
    echo -e "${DF_CYAN}Uptime:${DF_NC}    $(_motd_uptime)"
    echo -e "${DF_CYAN}Load:${DF_NC}      $(_motd_load)"
    echo -e "${DF_CYAN}Memory:${DF_NC}    $(_motd_mem)"
    echo -e "${DF_CYAN}Disk:${DF_NC}      $(_motd_disk)"
    
    local kernel=$(_motd_kernel)
    echo -e "${DF_CYAN}Kernel:${DF_NC}    ${kernel}"
    
    local governor=$(_motd_governor)
    [[ -n "$governor" ]] && echo -e "${DF_CYAN}Governor:${DF_NC}  ${governor}"
    
    local scheduler=$(_motd_scheduler)
    [[ -n "$scheduler" ]] && echo -e "${DF_CYAN}Scheduler:${DF_NC} ${scheduler}"
    
    local failed=$(_motd_failed_services)
    if (( failed > 0 )); then
        echo -e "${DF_RED}Failed:${DF_NC}    ${failed} service(s)"
    fi
}
