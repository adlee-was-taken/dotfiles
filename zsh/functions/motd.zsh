#!/usr/bin/env zsh
# ============================================================================
# Dynamic MOTD - Compact System Info on Shell Start
# ============================================================================
# A beautiful, informative welcome screen for your terminal
#
# Add to .zshrc:
#   source ~/.dotfiles/zsh/functions/motd.zsh
#   show_motd  # or call automatically
# ============================================================================

# ============================================================================
# Configuration
# ============================================================================

typeset -g MOTD_ENABLED="${MOTD_ENABLED:-true}"
typeset -g MOTD_SHOW_WEATHER="${MOTD_SHOW_WEATHER:-false}"
typeset -g MOTD_WEATHER_LOCATION="${MOTD_WEATHER_LOCATION:-}"

# Colors
typeset -g M_RESET=$'\033[0m'
typeset -g M_BOLD=$'\033[1m'
typeset -g M_DIM=$'\033[2m'
typeset -g M_CYAN=$'\033[36m'
typeset -g M_GREEN=$'\033[32m'
typeset -g M_YELLOW=$'\033[33m'
typeset -g M_RED=$'\033[31m'
typeset -g M_BLUE=$'\033[34m'
typeset -g M_MAGENTA=$'\033[35m'

# ============================================================================
# Data Collection Functions
# ============================================================================

_motd_hostname() {
    hostname -s 2>/dev/null || echo "${HOST:-unknown}"
}

_motd_user() {
    echo "${USER:-$(whoami)}"
}

_motd_uptime() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local boot=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
        local now=$(date +%s)
        local diff=$((now - boot))
    else
        local diff=$(cat /proc/uptime 2>/dev/null | cut -d. -f1)
    fi
    
    [[ -z "$diff" ]] && { echo "?"; return; }
    
    local days=$((diff / 86400))
    local hours=$(((diff % 86400) / 3600))
    local mins=$(((diff % 3600) / 60))
    
    if [[ $days -gt 0 ]]; then
        echo "${days}d ${hours}h"
    elif [[ $hours -gt 0 ]]; then
        echo "${hours}h ${mins}m"
    else
        echo "${mins}m"
    fi
}

_motd_cpu() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local cpu=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | awk '{print int($3)}')
    else
        local cpu=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print int($2)}')
        [[ -z "$cpu" ]] && cpu=$(cat /proc/stat 2>/dev/null | head -1 | awk '{print int(($2+$4)*100/($2+$4+$5))}')
    fi
    echo "${cpu:-?}%"
}

_motd_memory() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local total=$(sysctl -n hw.memsize 2>/dev/null)
        local used=$(vm_stat 2>/dev/null | awk '/Pages active/ {print $3}' | tr -d '.')
        if [[ -n "$total" && -n "$used" ]]; then
            local total_gb=$((total / 1073741824))
            local used_gb=$((used * 4096 / 1073741824))
            echo "${used_gb}/${total_gb}G"
        else
            echo "?G"
        fi
    else
        local mem=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3"/"$2}')
        echo "${mem:-?G}" | sed 's/i//g'
    fi
}

_motd_disk() {
    local disk=$(df -h ~ 2>/dev/null | awk 'NR==2 {print $4}')
    echo "${disk:-?}free"
}

_motd_load() {
    local load=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
    echo "${load:-?}"
}

_motd_updates() {
    local count=0
    if command -v checkupdates &>/dev/null; then
        count=$(checkupdates 2>/dev/null | wc -l)
    elif command -v apt &>/dev/null; then
        count=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
    elif command -v brew &>/dev/null; then
        count=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')
    fi
    echo "$count"
}

_motd_docker() {
    command -v docker &>/dev/null || return
    local running=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    [[ "$running" -gt 0 ]] && echo "${running} containers"
}

_motd_git_repos() {
    # Check for uncommitted changes in common dirs
    local needs_push=0
    local dirs=("$HOME/.dotfiles" "$HOME/projects"/* "$HOME/work"/* 2>/dev/null)
    
    for dir in "${dirs[@]}"; do
        [[ -d "$dir/.git" ]] || continue
        (cd "$dir" && ! git diff --quiet 2>/dev/null) && ((needs_push++))
    done
    
    [[ $needs_push -gt 0 ]] && echo "$needs_push dirty"
}

_motd_dotfiles_status() {
    [[ ! -d "$HOME/.dotfiles/.git" ]] && return
    
    cd "$HOME/.dotfiles" 2>/dev/null || return
    git fetch origin --quiet 2>/dev/null
    
    local behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || git rev-list HEAD..origin/master --count 2>/dev/null || echo 0)
    local ahead=$(git rev-list origin/main..HEAD --count 2>/dev/null || git rev-list origin/master..HEAD --count 2>/dev/null || echo 0)
    
    if [[ $behind -gt 0 ]]; then
        echo "↓$behind"
    elif [[ $ahead -gt 0 ]]; then
        echo "↑$ahead"
    else
        echo "✓"
    fi
}

_motd_date() {
    date '+%a %b %d'
}

_motd_time() {
    date '+%H:%M'
}

# ============================================================================
# Display Function
# ============================================================================

show_motd() {
    [[ "$MOTD_ENABLED" != "true" ]] && return
    
    # Collect data
    local user=$(_motd_user)
    local host=$(_motd_hostname)
    local uptime=$(_motd_uptime)
    local cpu=$(_motd_cpu)
    local mem=$(_motd_memory)
    local disk=$(_motd_disk)
    local load=$(_motd_load)
    local updates=$(_motd_updates)
    local docker=$(_motd_docker)
    local git_status=$(_motd_git_repos)
    local dotfiles=$(_motd_dotfiles_status)
    local dt=$(_motd_date)
    local tm=$(_motd_time)
    
    # Build status indicators
    local status_line=""
    
    [[ -n "$docker" ]] && status_line+="${M_CYAN}◉${M_RESET}$docker  "
    [[ -n "$git_status" ]] && status_line+="${M_YELLOW}⎇${M_RESET}$git_status  "
    [[ "$updates" -gt 0 ]] && status_line+="${M_GREEN}↑${M_RESET}${updates}updates  "
    [[ -n "$dotfiles" ]] && status_line+="${M_MAGENTA}●${M_RESET}dotfiles:$dotfiles"
    
    # Print compact MOTD
    echo
    echo "${M_DIM}┌──────────────────────────────────────────────────────────────┐${M_RESET}"
    printf "${M_DIM}│${M_RESET} ${M_BOLD}${M_CYAN}✦${M_RESET} ${M_BOLD}%s${M_RESET}@${M_CYAN}%s${M_RESET}%*s${M_DIM}%s %s${M_RESET} ${M_DIM}│${M_RESET}\n" \
        "$user" "$host" $((40 - ${#user} - ${#host})) "" "$dt" "$tm"
    echo "${M_DIM}├──────────────────────────────────────────────────────────────┤${M_RESET}"
    printf "${M_DIM}│${M_RESET} ▲ %-8s  ◆ %-10s  ◇ %-10s  ⊡ %-8s ${M_DIM}│${M_RESET}\n" \
        "up:$uptime" "cpu:$cpu" "mem:$mem" "$disk"
    
    if [[ -n "$status_line" ]]; then
        echo "${M_DIM}├──────────────────────────────────────────────────────────────┤${M_RESET}"
        printf "${M_DIM}│${M_RESET} %s%*s${M_DIM}│${M_RESET}\n" "$status_line" $((62 - ${#status_line} + 30)) ""
    fi
    
    echo "${M_DIM}└──────────────────────────────────────────────────────────────┘${M_RESET}"
    echo
}

# Alias
motd() { show_motd; }

# ============================================================================
# Minimal Version (single line)
# ============================================================================

show_motd_mini() {
    [[ "$MOTD_ENABLED" != "true" ]] && return
    
    local user=$(_motd_user)
    local host=$(_motd_hostname)
    local uptime=$(_motd_uptime)
    local mem=$(_motd_memory)
    local updates=$(_motd_updates)
    
    local info="${M_CYAN}${user}@${host}${M_RESET}"
    info+=" ${M_DIM}│${M_RESET} ▲${uptime}"
    info+=" ${M_DIM}│${M_RESET} ◇${mem}"
    [[ "$updates" -gt 0 ]] && info+=" ${M_DIM}│${M_RESET} ${M_GREEN}↑${updates}${M_RESET}"
    
    echo "$info"
    echo
}

# ============================================================================
# Auto-show on source (optional)
# ============================================================================

# Uncomment to show automatically:
# show_motd
