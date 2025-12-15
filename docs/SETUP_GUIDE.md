# Setup Guide

Step-by-step instructions for setting up and maintaining your dotfiles.

## Prerequisites

- Git
- Curl
- Zsh (will be installed if missing)

## Fresh Install

### Option 1: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main/install.sh | bash
```

### Option 2: Clone First

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### What the Installer Does

1. Detects OS (Ubuntu, Arch, Fedora, macOS)
2. Installs dependencies (git, curl, zsh)
3. Backs up existing configs to `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`
4. Installs oh-my-zsh
5. Installs zsh plugins (autosuggestions, syntax-highlighting)
6. Configures git (prompts for name/email if not in config)
7. Creates symlinks
8. Optionally installs espanso, fzf, bat, eza
9. Sets zsh as default shell

### Install Options

```bash
./install.sh                # Full interactive install
./install.sh --skip-deps    # Skip dependency check (for re-runs)
./install.sh --deps-only    # Only install dependencies
./install.sh --uninstall    # Remove symlinks, offer to restore backups
./install.sh --uninstall --purge  # Also remove ~/.dotfiles
./install.sh --help         # Show all options
```

## Post-Install

### Verify Installation

```bash
dotfiles-doctor.sh          # Check health of installation
dotfiles-doctor.sh --fix    # Attempt to fix issues
```

### Check Version

```bash
dotfiles-version.sh         # Show local vs remote version
dotfiles-version.sh --check # Exit 1 if updates available
```

### Personalize Espanso

```bash
./bin/setup-espanso.sh
```

Updates `personal.yml` with your name, email, etc.

### Test It

```bash
source ~/.zshrc           # Reload shell
echo "..date" | espanso   # Test espanso (or just type ..date anywhere)
```

### Install Zsh Plugins (if missing)

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

## Updating

```bash
cd ~/.dotfiles
git pull origin main
./install.sh
source ~/.zshrc
```

Or use the helper:

```bash
update-dotfiles.sh
```

## Pushing Changes

```bash
cd ~/.dotfiles
git add .
git commit -m "Update aliases"
git push origin main
```

## Multi-Machine Sync

```bash
# Machine A: push changes
cd ~/.dotfiles && git add . && git commit -m "Update" && git push

# Machine B: pull changes
cd ~/.dotfiles && git pull && source ~/.zshrc
```

## File Structure

| Path | Purpose |
|------|---------|
| `zsh/.zshrc` | Main shell config |
| `zsh/themes/adlee.zsh-theme` | Prompt theme |
| `zsh/functions/snapper.zsh` | Btrfs snapshot helpers |
| `espanso/match/base.yml` | Text snippets |
| `espanso/match/personal.yml` | Your personal info |
| `git/.gitconfig` | Git settings |
| `vim/.vimrc` | Vim config |
| `tmux/.tmux.conf` | Tmux config |
| `bin/` | Utility scripts |

## Symlinks Created

| Source | Target |
|--------|--------|
| `~/.dotfiles/zsh/.zshrc` | `~/.zshrc` |
| `~/.dotfiles/zsh/themes/adlee.zsh-theme` | `~/.oh-my-zsh/themes/adlee.zsh-theme` |
| `~/.dotfiles/git/.gitconfig` | `~/.gitconfig` |
| `~/.dotfiles/vim/.vimrc` | `~/.vimrc` |
| `~/.dotfiles/tmux/.tmux.conf` | `~/.tmux.conf` |
| `~/.dotfiles/espanso/` | `~/.config/espanso` |

## System-Wide Theme

Deploy to all users on a system:

```bash
# Interactive
sudo ./bin/deploy-zshtheme-systemwide.sh

# All users with oh-my-zsh
sudo ./bin/deploy-zshtheme-systemwide.sh --all

# Current user + root only
sudo ./bin/deploy-zshtheme-systemwide.sh --current

# Check status
sudo ./bin/deploy-zshtheme-systemwide.sh --status
```

Creates symlinks from each user's oh-my-zsh themes folder to `/usr/local/share/zsh/themes/adlee.zsh-theme`.

## Configuration

### dotfiles.conf

The main configuration file. Edit to customize your installation:

```bash
# --- Version ---
DOTFILES_VERSION="1.0.0"

# --- User Identity ---
USER_FULLNAME="Your Name"
USER_EMAIL="you@example.com"
USER_GITHUB="yourusername"

# --- Git Configuration ---
GIT_USER_NAME=""           # Falls back to USER_FULLNAME
GIT_USER_EMAIL=""          # Falls back to USER_EMAIL
GIT_DEFAULT_BRANCH="main"
GIT_CREDENTIAL_HELPER="store"

# --- Feature Toggles ---
INSTALL_DEPS="auto"        # "auto", "true", "false", or "ask"
INSTALL_ZSH_PLUGINS="true" # Auto-install zsh plugins
INSTALL_ESPANSO="ask"
INSTALL_FZF="ask"
INSTALL_BAT="ask"
INSTALL_EZA="ask"
SET_ZSH_DEFAULT="ask"
```

### Git Identity

The installer configures git automatically:

1. Uses `GIT_USER_NAME` / `GIT_USER_EMAIL` from config
2. Falls back to `USER_FULLNAME` / `USER_EMAIL`
3. Prompts if both are empty

To reconfigure git later:

```bash
git config --global user.name "New Name"
git config --global user.email "new@email.com"
```

Or edit `dotfiles.conf` and re-run `./install.sh`.

## Customization Tips

### Add Aliases

Edit `~/.dotfiles/zsh/.zshrc`:

```bash
alias projects='cd ~/projects'
alias k='kubectl'
```

### Machine-Specific Config

Create `~/.zshrc.local` (not tracked by git):

```bash
# Work machine specific
export WORK_API_KEY="xxx"
alias vpn='sudo openconnect ...'
```

### Theme Colors

Edit `~/.dotfiles/zsh/themes/adlee.zsh-theme` and look for:

```zsh
typeset -g COLOR_GREEN='%{$FG[118]%}'
typeset -g COLOR_BLUE='%{$FG[069]%}'
```

## Troubleshooting

### Run the Doctor

```bash
dotfiles-doctor.sh          # Diagnose issues
dotfiles-doctor.sh --fix    # Auto-fix what's possible
```

### Common Issues

| Issue | Fix |
|-------|-----|
| Theme not loading | `dotfiles-doctor.sh --fix` |
| Zsh plugins missing | `./install.sh` (auto-installs) |
| Espanso not expanding | `espanso restart` |
| Git identity not set | Re-run `./install.sh` |
| Broken symlinks | `./install.sh` |

### Manual Fixes

```bash
# Reinstall zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Fix permissions
chmod +x ~/.dotfiles/install.sh
chmod +x ~/.dotfiles/bin/*
```

## Uninstalling

### Quick Uninstall

```bash
./install.sh --uninstall           # Remove symlinks, offer backup restore
./install.sh --uninstall --purge   # Also delete ~/.dotfiles
```

### Manual Uninstall

```bash
# Remove symlinks
rm ~/.zshrc ~/.gitconfig ~/.vimrc ~/.tmux.conf
rm ~/.oh-my-zsh/themes/adlee.zsh-theme
rm -rf ~/.config/espanso

# Restore backups
cp ~/.dotfiles_backup_*/.zshrc ~/ 

# Remove dotfiles
rm -rf ~/.dotfiles
```
