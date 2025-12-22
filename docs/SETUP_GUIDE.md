# Setup Guide

Complete guide for installing, configuring, and maintaining your Arch/CachyOS dotfiles.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Post-Install Setup](#post-install-setup)
- [Configuration](#configuration)
- [Features Guide](#features-guide)
- [Customization](#customization)
- [Multi-Machine Setup](#multi-machine-setup)
- [Troubleshooting](#troubleshooting)
- [Uninstalling](#uninstalling)

---

## Prerequisites

**Required:**
- Arch Linux or CachyOS
- Git
- Curl
- Pacman (built-in)

**Optional (for full features):**
- `fzf` - For command palette and fuzzy finding
- `age` or `gpg` - For secrets vault
- `lastpass-cli` - For password manager integration
- `nvim` - For Neovim support (Vim is sufficient)

---

## Installation Methods

### Method 1: Interactive Wizard (Recommended)

The wizard provides a beautiful TUI to customize your installation:

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --wizard
```

The wizard will guide you through:
1. Identity setup (name, email, GitHub)
2. Git configuration
3. Feature selection
4. Theme choice
5. Advanced options

### Method 2: One-liner

Quick install with defaults:

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh
```

### Method 3: Standard Install

Clone and run with prompts:

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Install Options

```bash
./install.sh                    # Interactive install
./install.sh --wizard           # TUI wizard
./install.sh --skip-deps        # Skip dependency installation
./install.sh --deps-only        # Only install dependencies, then exit
./install.sh --uninstall        # Remove symlinks
./install.sh --uninstall --purge # Remove everything
./install.sh --help             # Show all options
```

---

## Post-Install Setup

### 1. Verify Installation

```bash
dotfiles-doctor.sh
```

This checks:
- All symlinks are valid
- Zsh plugins installed
- Git configured
- Theme loaded
- Optional tools present

Fix issues automatically:

```bash
dotfiles-doctor.sh --fix
```

### 2. Restart Shell

```bash
exec zsh
# or just close and reopen your terminal
```

### 3. Configure LastPass (Optional)

```bash
pw list
# First run will prompt you to login
# Enter your LastPass email and master password
```

### 4. Set Up Secrets Vault (Optional)

```bash
vault init
vault set GITHUB_TOKEN "your-token-here"
vault list
```

### 5. Configure Directory Bookmarks (Optional)

```bash
bookmark projects ~/projects
bookmark work ~/work
bookmark list
```

---

## Configuration

### Main Configuration File

All settings are in `~/.dotfiles/dotfiles.conf`:

```bash
# ============================================================================
# Identity
# ============================================================================
USER_FULLNAME="Your Name"
USER_EMAIL="you@example.com"
USER_GITHUB="yourusername"

# ============================================================================
# Git Configuration
# ============================================================================
GIT_USER_NAME=""              # Falls back to USER_FULLNAME
GIT_USER_EMAIL=""             # Falls back to USER_EMAIL
GIT_DEFAULT_BRANCH="main"

# ============================================================================
# Feature Toggles
# ============================================================================
# Values: "true", "false", or "ask"

INSTALL_DEPS="auto"           # Auto-skip if already installed
INSTALL_ZSH_PLUGINS="true"    # zsh-autosuggestions, syntax-highlighting
INSTALL_FZF="ask"
INSTALL_BAT="ask"
INSTALL_EZA="ask"
INSTALL_NEOVIM="ask"
SET_ZSH_DEFAULT="ask"

# ============================================================================
# Advanced Features
# ============================================================================
ENABLE_SMART_SUGGESTIONS="true"   # Typo correction
ENABLE_COMMAND_PALETTE="true"     # Ctrl+Space launcher
ENABLE_SHELL_ANALYTICS="false"    # Command stats
ENABLE_VAULT="true"               # Encrypted secrets
DOTFILES_AUTO_SYNC_CHECK="true"   # Check for updates on shell start
```

### Applying Configuration Changes

After editing `dotfiles.conf`:

```bash
./install.sh --skip-deps
# or just
source ~/.zshrc
```

---

## Features Guide

### Command Palette

**Trigger:** `Ctrl+Space` or `Ctrl+P`

The command palette searches:
- ⚡ Aliases
- λ Functions
- ↺ Recent commands
- 📁 Bookmarked directories
- ⚙ Dotfiles scripts
- ★ Quick actions
- ⎇ Git commands (context-aware)
- ◉ Docker commands

**Keybindings in palette:**
| Key | Action |
|-----|--------|
| `Enter` | Execute command |
| `Ctrl+E` | Edit command first |
| `Ctrl+Y` | Copy to clipboard |
| `Ctrl+R` | Refresh entries |
| `Esc` | Cancel |

**Bookmarks:**

```bash
bookmark <name> [path]    # Save bookmark (default: current dir)
bookmark list             # List all bookmarks
bookmark delete <name>    # Remove bookmark
jump <name>               # Go to bookmark
j                         # Fuzzy select bookmark
```

### Smart Suggestions

Automatically corrects 100+ common typos:

```bash
gti → git
dokcer → docker
sl → ls
pytohn → python
```

Suggests aliases for frequently typed commands:

```bash
💡 You've typed 'git status' 50 times
   You already have an alias: gs
```

**Commands:**

```bash
fuck                      # Re-run last command with typo fixed
```

### Shell Analytics

```bash
dotfiles-stats.sh            # Full dashboard
dotfiles-stats.sh --top 20   # Top 20 commands
dotfiles-stats.sh --suggest  # Alias recommendations
dotfiles-stats.sh --heatmap  # Activity by hour
dotfiles-stats.sh --dirs     # Most visited directories
dotfiles-stats.sh --git      # Git command breakdown
dotfiles-stats.sh --export   # Export as JSON

# Aliases
dfstats                      # Full dashboard
stats                        # Full dashboard
tophist                      # Top commands
suggest                      # Alias suggestions
```

### Secrets Vault

Encrypted storage using `age` or `gpg`:

```bash
dotfiles-vault.sh set KEY "value"     # Store (or prompt for value)
dotfiles-vault.sh get KEY             # Retrieve
dotfiles-vault.sh list                # Show all keys
dotfiles-vault.sh delete KEY          # Remove
dotfiles-vault.sh shell               # Print as export statements
dotfiles-vault.sh export backup.enc   # Backup encrypted vault
dotfiles-vault.sh import backup.enc   # Restore vault
dotfiles-vault.sh status              # Show vault info

# Aliases
vault set KEY "value"
vault get KEY
vault list
vls                                   # vault list
vget KEY                              # vault get
vset KEY                              # vault set
```

**Auto-loading:** Secrets are automatically loaded into your environment on shell start.

### LastPass Integration

Unified interface for LastPass CLI:

```bash
pw list                    # List all items
pw get <item>              # Get password
pw get <item> username     # Get specific field
pw otp <item>              # Get TOTP/2FA code
pw copy <item>             # Copy password to clipboard
pw search <query>          # Search items
pw lock                    # Logout/lock session
pwf                        # Fuzzy search items, copy password (requires fzf)
pwof                       # Fuzzy search items, copy OTP (requires fzf)
```

**Install LastPass CLI:**

```bash
# Via AUR with paru (recommended)
paru -S lastpass-cli

# Or with yay
yay -S lastpass-cli
```

### Dotfiles Sync

```bash
dotfiles-sync.sh              # Interactive sync
dotfiles-sync.sh --status     # Show sync status
dotfiles-sync.sh --push       # Push local changes
dotfiles-sync.sh --pull       # Pull remote changes
dotfiles-sync.sh --diff       # Show local changes
dotfiles-sync.sh --watch 300  # Auto-sync every 5 minutes
dotfiles-sync.sh --log        # Show sync history

# Aliases
dfs                           # Interactive sync
dfsync                        # Interactive sync
dfpush                        # Push changes
dfpull                        # Pull changes
dfstatus                      # Show status
```

**Auto-check:** On shell start, you'll be notified of available updates.

### Dynamic MOTD

System information displayed on shell startup:

```
┌──────────────────────────────────────────────────────────────┐
│ ✦ user@hostname                              Mon Dec 15 14:30│
├──────────────────────────────────────────────────────────────┤
│ ▲ up:4d 7h   ◆ load:0.45     ◇ mem:8.2/32G   ⊡ 234G free  │
└──────────────────────────────────────────────────────────────┘
```

Shows: uptime, load average, memory, disk space

**Configuration:**

```bash
ENABLE_MOTD="true"         # Enable MOTD
MOTD_STYLE="compact"       # compact (box), mini (single line), or off
```

**Manual commands:**

```bash
show_motd                  # Show compact MOTD
show_motd_mini             # Show single-line MOTD
motd                       # Alias for show_motd
```

### Snapper Integration

Btrfs snapshot management for Arch/CachyOS with limine bootloader:

```bash
snap-create "Description"     # Create snapshot with validation
snap-list [n]                 # Show last n snapshots (default: 10)
snap-show <num>               # Details for specific snapshot
snap-delete <num>             # Delete snapshot + update limine
snap-check-limine             # Verify boot menu sync
snap-sync                     # Manually trigger sync
snap-info                     # Detailed breakdown by type
snap-validate-service         # Check service health
```

**Install limine-snapper-sync:**

```bash
paru -S limine-snapper-sync
sudo systemctl enable limine-snapper-sync.service
```

See [SNAPPER.md](docs/SNAPPER.md) for comprehensive guide.

### Tmux Workspace Manager

```bash
tw <name>                     # Quick attach or create workspace
tw-create <name> [template]   # Create from template
tw-list                       # List all workspaces
tw-delete <name>              # Delete workspace
tw-save <name>                # Save current layout as template
tw-sync                       # Toggle pane synchronization
twf                           # Fuzzy search workspaces
tw-templates                  # List available templates
```

**Available Templates:**
- `dev` - 3 panes: vim (50%), terminal (25%), logs (25%)
- `ops` - 4-pane monitoring grid
- `ssh-multi` - 4 panes for multi-server management
- `debug` - 2 panes: main (70%), helper (30%)
- `full` - Single full-screen pane
- `review` - Side-by-side comparison panes

See [SSH_TMUX_INTEGRATION.md](docs/SSH_TMUX_INTEGRATION.md) for advanced workflows.

### SSH Session Manager

```bash
ssh-save <name> <connection> [port] [key] [options] [description]
ssh-connect <name>            # Connect with auto-tmux
ssh-list                      # List all profiles
sshf                          # Fuzzy search and connect
ssh-delete <name>             # Delete profile
ssh-reconnect                 # Quick reconnect
ssh-sync-dotfiles <name>      # Deploy dotfiles to remote
```

---

## Customization

### Adding Aliases

Edit `~/.dotfiles/zsh/.zshrc`:

```bash
# Custom aliases
alias projects='cd ~/projects'
alias k='kubectl'
alias tf='terraform'
```

### Machine-Specific Config

Create `~/.zshrc.local` (not tracked by git):

```bash
# Work machine
export WORK_EMAIL="me@company.com"

# Local paths
export PATH="$HOME/work-tools/bin:$PATH"
```

### Custom Espanso Snippets

Edit `~/.dotfiles/espanso/match/personal.yml`:

```yaml
matches:
  - trigger: "..myemail"
    replace: "your.email@example.com"
  
  - trigger: "..sig"
    replace: |
      Best regards,
      Your Name
```

### Theme Customization

Edit `~/.dotfiles/zsh/themes/adlee.zsh-theme`:

```zsh
# Change colors
typeset -g COLOR_GREEN='%{$FG[118]%}'
typeset -g COLOR_BLUE='%{$FG[069]%}'

# Change timer threshold (seconds)
typeset -g TIMER_THRESHOLD=10
```

---

## Multi-Machine Setup

### Initial Setup on New Machine

```bash
# Clone your dotfiles
git clone https://github.com/YOUR_USER/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Syncing Changes

**On Machine A (make changes):**

```bash
cd ~/.dotfiles
# Edit files...
dotfiles-sync.sh --push "Added new aliases"
```

**On Machine B (get changes):**

```bash
dotfiles-sync.sh --pull
source ~/.zshrc
```

### Automatic Sync

Enable watch mode (runs in background):

```bash
dotfiles-sync.sh --watch 300  # Check every 5 minutes
```

Or add to crontab:

```bash
*/30 * * * * ~/.dotfiles/bin/dotfiles-sync.sh --auto
```

---

## Troubleshooting

### Run the Doctor First

```bash
dotfiles-doctor.sh --fix
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Theme not loading | Check `ZSH_THEME="adlee"` in .zshrc, run `source ~/.zshrc` |
| Zsh plugins missing | Run `./install.sh` (auto-installs plugins) |
| Command palette not working | Install fzf: `paru -S fzf` |
| Vault errors | Install age: `paru -S age` or gpg: `paru -S gnupg` |
| LastPass not working | Install: `paru -S lastpass-cli` |
| Snapper integration broken | Enable service: `sudo systemctl enable limine-snapper-sync.service` |
| Symlinks broken | Run `./install.sh --skip-deps` to recreate |

### Manual Fixes

**Reinstall zsh plugins:**

```bash
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
./install.sh --skip-deps
```

**Reset git config:**

```bash
rm ~/.gitconfig
./install.sh --skip-deps
```

**Fix permissions:**

```bash
chmod +x ~/.dotfiles/install.sh
chmod +x ~/.dotfiles/bin/*
```

### Getting Help

```bash
# Any script
<script> --help

# Examples
./install.sh --help
vault --help
dotfiles-sync.sh --help
dotfiles-stats.sh --help
```

---

## Uninstalling

### Quick Uninstall

```bash
./install.sh --uninstall
```

This will:
1. Remove all symlinks
2. Find and offer to restore backups
3. Keep ~/.dotfiles directory

### Complete Removal

```bash
./install.sh --uninstall --purge
```

This also removes the `~/.dotfiles` directory.

### Manual Uninstall

```bash
# Remove symlinks
rm ~/.zshrc ~/.gitconfig ~/.vimrc ~/.tmux.conf ~/.config/nvim
rm ~/.oh-my-zsh/themes/adlee.zsh-theme
rm ~/.local/bin/dotfiles-*.sh

# Restore backups (if any)
ls ~/.dotfiles_backup_*

# Remove dotfiles
rm -rf ~/.dotfiles

# Change shell back to bash
chsh -s /bin/bash
```

---

## Security Notes

- `.gitignore` excludes sensitive files (`.env`, `secrets/`, `*.local`, `vault/`)
- Vault uses strong encryption (age/gpg)
- Never commit API keys or tokens
- Personal espanso snippets may contain sensitive info
- Review `git/.gitconfig` before pushing (contains email)

---

## System Requirements Recap

| Component | Requirement |
|-----------|-------------|
| OS | Arch Linux or CachyOS |
| Shell | Zsh (auto-installed) |
| Package Manager | Pacman (built-in) |
| Editor | Vim (required) |
| Editor | Neovim (optional) |
| Password Manager | LastPass CLI (optional) |
| Encryption | age or gpg (optional, for vault) |

---

For more detailed guides, see:
- [SSH_TMUX_INTEGRATION.md](docs/SSH_TMUX_INTEGRATION.md) - SSH and Tmux integration
- [SNAPPER.md](docs/SNAPPER.md) - Btrfs snapshot management
- [ESPANSO.md](docs/ESPANSO.md) - Text expansion snippets
