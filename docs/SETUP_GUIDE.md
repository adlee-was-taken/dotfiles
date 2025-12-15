# Setup Guide

Complete guide for installing, configuring, and maintaining your dotfiles.

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
- Git
- Curl
- Zsh (installed automatically if missing)

**Optional (for full features):**
- `fzf` - For command palette and fuzzy finding
- `age` or `gpg` - For secrets vault
- `gum` - For beautiful setup wizard

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
curl -fsSL https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main/install.sh | bash
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
./install.sh --deps-only        # Only install dependencies
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

### 3. Personalize Espanso (Optional)

```bash
setup-espanso.sh
```

This sets up your personal info for text expansion (email, name, signatures).

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
GIT_CREDENTIAL_HELPER="store"

# ============================================================================
# Feature Toggles
# ============================================================================
# Values: "true", "false", or "ask"

INSTALL_DEPS="auto"           # Auto-skip if already installed
INSTALL_ZSH_PLUGINS="true"    # zsh-autosuggestions, syntax-highlighting
INSTALL_FZF="ask"
INSTALL_BAT="ask"
INSTALL_EZA="ask"
INSTALL_ESPANSO="ask"
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
shell-stats.sh            # Full dashboard
shell-stats.sh --top 20   # Top 20 commands
shell-stats.sh --suggest  # Alias recommendations
shell-stats.sh --heatmap  # Activity by hour
shell-stats.sh --dirs     # Most visited directories
shell-stats.sh --git      # Git command breakdown
shell-stats.sh --docker   # Docker command breakdown
shell-stats.sh --export   # Export as JSON
```

### Secrets Vault

Encrypted storage using `age` or `gpg`:

```bash
vault set KEY "value"     # Store (or prompt for value)
vault get KEY             # Retrieve
vault list                # Show all keys
vault delete KEY          # Remove
vault shell               # Print as export statements
vault export backup.enc   # Backup encrypted vault
vault import backup.enc   # Restore vault
vault status              # Show vault info
```

**Auto-loading:** Secrets are automatically loaded into your environment on shell start.

### Dotfiles Sync

```bash
dotfiles-sync.sh              # Interactive sync
dotfiles-sync.sh --status     # Show sync status
dotfiles-sync.sh --push       # Push local changes
dotfiles-sync.sh --pull       # Pull remote changes
dotfiles-sync.sh --diff       # Show local changes
dotfiles-sync.sh --watch 300  # Auto-sync every 5 minutes
dotfiles-sync.sh --log        # Show sync history
```

**Auto-check:** On shell start, you'll be notified of available updates.

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
export CORP_PROXY="http://proxy:8080"
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
| Zsh plugins missing | Run `./install.sh` (auto-installs plugins now) |
| Command palette not working | Install fzf: `./install.sh` will prompt |
| Vault errors | Install age: `brew install age` or `pacman -S age` |
| Espanso not expanding | Run `espanso status`, then `espanso restart` |
| Sync conflicts | Run `dotfiles-sync.sh --conflicts` to see conflicts |
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
shell-stats.sh --help
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
rm ~/.zshrc ~/.gitconfig ~/.vimrc ~/.tmux.conf
rm ~/.oh-my-zsh/themes/adlee.zsh-theme
rm -rf ~/.config/espanso
rm ~/.local/bin/dotfiles-*.sh ~/.local/bin/vault.sh ~/.local/bin/shell-stats.sh

# Restore backups (if any)
ls ~/.dotfiles_backup_*

# Remove dotfiles
rm -rf ~/.dotfiles

# Optional: Remove oh-my-zsh
rm -rf ~/.oh-my-zsh

# Change shell back to bash
chsh -s /bin/bash
```

---

## File Reference

### Symlinks Created

| Source | Target |
|--------|--------|
| `~/.dotfiles/zsh/.zshrc` | `~/.zshrc` |
| `~/.dotfiles/zsh/themes/adlee.zsh-theme` | `~/.oh-my-zsh/themes/adlee.zsh-theme` |
| `~/.dotfiles/git/.gitconfig` | `~/.gitconfig` |
| `~/.dotfiles/vim/.vimrc` | `~/.vimrc` |
| `~/.dotfiles/tmux/.tmux.conf` | `~/.tmux.conf` |
| `~/.dotfiles/espanso/` | `~/.config/espanso` |
| `~/.dotfiles/bin/*` | `~/.local/bin/*` |

### Key Files

| File | Purpose |
|------|---------|
| `dotfiles.conf` | Central configuration |
| `zsh/.zshrc` | Main shell config |
| `zsh/themes/adlee.zsh-theme` | Prompt theme |
| `zsh/functions/smart-suggest.zsh` | Typo correction |
| `zsh/functions/command-palette.zsh` | Fuzzy launcher |
| `espanso/match/base.yml` | Text expansion snippets |
| `espanso/match/personal.yml` | Personal snippets |
| `vault/` | Encrypted secrets (gitignored) |

---

## Security Notes

- `.gitignore` excludes sensitive files (`.env`, `secrets/`, `*.local`, `vault/`)
- Vault uses strong encryption (age/gpg)
- Never commit API keys or tokens
- Review `git/.gitconfig` before pushing (contains email)
- Personal espanso snippets may contain sensitive info
