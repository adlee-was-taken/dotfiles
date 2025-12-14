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
5. Creates symlinks
6. Optionally installs espanso, fzf, bat, eza
7. Sets zsh as default shell

## Post-Install

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

### Theme Not Loading

```bash
grep ZSH_THEME ~/.zshrc  # Should show: ZSH_THEME="adlee"
source ~/.zshrc
```

### Espanso Not Expanding

```bash
espanso status    # Should show "running"
espanso restart
espanso log       # Check for errors
```

### Broken Symlinks

```bash
# Find broken symlinks in home
find ~ -maxdepth 1 -type l -xtype l

# Re-run installer
cd ~/.dotfiles && ./install.sh
```

### Permission Errors

```bash
chmod +x ~/.dotfiles/install.sh
chmod +x ~/.dotfiles/bin/*
```

## Security Notes

- `.gitignore` excludes `.env`, `secrets/`, and `*.local` files
- Review `git/.gitconfig` before pushing (contains email)
- Personal espanso snippets may contain sensitive info

## Uninstalling

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
