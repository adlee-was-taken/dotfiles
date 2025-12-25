# ============================================================================
# Btrfs Helpers for Arch/CachyOS
# ============================================================================
# Quick commands for btrfs filesystem management
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

typeset -g BTRFS_DEFAULT_MOUNT="${BTRFS_DEFAULT_MOUNT:-/}"

_btrfs_check() {
    df_require_cmd btrfs btrfs-progs || return 1
    if ! df_is_btrfs; then
        df_print_warning "Root filesystem is not btrfs"
        return 1
    fi
    return 0
}

btrfs-usage() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    df_print_func_name "Btrfs Filesystem Usage: ${mount}"
    sudo btrfs filesystem usage "$mount" -h
}

btrfs-subs() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    df_print_func_name "Btrfs Subvolumes"
    df_print_section "Subvolume List"
    sudo btrfs subvolume list "$mount" | while read -r line; do
        local path=$(echo "$line" | awk '{print $NF}')
        local id=$(echo "$line" | awk '{print $2}')
        df_print_indent "● [$id] $path"
    done
    echo ""
    df_print_section "Default Subvolume"
    sudo btrfs subvolume get-default "$mount"
}

btrfs-balance() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    local usage="${2:-50}"
    df_print_func_name "Btrfs Balance"
    df_confirm_warning "This may take a while and use significant I/O" || return 0
    echo ""
    df_print_step "Balancing data chunks with <${usage}% usage..."
    sudo btrfs balance start -dusage="$usage" -musage="$usage" "$mount" -v
    [[ $? -eq 0 ]] && df_print_success "Balance completed" || df_print_warning "Balance finished (may have been interrupted)"
}

btrfs-balance-status() {
    _btrfs_check || return 1
    df_print_func_name "Btrfs Balance Status"
    sudo btrfs balance status "${1:-$BTRFS_DEFAULT_MOUNT}"
}

btrfs-balance-cancel() {
    _btrfs_check || return 1
    df_print_step "Cancelling balance..."
    sudo btrfs balance cancel "${1:-$BTRFS_DEFAULT_MOUNT}"
}

btrfs-scrub() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    df_print_func_name "Btrfs Scrub"
    local status=$(sudo btrfs scrub status "$mount" 2>/dev/null)
    if echo "$status" | grep -q "running"; then
        df_print_section "Scrub Status (running)"
        echo "$status" | sed 's/^/  /'
        return 0
    fi
    df_print_warning "Scrub verifies data integrity and may take hours"
    df_confirm "Start scrub?" || return 0
    df_print_step "Starting scrub..."
    sudo btrfs scrub start "$mount"
    echo ""
    df_print_section "Scrub Status"
    sudo btrfs scrub status "$mount"
    df_print_info "Monitor with: btrfs-scrub-status"
}

btrfs-scrub-status() {
    _btrfs_check || return 1
    df_print_func_name "Btrfs Scrub Status"
    sudo btrfs scrub status "${1:-$BTRFS_DEFAULT_MOUNT}"
}

btrfs-scrub-cancel() {
    _btrfs_check || return 1
    df_print_step "Cancelling scrub..."
    sudo btrfs scrub cancel "${1:-$BTRFS_DEFAULT_MOUNT}"
}

btrfs-defrag() {
    _btrfs_check || return 1
    local target="${1:-.}"
    [[ ! -e "$target" ]] && { df_print_error "Target not found: $target"; return 1; }
    df_print_func_name "Btrfs Defragment"
    if [[ -d "$target" ]]; then
        df_print_warning "Recursive defrag on directory: $target"
        df_confirm "Continue?" || return 0
        sudo btrfs filesystem defragment -r -v "$target"
    else
        df_print_step "Defragmenting: $target"
        sudo btrfs filesystem defragment -v "$target"
    fi
    df_print_success "Defragmentation complete"
}

btrfs-compress() {
    _btrfs_check || return 1
    df_require_cmd compsize || return 1
    df_print_func_name "Btrfs Compression Statistics"
    sudo compsize "${1:-$BTRFS_DEFAULT_MOUNT}"
}

btrfs-info() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    df_print_func_name "Btrfs Filesystem Information"
    df_print_section "Filesystem Show"
    sudo btrfs filesystem show "$mount"
    echo ""
    df_print_section "Filesystem df"
    sudo btrfs filesystem df "$mount"
    echo ""
    df_print_section "Device Stats"
    sudo btrfs device stats "$mount"
}

btrfs-health() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    df_print_func_name "Btrfs Health Check"
    local issues=0
    
    df_print_section "Device Errors"
    local errors=$(sudo btrfs device stats "$mount" 2>/dev/null | grep -v " 0$" | grep -v "^$")
    [[ -z "$errors" ]] && df_print_indent "✓ No errors" || { df_print_indent "✗ Errors detected:"; echo "$errors" | sed 's/^/    /'; ((issues++)); }
    
    echo ""
    df_print_section "Space Allocation"
    local used_pct=$(sudo btrfs filesystem usage "/" -b 2>/dev/null | grep "Used:" | awk -F"%" '{print $1}' | awk -F"(" '{print $2"%"}' | head -2 | tail -1)
    if [[ -n "$used_pct" ]]; then
        (( used_pct >= 90 )) && { df_print_indent "✗ ${used_pct}% full - critical!"; ((issues++)); } || \
        (( used_pct >= 80 )) && df_print_indent "⚠ ${used_pct}% full" || df_print_indent "✓ ${used_pct}% used"
    fi
    
    echo ""
    df_print_section "Last Scrub"
    local scrub=$(sudo btrfs scrub status "$mount" 2>/dev/null)
    local scrub_date=$(echo "$scrub" | grep "Scrub started" | awk '{print $3, $4, $5}')
    [[ -n "$scrub_date" ]] && df_print_indent "Last: $scrub_date" || df_print_indent "⚠ No scrub run yet"
    
    echo ""
    (( issues == 0 )) && df_print_success "Filesystem healthy" || df_print_error "Found $issues issue(s)"
}

btrfs-snap-usage() {
    _btrfs_check || return 1
    df_print_func_name "Snapshot Disk Space Usage"
    if [[ -d "/.snapshots" ]]; then
        df_print_section "Snapshot Directory"
        local size=$(timeout 10 sudo du -sh /.snapshots 2>/dev/null | cut -f1)
        df_print_indent "${size:-Unable to calculate}"
        echo ""
        df_print_section "Individual Snapshots (top 10)"
        timeout 30 sudo du -sh /.snapshots/*/ 2>/dev/null | sort -h | tail -10 | sed 's/^/  /'
    else
        df_print_warning "No /.snapshots directory found"
    fi
}

btrfs-maintain() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    df_print_func_name "Btrfs Maintenance Routine"
    echo "This will: health check, balance, scrub"
    df_confirm_warning "This may take several hours" || return 0
    df_print_step "Step 1/3: Health Check"
    btrfs-health "$mount"
    df_print_step "Step 2/3: Balance"
    sudo btrfs balance start -dusage=50 -musage=50 "$mount"
    df_print_step "Step 3/3: Scrub"
    sudo btrfs scrub start -B "$mount"
    df_print_success "Maintenance complete"
}

btrfs-help() {
    df_print_func_name "Btrfs Helper Commands"
    cat << 'EOF'
  btrfs-usage [mount]     Filesystem usage
  btrfs-subs [mount]      List subvolumes
  btrfs-info [mount]      Full filesystem info
  btrfs-health [mount]    Quick health check
  btrfs-compress [path]   Compression stats
  btrfs-balance [mount]   Start balance
  btrfs-scrub [mount]     Start scrub
  btrfs-defrag <path>     Defragment
  btrfs-snap-usage        Snapshot space usage
  btrfs-maintain [mount]  Full maintenance
EOF
}

alias btru='btrfs-usage' btrs='btrfs-subs' btrh='btrfs-health' btri='btrfs-info' btrc='btrfs-compress'
