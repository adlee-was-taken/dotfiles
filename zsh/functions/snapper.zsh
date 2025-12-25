# ============================================================================
# Snapper Snapshot Functions for CachyOS/Arch with limine-snapper-sync
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

snap-create() {
    local desc="$*"
    local limine="/boot/limine.conf"
    
    df_print_func_name "Snapper Snapshot Creation"
    
    if [[ -z "$desc" ]]; then
        df_print_warning "No description"
        echo -n "Description: "; read desc
        [[ -z "$desc" ]] && { df_print_error "Required"; return 1; }
    fi
    
    [[ ! -f "$limine" ]] && { df_print_error "Limine not found: $limine"; return 1; }
    
    df_print_step "Checking limine.conf before snapshot"
    local before=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine" || echo "0")
    df_print_success "Before: $before entries"
    
    df_print_step "Creating snapshot: \"$desc\""
    local num=$(sudo snapper -c root create --description "$desc" --print-number)
    [[ -z "$num" ]] && { df_print_error "Failed"; return 1; }
    df_print_success "Created: #$num"
    
    df_print_step "Triggering limine-snapper-sync..."
    sudo systemctl start limine-snapper-sync.service && df_print_success "Triggered" || df_print_warning "May run automatically"
    sleep 2
    
    df_print_step "Validating"
    local after=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine" || echo "0")
    
    if sudo grep -qP "^\\s*///$num\\s*│" "$limine"; then
        df_print_success "Snapshot #$num in limine.conf"
        (( after > before )) && df_print_success "Added $((after - before)) entry"
    else
        df_print_error "Snapshot #$num NOT in limine.conf"
        return 1
    fi
    
    echo ""
    df_print_section "Summary"
    df_print_indent "Number: #$num"
    df_print_indent "Description: $desc"
}

snap-list() {
    local count="${1:-10}"
    df_print_func_name "Snapper Snapshots (last $count)"
    sudo snapper -c root list | tail -n "$((count + 1))"
}

snap-show() {
    [[ -z "$1" ]] && { echo "Usage: snap-show <num>"; return 1; }
    df_print_func_name "Snapshot #$1"
    sudo snapper -c root list | grep "^\s*$1\s"
    echo ""
    df_print_section "In limine.conf"
    sudo grep -qP "^\\s*///$1\\s*│" /boot/limine.conf && \
        sudo grep -P "^\\s*///$1\\s*│" /boot/limine.conf || df_print_warning "Not found"
}

snap-delete() {
    [[ -z "$1" ]] && { echo "Usage: snap-delete <num>"; return 1; }
    df_print_func_name "Delete Snapshot #$1"
    
    local before=$(sudo grep -cP "^\\s*///\\d+\\s*│" /boot/limine.conf || echo "0")
    sudo snapper -c root delete "$1" && df_print_success "Deleted #$1" || { df_print_error "Failed"; return 1; }
    
    df_print_step "Syncing limine..."
    sudo systemctl start limine-snapper-sync.service; sleep 2
    
    sudo grep -qP "^\\s*///$1\\s*│" /boot/limine.conf && df_print_error "Still in limine!" || df_print_success "Removed from limine"
}

snap-sync() {
    df_print_func_name "Limine-Snapper-Sync"
    df_print_step "Triggering sync..."
    sudo systemctl start limine-snapper-sync.service && { sleep 2; df_print_success "Done"; } || df_print_error "Failed"
}

snap-check() {
    df_print_func_name "Limine Snapshot Entries"
    local latest=$(sudo snapper -c root list | tail -n +3 | grep -v "^\s*0\s" | tail -1 | awk '{print $1}')
    [[ -z "$latest" ]] && { df_print_warning "No snapshots"; return 1; }
    df_print_info "Latest: #$latest"
    sudo grep -qP "^\\s*///$latest\\s*│" /boot/limine.conf && \
        df_print_success "Latest in limine.conf" || df_print_error "Latest NOT in limine.conf"
    local count=$(sudo grep -cP "^\\s*///\\d+\\s*│" /boot/limine.conf || echo "0")
    df_print_info "Total entries: $count"
}

alias snap='snap-create' snapls='snap-list' snaprm='snap-delete' snapcheck='snap-check'
