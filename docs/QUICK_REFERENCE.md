# Quick Reference

Fast lookup for common dotfiles commands and features.

## 🚀 Quick Start

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --wizard
```

---

## 📋 Core Commands

### Installation & Management
| Command | Purpose |
|---------|---------|
| `./install.sh` | Standard install |
| `./install.sh --wizard` | Interactive TUI wizard |
| `./install.sh --skip-deps` | Reinstall without checking deps |
| `./install.sh --uninstall` | Remove symlinks |
| `dotfiles-doctor.sh` | Health check |
| `dotfiles-doctor.sh --fix` | Auto-fix issues |
| `dfd` | Alias for health check |

### Updates
| Command | Purpose |
|---------|---------|
| `dotfiles-update.sh` | Update dotfiles |
| `dotfiles-sync.sh` | Sync across machines |
| `dfpush` | Push local changes |
| `dfpull` | Pull remote changes |
| `dfstatus` | Check sync status |

### Info
| Command | Purpose |
|---------|---------|
| `dotfiles-version.sh` | Show version |
| `dfv` | Alias for version |

---

## 🎯 Command Palette

**Trigger:** `Ctrl+Space` or `Ctrl+P`

Searches: aliases, functions, recent commands, bookmarks, git commands, dotfiles scripts

**Keybindings:**
- `Enter` - Execute
- `Ctrl+E` - Edit before running
- `Ctrl+Y` - Copy to clipboard

---

## 🔑 Password Manager (LastPass)

```bash
pw list                    # List all items
pw get github              # Get password
pw get github username     # Get specific field
pw otp github              # Get TOTP code
pw copy aws                # Copy to clipboard
pw search mail             # Search items
pwf                        # Fuzzy search + copy
pwof                       # Fuzzy search + copy OTP
pw lock                    # Logout
```

---

## 📁 Directory Bookmarks

```bash
bookmark <n> [path]       # Save bookmark (default: current dir)
bookmark list             # List all
bookmark delete <n>       # Delete
jump <n>                  # Go to bookmark
j                         # Fuzzy select
```

---

## 🔐 Secrets Vault

```bash
vault set KEY "value"     # Store (or prompt for value)
vault get KEY             # Retrieve
vault list                # List all keys
vault delete KEY          # Remove
vault shell               # Print as export statements
vault export backup.enc   # Backup
vault import backup.enc   # Restore
```

---

## 📊 Shell Analytics

```bash
dotfiles-stats.sh         # Full dashboard
dfstats                   # Alias for full
stats                     # Another alias
dotfiles-stats.sh --top 20 # Top 20 commands
dotfiles-stats.sh --suggest # Alias suggestions
```

---

## 📸 Snapper (Btrfs Snapshots)

```bash
snap-create "Description" # Create snapshot
snap-list                 # Show snapshots
snap-list 20              # Show last 20
snap-show 42              # Show details
snap-delete 42            # Delete
snap-check-limine         # Verify boot menu
snap-sync                 # Manual sync
snap-info                 # Detailed breakdown
```

---

## 🌐 SSH Management

```bash
ssh-save <n> <conn>       # Save profile
ssh-list                  # List profiles
ssh-connect <n>           # Connect (auto-tmux)
sshf                      # Fuzzy search + connect
ssh-delete <n>            # Delete
ssh-sync-dotfiles <n>     # Deploy dotfiles to remote
ssh-reconnect             # Quick reconnect
```

---

## 🎪 Tmux Workspace Manager

```bash
tw <n>                    # Quick attach/create
tw-create <n> [tmpl]     # Create with template
tw-list                   # List workspaces
tw-delete <n>             # Delete
tw-save <n>               # Save as template
tw-sync                   # Toggle pane sync
twf                       # Fuzzy select
tw-templates              # List available templates
```

**Templates:**
- `dev` - vim (50%) + terminal (25%) + logs (25%)
- `ops` - 4-pane monitoring grid
- `ssh-multi` - 4 synchronized panes
- `debug` - main (70%) + helper (30%)
- `full` - Single fullscreen
- `review` - Side-by-side comparison

---

## ⚡ Aliases (All Commands)

| Alias | Command | Purpose |
|-------|---------|---------|
| `dfd` | `dotfiles-doctor.sh` | Health check |
| `dffix` | `dotfiles-doctor.sh --fix` | Auto-fix |
| `dfs` | `dotfiles-sync.sh` | Sync |
| `dfpush` | `dotfiles-sync.sh --push` | Push |
| `dfpull` | `dotfiles-sync.sh --pull` | Pull |
| `dfu` | `dotfiles-update.sh` | Update |
| `dfv` | `dotfiles-version.sh` | Version |
| `dfstats` | `dotfiles-stats.sh` | Analytics |
| `stats` | `dotfiles-stats.sh` | Analytics |
| `pw` | LastPass manager | Password lookup |
| `pwf` | LastPass fuzzy | Fuzzy password |
| `vault` | `dotfiles-vault.sh` | Secrets |
| `vls` | `vault list` | List secrets |
| `reload` | `source ~/.zshrc` | Reload shell |
| `j` | Fuzzy bookmark | Jump to bookmark |
| `tw` | Tmux workspace | Quick workspace |
| `twf` | Fuzzy tmux | Fuzzy workspace |
| `sshf` | Fuzzy SSH | Fuzzy SSH connect |

---

## 🎨 Customization

**Main config file:** `~/.dotfiles/dotfiles.conf`

**Machine-specific config:** `~/.zshrc.local` (not tracked)

**Text snippets:** `~/.dotfiles/espanso/match/personal.yml`

**Theme:** `~/.dotfiles/zsh/themes/adlee.zsh-theme`

---

## 📚 Common Tasks

### Create Dev Project
```bash
tw-create myproject dev        # Create workspace
pw get github                  # Get credentials
git clone <repo>
```

### Monitor Multiple Servers
```bash
ssh-save web1 user@web1.com
ssh-save web2 user@web2.com
tw-create monitoring ops       # 4-pane grid
ssh-connect web1               # In pane 1
ssh-connect web2               # In pane 2
tw-sync                        # Enable sync
```

### System Backup Before Update
```bash
snap-create "Before pacman update"
sudo pacman -Syu
snap-create "After pacman update"
```

### Recover Lost File
```bash
snap-list                      # Find relevant snapshot
snap-show 42                   # Check timestamp
sudo mount -t btrfs -o subvol=@/.snapshots/42/snapshot /dev/device /mnt/snap
cp /mnt/snap/path/to/file ~/
sudo umount /mnt/snap
```

### Sync Dotfiles to Remote
```bash
ssh-save prod user@prod.com
ssh-sync-dotfiles prod
```

### Fuzzy Find and Execute
```bash
Ctrl+Space                     # Open command palette
git                            # Type partial
```

---

## 🔧 Configuration Examples

### Change Default Theme
Edit `~/.dotfiles/dotfiles.conf`:
```bash
ZSH_THEME="adlee"             # Already default
```

### Enable More Features
Edit `~/.dotfiles/dotfiles.conf`:
```bash
INSTALL_NEOVIM="true"         # Auto-install neovim
INSTALL_FZF="true"            # Auto-install fzf
ENABLE_VAULT="true"           # Enable secrets
```

### Add Custom Alias
Edit `~/.dotfiles/zsh/aliases.zsh`:
```bash
alias projects='cd ~/projects'
alias k='kubectl'
```

### Machine-Specific Config
Create `~/.zshrc.local`:
```bash
export WORK_EMAIL="me@work.com"
alias vpn='wg-quick up work-vpn'
```

---

## 🆘 Troubleshooting

### Health Check
```bash
dotfiles-doctor.sh
# or
dfd
```

### Reset Zsh
```bash
./install.sh --skip-deps
source ~/.zshrc
```

### Check Version
```bash
dotfiles-version.sh
# or
dfv
```

### View Logs
```bash
dotfiles-doctor.sh --verbose
```

---

## 🎯 Zsh Keybindings

| Key | Action |
|-----|--------|
| `Tab` | Autocomplete |
| `Ctrl+Space` | Command palette |
| `Ctrl+P` | Command palette (alt) |
| `Ctrl+B, C` | New tmux window |
| `Ctrl+B, D` | Detach tmux |
| `Ctrl+L` | Clear screen |
| `Ctrl+U` | Clear line |
| `Ctrl+R` | Search history |
| `Ctrl+A` | Start of line |
| `Ctrl+E` | End of line |

---

## 📦 System Requirements

- **OS:** Arch Linux or CachyOS
- **Shell:** Zsh (auto-installed)
- **Editor:** Vim (required)
- **Optional:** Neovim, LastPass CLI, fzf, bat, eza
- **Bootloader:** Limine (for Snapper)

---

## 🔗 Important Paths

| Path | Purpose |
|------|---------|
| `~/.dotfiles` | Main dotfiles directory |
| `~/.dotfiles/dotfiles.conf` | Main configuration |
| `~/.dotfiles/zsh/functions/` | Shell functions |
| `~/.dotfiles/bin/` | Utility scripts |
| `~/.zshrc.local` | Machine-specific config |
| `~/.dotfiles_backup_*` | Backup of original files |
| `~/.ssh/config` | SSH profiles (generated) |

---

## 📖 Full Documentation

- [README.md](README.md) - Full feature overview
- [SETUP_GUIDE.md](docs/SETUP_GUIDE.md) - Installation and setup
- [SSH_TMUX_INTEGRATION.md](docs/SSH_TMUX_INTEGRATION.md) - SSH and Tmux
- [SNAPPER.md](docs/SNAPPER.md) - Snapshot management
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contributing guidelines
- [CHANGELOG.md](CHANGELOG.md) - Version history

---

## 💡 Tips

1. **Reload Shell** - Changes to zsh config:
   ```bash
   reload
   # or
   source ~/.zshrc
   ```

2. **Test Commands** - Before committing in tmux:
   ```bash
   command --help
   man command
   ```

3. **Fuzzy Everything** - Most dotfiles tools work with fzf:
   ```bash
   pwf          # Fuzzy password
   sshf         # Fuzzy SSH
   twf          # Fuzzy tmux
   ```

4. **Check Health Regularly**:
   ```bash
   dfd          # Weekly health check
   ```

5. **Keep Vault Safe**:
   ```bash
   vault list
   vault export ~/backup.enc
   # Store backup.enc safely
   ```

---

**Last Updated:** 2025-12-21  
**Version:** 3.0.0  
**Platform:** Arch/CachyOS
