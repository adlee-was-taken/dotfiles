# Snapper Snapshot Management

Zsh functions for managing btrfs snapshots with limine-snapper-sync integration on CachyOS/Arch.

## Requirements

- Btrfs filesystem with snapper configured
- `limine-snapper-sync` package (AUR)
- Snapper config named "root"
- Limine bootloader

---

## Quick Reference

| Command | Alias | Description |
|---------|-------|-------------|
| `snap-create "desc"` | `snap` | Create snapshot + validate limine entry |
| `snap-list [n]` | `snapls` | Show last n snapshots (default: 10) |
| `snap-show <num>` | `snapshow` | Details for specific snapshot |
| `snap-delete <num>` | `snaprm` | Delete snapshot + update limine |
| `snap-check-limine` | `snapcheck` | Verify boot menu sync status |
| `snap-sync` | `snapsync` | Manually trigger limine sync |
| `snap-info` | `snapinfo` | Detailed breakdown by type |
| `snap-validate-service` | - | Check service health |

---

## Usage Examples

### Create Before Updates

```bash
snap-create "Before system update"
# or using alias:
snap "Before system update"
```

Output:

```
╔════════════════════════════════════════════════════════════╗
║  Snapper Snapshot Creation & Validation                    ║
╚════════════════════════════════════════════════════════════╝

==> Checking limine.conf state before snapshot
✓ Before: 5 snapshot entries
✓ Before checksum: a1b2c3d4...

==> Creating snapshot: "Before system update"
✓ Snapshot created: #42

==> Triggering limine-snapper-sync service...
✓ Service triggered successfully

==> Validating limine.conf update
✓ limine.conf was updated
✓ Added 1 new snapshot entry
✓ Found snapshot #42 in limine.conf

╔════════════════════════════════════════════════════════════╗
║  Summary                                                   ║
╚════════════════════════════════════════════════════════════╝
Snapshot Number:       #42
Description:           "Before system update"
Status:                ✓ VALIDATED
```

### Check Boot Menu Sync

```bash
snap-check-limine
# or:
snapcheck
```

Shows:
- All snapshots in limine.conf
- Comparison with snapper list
- Missing entries (if any)
- Sync status

### List Recent Snapshots

```bash
snap-list        # Last 10
snap-list 20     # Last 20
# or:
snapls 20
```

### View Snapshot Details

```bash
snap-show 42
# or:
snapshow 42
```

Shows:
- Snapshot info from snapper
- Corresponding entry in limine.conf

### Delete Snapshot

```bash
snap-delete 42
# or:
snaprm 42
```

Automatically:
- Deletes snapshot from snapper
- Triggers limine-snapper-sync
- Verifies removal from boot menu

---

## How It Works

1. **`snap-create`** calls `snapper -c root create`
2. Triggers `limine-snapper-sync.service`
3. Validates that `/boot/limine.conf` was updated
4. Shows the new boot entry

The limine bootloader can then boot any snapshot directly from the boot menu.

---

## Snapshot Types

| Type | Created By |
|------|------------|
| `single` | Manual (your `snap-create` calls) |
| `pre` | Auto before package operations |
| `post` | Auto after package operations |

View breakdown with `snap-info` or `snapinfo`.

---

## Pre/Post System Changes Workflow

```bash
# Before risky change
snap "Before kernel update"

# Make changes
sudo pacman -Syu

# If something breaks:
# 1. Reboot
# 2. Select snapshot from limine boot menu
# 3. System restored to pre-update state
```

---

## Troubleshooting

### Snapshot Created but Not in Boot Menu

```bash
# Check service status
snap-validate-service

# Manual sync
snap-sync
# or:
snapsync

# Verify
snap-check-limine
```

### Service Not Running

```bash
sudo systemctl enable limine-snapper-sync.service
sudo systemctl start limine-snapper-sync.service
```

### Boot Menu Has Stale Entries

```bash
# Delete old snapshot
snap-delete 42

# This auto-triggers sync to remove from limine.conf
```

### Check Service Logs

```bash
sudo journalctl -u limine-snapper-sync.service -n 50
```

### Validate Everything

```bash
snap-validate-service
```

This checks:
- Service unit exists
- Service is enabled
- Snapper config exists
- limine.conf exists
- Current sync status

---

## Configuration

Functions are sourced from `~/.dotfiles/zsh/functions/snapper.zsh`.

Settings in `~/.dotfiles/dotfiles.conf`:

```bash
SNAPPER_CONFIG="root"
LIMINE_CONF="/boot/limine.conf"
```

---

## Limitations

- Only works with **limine bootloader**
- Requires snapper config named **"root"**
- `limine-snapper-sync` typically limits boot entries to recent snapshots (intentional to prevent menu clutter)

---

## Installing limine-snapper-sync

On Arch/CachyOS:

```bash
# If using paru
paru -S limine-snapper-sync

# If using yay
yay -S limine-snapper-sync

# Enable service
sudo systemctl enable limine-snapper-sync.service
```

---

## Manual Snapper Commands

If you need to use snapper directly:

```bash
# List all snapshots
sudo snapper -c root list

# Create snapshot
sudo snapper -c root create --description "My snapshot"

# Delete snapshot
sudo snapper -c root delete 42

# Compare snapshots
sudo snapper -c root diff 41..42

# Show snapper config
sudo snapper -c root get-config
```

---

## Boot Recovery

If your system won't boot:

1. At limine boot menu, select a snapshot
2. System boots into that snapshot state
3. Once booted, you can:
   - Fix the issue
   - Roll back permanently with `snapper rollback`
   - Create a new snapshot of the working state
