# Snapper Snapshot Management

Zsh functions for managing btrfs snapshots with limine-snapper-sync integration on CachyOS/Arch.

## Requirements

- Btrfs filesystem with snapper configured
- `limine-snapper-sync` package (AUR)
- Snapper config named "root"

## Quick Reference

| Command | Description |
|---------|-------------|
| `snap-create "desc"` | Create snapshot + validate limine entry |
| `snap-list [n]` | Show last n snapshots (default: 10) |
| `snap-show <num>` | Details for specific snapshot |
| `snap-delete <num>` | Delete snapshot + update limine |
| `snap-check-limine` | Verify boot menu sync status |
| `snap-sync` | Manually trigger limine sync |
| `snap-info` | Detailed breakdown by type |
| `snap-validate-service` | Check service health |

### Aliases

```bash
snap      → snap-create
snapls    → snap-list
snaprm    → snap-delete
snapshow  → snap-show
snapcheck → snap-check-limine
snapsync  → snap-sync
snapinfo  → snap-info
```

## Usage Examples

### Create Before Updates

```bash
snap-create "Before system update"
# or just:
snap "Before system update"
```

Output shows:
- Snapshot number created
- Limine sync trigger
- Validation that entry was added to boot menu

### Check Boot Menu Sync

```bash
snap-check-limine
```

Shows:
- All snapshots in limine.conf
- Comparison with snapper list
- Missing entries (if any)

### Pre/Post System Changes

```bash
# Before risky change
snap "Before kernel update"

# Make changes...
sudo pacman -Syu

# If something breaks, boot into the snapshot from limine menu
```

## How It Works

1. **snap-create** calls `snapper -c root create`
2. Triggers `limine-snapper-sync.service`
3. Validates that `/boot/limine.conf` was updated
4. Shows the new boot entry

The limine bootloader can then boot any snapshot directly.

## Snapshot Types

| Type | Created By |
|------|------------|
| `single` | Manual (your `snap-create` calls) |
| `pre` | Auto before package operations |
| `post` | Auto after package operations |

View with `snap-info`.

## Troubleshooting

### Snapshot Created but Not in Boot Menu

```bash
# Check service status
snap-validate-service

# Manual sync
snap-sync

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

## Configuration

Functions are in `~/.dotfiles/zsh/functions/snapper.zsh` and sourced by `.zshrc`.

Key settings:
- Snapper config: `root`
- Limine config: `/boot/limine.conf`
- Sync service: `limine-snapper-sync.service`

## Limitations

- Only works with limine bootloader
- Requires snapper config named "root"
- limine-snapper-sync typically limits boot entries to recent snapshots (this is intentional to prevent menu clutter)
