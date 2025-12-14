# ============================================================================
# Snapper Snapshot Functions for CachyOS/Arch with limine-snapper-sync
# ============================================================================
# Add these functions to your ~/.zshrc or ~/.dotfiles/zsh/.zshrc

# Colors for output
SNAP_GREEN='\033[0;32m'
SNAP_YELLOW='\033[1;33m'
SNAP_RED='\033[0;31m'
SNAP_BLUE='\033[0;34m'
SNAP_NC='\033[0m' # No Color

# ============================================================================
# Main Snapshot Function with Limine Validation
# ============================================================================

snap-create() {
    local description="$*"
    local snap_config="root"
    local limine_conf="/boot/limine.conf"
    
    # Print header
    echo -e "\n${SNAP_BLUE}╔════════════════════════════════════════════════════════════╗${SNAP_NC}"
    echo -e "${SNAP_BLUE}║${SNAP_NC}  Snapper Snapshot Creation & Validation                  ${SNAP_BLUE}║${SNAP_NC}"
    echo -e "${SNAP_BLUE}╚════════════════════════════════════════════════════════════╝${SNAP_NC}\n"
    
    # Check if description was provided
    if [[ -z "$description" ]]; then
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} No description provided"
        echo -n "Enter snapshot description: "
        read description
        
        if [[ -z "$description" ]]; then
            echo -e "${SNAP_RED}✗${SNAP_NC} Description required. Aborting."
            return 1
        fi
    fi
    
    # Check if limine.conf exists
    if [[ ! -f "$limine_conf" ]]; then
        echo -e "${SNAP_RED}✗${SNAP_NC} Limine config not found: $limine_conf"
        return 1
    fi
    
    # Get limine.conf state before snapshot
    echo -e "${SNAP_BLUE}==>${SNAP_NC} Checking limine.conf state before snapshot"
    local before_checksum=$(sudo md5sum "$limine_conf" | awk '{print $1}')
    local before_entries=$(sudo grep -c "^:.*Snapshot" "$limine_conf" || echo "0")
    
    echo -e "${SNAP_GREEN}✓${SNAP_NC} Before: $before_entries snapshot entries"
    echo -e "${SNAP_GREEN}✓${SNAP_NC} Before checksum: $before_checksum"
    
    # Create the snapshot
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Creating snapshot: \"$description\""
    
    local snapshot_num=$(sudo snapper -c "$snap_config" create \
        --description "$description" \
        --print-number)
    
    if [[ -z "$snapshot_num" ]]; then
        echo -e "${SNAP_RED}✗${SNAP_NC} Failed to create snapshot"
        return 1
    fi
    
    echo -e "${SNAP_GREEN}✓${SNAP_NC} Snapshot created: #$snapshot_num"
    
    # Trigger limine-snapper-sync service
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Triggering limine-snapper-sync service..."
    
    if sudo systemctl start limine-snapper-sync.service; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Service triggered successfully"
    else
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} Failed to trigger service (may run automatically)"
    fi
    
    # Wait a moment for the service to complete
    echo -e "${SNAP_BLUE}==>${SNAP_NC} Waiting for limine-snapper-sync to update limine.conf..."
    sleep 2
    
    # Get limine.conf state after snapshot
    echo -e "${SNAP_BLUE}==>${SNAP_NC} Validating limine.conf update"
    local after_checksum=$(sudo md5sum "$limine_conf" | awk '{print $1}')
    local after_entries=$(sudo grep -c "^:.*Snapshot" "$limine_conf" || echo "0")
    
    # Validate the update
    local validation_passed=true
    
    if [[ "$before_checksum" == "$after_checksum" ]]; then
        echo -e "${SNAP_RED}✗${SNAP_NC} limine.conf was NOT updated (checksum unchanged)"
        validation_passed=false
    else
        echo -e "${SNAP_GREEN}✓${SNAP_NC} limine.conf was updated"
    fi
    
    if [[ "$after_entries" -le "$before_entries" ]]; then
        echo -e "${SNAP_RED}✗${SNAP_NC} No new snapshot entry added to limine.conf"
        validation_passed=false
    else
        local new_entries=$((after_entries - before_entries))
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Added $new_entries new snapshot entry/entries"
    fi
    
    # Check for the specific snapshot in limine.conf
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Searching for snapshot #$snapshot_num in limine.conf"
    
    if sudo grep -q "Snapshot $snapshot_num" "$limine_conf"; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Found snapshot #$snapshot_num in limine.conf"
        
        # Show the entry
        echo -e "\n${SNAP_BLUE}Snapshot entry:${SNAP_NC}"
        sudo grep -A 3 "Snapshot $snapshot_num" "$limine_conf" | sed 's/^/  /'
    else
        echo -e "${SNAP_RED}✗${SNAP_NC} Snapshot #$snapshot_num NOT found in limine.conf"
        validation_passed=false
    fi
    
    # Print summary
    echo -e "\n${SNAP_BLUE}╔════════════════════════════════════════════════════════════╗${SNAP_NC}"
    echo -e "${SNAP_BLUE}║${SNAP_NC}  Summary                                                   ${SNAP_BLUE}║${SNAP_NC}"
    echo -e "${SNAP_BLUE}╚════════════════════════════════════════════════════════════╝${SNAP_NC}"
    echo -e "Snapshot Number:       #$snapshot_num"
    echo -e "Description:           \"$description\""
    echo -e "Config:                $snap_config"
    echo -e "Before entries:        $before_entries"
    echo -e "After entries:         $after_entries"
    
    if [[ "$validation_passed" == true ]]; then
        echo -e "Status:                ${SNAP_GREEN}✓ VALIDATED${SNAP_NC}"
        echo -e "\n${SNAP_GREEN}✓${SNAP_NC} Snapshot created and limine.conf successfully updated!"
        return 0
    else
        echo -e "Status:                ${SNAP_RED}✗ VALIDATION FAILED${SNAP_NC}"
        echo -e "\n${SNAP_RED}✗${SNAP_NC} Snapshot created but limine.conf validation failed!"
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} Check if limine-snapper-sync service is running properly"
        echo -e "${SNAP_YELLOW}Run:${SNAP_NC} sudo systemctl status limine-snapper-sync.service"
        return 1
    fi
}

# ============================================================================
# Helper Functions
# ============================================================================

# List recent snapshots
snap-list() {
    local count="${1:-10}"
    echo -e "${SNAP_BLUE}Recent $count snapshots:${SNAP_NC}\n"
    sudo snapper -c root list | tail -n "$((count + 1))"
}

# Show snapshot details
snap-show() {
    if [[ -z "$1" ]]; then
        echo -e "${SNAP_RED}✗${SNAP_NC} Usage: snap-show <snapshot_number>"
        return 1
    fi
    
    echo -e "${SNAP_BLUE}Snapshot #$1 details:${SNAP_NC}\n"
    sudo snapper -c root list | grep "^\s*$1\s"
    
    echo -e "\n${SNAP_BLUE}In limine.conf:${SNAP_NC}"
    if sudo grep -q "Snapshot $1" /boot/limine.conf; then
        sudo grep -A 3 "Snapshot $1" /boot/limine.conf
    else
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} Not found in limine.conf"
    fi
}

# Delete snapshot with limine validation
snap-delete() {
    if [[ -z "$1" ]]; then
        echo -e "${SNAP_RED}✗${SNAP_NC} Usage: snap-delete <snapshot_number>"
        return 1
    fi
    
    local snapshot_num="$1"
    local limine_conf="/boot/limine.conf"
    
    echo -e "${SNAP_BLUE}==>${SNAP_NC} Deleting snapshot #$snapshot_num"
    
    # Check before deletion
    local before_entries=$(sudo grep -c "^:.*Snapshot" "$limine_conf" || echo "0")
    
    # Delete the snapshot
    sudo snapper -c root delete "$snapshot_num"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Snapshot #$snapshot_num deleted"
        
        # Trigger sync service
        echo -e "${SNAP_BLUE}==>${SNAP_NC} Triggering limine-snapper-sync..."
        sudo systemctl start limine-snapper-sync.service
        
        # Wait for service to complete
        sleep 2
        
        # Check after deletion
        local after_entries=$(sudo grep -c "^:.*Snapshot" "$limine_conf" || echo "0")
        
        if [[ "$after_entries" -lt "$before_entries" ]]; then
            echo -e "${SNAP_GREEN}✓${SNAP_NC} limine.conf updated (removed entry)"
        else
            echo -e "${SNAP_YELLOW}⚠${SNAP_NC} limine.conf may not have been updated"
        fi
        
        # Verify snapshot is gone from limine.conf
        if ! sudo grep -q "Snapshot $snapshot_num" "$limine_conf"; then
            echo -e "${SNAP_GREEN}✓${SNAP_NC} Snapshot #$snapshot_num removed from limine.conf"
        else
            echo -e "${SNAP_RED}✗${SNAP_NC} Snapshot #$snapshot_num still in limine.conf!"
        fi
    else
        echo -e "${SNAP_RED}✗${SNAP_NC} Failed to delete snapshot #$snapshot_num"
        return 1
    fi
}

# Check limine.conf for all snapshots
snap-check-limine() {
    local limine_conf="/boot/limine.conf"
    
    echo -e "${SNAP_BLUE}╔════════════════════════════════════════════════════════════╗${SNAP_NC}"
    echo -e "${SNAP_BLUE}║${SNAP_NC}  Limine Snapshot Entries                                  ${SNAP_BLUE}║${SNAP_NC}"
    echo -e "${SNAP_BLUE}╚════════════════════════════════════════════════════════════╝${SNAP_NC}\n"
    
    if [[ ! -f "$limine_conf" ]]; then
        echo -e "${SNAP_RED}✗${SNAP_NC} Limine config not found: $limine_conf"
        return 1
    fi
    
    # Count snapshot entries
    local entry_count=$(sudo grep -c "^:.*Snapshot" "$limine_conf" || echo "0")
    echo -e "${SNAP_BLUE}Total snapshot entries:${SNAP_NC} $entry_count\n"
    
    # Show all snapshot entries
    if [[ "$entry_count" -gt 0 ]]; then
        echo -e "${SNAP_BLUE}Snapshot boot entries:${SNAP_NC}\n"
        sudo grep "^:.*Snapshot" "$limine_conf" | nl -w2 -s'. '
    else
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} No snapshot entries found in limine.conf"
    fi
    
    # Compare with actual snapshots
    echo -e "\n${SNAP_BLUE}Comparing with snapper list:${SNAP_NC}\n"
    
    local snapper_count=$(sudo snapper -c root list | grep -v "single" | tail -n +3 | wc -l)
    echo -e "Snapshots in snapper:     $snapper_count"
    echo -e "Entries in limine.conf:   $entry_count"
    
    if [[ "$snapper_count" -eq "$entry_count" ]]; then
        echo -e "Status:                   ${SNAP_GREEN}✓ SYNCED${SNAP_NC}"
    else
        echo -e "Status:                   ${SNAP_YELLOW}⚠ OUT OF SYNC${SNAP_NC}"
        echo -e "\n${SNAP_YELLOW}Note:${SNAP_NC} Some snapshots may be excluded from boot menu by configuration"
    fi
}

# Manually trigger sync service
snap-sync() {
    echo -e "${SNAP_BLUE}==>${SNAP_NC} Manually triggering limine-snapper-sync..."
    
    if sudo systemctl start limine-snapper-sync.service; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Service triggered successfully"
        
        # Wait for completion
        sleep 2
        
        # Show status
        echo -e "\n${SNAP_BLUE}Service status:${SNAP_NC}"
        sudo systemctl status limine-snapper-sync.service --no-pager -l | tail -n 10
    else
        echo -e "${SNAP_RED}✗${SNAP_NC} Failed to trigger service"
        return 1
    fi
}

# Validate limine-snapper-sync service is working
snap-validate-service() {
    echo -e "${SNAP_BLUE}╔════════════════════════════════════════════════════════════╗${SNAP_NC}"
    echo -e "${SNAP_BLUE}║${SNAP_NC}  Limine-Snapper-Sync Service Validation                  ${SNAP_BLUE}║${SNAP_NC}"
    echo -e "${SNAP_BLUE}╚════════════════════════════════════════════════════════════╝${SNAP_NC}\n"
    
    # Check if service unit exists
    echo -e "${SNAP_BLUE}==>${SNAP_NC} Checking service unit"
    
    if systemctl list-unit-files | grep -q "limine-snapper-sync.service"; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} limine-snapper-sync.service unit exists"
    else
        echo -e "${SNAP_RED}✗${SNAP_NC} limine-snapper-sync.service unit NOT found"
        echo -e "\n${SNAP_YELLOW}Install with:${SNAP_NC} paru -S limine-snapper-sync"
        return 1
    fi
    
    # Check if service is enabled
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Checking if service is enabled"
    
    if systemctl is-enabled limine-snapper-sync.service &>/dev/null; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Service is enabled"
    else
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} Service is NOT enabled"
        echo -e "${SNAP_YELLOW}Enable with:${SNAP_NC} sudo systemctl enable limine-snapper-sync.service"
    fi
    
    # Check service status
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Checking service status"
    
    if systemctl is-active limine-snapper-sync.service &>/dev/null; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Service is active"
    else
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} Service is inactive (this is normal for oneshot services)"
    fi
    
    # Show recent service logs
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Recent service logs (last 10 lines)"
    echo ""
    sudo journalctl -u limine-snapper-sync.service -n 10 --no-pager | sed 's/^/  /'
    
    # Check snapper config
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Checking snapper configuration"
    
    if [[ -f "/etc/snapper/configs/root" ]]; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Snapper root config exists"
    else
        echo -e "${SNAP_RED}✗${SNAP_NC} Snapper root config not found"
    fi
    
    # Check limine.conf
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Checking limine.conf"
    
    if [[ -f "/boot/limine.conf" ]]; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} limine.conf exists"
        local snap_entries=$(sudo grep -c "^:.*Snapshot" /boot/limine.conf || echo "0")
        echo -e "  Snapshot entries: $snap_entries"
    else
        echo -e "${SNAP_RED}✗${SNAP_NC} limine.conf not found"
    fi
    
    echo -e "\n${SNAP_GREEN}✓${SNAP_NC} Validation complete"
}

# Quick snapshot aliases
alias snap='snap-create'
alias snapls='snap-list'
alias snaprm='snap-delete'
alias snapshow='snap-show'
alias snapcheck='snap-check-limine'
alias snapsync='snap-sync'

# ============================================================================
# Usage Examples (commented out - uncomment to see examples)
# ============================================================================

# snap-create "Before system update"
# snap-list 20
# snap-show 42
# snap-delete 42
# snap-check-limine
# snap-sync
# snap-validate-serviceNC}"
