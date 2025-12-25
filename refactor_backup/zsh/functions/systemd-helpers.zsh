# ============================================================================
# Systemd Integration for Arch/CachyOS
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

# Core shortcuts
sc() { sudo systemctl "$@"; }
scu() { systemctl --user "$@"; }

scr() {
    [[ -z "$1" ]] && { echo "Usage: scr <service>"; return 1; }
    df_print_step "Restarting $1..."
    sudo systemctl restart "$1" && { df_print_success "Restarted"; sudo systemctl status "$1" --no-pager -l; } || df_print_error "Failed"
}

sce() {
    [[ -z "$1" ]] && { echo "Usage: sce <service>"; return 1; }
    df_print_step "Enabling $1..."
    sudo systemctl enable --now "$1" && { df_print_success "Enabled"; sudo systemctl status "$1" --no-pager -l | head -15; } || df_print_error "Failed"
}

scd() {
    [[ -z "$1" ]] && { echo "Usage: scd <service>"; return 1; }
    df_print_step "Disabling $1..."
    sudo systemctl disable --now "$1" && df_print_success "Disabled" || df_print_error "Failed"
}

sclog() {
    [[ -z "$1" ]] && { echo "Usage: sclog <service>"; return 1; }
    df_print_step "Following logs for $1 (Ctrl+C to exit)..."
    sudo journalctl -xeu "$1" -f -n "${2:-50}"
}

sclogs() {
    [[ -z "$1" ]] && { echo "Usage: sclogs <service>"; return 1; }
    sudo journalctl -xeu "$1" -n "${2:-50}" --no-pager
}

sc-failed() {
    df_print_func_name "Failed Services"
    df_print_section "System"
    local sys=$(systemctl --failed --no-pager --no-legend 2>/dev/null)
    [[ -z "$sys" ]] && df_print_indent "✓ None" || echo "$sys" | sed 's/^/  /'
    echo ""
    df_print_section "User"
    local usr=$(systemctl --user --failed --no-pager --no-legend 2>/dev/null)
    [[ -z "$usr" ]] && df_print_indent "✓ None" || echo "$usr" | sed 's/^/  /'
}

sc-timers() {
    df_print_func_name "Active Timers"
    df_print_section "System"
    systemctl list-timers --no-pager | head -15
    echo ""
    df_print_section "User"
    systemctl --user list-timers --no-pager 2>/dev/null | head -10
}

sc-boot() {
    df_print_func_name "Boot Analysis"
    df_print_section "Summary"
    systemd-analyze
    echo ""
    df_print_section "Slowest (top 10)"
    systemd-analyze blame --no-pager | head -10 | sed 's/^/  /'
}

sc-search() {
    [[ -z "$1" ]] && { echo "Usage: sc-search <query>"; return 1; }
    df_print_func_name "Service Search: $1"
    systemctl list-unit-files --type=service --no-pager | grep -i "$1"
}

sc-info() {
    [[ -z "$1" ]] && { echo "Usage: sc-info <service>"; return 1; }
    df_print_func_name "Service: $1"
    systemctl status "$1" --no-pager -l 2>/dev/null || sudo systemctl status "$1" --no-pager -l
    echo ""
    df_print_section "Unit File"
    systemctl cat "$1" 2>/dev/null | head -30
}

# fzf interactive
if df_cmd_exists fzf; then
    scf() {
        local svc=$(systemctl list-units --type=service --no-pager --no-legend | \
            fzf $(df_fzf_opts) --prompt='Service > ' --preview='systemctl status {1} --no-pager' | awk '{print $1}')
        [[ -z "$svc" ]] && return
        df_print_info "Selected: $svc"
        echo "[s]tatus [r]estart [l]ogs [e]nable [d]isable"
        read -k 1 "act?Action: "; echo
        case "$act" in
            s) sudo systemctl status "$svc" --no-pager -l ;;
            r) scr "$svc" ;;
            l) sclog "$svc" ;;
            e) sce "$svc" ;;
            d) scd "$svc" ;;
        esac
    }
fi

sc-help() {
    df_print_func_name "Systemd Commands"
    cat << 'EOF'
  sc <args>         sudo systemctl
  scu <args>        systemctl --user
  scr <svc>         Restart + status
  sce <svc>         Enable + start
  scd <svc>         Disable + stop
  sclog <svc>       Follow logs
  sclogs <svc>      Recent logs
  sc-failed         Failed services
  sc-timers         Active timers
  sc-boot           Boot analysis
  sc-search <q>     Search services
  sc-info <svc>     Service details
  scf               Interactive (fzf)
EOF
}

alias scs='sc status' scstart='sc start' scstop='sc stop' screload='sc daemon-reload'
alias jctl='journalctl' jctlf='journalctl -f' jctlb='journalctl -b'
