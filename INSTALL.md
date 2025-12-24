# Installation Guide

Complete installation guide for ADLee's Dotfiles on Arch Linux and CachyOS.

## Table of Contents

- [Requirements](#requirements)
- [Quick Install](#quick-install)
- [Step-by-Step Installation](#step-by-step-installation)
- [Post-Installation](#post-installation)
- [Optional Tools](#optional-tools)
- [Customization](#customization)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [Troubleshooting](#troubleshooting)

---

## Requirements

### Operating System

- **Arch Linux** or **CachyOS** (other Arch-based distros may work but are untested)

### Required Packages

These are installed automatically by `install.sh`:

| Package | Purpose |
|---------|---------|
| `git` | Version control |
| `curl` | HTTP requests |
| `zsh` | Shell |

### Recommended Packages

| Package | Purpose | Install |
|---------|---------|---------|
| `fzf` | Fuzzy finder (command palette) | `sudo pacman -S fzf` |
| `bat` | Better cat with syntax highlighting | `sudo pacman -S bat` |
| `eza` | Modern ls replacement | `sudo pacman -S eza` |
| `tmux` | Terminal multiplexer | `sudo pacman -S tmux` |
| `neovim` | Modern vim | `sudo pacman -S neovim` |

### For Full Functionality

| Package | Purpose | Install |
|---------|---------|---------|
| `age` or `gpg` | Vault encryption | `sudo pacman -S age` |
| `lastpass-cli` | Password manager | `paru -S lastpass-cli` |
| `snapper` | Btrfs snapshots | `sudo pacman -S snapper` |
| `limine-snapper-sync` | Boot menu sync | `paru -S limine-snapper-sync` |
| `compsize` | Btrfs compression stats | `sudo pacman -S compsize` |
| `gum` | Interactive wizard | `sudo pacman -S gum` |

---

## Quick Install

### One-Liner

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh
```

### With Interactive Wizard

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --wizard
```

---

## Step-by-Step Installation

### 1. Clone the Repository

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Review Configuration (Optional)

Edit `dotfiles.conf` before installing to customize:

```bash
vim dotfiles.conf
```

Key settings to review:

```bash
# Your identity
USER_FULLNAME="Your Name"
USER_EMAIL="you@example.com"
USER_GITHUB="yourusername"

# Feature toggles
INSTALL_FZF="ask"        # true, false, or ask
INSTALL_BAT="ask"
INSTALL_EZA="ask"
INSTALL_NEOVIM="ask"
SET_ZSH_DEFAULT="ask"

# MOTD style
MOTD_STYLE="compact"     # compact, mini, full, or none
```

### 3. Run the Installer

```bash
./install.sh
```

The installer will:

1. Detect your OS (Arch/CachyOS only)
2. Install core dependencies (git, curl, zsh)
3. Backup existing configuration files
4. Install Oh-My-Zsh
5. Install zsh plugins (autosuggestions, syntax-highlighting)
6. Configure git (prompts for name/email if not set)
7. Create symlinks for all dotfiles
8. Optionally set zsh as default shell
9. Offer to install optional tools

### 4. Restart Your Terminal

```bash
exec zsh
```

Or simply close and reopen your terminal.

---

## Post-Installation

### Verify Installation

```bash
dfd    # or: dotfiles-doctor.sh
```

This runs a health check and reports any issues.

### Fix Any Issues

```bash
dffix  # or: dotfiles-doctor.sh --fix
```

### Initialize the Secrets Vault

If you plan to use the vault for storing API keys:

```bash
vault init
```

### Set Up LastPass (Optional)

```bash
# Install
paru -S lastpass-cli

# Login
lpass login your@email.com

# Test
pw list
```

### Configure Snapper (CachyOS/Btrfs)

If using btrfs with snapshots:

```bash
# Install snapper
sudo pacman -S snapper

# Create config for root
sudo snapper -c root create-config /

# Install limine sync (if using limine bootloader)
paru -S limine-snapper-sync
sudo systemctl enable limine-snapper-sync.service

# Verify
snap-validate-service
```

---

## Optional Tools

### AUR Helper

If you don't have an AUR helper:

```bash
# Install paru (recommended)
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si
```

### Recommended Tool Installation

```bash
# All recommended tools at once
sudo pacman -S fzf bat eza tmux neovim fd ripgrep

# AUR packages
paru -S lastpass-cli glow
```

### Espanso (Text Expansion)

```bash
# Install
paru -S espanso-wayland  # or espanso-x11 for X11

# Start service
espanso service start

# Link config
ln -sf ~/.dotfiles/espanso ~/.config/espanso

# Personalize
./setup/setup-espanso.sh
```

---

## Customization

### Local Overrides

Create `~/.zshrc.local` for machine-specific settings that won't be synced:

```bash
# ~/.zshrc.local

# Machine-specific aliases
alias proj='cd ~/my-local-project'

# Local environment variables
export MY_LOCAL_VAR="value"

# Override settings
MOTD_STYLE="mini"
```

### Adding Custom Functions

Add `.zsh` files to `~/.dotfiles/zsh/functions/` – they're auto-loaded.

### Custom Tmux Templates

Add templates to `~/.dotfiles/.tmux-templates/`:

```bash
# ~/.dotfiles/.tmux-templates/mytemplate.tmux
# My custom layout
split-window -h -p 40
split-window -v -p 30
select-pane -t 0
```

Use with: `tw-create myproject mytemplate`

### Custom Bookmarks

```bash
bookmark work ~/projects/work
bookmark docs ~/Documents
j work    # jump to bookmark
```

---

## Updating

### Update Dotfiles

```bash
dfu    # or: dotfiles-update.sh
```

This will:
1. Pull latest changes from git
2. Optionally re-run the installer to update symlinks

### Check for Updates

```bash
dfv    # or: dotfiles-version.sh
```

### Sync Across Machines

```bash
# Push local changes
dfpush "Updated aliases"

# Pull remote changes
dfpull

# Check sync status
dfs
```

---

## Uninstalling

### Remove Symlinks Only

```bash
./install.sh --uninstall
```

This will:
1. Remove all symlinks created by the installer
2. Offer to restore backed-up files

### Complete Removal

```bash
./install.sh --uninstall --purge
```

This will:
1. Remove all symlinks
2. Offer to restore backups
3. Delete the `~/.dotfiles` directory

### Manual Cleanup

If needed, manually remove:

```bash
rm -rf ~/.dotfiles
rm -f ~/.zshrc ~/.gitconfig ~/.vimrc ~/.tmux.conf
rm -rf ~/.config/nvim
rm -f ~/.local/bin/dotfiles-*
```

---

## Troubleshooting

### Command Not Found

If dotfiles commands aren't available:

```bash
# Ensure PATH includes ~/.local/bin
echo $PATH | grep -q ".local/bin" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc.local

# Reload
source ~/.zshrc
```

### Oh-My-Zsh Issues

```bash
# Reinstall Oh-My-Zsh
rm -rf ~/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Reinstall plugins
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

### Broken Symlinks

```bash
# Check for broken symlinks
dfd

# Fix automatically
dffix
```

### MOTD Not Showing

Check configuration:

```bash
# In dotfiles.conf
ENABLE_MOTD="true"
MOTD_STYLE="compact"

# Force show
motd --force
```

### Slow Shell Startup

Compile zsh files for faster loading:

```bash
dfcompile
```

Profile startup time:

```bash
# Add to top of ~/.zshrc
zmodload zsh/zprof

# At bottom of ~/.zshrc
zprof

# Then start new shell and review output
```

### Git Configuration Issues

```bash
# Check current config
git config --global --list

# Set manually
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### FZF Not Working

```bash
# Verify installation
which fzf

# Check if sourced correctly
[[ -d "$HOME/.fzf" || -f "/usr/share/fzf/key-bindings.zsh" ]] && echo "FZF available"

# Source manually if needed
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
```

### Permission Denied on Scripts

```bash
# Fix permissions
chmod +x ~/.dotfiles/install.sh
chmod +x ~/.dotfiles/bin/*.sh
```

Or use:

```bash
dffix
```

---

## Install Options Reference

```bash
./install.sh [OPTIONS]

Options:
  (none)         Standard installation
  --wizard       Interactive TUI wizard
  --skip-deps    Skip dependency installation
  --deps-only    Only install dependencies
  --uninstall    Remove symlinks
  --purge        With --uninstall, also remove ~/.dotfiles
  --help         Show help
```

---

## Getting Help

```bash
# Dotfiles health check
dfd

# Version and update info
dfv

# Command help
dotfiles-cli help
```

For issues, check the [GitHub repository](https://github.com/adlee-was-taken/dotfiles).
