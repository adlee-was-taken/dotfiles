# Snapper Integration Guide

Complete guide to managing Btrfs snapshots with Snapper on Arch/CachyOS with limine bootloader integration.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Basic Commands](#basic-commands)
- [Snapshot Management](#snapshot-management)
- [Limine Boot Menu Integration](#limine-boot-menu-integration)
- [Automated Snapshots](#automated-snapshots)
- [Recovery Workflows](#recovery-workflows)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Overview

Snapper is a tool for creating and managing Btrfs filesystem snapshots. Combined with `limine-snapper-sync`, it provides:

- **Point-in-time recovery** - Restore to specific snapshots
- **System rollback** - Boot previous system states
- **Change tracking** - See what changed between snapshots
- **Automated backups** - Create snapshots on schedule or before updates

**Arch/CachyOS Benefits:**
- Native Btrfs support
- Limine bootloader integration for boot menu entries
- Pre-configured subvolume layouts
- Snapshots directly bootable via limine

---

## Prerequisites

### System Requirements

- **OS:** Arch Linux or CachyOS
- **Filesystem:** Btrfs (required for snapshots)
- **Bootloader:** Limine (for boot menu integration)
- **Subvolume Layout:** Standard Arch Btrfs layout

### Check Your Setup

```bash
# Verify Btrfs filesystem
df -T /
# Output: Filesystem Type Mounted on
#         /dev/nvme0n1p2 btrfs /

# Check subvolumes
btrfs subvolume list /
# Output should show: @ (root), @home, @var, @cache, etc.

# Verify limine bootloader
cat /proc/cmdline | grep limine
# or check EFI boot entry
efibootmgr
```

---

## Installation

### 1. Install Snapper

```bash
# Via pacman
sudo pacman -S snapper

# Or via AUR (paru or yay)
paru -S snapper
```

### 2. Install Limine Snapper Sync

```bash
# Via AUR
paru -S limine-snapper-sync

# Or yay
yay -S limine-snapper-sync
```

### 3. Configure Snapper

Create config for root subvolume:

```bash
sudo snapper -c root create-config /
```

Create config for home subvolume (optional):

```bash
sudo snapper -c home create-config /home
```

### 4. Enable Service

```bash
# Enable limine-snapper-sync service
sudo systemctl enable limine-snapper-sync.service
sudo systemctl start limine-snapper-sync.service

# Verify it's running
sudo systemctl status limine-snapper-sync.service
```

### 5. Verify Installation

```bash
snap-validate-service
```

Output:
```
✓ snapper installed
✓ limine-snapper-sync installed
✓ limine-snapper-sync enabled
✓ limine-snapper-sync running
✓ Snapper configs: root, home
```

---

## Basic Commands

### Create Snapshots

```bash
# Basic snapshot
snap-create "Initial setup"

# Snapshot with detailed description
snap-create "Before system upgrade - v6.13 → v6.14"

# Multiple snapshots
snap-create "Pre-AUR updates"
# ... do updates ...
snap-create "Post-AUR updates"
```

### List Snapshots

```bash
# Show last 10 snapshots
snap-list

# Show last 20 snapshots
snap-list 20

# Show all snapshots
snap-list all
```

Output:
```
Snapper Snapshots (root):
  42   | 2025-12-21 14:30  | single   | Before system upgrade
  41   | 2025-12-21 10:15  | single   | Initial setup
  40   | 2025-12-20 23:45  | pre      | Auto-snapshot (before pacman)
```

### View Snapshot Details

```bash
snap-show 42
```

Output:
```
Snapshot 42 (root):
  Created:        2025-12-21 14:30:14
  Type:           single
  Description:    Before system upgrade
  Filesystem:     btrfs
  Subvolume:      @
  UUID:           a1b2c3d4-e5f6...
  Space used:     2.3G
```

### Delete Snapshots

```bash
# Delete single snapshot
snap-delete 40

# Delete multiple
snap-delete 38 39 40

# Interactive delete
snap-delete --interactive
```

### Check Boot Menu Sync

```bash
snap-check-limine
```

Verifies:
- Limine config up to date
- All snapshots in boot menu
- Limine file locations correct

Output:
```
✓ Limine config found
✓ 12 boot entries detected
✓ Snapshots synced: 42, 41, 40
✓ Boot menu up to date
```

### Detailed Snapshot Info

```bash
snap-info
```

Shows breakdown by type:
- Pre-snapshots (before package operations)
- Post-snapshots (after package operations)
- Manual snapshots
- Timeline snapshots (if enabled)

### Manually Sync with Boot Menu

```bash
snap-sync
```

Manually trigger sync if you suspect desync between snapshots and boot menu.

---

## Snapshot Management

### Pre-configured Configs

Snapper comes with configs for different subvolumes. Manage them:

```bash
# List all configs
sudo snapper list-configs

# View config details
sudo snapper get-config root
sudo snapper get-config home
```

### Automatic Pre/Post Snapshots

Snapper automatically creates snapshots before/after pacman operations.

**Before update:**
```bash
sudo pacman -Syu
# Snapper auto-creates "pre" snapshot
# ... pacman runs ...
# Snapper auto-creates "post" snapshot
```

**View pre/post pairs:**
```bash
snap-list | grep "pre\|post"
```

### Timeline Snapshots (Optional)

Enable hourly/daily/monthly snapshots (not enabled by default):

```bash
# Edit snapper config
sudo nano /etc/snapper/configs/root

# Find TIMELINE settings:
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"

# Set cleanup policy
TIMELINE_MIN_AGE="1800"        # Min 30 min between timeline snapshots
TIMELINE_LIMIT_HOURLY="10"     # Keep 10 hourly
TIMELINE_LIMIT_DAILY="7"       # Keep 7 daily
TIMELINE_LIMIT_WEEKLY="0"      # Disable weekly
TIMELINE_LIMIT_MONTHLY="12"    # Keep 12 monthly
TIMELINE_LIMIT_YEARLY="10"     # Keep 10 yearly
```

Enable timeline service:

```bash
sudo systemctl enable snapper-timeline.timer
sudo systemctl start snapper-timeline.timer
```

### Cleanup Policies

Configure what snapshots to keep (in `/etc/snapper/configs/root`):

```bash
# Keep this many... after cleanup runs
ALLOW_USERS=""
ALLOW_GROUPS=""

SYNC_ACL="no"

AUTODETECT_FILESYSTEMS="yes"

BTRFS_QGROUPS=""

BACKGROUND_COMPARISON="yes"

FSTYPE="btrfs"

SUBVOLUME="/"

NUMBER_CLEANUP="yes"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"

TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="12"
TIMELINE_LIMIT_YEARLY="10"

EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_CLEANUP_AGE="604800"
```

Then run cleanup:

```bash
sudo snapper -c root cleanup number
sudo snapper -c root cleanup timeline
sudo snapper -c home cleanup number
```

---

## Limine Boot Menu Integration

### How It Works

`limine-snapper-sync` automatically:
1. Detects all Snapper snapshots
2. Creates boot menu entries for each
3. Updates Limine configuration
4. Manages entries (adds/removes as snapshots change)

### Boot Menu Entries

After syncing, your limine boot menu will show:

```
Limine Boot Menu
────────────────────────────
1. Current System (Arch Linux)
   └─ @ (default)
   
2. Snapshot 42: Before system upgrade
   └─ @/.snapshots/42/snapshot
   
3. Snapshot 41: Initial setup
   └─ @/.snapshots/41/snapshot
   
4. Snapshot 40: Auto-snapshot (before pacman)
   └─ @/.snapshots/40/snapshot
```

### Boot from Snapshot

1. Restart computer
2. At Limine menu, select snapshot
3. System boots from snapshot subvolume
4. All changes since snapshot are **not visible**

**Important:** This is **read-only** unless you manually mount it writable.

### Differences Between Subvolume Types

| Subvolume | Path | Bootable | Writable |
|-----------|------|----------|----------|
| Root (`@`) | `/` | Yes | Yes |
| Snapshot | `@/.snapshots/42/snapshot` | Yes | No (default) |
| Read-only snapshot | `@/.snapshots/42/snapshot` | Yes | No |

---

## Automated Snapshots

### Before System Updates

```bash
# Snapper automatically creates pre-snapshot
sudo pacman -Syu
# After update completes, post-snapshot created

# View the pair
snap-list | tail -2
```

### Custom Aliases for Common Operations

```bash
# Before AUR updates
alias aur-update='snap-create "Before AUR update" && paru -Syu && snap-create "After AUR update"'

# Before kernel update
alias kernel-update='snap-create "Before kernel update" && sudo pacman -S linux && snap-create "After kernel update"'
```

### Systemd Unit for Scheduled Snapshots

Create `/etc/systemd/system/snapper-daily.service`:

```ini
[Unit]
Description=Daily Snapper Snapshot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/snapper -c root create -d "Daily snapshot"
ExecStart=/usr/bin/snapper -c home create -d "Daily snapshot (home)"
```

Create `/etc/systemd/system/snapper-daily.timer`:

```ini
[Unit]
Description=Daily Snapper Snapshot Timer
Requires=snapper-daily.service

[Timer]
OnCalendar=daily
OnCalendar=*-*-* 02:00:00

[Install]
WantedBy=timers.target
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable snapper-daily.timer
sudo systemctl start snapper-daily.timer

# Check status
sudo systemctl list-timers
```

---

## Recovery Workflows

### Scenario 1: System Won't Boot After Update

**Steps:**

1. **At Limine menu:**
   - Select pre-update snapshot
   - Boot from snapshot

2. **Once booted from snapshot:**
   ```bash
   # Now in read-only snapshot environment
   # Make notes of what failed
   
   # If you want to apply fixes, remount writable
   sudo mount -o remount,rw /
   
   # Fix issues (reinstall package, etc)
   sudo pacman -S broken_package
   ```

3. **Restore full system from snapshot:**
   ```bash
   # Option A: Copy snapshot to live root
   sudo btrfs subvolume snapshot /.snapshots/40/snapshot /@.restore
   
   # Option B: Boot live, restore via btrfs
   sudo btrfs subvolume delete /
   sudo btrfs subvolume snapshot /.snapshots/40/snapshot /
   ```

4. **Reboot:**
   ```bash
   sudo reboot
   ```

### Scenario 2: Configuration Accidental Overwrite

**Steps:**

1. **Identify when file changed:**
   ```bash
   snap-list | grep -B5 -A5 "Some change"
   ```

2. **Find the snapshot before change:**
   ```bash
   snap-show 42
   snap-show 41
   ```

3. **Mount specific snapshot:**
   ```bash
   sudo mkdir -p /mnt/snapshot42
   sudo mount -t btrfs -o subvol=@/.snapshots/42/snapshot /dev/nvme0n1p2 /mnt/snapshot42
   ```

4. **Recover file:**
   ```bash
   sudo cp /mnt/snapshot42/etc/nginx/nginx.conf ~/.config/
   
   # Or view diff
   diff /mnt/snapshot42/etc/nginx/nginx.conf /etc/nginx/nginx.conf
   ```

5. **Cleanup:**
   ```bash
   sudo umount /mnt/snapshot42
   sudo rmdir /mnt/snapshot42
   ```

### Scenario 3: Rollback Entire System

**Complete recovery from snapshot:**

```bash
# Boot from Limine snapshot menu
# At snapshot, create new snapshot of current state (optional backup)
snap-create "Pre-rollback backup"

# Restore from specific snapshot
sudo btrfs subvolume delete @
sudo btrfs subvolume snapshot /.snapshots/40/snapshot @

# Reboot
sudo reboot
```

**After reboot:**
- System is fully restored to snapshot state
- All post-snapshot changes are gone
- Snapshots still exist (you can rollback again)

---

## Troubleshooting

### Verify Snapper Installation

```bash
snap-validate-service
```

### Check Snapper Configs

```bash
sudo snapper list-configs

# Detailed config
sudo snapper -c root get-config
```

### Boot Menu Not Updating

```bash
# Manual sync
sudo snapper list-configs
snap-sync

# Check limine service
sudo systemctl status limine-snapper-sync.service

# View logs
sudo journalctl -u limine-snapper-sync.service -n 20
```

### Can't Mount Snapshot

```bash
# Create temporary mount point
sudo mkdir -p /mnt/snap

# Identify snapshot subvolume
btrfs subvolume list /

# Mount specific snapshot
sudo mount -t btrfs -o subvol=@/.snapshots/42/snapshot /dev/nvme0n1p2 /mnt/snap

# Verify
ls /mnt/snap

# Cleanup when done
sudo umount /mnt/snap
```

### Snapper Disk Usage Growing

```bash
# Check snapshot usage
btrfs filesystem usage /

# Cleanup old snapshots
sudo snapper -c root cleanup number
sudo snapper -c home cleanup number

# Verify disk usage decreased
btrfs filesystem usage /
```

### Service Won't Start

```bash
# Check errors
sudo systemctl start limine-snapper-sync.service
sudo journalctl -xe

# Manually sync
sudo /usr/bin/snapper-limine-sync

# Check limine configuration
ls -la /boot/limine/
cat /boot/limine/limine.conf
```

---

## Best Practices

### Before Major Operations

```bash
# Always snapshot before:
snap-create "Before AUR package X"
snap-create "Before kernel update"
snap-create "Before major configuration change"

# Then perform the operation
# Monitor for issues

# If issues: boot snapshot via Limine
# If success: keep snapshot for point-in-time recovery
```

### Naming Conventions

```bash
# Good names
snap-create "Before pacman system update"
snap-create "After successful AUR update"
snap-create "Backup before /etc/nginx config change"

# Bad names
snap-create "snapshot"
snap-create "test"
snap-create "backup"
```

### Regular Cleanup

Schedule cleanup (weekly):

```bash
# Add to crontab
0 3 * * 0 /usr/bin/snapper -c root cleanup number
0 4 * * 0 /usr/bin/snapper -c home cleanup number
0 5 * * 0 /usr/bin/snapper-limine-sync
```

### Documentation

```bash
# Keep notes of major changes and snapshots
# In ~/Documents/snapshot-history.txt

# 2025-12-21 Snapshot 42: System upgrade 6.13→6.14
# 2025-12-20 Snapshot 41: Initial setup complete
# 2025-12-19 Snapshot 40: Base installation
```

### Backup Critical Data

```bash
# Don't rely only on snapshots
# Backup critical data separately

# Snapshots are for:
# - System recovery
# - Configuration recovery
# - Point-in-time rollback

# Backups are for:
# - Off-site redundancy
# - Long-term retention
# - Disaster recovery
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `snap-create` | Create snapshot |
| `snap-list` | List snapshots |
| `snap-show` | Show snapshot details |
| `snap-delete` | Delete snapshot |
| `snap-check-limine` | Verify boot menu sync |
| `snap-sync` | Manual sync to boot menu |
| `snap-validate-service` | Verify service health |
| `snap-info` | Show snapshot breakdown |

---

## See Also

- [README.md](../README.md) - Main documentation
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Installation guide
- [Snapper Documentation](https://github.com/openSUSE/snapper)
- [Limine Snapper Sync](https://github.com/terrapkg/limine-snapper-sync)
