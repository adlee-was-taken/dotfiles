# ============================================================================
# Btrfs Helpers for Arch/CachyOS
# ============================================================================
# Quick commands for btrfs filesystem management
# CachyOS defaults to btrfs, so these are highly useful
#
# Commands:
#   btrfs-usage         - Show filesystem usage
#   btrfs-subs          - List subvolumes
#   btrfs-balance       - Start balance operation
#   btrfs-scrub         - Start/check scrub
#   btrfs-defrag        - Defragment file or directory
#   btrfs-compress      - Show compression stats
#   btrfs-info          - Full filesystem info
#   btrfs-health        - Quick health check
# ============================================================================

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    typeset -g DF_RED=$'\033[0;31m' DF_BLUE=$'\033[0;34m'
    typeset -g DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
}

# ============================================================================
# Configuration
# ============================================================================

typeset -g BTRFS_DEFAULT_MOUNT="${BTRFS_DEFAULT_MOUNT:-/}"

# ============================================================================
# Detection
# ============================================================================

_btrfs_check() {
    if ! command -v btrfs &>/dev/null; then
        echo -e "${DF_RED}✗${DF_NC} btrfs-progs not installed"
        echo "Install: sudo pacman -S btrfs-progs"
        return 1
    fi
    
    # Check if root is btrfs
    local fstype=$(df -T / | awk 'NR==2 {print $2}')
    if [[ "$fstype" != "btrfs" ]]; then
        echo -e "${DF_YELLOW}⚠${DF_NC} Root filesystem is not btrfs (detected: $fstype)"
        return 1
    fi
    
    return 0
}

# ============================================================================
# Core Commands
# ============================================================================

# Show filesystem usage
btrfs-usage() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    
    echo -e "${DF_BLUE}Btrfs Filesystem Usage: ${DF_YELLOW}${mount}${DF_NC}"
    echo ""
    
    sudo btrfs filesystem usage "$mount" -h
}

# List all subvolumes
btrfs-subs() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"

    df_print_header "Btrfs Subvolumes" 
    #echo -e "${DF_BLUE}Btrfs Subvolumes"
    echo ""
    
    echo -e "${DF_CYAN}Subvolume List:${DF_NC}"
    sudo btrfs subvolume list "$mount" | while read -r line; do
        local path=$(echo "$line" | awk '{print $NF}')
        local id=$(echo "$line" | awk '{print $2}')
        echo -e "  ${DF_GREEN}●${DF_NC} [$id] $path"
    done
    
    echo ""
    echo -e "${DF_CYAN}Default Subvolume:${DF_NC}"
    sudo btrfs subvolume get-default "$mount"
}

# Start balance operation
btrfs-balance() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    local usage="${2:-50}"  # Default: rebalance chunks with <50% usage
    
    echo -e "${DF_BLUE}==>${DF_NC} Starting btrfs balance on ${mount}"
    echo -e "${DF_YELLOW}⚠${DF_NC} This may take a while and use significant I/O"
    echo ""
    
    read -q "REPLY?Continue? [y/N]: "; echo
    [[ ! "$REPLY" =~ ^[Yy]$ ]] && return 0
    
    echo ""
    echo -e "${DF_BLUE}==>${DF_NC} Balancing data chunks with <${usage}% usage..."
    sudo btrfs balance start -dusage="$usage" -musage="$usage" "$mount" -v
    
    if [[ $? -eq 0 ]]; then
        echo -e "${DF_GREEN}✓${DF_NC} Balance completed"
    else
        echo -e "${DF_YELLOW}⚠${DF_NC} Balance finished (may have been interrupted or had no work)"
    fi
}

# Check balance status
btrfs-balance-status() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    
    sudo btrfs balance status "$mount"
}

# Cancel running balance
btrfs-balance-cancel() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    
    echo -e "${DF_BLUE}==>${DF_NC} Cancelling balance on ${mount}..."
    sudo btrfs balance cancel "$mount"
}

# Start scrub operation
btrfs-scrub() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    df_print_header "Btrfs Scrub"    
    #echo -e "${DF_BLUE}Btrfs Scrub"
    echo ""
    
    # Check if scrub is already running
    local status=$(sudo btrfs scrub status "$mount" 2>/dev/null)
    if echo "$status" | grep -q "running"; then
        echo -e "${DF_CYAN}Scrub Status (running):${DF_NC}"
        echo "$status" | sed 's/^/  /'
        return 0
    fi
    
    echo -e "${DF_YELLOW}⚠${DF_NC} Scrub verifies data integrity and may take hours"
    read -q "REPLY?Start scrub? [y/N]: "; echo
    [[ ! "$REPLY" =~ ^[Yy]$ ]] && return 0
    
    echo ""
    echo -e "${DF_BLUE}==>${DF_NC} Starting scrub..."
    sudo btrfs scrub start "$mount"
    
    echo ""
    echo -e "${DF_CYAN}Scrub Status:${DF_NC}"
    sudo btrfs scrub status "$mount"
    
    echo ""
    echo -e "${DF_CYAN}Monitor with:${DF_NC} btrfs-scrub-status"
}

# Show scrub status
btrfs-scrub-status() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    
    sudo btrfs scrub status "$mount"
}

# Cancel scrub
btrfs-scrub-cancel() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    
    echo -e "${DF_BLUE}==>${DF_NC} Cancelling scrub on ${mount}..."
    sudo btrfs scrub cancel "$mount"
}

# Defragment file or directory
btrfs-defrag() {
    _btrfs_check || return 1
    local target="${1:-.}"
    
    if [[ ! -e "$target" ]]; then
        echo -e "${DF_RED}✗${DF_NC} Target not found: $target"
        return 1
    fi
    
    echo -e "${DF_BLUE}==>${DF_NC} Defragmenting: $target"
    
    if [[ -d "$target" ]]; then
        echo -e "${DF_YELLOW}⚠${DF_NC} Recursive defrag on directory"
        read -q "REPLY?Continue? [y/N]: "; echo
        [[ ! "$REPLY" =~ ^[Yy]$ ]] && return 0
        
        sudo btrfs filesystem defragment -r -v "$target"
    else
        sudo btrfs filesystem defragment -v "$target"
    fi
    
    echo -e "${DF_GREEN}✓${DF_NC} Defragmentation complete"
}

# Show compression stats (requires compsize)
btrfs-compress() {
    _btrfs_check || return 1
    local target="${1:-$BTRFS_DEFAULT_MOUNT}"
    
    if ! command -v compsize &>/dev/null; then
        echo -e "${DF_YELLOW}⚠${DF_NC} compsize not installed"
        echo "Install: sudo pacman -S compsize"
        return 1
    fi
    
    echo -e "${DF_BLUE}Btrfs Compression Statistics${FD_NC}"
    echo ""
    
    sudo compsize "$target"
}

# ============================================================================
# Information Commands
# ============================================================================

# Full filesystem info
btrfs-info() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
    df_print_header "Btrfs Filesystem Info" 
    #echo -e "${DF_BLUE}Btrfs Filesystem Information${DF_NC}"
    
    echo -e "\n${DF_CYAN}Filesystem Show:${DF_NC}"
    sudo btrfs filesystem show "$mount"
    
    echo -e "\n${DF_CYAN}Filesystem df:${DF_NC}"
    sudo btrfs filesystem df "$mount"
    
    echo -e "\n${DF_CYAN}Device Stats:${DF_NC}"
    sudo btrfs device stats "$mount"
    
    echo ""
}

# Quick health check
btrfs-health() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
   
    df_print_header "Btrfs Health Check"
    #echo -e "${DF_BLUE}Btrfs Health Check${DF_NC}"
    echo ""
    
    local issues=0
    
    # Check device stats for errors
    echo -e "${DF_CYAN}Device Errors:${DF_NC}"
    local stats=$(sudo btrfs device stats "$mount" 2>/dev/null)
    local errors=$(echo "$stats" | grep -v " 0$" | grep -v "^$")
    
    if [[ -z "$errors" ]]; then
        echo -e "  ${DF_GREEN}✓${DF_NC} No device errors detected"
    else
        echo -e "  ${DF_RED}✗${DF_NC} Errors detected:"
        echo "$errors" | sed 's/^/    /'
        issues=$((issues + 1))
    fi
    
    # Check allocation
    echo -e "\n${DF_CYAN}Space Allocation:${DF_NC}"
    local usage=$(sudo btrfs filesystem usage "$mount" -b 2>/dev/null)
    local used_pct=$(echo "$usage" | grep "Used:" | head -1 | awk '{print $2}' | tr -d '%')
    
    if [[ -n "$used_pct" ]]; then
        if (( used_pct >= 90 )); then
            echo -e "  ${DF_RED}✗${DF_NC} Filesystem ${used_pct}% full - critical!"
            issues=$((issues + 1))
        elif (( used_pct >= 80 )); then
            echo -e "  ${DF_YELLOW}⚠${DF_NC} Filesystem ${used_pct}% full - consider cleanup"
        else
            echo -e "  ${DF_GREEN}✓${DF_NC} Filesystem ${used_pct}% used"
        fi
    fi
    
    # Check last scrub
    echo -e "\n${DF_CYAN}Last Scrub:${DF_NC}"
    local scrub_status=$(sudo btrfs scrub status "$mount" 2>/dev/null)
    local scrub_date=$(echo "$scrub_status" | grep "Scrub started" | awk '{print $3, $4, $5}')
    local scrub_errors=$(echo "$scrub_status" | grep "Error summary" | grep -v "no errors")
    
    if [[ -n "$scrub_date" ]]; then
        echo -e "  Last scrub: $scrub_date"
        if [[ -n "$scrub_errors" ]]; then
            echo -e "  ${DF_RED}✗${DF_NC} Scrub found errors"
            echo "$scrub_errors" | sed 's/^/    /'
            issues=$((issues + 1))
        else
            echo -e "  ${DF_GREEN}✓${DF_NC} No errors in last scrub"
        fi
    else
        echo -e "  ${DF_YELLOW}⚠${DF_NC} No scrub has been run (recommended monthly)"
    fi
    
    # Summary
    echo ""
    if (( issues == 0 )); then
        echo -e "${DF_GREEN}✓${DF_NC} Btrfs filesystem appears healthy"
    else
        echo -e "${DF_RED}✗${DF_NC} Found $issues issue(s) - investigate above"
    fi
    
    echo ""
}

# ============================================================================
# Snapshot Helpers (complement snapper.zsh)
# ============================================================================

# Show snapshot space usage
btrfs-snap-usage() {
    _btrfs_check || return 1
   
    df_print_header "Snapshot Disc Usage"
    #echo -e "${DF_BLUE}Snapshot Space Usage${DF_NC}"
    echo ""
    
    if [[ -d "/.snapshots" ]]; then
        echo -e "${DF_CYAN}Snapshot Directory:${DF_NC}"
        sudo du -sh /.snapshots 2>/dev/null || echo "  Unable to calculate"
        
        echo -e "\n${DF_CYAN}Individual Snapshots:${DF_NC}"
        sudo du -sh /.snapshots/*/ 2>/dev/null | sort -h | tail -10 | sed 's/^/  /'
    else
        echo -e "${DF_YELLOW}⚠${DF_NC} No /.snapshots directory found"
    fi
    
    echo ""
}

# ============================================================================
# Maintenance
# ============================================================================

# Full maintenance routine
btrfs-maintain() {
    _btrfs_check || return 1
    local mount="${1:-$BTRFS_DEFAULT_MOUNT}"
   
    df_print_header "script-name"
    #echo -e "${DF_BLUE}Btrfs Maintenance Routine${DF_NC}"
    echo ""
    echo "This will perform:"
    echo "  1. Health check"
    echo "  2. Balance (low usage chunks)"
    echo "  3. Scrub (data integrity)"
    echo ""
    echo -e "${DF_YELLOW}⚠${DF_NC} This may take several hours"
    read -q "REPLY?Continue? [y/N]: "; echo
    [[ ! "$REPLY" =~ ^[Yy]$ ]] && return 0
    
    echo ""
    echo -e "${DF_BLUE}==>${DF_NC} Step 1/3: Health Check"
    btrfs-health "$mount"
    
    echo -e "${DF_BLUE}==>${DF_NC} Step 2/3: Balance"
    sudo btrfs balance start -dusage=50 -musage=50 "$mount"
    
    echo ""
    echo -e "${DF_BLUE}==>${DF_NC} Step 3/3: Scrub"
    sudo btrfs scrub start -B "$mount"  # -B runs in foreground
    
    echo ""
    echo -e "${DF_GREEN}✓${DF_NC} Maintenance complete"
    btrfs-health "$mount"
}

# ============================================================================
# Aliases
# ============================================================================

alias btru='btrfs-usage'
alias btrs='btrfs-subs'
alias btrh='btrfs-health'
alias btri='btrfs-info'
alias btrc='btrfs-compress'

# ============================================================================
# Help
# ============================================================================

btrfs-help() {
    df_print_header "Btrfs Helper CMD"
    #echo -e "${DF_BLUE}Btrfs Helper Commands${DF_NC}"
    
    cat << 'EOF'

  Information:
    btrfs-usage [mount]     Filesystem usage summary
    btrfs-subs [mount]      List all subvolumes
    btrfs-info [mount]      Full filesystem information
    btrfs-health [mount]    Quick health check
    btrfs-compress [path]   Compression statistics (requires compsize)
    
  Maintenance:
    btrfs-balance [mount]   Start balance operation
    btrfs-balance-status    Check balance progress
    btrfs-balance-cancel    Cancel running balance
    btrfs-scrub [mount]     Start scrub (integrity check)
    btrfs-scrub-status      Check scrub progress
    btrfs-scrub-cancel      Cancel running scrub
    btrfs-defrag <path>     Defragment file/directory
    btrfs-maintain [mount]  Full maintenance routine
    
  Snapshots:
    btrfs-snap-usage        Show snapshot space usage
    
  Aliases:
    btru    btrfs-usage
    btrs    btrfs-subs
    btrh    btrfs-health
    btri    btrfs-info
    btrc    btrfs-compress

  Note: Most commands default to / if no mount point specified.
  
  See also: snapper.zsh for snapshot management

EOF
}
