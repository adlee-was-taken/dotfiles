# ============================================================================
# Systemd Integration for Arch/CachyOS
# ============================================================================
# Quick shortcuts and helpers for systemd service management
#
# Commands:
#   sc <args>           - sudo systemctl
#   scu <args>          - systemctl --user
#   scr <service>       - restart and show status
#   sce <service>       - enable and start
#   scd <service>       - disable and stop
#   sclog <service>     - follow journal logs
#   sc-failed           - show failed services
#   sc-timers           - show active timers
#   sc-recent           - recently started services
#   sc-boot             - boot time analysis
# ============================================================================

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    typeset -g DF_RED=$'\033[0;31m' DF_BLUE=$'\033[0;34m'
    typeset -g DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
}

# ============================================================================
# Core Systemctl Shortcuts
# ============================================================================

# System-level systemctl (with sudo)
sc() {
    sudo systemctl "$@"
}

# User-level systemctl
scu() {
    systemctl --user "$@"
}

# Restart service and show status
scr() {
    local service="$1"
    [[ -z "$service" ]] && { echo "Usage: scr <service>"; return 1; }
    
    echo -e "${DF_BLUE}==>${DF_NC} Restarting ${service}..."
    if sudo systemctl restart "$service"; then
        echo -e "${DF_GREEN}✓${DF_NC} Restarted successfully"
        echo ""
        sudo systemctl status "$service" --no-pager -l
    else
        echo -e "${DF_RED}✗${DF_NC} Failed to restart ${service}"
        return 1
    fi
}

# Enable and start service
sce() {
    local service="$1"
    [[ -z "$service" ]] && { echo "Usage: sce <service>"; return 1; }
    
    echo -e "${DF_BLUE}==>${DF_NC} Enabling and starting ${service}..."
    if sudo systemctl enable --now "$service"; then
        echo -e "${DF_GREEN}✓${DF_NC} ${service} enabled and started"
        sudo systemctl status "$service" --no-pager -l | head -15
    else
        echo -e "${DF_RED}✗${DF_NC} Failed to enable ${service}"
        return 1
    fi
}

# Disable and stop service
scd() {
    local service="$1"
    [[ -z "$service" ]] && { echo "Usage: scd <service>"; return 1; }
    
    echo -e "${DF_BLUE}==>${DF_NC} Disabling and stopping ${service}..."
    if sudo systemctl disable --now "$service"; then
        echo -e "${DF_GREEN}✓${DF_NC} ${service} disabled and stopped"
    else
        echo -e "${DF_RED}✗${DF_NC} Failed to disable ${service}"
        return 1
    fi
}

# Follow journal logs for a service
sclog() {
    local service="$1"
    local lines="${2:-50}"
    [[ -z "$service" ]] && { echo "Usage: sclog <service> [lines]"; return 1; }
    
    echo -e "${DF_BLUE}==>${DF_NC} Following logs for ${service} (Ctrl+C to exit)..."
    sudo journalctl -xeu "$service" -f -n "$lines"
}

# Show recent logs for a service (without follow)
sclogs() {
    local service="$1"
    local lines="${2:-50}"
    [[ -z "$service" ]] && { echo "Usage: sclogs <service> [lines]"; return 1; }
    
    sudo journalctl -xeu "$service" -n "$lines" --no-pager
}

# ============================================================================
# Service Status Commands
# ============================================================================

# Show failed services (system and user)
sc-failed() {
    df_print_func_name "Failed Services"
    
    echo -e "${DF_CYAN}System Services:${DF_NC}"
    local sys_failed=$(systemctl --failed --no-pager --no-legend 2>/dev/null)
    if [[ -z "$sys_failed" ]]; then
        echo -e "  ${DF_GREEN}✓${DF_NC} No failed system services"
    else
        echo "$sys_failed" | sed 's/^/  /'
    fi
    
    echo -e "\n${DF_CYAN}User Services:${DF_NC}"
    local user_failed=$(systemctl --user --failed --no-pager --no-legend 2>/dev/null)
    if [[ -z "$user_failed" ]]; then
        echo -e "  ${DF_GREEN}✓${DF_NC} No failed user services"
    else
        echo "$user_failed" | sed 's/^/  /'
    fi
    
    echo ""
}

# Show active timers
sc-timers() {
    df_print_func_name "Active Timers"
    
    echo -e "${DF_CYAN}System Timers:${DF_NC}"
    systemctl list-timers --no-pager | head -20
    
    echo -e "\n${DF_CYAN}User Timers:${DF_NC}"
    systemctl --user list-timers --no-pager 2>/dev/null | head -10
    
    echo ""
}

# Show recently started/stopped services
sc-recent() {
    local count="${1:-15}"
    
    df_print_func_name "Recent Service Activity"
    
    echo -e "${DF_CYAN}Recently Started:${DF_NC}"
    systemctl list-units --type=service --state=running --no-pager --no-legend | \
        head -"$count" | awk '{print "  " $1}'
    
    echo -e "\n${DF_CYAN}Recent Journal (services):${DF_NC}"
    journalctl -p 3 -xb --no-pager | tail -"$count" | sed 's/^/  /'
    
    echo ""
}

# Boot time analysis
sc-boot() {
    df_print_func_name "Boot Time Analysis"
    
    echo -e "${DF_CYAN}Boot Summary:${DF_NC}"
    systemd-analyze
    
    echo -e "\n${DF_CYAN}Slowest Services (top 10):${DF_NC}"
    systemd-analyze blame --no-pager | head -10 | sed 's/^/  /'
    
    echo -e "\n${DF_CYAN}Critical Chain:${DF_NC}"
    systemd-analyze critical-chain --no-pager 2>/dev/null | head -15 | sed 's/^/  /'
    
    echo ""
}

# ============================================================================
# Service Search and Info
# ============================================================================

# Search for services by name
sc-search() {
    local query="$1"
    [[ -z "$query" ]] && { echo "Usage: sc-search <query>"; return 1; }
    
    df_print_func_name "Service Search: $query"
    
    systemctl list-unit-files --type=service --no-pager | grep -i "$query"
}

# Show detailed service info
sc-info() {
    local service="$1"
    [[ -z "$service" ]] && { echo "Usage: sc-info <service>"; return 1; }
    
    df_print_func_name "Service Info: $service"
    
    echo -e "${DF_CYAN}Status:${DF_NC}"
    systemctl status "$service" --no-pager -l 2>/dev/null || \
        sudo systemctl status "$service" --no-pager -l
    
    echo -e "\n${DF_CYAN}Unit File:${DF_NC}"
    systemctl cat "$service" 2>/dev/null | head -30
    
    echo ""
}

# ============================================================================
# Quick Status for MOTD Integration
# ============================================================================

# Get count of failed services (for MOTD/prompt)
_systemd_failed_count() {
    local count=$(systemctl --failed --no-pager --no-legend 2>/dev/null | wc -l)
    echo "$count"
}

# Check if a service is active (for scripts)
_systemd_is_active() {
    local service="$1"
    systemctl is-active --quiet "$service" 2>/dev/null
}

# Check if a service is enabled (for scripts)
_systemd_is_enabled() {
    local service="$1"
    systemctl is-enabled --quiet "$service" 2>/dev/null
}

# ============================================================================
# Interactive Service Management (requires fzf)
# ============================================================================

if command -v fzf &>/dev/null; then
    # Interactive service selector
    scf() {
        local service=$(systemctl list-units --type=service --no-pager --no-legend | \
            awk '{print $1, $2, $3, $4}' | \
            fzf --height=50% --layout=reverse --border=rounded \
                --prompt='Service > ' \
                --preview='systemctl status {1} --no-pager' \
                --preview-window=right:50%:wrap | \
            awk '{print $1}')
        
        if [[ -n "$service" ]]; then
            echo -e "${DF_BLUE}Selected:${DF_NC} $service"
            echo ""
            echo "Actions: [s]tatus [r]estart [o]stop [l]ogs [e]nable [d]isable [q]uit"
            read -k 1 "action?Action: "
            echo ""
            
            case "$action" in
                s) sudo systemctl status "$service" --no-pager -l ;;
                r) scr "$service" ;;
                o) sudo systemctl stop "$service" ;;
                l) sclog "$service" ;;
                e) sce "$service" ;;
                d) scd "$service" ;;
                q) return 0 ;;
                *) echo "Unknown action" ;;
            esac
        fi
    }
    
    # Interactive log viewer
    sclogf() {
        local service=$(systemctl list-units --type=service --no-pager --no-legend | \
            awk '{print $1}' | \
            fzf --height=40% --layout=reverse --prompt='Service logs > ')
        
        [[ -n "$service" ]] && sclog "$service"
    }
fi

# ============================================================================
# Aliases
# ============================================================================

alias scs='sc status'
alias scstart='sc start'
alias scstop='sc stop'
alias screload='sc daemon-reload'
alias scmask='sc mask'
alias scunmask='sc unmask'

# Journal shortcuts
alias jctl='journalctl'
alias jctlf='journalctl -f'
alias jctlb='journalctl -b'
alias jctlerr='journalctl -p err -b'

# ============================================================================
# Help
# ============================================================================

sc-help() {
    df_print_func_name "Systemd Helper Commands"
    
    cat << 'EOF'

  Core Commands:
    sc <args>           sudo systemctl <args>
    scu <args>          systemctl --user <args>
    scr <service>       Restart and show status
    sce <service>       Enable and start (--now)
    scd <service>       Disable and stop (--now)
    sclog <service>     Follow journal logs (-f)
    sclogs <service>    Show recent logs (no follow)
    
  Status Commands:
    sc-failed           Show failed services
    sc-timers           Show active timers
    sc-recent           Recently started services
    sc-boot             Boot time analysis
    sc-search <query>   Search services by name
    sc-info <service>   Detailed service info
    
  Interactive (requires fzf):
    scf                 Interactive service manager
    sclogf              Interactive log viewer
    
  Aliases:
    scs                 sc status
    scstart             sc start
    scstop              sc stop
    screload            sc daemon-reload
    
  Journal:
    jctl                journalctl
    jctlf               journalctl -f
    jctlb               journalctl -b (current boot)
    jctlerr             journalctl -p err -b

EOF
}
