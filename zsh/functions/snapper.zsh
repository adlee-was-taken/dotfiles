# ============================================================================
# Snapper Snapshot Functions for CachyOS/Arch with limine-snapper-sync
# ============================================================================
# Note: This relies on limine-snapper-sync service for automatic boot menu
# integration. We only validate that sync occurred, not trigger it manually.
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

LIMINE_CONF="/boot/limine.conf"

# ============================================================================
# Core Snapshot Functions
# ============================================================================

snap-create() {
    local desc="$*"
    
    df_print_func_name "Snapper Snapshot Creation"
    
    if [[ -z "$desc" ]]; then
        df_print_warning "No description"
        echo -n "Description: "; read desc
        [[ -z "$desc" ]] && { df_print_error "Required"; return 1; }
    fi
    
    # Check limine.conf exists (with sudo)
    if ! sudo test -f "$LIMINE_CONF"; then
        df_print_warning "Limine config not found: $LIMINE_CONF"
    fi
    
    df_print_step "Creating snapshot: \"$desc\""
    local num=$(sudo snapper -c root create --description "$desc" --print-number)
    [[ -z "$num" ]] && { df_print_error "Failed"; return 1; }
    df_print_success "Created: #$num"
    
    # Wait for limine-snapper-sync to run (triggered automatically)
    df_print_step "Waiting for limine-snapper-sync..."
    sleep 3
    
    # Validate sync occurred
    _snap_validate_limine "$num"
    
    echo ""
    df_print_section "Summary"
    df_print_indent "Number: #$num"
    df_print_indent "Description: $desc"
    
    # Return the snapshot number for use by other functions
    echo "$num"
}

# Validate a snapshot is in limine.conf
_snap_validate_limine() {
    local num="$1"
    
    if ! sudo test -f "$LIMINE_CONF"; then
        df_print_info "Limine config not found (non-limine system?)"
        return 0
    fi
    
    if sudo grep -qP "^\\s*///$num\\s*│" "$LIMINE_CONF" 2>/dev/null; then
        df_print_success "Snapshot #$num synced to boot menu"
        return 0
    else
        df_print_info "Snapshot #$num not yet in boot menu (sync may be pending)"
        return 1
    fi
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
    if sudo test -f "$LIMINE_CONF"; then
        sudo grep -qP "^\\s*///$1\\s*│" "$LIMINE_CONF" 2>/dev/null && \
            sudo grep -P "^\\s*///$1\\s*│" "$LIMINE_CONF" || df_print_warning "Not found in boot menu"
    else
        df_print_info "Limine not configured"
    fi
}

snap-delete() {
    [[ -z "$1" ]] && { echo "Usage: snap-delete <num>"; return 1; }
    df_print_func_name "Delete Snapshot #$1"
    
    sudo snapper -c root delete "$1" && df_print_success "Deleted #$1" || { df_print_error "Failed"; return 1; }
    
    # Wait for limine-snapper-sync to process deletion
    df_print_step "Waiting for boot menu sync..."
    sleep 3
    
    if sudo test -f "$LIMINE_CONF"; then
        sudo grep -qP "^\\s*///$1\\s*│" "$LIMINE_CONF" 2>/dev/null && \
            df_print_warning "Still in boot menu (sync pending)" || \
            df_print_success "Removed from boot menu"
    fi
}

snap-sync() {
    df_print_func_name "Limine-Snapper-Sync Status"
    
    df_print_step "Service status:"
    systemctl status limine-snapper-sync.service --no-pager -n 3 2>/dev/null || \
        df_print_warning "Service not found"
    
    echo ""
    df_print_step "Path unit status:"
    systemctl status limine-snapper-sync.path --no-pager -n 3 2>/dev/null || \
        df_print_info "Path unit not found (may use different trigger)"
    
    echo ""
    if sudo test -f "$LIMINE_CONF"; then
        local count=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$LIMINE_CONF" 2>/dev/null || echo "0")
        df_print_info "Snapshots in boot menu: $count"
    fi
}

snap-check() {
    df_print_func_name "Limine Snapshot Validation"
    
    if ! sudo test -f "$LIMINE_CONF"; then
        df_print_warning "Limine config not found: $LIMINE_CONF"
        return 1
    fi
    
    local latest=$(sudo snapper -c root list | tail -n +3 | grep -v "^\s*0\s" | tail -1 | awk '{print $1}')
    [[ -z "$latest" ]] && { df_print_warning "No snapshots found"; return 1; }
    
    df_print_info "Latest snapshot: #$latest"
    
    if sudo grep -qP "^\\s*///$latest\\s*│" "$LIMINE_CONF" 2>/dev/null; then
        df_print_success "Latest snapshot is in boot menu"
    else
        df_print_warning "Latest snapshot NOT in boot menu"
        df_print_info "Check: systemctl status limine-snapper-sync"
    fi
    
    local count=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$LIMINE_CONF" 2>/dev/null || echo "0")
    df_print_info "Total boot menu entries: $count"
}

# ============================================================================
# System Update with PRE/POST Snapshots
# ============================================================================

sys-update() {
    local update_date=$(date +"%Y-%m-%d %H:%M")
    local pre_num=""
    local post_num=""
    local update_cmd=""
    local update_success=false
    
    df_print_func_name "System Update with Snapshots"
    
    # Check for snapper
    if ! command -v snapper &>/dev/null; then
        df_print_warning "Snapper not installed, running update without snapshots"
        _sys_update_run
        return $?
    fi
    
    # Determine update command
    if command -v paru &>/dev/null; then
        update_cmd="paru -Syu"
    elif command -v yay &>/dev/null; then
        update_cmd="yay -Syu"
    else
        update_cmd="sudo pacman -Syu"
    fi
    
    echo ""
    df_print_info "Update command: $update_cmd"
    echo ""
    
    # -------------------------------------------------------------------------
    # PRE Snapshot
    # -------------------------------------------------------------------------
    df_print_step "Creating PRE snapshot..."
    
    pre_num=$(sudo snapper -c root create \
        --type pre \
        --cleanup-algorithm number \
        --description "System Update PRE ${update_date}" \
        --print-number 2>/dev/null)
    
    if [[ -z "$pre_num" || ! "$pre_num" =~ ^[0-9]+$ ]]; then
        df_print_error "Failed to create PRE snapshot"
        echo ""
        read -q "REPLY?Continue update without snapshots? [y/N] "
        echo ""
        [[ "$REPLY" != "y" ]] && { df_print_info "Aborted"; return 1; }
        _sys_update_run
        return $?
    fi
    
    df_print_success "PRE snapshot: #$pre_num"
    
    # -------------------------------------------------------------------------
    # Run Update
    # -------------------------------------------------------------------------
    echo ""
    df_print_step "Running system update..."
    echo ""
    
    # Run the update (don't use sudo if using paru/yay)
    if [[ "$update_cmd" == "sudo pacman -Syu" ]]; then
        sudo pacman -Syu
    else
        eval "$update_cmd"
    fi
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        update_success=true
        df_print_success "Update completed successfully"
    else
        df_print_warning "Update finished with exit code: $exit_code"
    fi
    
    # -------------------------------------------------------------------------
    # POST Snapshot
    # -------------------------------------------------------------------------
    echo ""
    df_print_step "Creating POST snapshot..."
    
    post_num=$(sudo snapper -c root create \
        --type post \
        --cleanup-algorithm number \
        --pre-number "$pre_num" \
        --description "System Update POST ${update_date}" \
        --print-number 2>/dev/null)
    
    if [[ -z "$post_num" || ! "$post_num" =~ ^[0-9]+$ ]]; then
        df_print_error "Failed to create POST snapshot"
        df_print_warning "PRE snapshot #$pre_num exists without POST pair"
    else
        df_print_success "POST snapshot: #$post_num (linked to PRE #$pre_num)"
    fi
    
    # -------------------------------------------------------------------------
    # Validate Limine Sync (service handles actual sync)
    # -------------------------------------------------------------------------
    echo ""
    df_print_step "Validating boot menu sync..."
    
    # Give limine-snapper-sync time to process
    sleep 3
    
    if [[ -n "$post_num" ]]; then
        _snap_validate_limine "$post_num"
    fi
    
    # -------------------------------------------------------------------------
    # Update package count for prompt
    # -------------------------------------------------------------------------
    if command -v checkupdates &>/dev/null; then
        export UPDATE_PKG_COUNT=$(checkupdates 2>/dev/null | wc -l)
    fi
    
    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------
    echo ""
    df_print_section "Summary"
    df_print_indent "PRE snapshot:  #$pre_num"
    [[ -n "$post_num" ]] && df_print_indent "POST snapshot: #$post_num"
    df_print_indent "Status: $([[ "$update_success" == true ]] && echo "Success" || echo "Completed with warnings")"
    echo ""
    df_print_info "To rollback: sudo snapper -c root undochange $pre_num..$post_num"
    df_print_info "To compare:  sudo snapper -c root status $pre_num..$post_num"
    
    return $exit_code
}

# Helper for running update without snapshots
_sys_update_run() {
    if command -v paru &>/dev/null; then
        paru -Syu
    elif command -v yay &>/dev/null; then
        yay -Syu
    else
        sudo pacman -Syu
    fi
    
    # Update package count for prompt
    if command -v checkupdates &>/dev/null; then
        export UPDATE_PKG_COUNT=$(checkupdates 2>/dev/null | wc -l)
    fi
}

# ============================================================================
# Rollback Helper
# ============================================================================

sys-rollback() {
    df_print_func_name "System Rollback"
    
    # Show recent pre/post pairs
    df_print_step "Recent update snapshots:"
    echo ""
    sudo snapper -c root list --type pre-post 2>/dev/null | tail -10
    echo ""
    
    if [[ -z "$1" ]]; then
        df_print_info "Usage: sys-rollback <pre-number>"
        df_print_info "Example: sys-rollback 42"
        echo ""
        df_print_info "This will undo changes between the PRE and POST snapshots."
        return 1
    fi
    
    local pre_num="$1"
    
    # Find the corresponding POST snapshot
    local post_num=$(sudo snapper -c root list --type pre-post 2>/dev/null | \
        awk -v pre="$pre_num" '$1 == pre {print $2}')
    
    if [[ -z "$post_num" ]]; then
        df_print_error "Could not find POST snapshot for PRE #$pre_num"
        return 1
    fi
    
    df_print_warning "This will undo all changes between snapshot #$pre_num and #$post_num"
    echo ""
    
    # Show what would change
    df_print_step "Changes to be reverted:"
    sudo snapper -c root status "$pre_num..$post_num" 2>/dev/null | head -20
    echo ""
    
    read -q "REPLY?Proceed with rollback? [y/N] "
    echo ""
    
    if [[ "$REPLY" == "y" ]]; then
        df_print_step "Rolling back..."
        sudo snapper -c root undochange "$pre_num..$post_num"
        
        if [[ $? -eq 0 ]]; then
            df_print_success "Rollback complete"
            df_print_warning "Reboot recommended to apply changes"
        else
            df_print_error "Rollback failed"
            return 1
        fi
    else
        df_print_info "Rollback cancelled"
    fi
}

# ============================================================================
# Aliases
# ============================================================================

alias snap='snap-create'
alias snapls='snap-list'
alias snaprm='snap-delete'
alias snapcheck='snap-check'
alias snapsync='snap-sync'
alias rollback='sys-rollback'
