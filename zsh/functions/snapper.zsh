# ============================================================================
# Snapper Snapshot Functions for CachyOS/Arch with limine-snapper-sync
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

# ============================================================================
# Core Snapshot Functions
# ============================================================================

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
    local before=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine" 2>/dev/null || echo "0")
    df_print_success "Before: $before entries"
    
    df_print_step "Creating snapshot: \"$desc\""
    local num=$(sudo snapper -c root create --description "$desc" --print-number)
    [[ -z "$num" ]] && { df_print_error "Failed"; return 1; }
    df_print_success "Created: #$num"
    
    df_print_step "Triggering limine-snapper-sync..."
    sudo systemctl start limine-snapper-sync.service && df_print_success "Triggered" || df_print_warning "May run automatically"
    sleep 2
    
    df_print_step "Validating"
    local after=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine" 2>/dev/null || echo "0")
    
    if sudo grep -qP "^\\s*///$num\\s*│" "$limine" 2>/dev/null; then
        df_print_success "Snapshot #$num in limine.conf"
        (( after > before )) && df_print_success "Added $((after - before)) entry"
    else
        df_print_warning "Snapshot #$num not yet in limine.conf (may sync later)"
    fi
    
    echo ""
    df_print_section "Summary"
    df_print_indent "Number: #$num"
    df_print_indent "Description: $desc"
    
    # Return the snapshot number for use by other functions
    echo "$num"
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
    sudo grep -qP "^\\s*///$1\\s*│" /boot/limine.conf 2>/dev/null && \
        sudo grep -P "^\\s*///$1\\s*│" /boot/limine.conf || df_print_warning "Not found"
}

snap-delete() {
    [[ -z "$1" ]] && { echo "Usage: snap-delete <num>"; return 1; }
    df_print_func_name "Delete Snapshot #$1"
    
    local before=$(sudo grep -cP "^\\s*///\\d+\\s*│" /boot/limine.conf 2>/dev/null || echo "0")
    sudo snapper -c root delete "$1" && df_print_success "Deleted #$1" || { df_print_error "Failed"; return 1; }
    
    df_print_step "Syncing limine..."
    sudo systemctl start limine-snapper-sync.service; sleep 2
    
    sudo grep -qP "^\\s*///$1\\s*│" /boot/limine.conf 2>/dev/null && df_print_error "Still in limine!" || df_print_success "Removed from limine"
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
    sudo grep -qP "^\\s*///$latest\\s*│" /boot/limine.conf 2>/dev/null && \
        df_print_success "Latest in limine.conf" || df_print_error "Latest NOT in limine.conf"
    local count=$(sudo grep -cP "^\\s*///\\d+\\s*│" /boot/limine.conf 2>/dev/null || echo "0")
    df_print_info "Total entries: $count"
}

# ============================================================================
# System Update with PRE/POST Snapshots
# ============================================================================

sys-update() {
    local update_date=$(date +"%Y-%m-%d %H:%M")
    local limine="/boot/limine.conf"
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
    # Sync with Limine
    # -------------------------------------------------------------------------
    echo ""
    df_print_step "Syncing with limine bootloader..."
    
    if [[ -f "$limine" ]]; then
        sudo systemctl start limine-snapper-sync.service 2>/dev/null
        sleep 2
        
        if [[ -n "$post_num" ]] && sudo grep -qP "^\\s*///$post_num\\s*│" "$limine" 2>/dev/null; then
            df_print_success "Snapshot #$post_num added to boot menu"
        else
            df_print_info "Limine sync triggered (may take a moment)"
        fi
    else
        df_print_info "Limine not detected, skipping boot menu sync"
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
