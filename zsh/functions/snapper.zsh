# ============================================================================
# Snapper Snapshot Functions for CachyOS/Arch with limine-snapper-sync
# ============================================================================

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    typeset -g DF_RED=$'\033[0;31m' DF_BLUE=$'\033[0;34m' DF_NC=$'\033[0m'
}

# ============================================================================
# Main Snapshot Function with Limine Validation
# ============================================================================

snap-create() {
    local description="$*"
    local snap_config="root"
    local limine_conf="/boot/limine.conf"
    
    df_print_func_name "Snapper Snapshot Creation"
    
    if [[ -z "$description" ]]; then
        echo -e "${DF_YELLOW}⚠${DF_NC} No description provided"
        echo -n "Enter snapshot description: "
        read description
        [[ -z "$description" ]] && { echo -e "${DF_RED}✗${DF_NC} Description required. Aborting."; return 1; }
    fi
    
    [[ ! -f "$limine_conf" ]] && { echo -e "${DF_RED}✗${DF_NC} Limine config not found: $limine_conf"; return 1; }
    
    echo -e "${DF_BLUE}==>${DF_NC} Checking limine.conf state before snapshot"
    local before_checksum=$(sudo md5sum "$limine_conf" | awk '{print $1}')
    local before_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
    
    echo -e "${DF_GREEN}✓${DF_NC} Before: $before_entries snapshot entries"
    echo -e "${DF_GREEN}✓${DF_NC} Before checksum: $before_checksum"
    
    echo -e "\n${DF_BLUE}==>${DF_NC} Creating snapshot: \"$description\""
    
    local snapshot_num=$(sudo snapper -c "$snap_config" create --description "$description" --print-number)
    
    [[ -z "$snapshot_num" ]] && { echo -e "${DF_RED}✗${DF_NC} Failed to create snapshot"; return 1; }
    
    echo -e "${DF_GREEN}✓${DF_NC} Snapshot created: #$snapshot_num"
    
    echo -e "\n${DF_BLUE}==>${DF_NC} Triggering limine-snapper-sync service..."
    
    if sudo systemctl start limine-snapper-sync.service; then
        echo -e "${DF_GREEN}✓${DF_NC} Service triggered successfully"
    else
        echo -e "${DF_YELLOW}⚠${DF_NC} Failed to trigger service (may run automatically)"
    fi
    
    echo -e "${DF_BLUE}==>${DF_NC} Waiting for limine-snapper-sync to update limine.conf..."
    sleep 2
    
    echo -e "${DF_BLUE}==>${DF_NC} Validating limine.conf update"
    local after_checksum=$(sudo md5sum "$limine_conf" | awk '{print $1}')
    local after_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
    
    local validation_passed=true
    
    if [[ "$before_checksum" == "$after_checksum" ]]; then
        echo -e "${DF_RED}✗${DF_NC} limine.conf was NOT updated (checksum unchanged)"
        validation_passed=false
    else
        echo -e "${DF_GREEN}✓${DF_NC} limine.conf was updated"
    fi
    
    if [[ "$after_entries" -le "$before_entries" ]]; then
        echo -e "${DF_RED}✗${DF_NC} No new snapshot entry added to limine.conf"
        validation_passed=false
    else
        local new_entries=$((after_entries - before_entries))
        echo -e "${DF_GREEN}✓${DF_NC} Added $new_entries new snapshot entry/entries"
    fi
    
    echo -e "\n${DF_BLUE}==>${DF_NC} Searching for snapshot #$snapshot_num in limine.conf"
    
    if sudo grep -qP "^\\s*///$snapshot_num\\s*│" "$limine_conf"; then
        echo -e "${DF_GREEN}✓${DF_NC} Found snapshot #$snapshot_num in limine.conf"
        echo -e "\n${DF_BLUE}Snapshot entry:${DF_NC}"
        local entry_line=$(sudo grep -nP "^\\s*///$snapshot_num\\s*│" "$limine_conf" | head -n 1 | cut -d: -f1)
        [[ -n "$entry_line" ]] && sudo sed -n "${entry_line}p; $((entry_line+1))p" "$limine_conf" | sed 's/^/  /'
    else
        echo -e "${DF_RED}✗${DF_NC} Snapshot #$snapshot_num NOT found in limine.conf"
        validation_passed=false
    fi
    
    echo ""
    echo -e "${DF_CYAN}Summary:${DF_NC}"
    echo -e "  Snapshot Number:  #$snapshot_num"
    echo -e "  Description:      \"$description\""
    echo -e "  Config:           $snap_config"
    echo -e "  Before entries:   $before_entries"
    echo -e "  After entries:    $after_entries"
    
    if [[ "$validation_passed" == true ]]; then
        echo -e "  Status:           ${DF_GREEN}✓ VALIDATED${DF_NC}"
        echo -e "\n${DF_GREEN}✓${DF_NC} Snapshot created and limine.conf successfully updated!"
        return 0
    else
        echo -e "  Status:           ${DF_RED}✗ VALIDATION FAILED${DF_NC}"
        echo -e "\n${DF_RED}✗${DF_NC} Snapshot created but limine.conf validation failed!"
        echo -e "${DF_YELLOW}⚠${DF_NC} Check if limine-snapper-sync service is running properly"
        echo -e "${DF_YELLOW}Run:${DF_NC} sudo systemctl status limine-snapper-sync.service"
        return 1
    fi
}

# ============================================================================
# Helper Functions
# ============================================================================

snap-list() {
    local count="${1:-10}"
    
    df_print_func_name "Snapper Snapshots (last $count)"
    
    sudo snapper -c root list | tail -n "$((count + 1))"
}

snap-show() {
    [[ -z "$1" ]] && { echo -e "${DF_RED}✗${DF_NC} Usage: snap-show <snapshot_number>"; return 1; }
    
    df_print_func_name "Snapshot #$1 Details"
    
    sudo snapper -c root list | grep "^\s*$1\s"
    
    echo -e "\n${DF_CYAN}In limine.conf:${DF_NC}"
    if sudo grep -qP "^\\s*///$1\\s*│" /boot/limine.conf; then
        local entry_line=$(sudo grep -nP "^\\s*///$1\\s*│" /boot/limine.conf | head -n 1 | cut -d: -f1)
        [[ -n "$entry_line" ]] && sudo sed -n "${entry_line}p; $((entry_line+1))p" /boot/limine.conf
    else
        echo -e "${DF_YELLOW}⚠${DF_NC} Not found in limine.conf"
    fi
}

snap-delete() {
    [[ -z "$1" ]] && { echo -e "${DF_RED}✗${DF_NC} Usage: snap-delete <snapshot_number>"; return 1; }
    
    local snapshot_num="$1"
    local limine_conf="/boot/limine.conf"
    
    df_print_func_name "Delete Snapshot #$snapshot_num"
    
    local before_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
    
    sudo snapper -c root delete "$snapshot_num"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${DF_GREEN}✓${DF_NC} Snapshot #$snapshot_num deleted"
        
        echo -e "${DF_BLUE}==>${DF_NC} Triggering limine-snapper-sync..."
        sudo systemctl start limine-snapper-sync.service
        sleep 2
        
        local after_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
        
        if [[ "$after_entries" -lt "$before_entries" ]]; then
            echo -e "${DF_GREEN}✓${DF_NC} limine.conf updated (removed entry)"
        else
            echo -e "${DF_YELLOW}⚠${DF_NC} limine.conf may not have been updated"
        fi
        
        if ! sudo grep -qP "^\\s*///$snapshot_num\\s*│" "$limine_conf"; then
            echo -e "${DF_GREEN}✓${DF_NC} Snapshot #$snapshot_num removed from limine.conf"
        else
            echo -e "${DF_RED}✗${DF_NC} Snapshot #$snapshot_num still in limine.conf!"
        fi
    else
        echo -e "${DF_RED}✗${DF_NC} Failed to delete snapshot #$snapshot_num"
        return 1
    fi
}

snap-check-limine() {
    local limine_conf="/boot/limine.conf"
    
    df_print_func_name "Limine Snapshot Entries"
    
    [[ ! -f "$limine_conf" ]] && { echo -e "${DF_RED}✗${DF_NC} Limine config not found: $limine_conf"; return 1; }
    
    local latest_snapshot=$(sudo snapper -c root list | tail -n +3 | grep -v "^\s*0\s" | tail -n 1 | awk '{print $1}')
    [[ -z "$latest_snapshot" ]] && { echo -e "${DF_YELLOW}⚠${DF_NC} No snapshots found in snapper"; return 1; }
    
    echo -e "${DF_CYAN}Latest snapshot:${DF_NC} #$latest_snapshot"
    
    echo -e "${DF_BLUE}==>${DF_NC} Checking if latest snapshot is in limine.conf"
    
    if sudo grep -qP "^\\s*///$latest_snapshot\s*│" "$limine_conf"; then
        echo -e "${DF_GREEN}✓${DF_NC} Latest snapshot #$latest_snapshot is present in limine.conf"
    else
        echo -e "${DF_RED}✗${DF_NC} Latest snapshot #$latest_snapshot is NOT in limine.conf"
    fi
    
    echo -e "\n${DF_BLUE}==>${DF_NC} Counting snapshot entries"
    local entry_count=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
    echo -e "${DF_CYAN}Total snapshot entries:${DF_NC} $entry_count"
}

snap-sync() {
    df_print_func_name "Limine-Snapper-Sync"
    
    echo -e "${DF_BLUE}==>${DF_NC} Manually triggering limine-snapper-sync..."
    
    if sudo systemctl start limine-snapper-sync.service; then
        echo -e "${DF_GREEN}✓${DF_NC} Service triggered successfully"
        sleep 2
        echo -e "\n${DF_CYAN}Service status:${DF_NC}"
        sudo systemctl status limine-snapper-sync.service --no-pager -l | tail -n 10
    else
        echo -e "${DF_RED}✗${DF_NC} Failed to trigger service"
        return 1
    fi
}

snap-validate-service() {
    df_print_func_name "Limine-Snapper-Sync Service Validation"
    
    echo -e "${DF_BLUE}==>${DF_NC} Checking service unit"
    
    if systemctl list-unit-files | grep -q "limine-snapper-sync.service"; then
        echo -e "${DF_GREEN}✓${DF_NC} limine-snapper-sync.service unit exists"
    else
        echo -e "${DF_RED}✗${DF_NC} limine-snapper-sync.service unit NOT found"
        echo -e "\n${DF_YELLOW}Install with:${DF_NC} paru -S limine-snapper-sync"
        return 1
    fi
    
    echo -e "\n${DF_BLUE}==>${DF_NC} Checking if service is enabled"
    
    if systemctl is-enabled limine-snapper-sync.service &>/dev/null; then
        echo -e "${DF_GREEN}✓${DF_NC} Service is enabled"
    else
        echo -e "${DF_YELLOW}⚠${DF_NC} Service is NOT enabled"
        echo -e "${DF_YELLOW}Enable with:${DF_NC} sudo systemctl enable limine-snapper-sync.service"
    fi
    
    echo -e "\n${DF_BLUE}==>${DF_NC} Recent service logs (last 10 lines)"
    echo ""
    sudo journalctl -u limine-snapper-sync.service -n 10 --no-pager | sed 's/^/  /'
    
    echo -e "\n${DF_GREEN}✓${DF_NC} Validation complete"
}

# Quick snapshot aliases
alias snap='snap-create'
alias snapls='snap-list'
alias snaprm='snap-delete'
alias snapshow='snap-show'
alias snapcheck='snap-check-limine'
alias snapsync='snap-sync'
