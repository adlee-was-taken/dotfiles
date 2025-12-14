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
    local before_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
    
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
    local after_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
    
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
    
    # Format in limine.conf is: ///[number] │ [date]
    if sudo grep -qP "^\\s*///$snapshot_num\\s*│" "$limine_conf"; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Found snapshot #$snapshot_num in limine.conf"
        
        # Show the entry with description
        echo -e "\n${SNAP_BLUE}Snapshot entry:${SNAP_NC}"
        local entry_line=$(sudo grep -nP "^\\s*///$snapshot_num\\s*│" "$limine_conf" | head -n 1 | cut -d: -f1)
        if [[ -n "$entry_line" ]]; then
            # Show the snapshot header and description
            sudo sed -n "${entry_line}p; $((entry_line+1))p" "$limine_conf" | sed 's/^/  /'
        fi
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
    if sudo grep -qP "^\\s*///$1\\s*│" /boot/limine.conf; then
        local entry_line=$(sudo grep -nP "^\\s*///$1\\s*│" /boot/limine.conf | head -n 1 | cut -d: -f1)
        if [[ -n "$entry_line" ]]; then
            sudo sed -n "${entry_line}p; $((entry_line+1))p" /boot/limine.conf
        fi
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
    
    # Check before deletion (count snapshot entries using correct format)
    local before_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
    
    # Delete the snapshot
    sudo snapper -c root delete "$snapshot_num"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Snapshot #$snapshot_num deleted"
        
        # Trigger sync service
        echo -e "${SNAP_BLUE}==>${SNAP_NC} Triggering limine-snapper-sync..."
        sudo systemctl start limine-snapper-sync.service
        
        # Wait for service to complete
        sleep 2
        
        # Check after deletion (use correct format)
        local after_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
        
        if [[ "$after_entries" -lt "$before_entries" ]]; then
            echo -e "${SNAP_GREEN}✓${SNAP_NC} limine.conf updated (removed entry)"
        else
            echo -e "${SNAP_YELLOW}⚠${SNAP_NC} limine.conf may not have been updated"
        fi
        
        # Verify snapshot is gone from limine.conf (use correct format)
        if ! sudo grep -qP "^\\s*///$snapshot_num\\s*│" "$limine_conf"; then
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
    echo -e "${SNAP_BLUE}║${SNAP_NC}  Limine Snapshot Entries                                   ${SNAP_BLUE}║${SNAP_NC}"
    echo -e "${SNAP_BLUE}╚════════════════════════════════════════════════════════════╝${SNAP_NC}\n"
    
    if [[ ! -f "$limine_conf" ]]; then
        echo -e "${SNAP_RED}✗${SNAP_NC} Limine config not found: $limine_conf"
        return 1
    fi
    
    # Get latest snapshot number (excluding snapshot 0)
    local latest_snapshot=$(sudo snapper -c root list | tail -n +3 | grep -v "^\s*0\s" | tail -n 1 | awk '{print $1}')
    
    if [[ -z "$latest_snapshot" ]]; then
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} No snapshots found in snapper"
        return 1
    fi
    
    echo -e "${SNAP_BLUE}Latest snapshot:${SNAP_NC} #$latest_snapshot"
    
    # Check if latest snapshot is in limine.conf
    # Format in limine.conf is: ///49 │ 2025-12-14 01:15:33
    echo -e "${SNAP_BLUE}==>${SNAP_NC} Checking if latest snapshot is in limine.conf"
    
    if sudo grep -qP "^\\s*///$latest_snapshot\s*│" "$limine_conf"; then
        echo -e "${SNAP_GREEN}✓${SNAP_NC} Latest snapshot #$latest_snapshot is present in limine.conf"
        
        # Show the entry with description
        echo -e "\n${SNAP_BLUE}Latest snapshot entry:${SNAP_NC}"
        local entry_line=$(sudo grep -nP "^\\s*///$latest_snapshot\s*│" "$limine_conf" | head -n 1 | cut -d: -f1)
        if [[ -n "$entry_line" ]]; then
            # Show the snapshot header and description (next line)
            sudo sed -n "${entry_line}p; $((entry_line+1))p" "$limine_conf" | sed 's/^/  /'
        fi
    else
        echo -e "${SNAP_RED}✗${SNAP_NC} Latest snapshot #$latest_snapshot is NOT in limine.conf"
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} This may indicate the sync service hasn't run yet"
    fi
    
    # Count snapshot entries (lines matching ///[number] │)
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Counting snapshot entries"
    local entry_count=$(sudo grep -cP "^\\s*///\\d+\\s*│" "$limine_conf" || echo "0")
    echo -e "${SNAP_BLUE}Total snapshot entries:${SNAP_NC} $entry_count\n"
    
    # Show all snapshot entries
    if [[ "$entry_count" -gt 0 ]]; then
        echo -e "${SNAP_BLUE}Snapshot boot entries:${SNAP_NC}\n"
        
        # Extract snapshot entries with their descriptions
        local snap_nums=($(sudo grep -oP "^\\s*///\\K\\d+(?=\\s*│)" "$limine_conf" | sort -n))
        
        local i=1
        for snap_num in "${snap_nums[@]}"; do
            local snap_line=$(sudo grep -nP "^\\s*///$snap_num\s*│" "$limine_conf" | head -n 1)
            local line_num=$(echo "$snap_line" | cut -d: -f1)
            local date_time=$(echo "$snap_line" | cut -d: -f2- | grep -oP "│\\s*\\K.*" || echo "")
            
            # Get description from next line (starts with "comment:")
            local desc=""
            if [[ -n "$line_num" ]]; then
                desc=$(sudo sed -n "$((line_num+1))p" "$limine_conf" | grep -oP "comment:\\s*\\K.*" || echo "")
            fi
            
            printf "%2d. Snapshot #%-3s  %s  %s\n" "$i" "$snap_num" "$date_time" "${desc:-(no description)}"
            ((i++))
        done
        
        # Show snapshot range
        if [[ ${#snap_nums[@]} -gt 0 ]]; then
            echo -e "\n${SNAP_BLUE}Snapshot range in boot menu:${SNAP_NC}"
            echo -e "  Oldest:  #${snap_nums[1]}"
            echo -e "  Newest:  #${snap_nums[-1]}"
        fi
    else
        echo -e "${SNAP_YELLOW}⚠${SNAP_NC} No snapshot entries found in limine.conf"
    fi
    
    # Compare with actual snapshots
    echo -e "\n${SNAP_BLUE}==>${SNAP_NC} Comparing with snapper list"
    echo ""
    
    # Count all snapshots except snapshot 0 (current system)
    local snapper_count=$(sudo snapper -c root list | tail -n +3 | grep -v "^\s*0\s" | wc -l)
    
    # Get oldest and newest snapshots
    local oldest_snapshot=$(sudo snapper -c root list | tail -n +3 | grep -v "^\s*0\s" | head -n 1 | awk '{print $1}')
    
    echo -e "Snapshots in snapper:     $snapper_count (range: #$oldest_snapshot to #$latest_snapshot)"
    echo -e "Entries in limine.conf:   $entry_count"
    
    if [[ "$snapper_count" -eq "$entry_count" ]]; then
        echo -e "Status:                   ${SNAP_GREEN}✓ FULLY SYNCED${SNAP_NC}"
    else
        local diff=$((snapper_count - entry_count))
        echo -e "Status:                   ${SNAP_YELLOW}⚠ PARTIALLY SYNCED${SNAP_NC}"
        echo -e "Missing from boot menu:   $diff snapshot(s)"
        
        # Check if latest is present (most important)
        if sudo grep -qP "^\\s*///$latest_snapshot\s*│" "$limine_conf"; then
            echo -e "\n${SNAP_GREEN}✓${SNAP_NC} Latest snapshot IS available for boot (this is what matters most)"
        else
            echo -e "\n${SNAP_RED}✗${SNAP_NC} Latest snapshot NOT available for boot (run: snap-sync)"
        fi
        
        echo -e "\n${SNAP_BLUE}Note:${SNAP_NC} limine-snapper-sync typically limits boot entries to recent snapshots"
        echo -e "      This is normal and prevents boot menu clutter"
        
        # Check the limit from comment line
        local limit_comment=$(sudo grep -oP "comment:\\s*\\K\\d+\\s*/\\s*\\d+" "$limine_conf" | head -n 1)
        if [[ -n "$limit_comment" ]]; then
            echo -e "      Current limit: $limit_comment snapshots"
        fi
        
        # Show which snapshots are missing if there aren't too many
        if [[ $diff -le 20 ]]; then
            echo -e "\n${SNAP_BLUE}Snapshots NOT in boot menu:${SNAP_NC}"
            
            local all_snapshots=($(sudo snapper -c root list | tail -n +3 | grep -v "^\s*0\s" | awk '{print $1}'))
            local limine_snapshots=($(sudo grep -oP "^\\s*///\\K\\d+(?=\\s*│)" "$limine_conf"))
            local missing_count=0
            
            for snap_num in "${all_snapshots[@]}"; do
                # Check if this snapshot is in limine.conf
                local found=false
                for limine_snap in "${limine_snapshots[@]}"; do
                    if [[ "$snap_num" == "$limine_snap" ]]; then
                        found=true
                        break
                    fi
                done
                
                if [[ "$found" == false ]]; then
                    if [[ $missing_count -lt 10 ]]; then
                        local snap_info=$(sudo snapper -c root list | grep "^\s*$snap_num\s")
                        local snap_type=$(echo "$snap_info" | awk '{print $2}')
                        local snap_desc=$(echo "$snap_info" | awk -F'|' '{print $5}' | xargs)
                        echo -e "  #$snap_num ($snap_type) - $snap_desc"
                    fi
                    ((missing_count++))
                fi
            done
            
            if [[ $missing_count -gt 10 ]]; then
                echo -e "  ... and $((missing_count - 10)) more"
            fi
        fi
    fi
}

# Show detailed snapshot information with types
snap-info() {
    echo -e "${SNAP_BLUE}╔════════════════════════════════════════════════════════════╗${SNAP_NC}"
    echo -e "${SNAP_BLUE}║${SNAP_NC}  Detailed Snapshot Information                            ${SNAP_BLUE}║${SNAP_NC}"
    echo -e "${SNAP_BLUE}╚════════════════════════════════════════════════════════════╝${SNAP_NC}\n"
    
    echo -e "${SNAP_BLUE}All snapshots with types:${SNAP_NC}\n"
    sudo snapper -c root list
    
    echo -e "\n${SNAP_BLUE}Breakdown by type:${SNAP_NC}\n"
    
    local single_count=$(sudo snapper -c root list | grep -c "single" || echo "0")
    local pre_count=$(sudo snapper -c root list | grep -c "pre" || echo "0")
    local post_count=$(sudo snapper -c root list | grep -c "post" || echo "0")
    local total=$(sudo snapper -c root list | tail -n +3 | grep -v "^\s*0\s" | wc -l)
    
    echo -e "Single snapshots:  $single_count"
    echo -e "Pre snapshots:     $pre_count"
    echo -e "Post snapshots:    $post_count"
    echo -e "Total snapshots:   $total"
    
    echo -e "\n${SNAP_BLUE}Snapshot types explained:${SNAP_NC}"
    echo -e "  ${SNAP_GREEN}single${SNAP_NC} - Manual snapshots (created by you)"
    echo -e "  ${SNAP_GREEN}pre${SNAP_NC}    - Before system changes (e.g., package updates)"
    echo -e "  ${SNAP_GREEN}post${SNAP_NC}   - After system changes"
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
        local snap_entries=$(sudo grep -cP "^\\s*///\\d+\\s*│" /boot/limine.conf || echo "0")
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
alias snapinfo='snap-info'

# ============================================================================
# Usage Examples (commented out - uncomment to see examples)
# ============================================================================

# snap-create "Before system update"
# snap-list 20
# snap-show 42
# snap-delete 42
# snap-check-limine
# snap-sync
# snap-validate-service
