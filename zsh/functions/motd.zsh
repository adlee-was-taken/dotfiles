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

# ============================================================================
# Source Configuration
# ============================================================================
# utils.zsh sources config.zsh which sources dotfiles.conf
# This gives us DF_WIDTH, MOTD_STYLE, colors, and all other settings

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null || {
    # Fallback if utils.zsh not available
    typeset -g DF_RESET=$'\033[0m' DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
    typeset -g DF_BLUE=$'\033[38;5;39m' DF_CYAN=$'\033[38;5;51m'
    typeset -g DF_GREEN=$'\033[38;5;82m' DF_YELLOW=$'\033[38;5;220m'
    typeset -g DF_RED=$'\033[38;5;196m' DF_GREY=$'\033[38;5;242m' DF_NC=$'\033[0m'
    typeset -g DF_LIGHT_BLUE=$'\033[38;5;39m' DF_LIGHT_GREEN=$'\033[38;5;82m'
    typeset -g DF_WIDTH="${DF_WIDTH:-66}"
    typeset -g MOTD_STYLE="${MOTD_STYLE:-compact}"
}

# ============================================================================
# Optimized Info Gathering (using /proc directly)
# ============================================================================

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

_motd_load() { cut -d' ' -f1 /proc/loadavg 2>/dev/null || echo "?"; }

_motd_mem() {
    awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {
        if (total > 0) {
            used=(total-avail)/1024/1024
            total_gb=total/1024/1024
            printf "%.1fG/%.0fG", used, total_gb
        } else { print "N/A" }
    }' /proc/meminfo 2>/dev/null || echo "N/A"
}

_motd_disk() { df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2}' || echo "N/A"; }

_motd_failed_services() {
    local cache_file="/tmp/.motd-failed-${UID}"
    local cache_age=300
    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        (( file_age < cache_age )) && { cat "$cache_file"; return; }
    fi
    local count=$(systemctl --failed --no-pager --no-legend 2>/dev/null | wc -l)
    echo "$count" > "$cache_file" 2>/dev/null
    echo "$count"
}

_motd_updates() { echo "${UPDATE_PKG_COUNT:-0}"; }

# ============================================================================
# Box Drawing - Uses DF_WIDTH from config
# ============================================================================

_motd_line() {
    local char="$1"
    local width="${DF_WIDTH}"
    local line=""
    for ((i=0; i<width; i++)); do line+="$char"; done
    echo "$line"
}

# ============================================================================
# Main Display Function (Compact)
# ============================================================================

show_motd() {
    [[ -n "$_MOTD_SHOWN" && "$1" != "--force" ]] && return 0
    typeset -g _MOTD_SHOWN=1

    local width="${DF_WIDTH:-66}"
    local hostname="${HOST:-$(hostname -s 2>/dev/null)}"
    local username=$(whoami)
    local datetime=$(date '+%a %b %d %H:%M')
    local uptime=$(_motd_uptime)
    local load=$(_motd_load)
    local mem=$(_motd_mem)
    local disk=$(_motd_disk)
    local hline=$(_motd_line '═')
    local inner=$((width - 2))

    echo ""
    echo "${DF_GREY}╒${hline}╕${DF_NC}"
    
    local h_left="✦ ${username}@${hostname} "
    local h_center=$(hostname -i 2>/dev/null | awk -F" " '{print $1}')
    local h_right="${datetime}"
    local h_pad=$(((inner - ${#h_left} - ${#h_center} - ${#h_right}) / 2))
    local h_spaces=""
    for ((i=0; i<h_pad; i++)); do h_spaces+=" "; done

    if [ "$EUID" -ne 0 ]; then 
        echo "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}${h_left}${DF_NC}${h_spaces}${DF_YELLOW}${h_center}${h_spaces}${DF_NC}${DF_BOLD}${h_right}${DF_NC} ${DF_GREY}│${DF_NC}"
    else
        echo "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_RED}${h_left}${DF_NC}${h_spaces}${DF_YELLOW}${h_center}${h_spaces}${DF_NC}${DF_BOLD}${h_right}${DF_NC} ${DF_GREY}│${DF_NC}"
    fi 
    
    echo "${DF_GREY}╘${hline}╛${DF_NC}"
    
    local s1="${DF_GREY}｢${DF_YELLOW}▲ ${DF_NC}${uptime}${DF_GREY}｣"
    local s2="${DF_GREY}｢${DF_CYAN}◆ ${DF_NC}${load}${DF_GREY}｣"
    local s3="${DF_GREY}｢${DF_GREEN}▪ ${DF_NC}${mem}${DF_GREY}｣"
    local s4="${DF_GREY}｢${DF_BLUE}● ${DF_NC}${disk}${DF_GREY}｣"

    echo " ${s1}  ${s2}  ${s3}  ${s4}"
    
    # Failed services warning
    if [[ "${MOTD_SHOW_FAILED_SERVICES:-true}" == "true" ]]; then
        local failed=$(_motd_failed_services)
        (( failed > 0 )) && echo "  ${DF_RED}⚠${DF_NC} ${failed} failed service(s)"
    fi
    
    echo ""
}

# ============================================================================
# Mini Format (Single Line)
# ============================================================================

show_motd_mini() {
    local hostname="${HOST:-$(hostname -s 2>/dev/null)}"
    local uptime=$(_motd_uptime)
    local load=$(_motd_load)
    echo "${DF_LIGHT_BLUE}${hostname}${DF_NC} │ up ${uptime} │ load ${load}"
}

# ============================================================================
# Full Format (Extended Info)
# ============================================================================

show_motd_full() {
    show_motd --force
    
    local width="${DF_WIDTH:-66}"
    
    echo "${DF_CYAN}System Details${DF_NC}"
    printf "${DF_GREY}─%.0s${DF_NC}" $(seq 1 $width); echo ""
    
    echo "  ${DF_DIM}Kernel:${DF_NC}    $(uname -r)"
    echo "  ${DF_DIM}Shell:${DF_NC}     ${SHELL##*/} ${ZSH_VERSION:-}"
    
    if [[ -f /etc/os-release ]]; then
        local distro=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
        echo "  ${DF_DIM}OS:${DF_NC}        ${distro}"
    fi
    
    if command -v pacman &>/dev/null; then
        local pkg_count=$(pacman -Q 2>/dev/null | wc -l)
        echo "  ${DF_DIM}Packages:${DF_NC}  ${pkg_count}"
    fi
    
    echo ""
}

# ============================================================================
# Auto-display based on MOTD_STYLE from config
# ============================================================================

_motd_auto() {
    case "${MOTD_STYLE:-compact}" in
        full) show_motd_full ;;
        mini) show_motd_mini ;;
        none|off|false) ;;
        *) show_motd ;;
    esac
}

# Run on source if ENABLE_MOTD is true
[[ "${ENABLE_MOTD:-true}" == "true" ]] && _motd_auto
