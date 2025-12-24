# ADLee's Dotfiles

Personal configuration files for a fast, productive development environment on **Arch Linux** and **CachyOS**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![OS](https://img.shields.io/badge/OS-Arch%20%2F%20CachyOS-blue.svg)](https://archlinux.org/)

```
┌[alee@battlestation]─[~/.dotfiles ⎇ main]─[⇑3]
└%
```

## Features at a Glance

| Feature | Description |
|---------|-------------|
| **Dynamic MOTD** | System info on shell start (uptime, load, memory, updates) |
| **Two-Line Prompt** | Git status, command timer, update indicator, root detection |
| **Command Palette** | Raycast-style fuzzy launcher (`Ctrl+Space`) |
| **Smart Suggestions** | Typo correction + alias recommendations |
| **Systemd Helpers** | Quick service management shortcuts |
| **Btrfs Helpers** | Filesystem health, scrub, balance commands |
| **Snapper Integration** | Btrfs snapshots with limine boot menu sync |
| **Secrets Vault** | Encrypted storage for API keys (age/gpg) |
| **Password Manager** | LastPass CLI integration |
| **Tmux Workspaces** | Project templates with pre-configured layouts |
| **SSH Manager** | Save and manage SSH connections with tmux |
| **Python Templates** | Quick project scaffolding (Django, Flask, FastAPI, etc.) |
| **Dotfiles Sync** | Keep configuration in sync across machines |
| **Shell Analytics** | Track command usage and get insights |

---

## Quick Start

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

See `INSTALL.md` for detailed installation instructions.

---

## Command Reference

### Dotfiles Management

| Command | Alias | Description |
|---------|-------|-------------|
| `dotfiles-doctor.sh` | `dfd`, `doctor` | Health check |
| `dotfiles-doctor.sh --fix` | `dffix` | Auto-fix issues |
| `dotfiles-doctor.sh --quick` | - | Quick essential checks |
| `dotfiles-sync.sh` | `dfs`, `dfsync` | Sync status |
| `dotfiles-sync.sh push` | `dfpush` | Push changes to remote |
| `dotfiles-sync.sh pull` | `dfpull` | Pull remote changes |
| `dotfiles-update.sh` | `dfu`, `dfupdate` | Update dotfiles |
| `dotfiles-version.sh` | `dfv`, `dfversion` | Version info |
| `dotfiles-stats.sh` | `dfstats` | Shell analytics |
| `dotfiles-vault.sh` | `vault` | Secrets manager |
| `dotfiles-compile.sh` | `dfcompile` | Compile zsh for speed |
| `source ~/.zshrc` | `reload`, `rl` | Reload shell config |

### Quick Edit Aliases

| Alias | Opens |
|-------|-------|
| `v.zshrc` | `~/.zshrc` |
| `v.conf` | `~/.dotfiles/dotfiles.conf` |
| `v.alias` | `~/.dotfiles/zsh/aliases.zsh` |
| `v.motd` | `~/.dotfiles/zsh/functions/motd.zsh` |
| `v.edit` | `~/.dotfiles` directory in editor |

---

## Systemd Helpers

Quick shortcuts for systemd service management.

### Core Commands

| Command | Description |
|---------|-------------|
| `sc <args>` | `sudo systemctl <args>` |
| `scu <args>` | `systemctl --user <args>` |
| `scr <service>` | Restart service and show status |
| `sce <service>` | Enable and start service |
| `scd <service>` | Disable and stop service |
| `sclog <service>` | Follow journal logs (`-f`) |
| `sclogs <service>` | Show recent logs (no follow) |

### Status Commands

| Command | Description |
|---------|-------------|
| `sc-failed` | Show failed services (system + user) |
| `sc-timers` | Show active timers |
| `sc-recent` | Recently started services |
| `sc-boot` | Boot time analysis |
| `sc-search <query>` | Search services by name |
| `sc-info <service>` | Detailed service info |

### Interactive (requires fzf)

| Command | Description |
|---------|-------------|
| `scf` | Interactive service manager with preview |
| `sclogf` | Interactive log viewer |

### Aliases

| Alias | Command |
|-------|---------|
| `scs` | `sc status` |
| `scstart` | `sc start` |
| `scstop` | `sc stop` |
| `screload` | `sc daemon-reload` |
| `jctl` | `journalctl` |
| `jctlf` | `journalctl -f` |
| `jctlb` | `journalctl -b` |
| `jctlerr` | `journalctl -p err -b` |

---

## Btrfs Helpers

Quick commands for btrfs filesystem management (CachyOS defaults to btrfs).

### Information

| Command | Alias | Description |
|---------|-------|-------------|
| `btrfs-usage [mount]` | `btru` | Filesystem usage summary |
| `btrfs-subs [mount]` | `btrs` | List all subvolumes |
| `btrfs-info [mount]` | `btri` | Full filesystem information |
| `btrfs-health [mount]` | `btrh` | Quick health check |
| `btrfs-compress [path]` | `btrc` | Compression stats (requires `compsize`) |

### Maintenance

| Command | Description |
|---------|-------------|
| `btrfs-balance [mount]` | Start balance operation |
| `btrfs-balance-status` | Check balance progress |
| `btrfs-balance-cancel` | Cancel running balance |
| `btrfs-scrub [mount]` | Start scrub (integrity check) |
| `btrfs-scrub-status` | Check scrub progress |
| `btrfs-scrub-cancel` | Cancel running scrub |
| `btrfs-defrag <path>` | Defragment file/directory |
| `btrfs-maintain [mount]` | Full maintenance routine |

### Snapshots

| Command | Description |
|---------|-------------|
| `btrfs-snap-usage` | Show snapshot space usage |

> **Note:** Most commands default to `/` if no mount point is specified. See also `snapper.zsh` for snapshot management.

---

## Snapper Integration

Btrfs snapshot management with limine bootloader sync.

| Command | Alias | Description |
|---------|-------|-------------|
| `snap-create "description"` | `snap` | Create snapshot with validation |
| `snap-list [count]` | `snapls` | List recent snapshots (default: 10) |
| `snap-show <number>` | `snapshow` | Show snapshot details |
| `snap-delete <number>` | `snaprm` | Delete snapshot |
| `snap-check-limine` | `snapcheck` | Verify boot menu sync |
| `snap-sync` | `snapsync` | Manually trigger limine sync |
| `snap-validate-service` | - | Check service status |

### System Update with Snapshot

```bash
sys-update    # Creates pre/post snapshot around pacman -Syu
```

---

## Command Palette

Press **`Ctrl+Space`** or **`Ctrl+P`** to open the fuzzy command launcher.

```
╭──────────────────────────────────────────╮
│ ❯ git                                    │
├──────────────────────────────────────────┤
│ ⎇  git status                            │
│ ⎇  git pull main                         │
│ ⚡ gs (alias → git status)               │
│ ↺  git commit -m "..."                   │
│ ★  Edit .zshrc                           │
╰──────────────────────────────────────────╯
```

### Searches

- Aliases and functions
- Recent commands
- Git commands (when in repo)
- Docker commands
- Bookmarked directories
- Dotfiles scripts
- Quick actions

### Keybindings

| Key | Action |
|-----|--------|
| `Enter` | Execute command |
| `Ctrl+E` | Edit before running |
| `Ctrl+Y` | Copy to clipboard |
| `Ctrl+R` | Reload entries |

### Directory Bookmarks

| Command | Alias | Description |
|---------|-------|-------------|
| `bookmark <name> [path]` | `bm` | Save bookmark (default: current dir) |
| `bookmark list` | `bm list` | List all bookmarks |
| `bookmark delete <name>` | `bm rm` | Delete bookmark |
| `jump <name>` | `j` | Go to bookmark (fuzzy select if no name) |

---

## Smart Suggestions

Automatic typo correction for 100+ common mistakes:

```bash
$ gti status
✗ Command not found: gti
→ Did you mean: git?
```

Alias recommendations for frequently typed commands:

```bash
💡 Tip: You've typed 'git status' 50 times
   Consider adding: alias gs='git status'
```

### Supported Typos

Git, Docker, common commands (ls, cat, grep, mkdir, etc.), Python, Node, sudo, ssh, vim, and more.

### Quick Fix

```bash
fuck    # Re-run last command with typo correction
```

---

## MOTD (Message of the Day)

System info displayed on shell startup.

### Display Styles

| Style | Command | Description |
|-------|---------|-------------|
| Compact | `show_motd` | Box format with stats |
| Mini | `show_motd_mini` | Single line |
| Full | `show_motd_full` | Extended info with kernel, scheduler |

### Configuration

In `dotfiles.conf`:

```bash
ENABLE_MOTD="true"
MOTD_STYLE="compact"    # compact, mini, full, or none
```

### Force Refresh

```bash
motd          # Compact
motd-mini     # Mini
motd-full     # Full
sysbrief      # Quick system overview (callable anytime)
```

---

## Secrets Vault

Encrypted storage for API keys and tokens using `age` or `gpg`.

| Command | Description |
|---------|-------------|
| `vault init` | Initialize vault |
| `vault set <key> [value]` | Store secret (prompts if value omitted) |
| `vault get <key>` | Retrieve secret |
| `vault list` | List all keys |
| `vault delete <key>` | Delete secret |
| `vault shell` | Print as export statements |
| `vault export <file>` | Backup vault (encrypted) |
| `vault import <file>` | Restore from backup |
| `vault status` | Show vault info |

### Aliases

| Alias | Command |
|-------|---------|
| `vls` | `vault list` |
| `vget` | `vault get` |
| `vset` | `vault set` |

### Auto-load on Shell Start

Secrets can be auto-exported to environment. Enable in `.zshrc`:

```bash
eval $(vault shell)
```

---

## Password Manager (LastPass)

Unified interface for LastPass CLI.

| Command | Description |
|---------|-------------|
| `pw list` | List all items |
| `pw get <item> [field]` | Get field (default: password) |
| `pw otp <item>` | Get TOTP code |
| `pw search <query>` | Search items |
| `pw copy <item> [field]` | Copy to clipboard |
| `pw lock` | Logout/lock session |

### Fields

`password`, `username`, `url`, `notes`, or any custom field name.

### Aliases

| Alias | Command |
|-------|---------|
| `pwl` | `pw list` |
| `pwg` | `pw get` |
| `pwc` | `pw copy` |
| `pws` | `pw search` |

### FZF Integration

| Command | Description |
|---------|-------------|
| `pwf` | Fuzzy search and copy password |
| `pwof` | Fuzzy search and copy OTP |

---

## Tmux Workspace Manager

Pre-configured layouts for different workflows.

### Workspace Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `tw <name> [template]` | - | Attach or create workspace |
| `tw-create <name> [template]` | `twc` | Create workspace |
| `tw-attach <name>` | `twa` | Attach to workspace |
| `tw-list` | `twl` | List active workspaces |
| `tw-delete <name>` | `twd` | Delete workspace |
| `tw-save <name>` | `tws` | Save current layout as template |
| `tw-templates` | `twt` | List available templates |
| `tw-template-edit <name>` | `twe` | Edit template |
| `tw-sync` | - | Toggle pane synchronization |
| `tw-rename <old> <new>` | - | Rename workspace |
| `twf` | - | Fuzzy search workspaces |

### Built-in Templates

| Template | Description |
|----------|-------------|
| `dev` | Vim (50%) + terminal (25%) + logs (25%) |
| `ops` | 4-pane monitoring grid |
| `ssh-multi` | 4 panes for multi-server management |
| `debug` | Main (70%) + helper (30%) |
| `full` | Single full-screen pane |
| `review` | Side-by-side code review |

---

## SSH Session Manager

Save and manage SSH connections with automatic tmux integration.

| Command | Alias | Description |
|---------|-------|-------------|
| `ssh-save <name> <user@host> [port] [key] [opts] [desc]` | `sshs` | Save profile |
| `ssh-list` | `sshl` | List all profiles |
| `ssh-connect <name>` | `sshc` | Connect (auto tmux) |
| `ssh-delete <name>` | `sshd` | Delete profile |
| `ssh-reconnect [name]` | `sshr` | Reconnect (default: last) |
| `ssh-sync-dotfiles <name>` | `sshsync` | Deploy dotfiles to remote |
| `sshf` | - | Fuzzy search and connect |

### Configuration

In `dotfiles.conf`:

```bash
SSH_AUTO_TMUX="true"              # Auto-create tmux session
SSH_TMUX_SESSION_PREFIX="ssh"     # Session naming prefix
SSH_SYNC_DOTFILES="ask"           # Sync dotfiles on connect
```

---

## Python Project Templates

Quick project scaffolding with virtual environments.

| Command | Alias | Description |
|---------|-------|-------------|
| `py-new <name>` | `pynew` | Basic Python project |
| `py-django <name>` | `pydjango` | Django web app |
| `py-flask <name>` | `pyflask` | Flask web app |
| `py-fastapi <name>` | `pyfast` | FastAPI REST API |
| `py-data <name>` | `pydata` | Data science project |
| `py-cli <name>` | `pycli` | CLI tool with Click |

### Quick Venv Activation

```bash
venv    # Activates venv, .venv, or env if found
```

---

## Shell Analytics

Track command usage and get insights.

| Command | Description |
|---------|-------------|
| `dfstats` | Full dashboard |
| `dfstats top [n]` | Top N commands |
| `dfstats suggest` | Alias suggestions |
| `dfstats breakdown` | Category breakdown |
| `dfstats heatmap` | Activity by hour |
| `dfstats dirs` | Most visited directories |
| `dfstats git` | Git command breakdown |
| `dfstats export` | Export as JSON |

---

## Common Aliases

### Navigation

| Alias | Command |
|-------|---------|
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `~` | `cd ~` |
| `c.` | `cd ~/.dotfiles` |

### Git

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `glog` | `git log --oneline --graph --decorate --all` |

### Docker

| Alias | Command |
|-------|---------|
| `d` | `docker` |
| `dc` | `docker-compose` |
| `dps` | `docker ps` |
| `dpa` | `docker ps -a` |
| `di` | `docker images` |
| `dex` | `docker exec -it` |

### System

| Alias | Command |
|-------|---------|
| `h` | `history` |
| `c` | `clear` |
| `myip` | `curl -s ifconfig.me` |
| `ports` | `netstat -tulanp` |

### Tools (conditional)

| Alias | Command | Condition |
|-------|---------|-----------|
| `ls` | `eza --icons` | if eza installed |
| `ll` | `eza -lah --icons` | if eza installed |
| `la` | `eza -a --icons` | if eza installed |
| `lt` | `eza --tree --level=2 --icons` | if eza installed |
| `cat` | `bat --paging=never` | if bat installed |

---

## Zsh Theme Features

The `adlee` theme provides:

- **Two-line prompt** for clarity
- **Git integration** with branch name and dirty indicator (`*`)
- **Command timer** for commands taking >10 seconds
- **Update indicator** showing available package updates
- **Root detection** (red `#` for root, blue `%` for users)
- **Smart path display**

### Timer Display

| Duration | Color |
|----------|-------|
| >1 hour | Red |
| >1 minute | Orange |
| >10 seconds | Green |

---

## Espanso Text Expansion

Text expansion snippets for quick typing.

### Date/Time

| Trigger | Output |
|---------|--------|
| `..date` | `2025-12-24` |
| `..time` | `14:30:45` |
| `..dt` | `2025-12-24 14:30:45 EST` |
| `..ts` | ISO 8601 timestamp |
| `..epoch` | Unix timestamp |

### Quick Text

| Trigger | Output |
|---------|--------|
| `..shrug` | `¯\_(ツ)_/¯` |
| `..flip` | `(╯°□°)╯︵ ┻━┻` |
| `..lgtm` | `Looks good to me` |

### Code

| Trigger | Output |
|---------|--------|
| `..bash` | Bash shebang + set -euo pipefail |
| `..python` | Python main boilerplate |
| `..mdcode` | Markdown code block |

See [REFERENCE.md](REFERENCE.md) for complete Espanso reference.

---

## Key Bindings

| Binding | Action |
|---------|--------|
| `Ctrl+Space` | Command palette |
| `Ctrl+P` | Command palette (alternative) |
| `Alt+R` | Reload zsh config |
| `Ctrl+→` | Forward word |
| `Ctrl+←` | Backward word |
| `Home` | Beginning of line |
| `End` | End of line |

---

## Configuration

Edit `~/.dotfiles/dotfiles.conf`:

```bash
# Identity
USER_FULLNAME="Your Name"
USER_EMAIL="you@example.com"
USER_GITHUB="yourusername"

# MOTD
ENABLE_MOTD="true"
MOTD_STYLE="compact"

# Features
ENABLE_SMART_SUGGESTIONS="true"
ENABLE_COMMAND_PALETTE="true"
ENABLE_VAULT="true"
DOTFILES_AUTO_SYNC_CHECK="true"

# Btrfs
BTRFS_DEFAULT_MOUNT="/"

# Package Manager
AUR_HELPER="auto"    # paru, yay, or auto
```

---

## Repository Structure

```
~/.dotfiles/
├── install.sh              # Main installer
├── dotfiles.conf           # Central configuration
├── bin/                    # Scripts (symlinked to ~/.local/bin)
│   ├── dotfiles-doctor.sh
│   ├── dotfiles-sync.sh
│   ├── dotfiles-update.sh
│   ├── dotfiles-vault.sh
│   ├── dotfiles-stats.sh
│   ├── dotfiles-version.sh
│   └── dotfiles-compile.sh
├── zsh/
│   ├── .zshrc
│   ├── aliases.zsh
│   ├── lib/
│   │   └── colors.zsh      # Shared color definitions
│   ├── themes/
│   │   └── adlee.zsh-theme
│   └── functions/
│       ├── btrfs-helpers.zsh
│       ├── command-palette.zsh
│       ├── motd.zsh
│       ├── password-manager.zsh
│       ├── python-templates.zsh
│       ├── smart-suggest.zsh
│       ├── snapper.zsh
│       ├── ssh-manager.zsh
│       ├── systemd-helpers.zsh
│       └── tmux-workspaces.zsh
├── vim/.vimrc
├── tmux/.tmux.conf
├── git/.gitconfig.template
├── espanso/                # Text expansion
├── setup/                  # Setup scripts
└── .tmux-templates/        # Workspace layouts
```

---

## License

MIT – See [LICENSE](LICENSE)

---

**Author:** Aaron D. Lee  
**Repository:** https://github.com/adlee-was-taken/dotfiles
