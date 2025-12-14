# ADLee's Dotfiles

> Personal configuration files and automation scripts for a powerful, consistent development environment across Linux/macOS systems.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![Maintained](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/adlee-was-taken/dotfiles/graphs/commit-activity)

## 📸 Preview

```
┌[alee@hostname]─[~/projects/dotfiles ⎇ main *]
└%
```

## ✨ Features

### 🎨 Custom Zsh Theme
- **adlee.zsh-theme** - A feature-rich, performant zsh theme
  - Git branch/status integration with visual indicators
  - Command execution timer (shows time for commands > 10s)
  - Smart path truncation for long directories
  - User/root detection (blue prompt for users, red for root)
  - Clean, minimal design that's easy to read

### ⌨️ Espanso Text Expansion
- **100+ pre-configured snippets** using `..trigger` syntax
  - Date/time stamps (UTC, local, ISO 8601)
  - Git shortcuts (`..gst`, `..gco`, `..gcm`)
  - Docker commands (`..dps`, `..dcup`, `..dlog`)
  - Code templates (bash, python, markdown)
  - System info (`..ip`, `..user`, `..branch`)
  - Common typo corrections
  - Personal information templates

### 🛠️ Modern CLI Tools
- **fzf** - Fuzzy finder for files and history
- **bat** - Syntax-highlighted file viewer
- **eza** - Modern ls replacement with icons
- **espanso** - Universal text expander

### 🔄 Easy Deployment
- **One-command installation** on new systems
- **Automated backups** of existing configs
- **System-wide theme deployment** for all users
- **Modular architecture** for easy customization

## 📁 Repository Structure

```
dotfiles/
├── install.sh                      # Main installation script
├── README.md                       # This file
├── LICENSE                         # MIT License
├── .gitignore                      # Git ignore rules
│
├── zsh/
│   ├── .zshrc                      # Main zsh configuration
│   └── themes/
│       └── adlee.zsh-theme         # Custom zsh theme
│
├── espanso/
│   ├── config/
│   │   └── default.yml             # Espanso settings
│   └── match/
│       ├── base.yml                # Base snippets (100+ triggers)
│       └── personal.yml            # Personal info snippets
│
├── git/
│   ├── .gitconfig                  # Git configuration
│   └── .gitignore_global           # Global gitignore patterns
│
├── vim/
│   └── .vimrc                      # Vim configuration
│
├── tmux/
│   └── .tmux.conf                  # Tmux configuration
│
├── bin/
│   ├── update-dotfiles             # Update from repo
│   ├── setup-espanso.sh            # Espanso setup wizard
│   └── deploy-zshtheme-systemwide.sh  # System-wide deployment
│
└── docs/
    ├── SETUP_GUIDE.md              # Detailed setup instructions
    └── ESPANSO.md                  # Espanso reference guide
```

## 🚀 Quick Start

### Option 1: One-Line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main/install.sh | bash
```

### Option 2: Manual Install

```bash
# Clone the repository
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer
./install.sh
```

### What Gets Installed?

The installer will:
1. ✅ Detect your OS (Ubuntu, Arch, Fedora, macOS)
2. ✅ Install dependencies (git, curl, zsh)
3. ✅ Backup existing configs to `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`
4. ✅ Install oh-my-zsh
5. ✅ Create symlinks to dotfiles
6. ✅ Optionally install espanso, fzf, bat, eza
7. ✅ Set zsh as default shell

## ⚙️ Post-Installation

### Set Up Espanso

Personalize your text expansion snippets:

```bash
cd ~/.dotfiles
./bin/setup-espanso.sh
```

This wizard will:
- Update `personal.yml` with your name, email, etc.
- Install optional espanso packages (emoji, math symbols)
- Show you useful triggers and tips

### Test Espanso

Try typing these anywhere:
- `..date` → 2024-12-13
- `..time` → 14:30:45
- `..ip` → Your public IP
- `..shrug` → ¯\\\_(ツ)_/¯

Toggle espanso: `ALT+SHIFT+E`  
Search snippets: `ALT+SPACE`

### Deploy Theme System-Wide (Optional)

To share the theme across all users on your system:

```bash
cd ~/.dotfiles
sudo ./bin/deploy-zshtheme-systemwide.sh --all
```

Options:
- `--all` - Deploy to all users with oh-my-zsh
- `--current` - Deploy to current user + root only
- `--status` - Show deployment status
- `--force` - Force replace existing links

## 🔄 Updating

### Update Dotfiles from GitHub

```bash
cd ~/.dotfiles
git pull origin main
./install.sh  # Re-link updated files
```

Or use the helper script:

```bash
update-dotfiles
```

### Push Changes to GitHub

```bash
cd ~/.dotfiles
git add .
git commit -m "Update theme colors"
git push origin main
```

## 🎨 Customization

### Modify the Zsh Theme

```bash
vim ~/.dotfiles/zsh/themes/adlee.zsh-theme
source ~/.zshrc  # Test changes
```

### Add Custom Aliases

Edit `~/.dotfiles/zsh/.zshrc` and add to the aliases section:

```bash
# Custom aliases
alias projects='cd ~/projects'
alias dc='docker-compose'
```

### Add Espanso Snippets

Edit `~/.dotfiles/espanso/match/base.yml`:

```yaml
matches:
  - trigger: "..myproject"
    replace: "cd ~/projects/my-awesome-project"
```

Then restart espanso:
```bash
espanso restart
```

## 📚 Documentation

- **[SETUP_GUIDE.md](docs/SETUP_GUIDE.md)** - Detailed setup instructions
- **[ESPANSO.md](docs/ESPANSO.md)** - Complete espanso reference
- **[Zsh Theme Variables](zsh/themes/adlee.zsh-theme)** - Customize colors and format

## 🌟 Espanso Quick Reference

### Date & Time
| Trigger | Output |
|---------|--------|
| `..date` | 2024-12-13 |
| `..time` | 14:30:45 |
| `..ts` | 2024-12-13T14:30:45.123Z |
| `..epoch` | 1702476645 |

### Git Shortcuts
| Trigger | Output |
|---------|--------|
| `..gst` | `git status` |
| `..gco` | `git checkout ` |
| `..gcm` | `git commit -m ""` |
| `..branch` | Current git branch name |

### System Info
| Trigger | Output |
|---------|--------|
| `..user` | Current username |
| `..host` | Hostname |
| `..ip` | Public IP address |
| `..pwd` | Current directory |

### Emoticons
| Trigger | Output |
|---------|--------|
| `..shrug` | ¯\\\_(ツ)_/¯ |
| `..flip` | (╯°□°)╯︵ ┻━┻ |
| `..check` | ✓ |

[See full list in ESPANSO.md](docs/ESPANSO.md)

## 🖥️ Multi-System Setup

### Deploy to New System

```bash
# On the new system
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Sync Changes Between Systems

```bash
# On system A (make changes)
cd ~/.dotfiles
git add .
git commit -m "Update aliases"
git push

# On system B (pull changes)
cd ~/.dotfiles
git pull
source ~/.zshrc
```

## 🔧 Troubleshooting

### Theme Not Loading

Ensure `ZSH_THEME="adlee"` in `~/.zshrc`:
```bash
grep ZSH_THEME ~/.zshrc
```

Then reload:
```bash
source ~/.zshrc
```

### Espanso Not Expanding

Check if espanso is running:
```bash
espanso status
```

If not running:
```bash
espanso service start
```

View logs:
```bash
espanso log
```

### Symlinks Broken

Remove broken symlinks:
```bash
find ~ -maxdepth 1 -type l -xtype l -delete
```

Re-run installation:
```bash
cd ~/.dotfiles && ./install.sh
```

### Permission Errors

Make scripts executable:
```bash
chmod +x ~/.dotfiles/install.sh
chmod +x ~/.dotfiles/bin/*
```

## 🤝 Contributing

This is a personal dotfiles repository, but suggestions and improvements are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -m 'Add some improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [oh-my-zsh](https://ohmyz.sh/) - Zsh configuration framework
- [espanso](https://espanso.org/) - Text expander
- [vimrc](https://github.com/amix/vimrc) - Ultimate virmrc by amix
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [bat](https://github.com/sharkdp/bat) - Cat clone with syntax highlighting
- [eza](https://github.com/eza-community/eza) - Modern ls replacement

## Resources

- [Arch Linux Wiki: Dotfiles](https://wiki.archlinux.org/title/Dotfiles)
- [GitHub: Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
- [Espanso Hub](https://hub.espanso.org/)

---

**Author**: Aaron D. Lee  
**Repository**: https://github.com/adlee-was-taken/dotfiles  
**Last Updated**: 2024-12-13

If you find this useful, consider giving it a star!# dotfiles
Aaron D. Lee's dotfiles for Linux/MacOs
