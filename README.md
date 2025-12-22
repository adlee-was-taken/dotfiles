# ADLee's Dotfiles (Arch/CachyOS)

Personal configuration files for a fast, productive dev environment on **Arch Linux** and **CachyOS**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![OS](https://img.shields.io/badge/OS-Arch%2FCachyOS-blue.svg)](https://archlinux.org/)

```
┌[alee@battlestation]─[~/.dotfiles ⎇ main]
└%
```

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Setup Wizard** | Beautiful TUI installer with feature selection |
| **Dynamic MOTD** | System info on shell start (uptime, CPU, memory, updates) |
| **Zsh Theme** | Two-line prompt with git status, command timer, root detection |
| **Command Palette** | Raycast-style fuzzy launcher (Ctrl+Space) |
| **Smart Suggestions** | Typo correction + alias recommendations |
| **Shell Analytics** | Track command usage and get insights |
| **Secrets Vault** | Encrypted storage for API keys and sensitive data |
| **LastPass CLI** | Unified password manager integration |
| **Dotfiles Sync** | Keep configuration in sync across machines |
| **Snapper Integration** | Btrfs snapshot management with limine-snapper-sync |
| **Tmux Workspaces** | Project templates with pre-configured layouts |
| **SSH Manager** | Save and manage SSH connections with tmux integration |

## 🚀 Quick Start

### One-liner Install
```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh
```

### Interactive Wizard (Recommended)
```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --wizard
```

### Standard Install
```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## 📋 System Requirements

- **OS:** Arch Linux or CachyOS
- **Editors:** Vim (required), Neovim (optional)
- **Password Manager:** LastPass
- **Shell:** Zsh (installed by script)
- **Package Manager:** Pacman (built-in)

## 📁 Repository Layout

```
dotfiles/
├── install.sh                 # Main installer script
├── dotfiles.conf              # Central configuration
├── zsh/
│   ├── .zshrc                 # Shell configuration
│   ├── aliases.zsh            # Command aliases
│   ├── themes/adlee.zsh-theme # Prompt theme
│   └── functions/
│       ├── command-palette.zsh    # Ctrl+Space launcher
│       ├── motd.zsh               # System info display
│       ├── smart-suggest.zsh      # Typo correction
│       ├── password-manager.zsh   # LastPass integration
│       ├── snapper.zsh            # Btrfs snapshots
│       ├── ssh-manager.zsh        # SSH profiles
│       ├── tmux-workspaces.zsh    # Workspace templates
│       └── python-templates.zsh   # Python project scaffolding
├── vim/.vimrc                 # Vim configuration
├── nvim/                      # Neovim configuration
├── tmux/.tmux.conf           # Tmux configuration
├── git/.gitconfig.template   # Git configuration template
└── bin/                       # Scripts (symlinked to ~/.local/bin)
    ├── dotfiles-doctor.sh     # Health checker
    ├── dotfiles-sync.sh       # Multi-machine sync
    ├── dotfiles-stats.sh      # Shell analytics
    ├── dotfiles-update.sh     # Update dotfiles
    ├── dotfiles-vault.sh      # Encrypted secrets manager
    └── dotfiles-version.sh    # Version info
```

## 🎮 Command Palette

Press **Ctrl+Space** or **Ctrl+P** to open the fuzzy command launcher:

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

**Searches:** aliases, functions, recent commands, bookmarks, git commands, quick actions

**Keybindings:**
- `Enter` - Execute command
- `Ctrl+E` - Edit before running
- `Ctrl+Y` - Copy to clipboard

### Directory Bookmarks

```bash
bookmark projects ~/projects    # Save bookmark
bookmark list                   # List all
jump projects                   # Go to bookmark
j                               # Fuzzy select
```

## 🔧 Smart Suggestions

Automatic typo correction for 100+ common mistakes:

```bash
$ gti status
✗ Command not found: gti
→ Did you mean: git?

$ dokcer ps
✗ Command not found: dokcer
→ Did you mean: docker?
```

Alias recommendations for frequently typed commands:

```bash
💡 Tip: You've typed 'git status' 50 times
   Consider adding: alias gs='git status'
```

## 📊 Shell Analytics

```bash
dotfiles-stats.sh              # Full dashboard
# or use aliases:
dfstats
stats
```

```
╔═══════════════════════════════════════════════════════════════════╗
║  Shell Analytics Dashboard                                        ║
╠═══════════════════════════════════════════════════════════════════╣
║  Total commands:  4,832                                           ║
║  Unique commands: 847                                             ║
║                                                                   ║
║  Top Commands                                                     ║
║  git          847  ████████████████████████░░░░░░                 ║
║  cd           412  ████████████░░░░░░░░░░░░░░░░░░                 ║
║  ls           398  ███████████░░░░░░░░░░░░░░░░░░░                 ║
╚═══════════════════════════════════════════════════════════════════╝
```

## 🔐 Secrets Vault

Encrypted storage for API keys and tokens:

```bash
vault set GITHUB_TOKEN ghp_xxxxxxxxxxxx
vault set AWS_SECRET_KEY              # Prompts for hidden input
vault get GITHUB_TOKEN
vault list                            # Shows keys only
vault delete OLD_KEY
# Full command: dotfiles-vault.sh
```

Export to environment:

```bash
eval $(vault shell)                   # Load all secrets
```

Uses `age` or `gpg` encryption. Secrets auto-load on shell start.

## 🔑 Password Manager Integration

LastPass CLI for unified password management:

```bash
pw list                    # List all items
pw get github              # Get password
pw get github username     # Get specific field
pw otp github              # Get TOTP code
pw copy aws                # Copy password to clipboard
pw search mail             # Search items
pwf                        # Fuzzy search + copy (requires fzf)
```

### Install LastPass CLI

```bash
# Via AUR with paru (recommended)
paru -S lastpass-cli

# Or with yay
yay -S lastpass-cli
```

## 🖥️ Dynamic MOTD

System info displayed on shell startup:

```
┌──────────────────────────────────────────────────────────────┐
│ ✦ alee@battlestation                     Mon Dec 15 14:30   │
├──────────────────────────────────────────────────────────────┤
│ ▲ up:4d 7h   ◆ load:0.45     ◇ mem:8.2/32G   ⊡ 234G free  │
└──────────────────────────────────────────────────────────────┘
```

Shows: uptime, load average, memory usage, disk space

**Configuration:**
```bash
ENABLE_MOTD="true"         # Enable MOTD
MOTD_STYLE="compact"       # compact (box), mini (single line), or off
```

## 🎨 Zsh Theme

```
┌[user@hostname]─[~/projects ⎇ main *]
└%
```

**Features:**
- Two-line prompt for clarity
- Git integration (branch name with dirty indicator `*`)
- Command timer (shows elapsed time for commands >10s)
- Smart path truncation
- Root detection (red for root, blue for users)

## 🔄 Dotfiles Sync

Keep configuration synchronized across machines:

```bash
dotfiles-sync.sh              # Interactive sync
dotfiles-sync.sh --status     # Show sync status
dotfiles-sync.sh --push       # Push changes
dotfiles-sync.sh --pull       # Pull changes
dotfiles-sync.sh --watch 300  # Auto-sync every 5 min
```

On shell start, you'll see notifications of available updates.

## 📸 Snapper Integration

Btrfs snapshot management for Arch with limine bootloader:

```bash
snap-create "Before system update"    # Create snapshot
snap-list 20                           # List recent snapshots
snap-check-limine                      # Verify boot menu sync
snap-delete 42                         # Delete snapshot
snap-validate-service                  # Check service status
```

Auto-syncs with `limine-snapper-sync` for boot menu entries.

**Install on CachyOS/Arch:**
```bash
paru -S limine-snapper-sync
sudo systemctl enable limine-snapper-sync.service
```

## 🎯 Tmux Workspace Manager

Pre-configured layouts for different workflows:

```bash
tw-create myproject dev        # Create dev workspace
tw myproject                    # Quick attach or create
tw-list                         # List active workspaces
tw-save my-custom-layout       # Save current layout as template
tw-sync                         # Toggle pane sync for multi-server
twf                             # Fuzzy search workspaces
```

**Available Templates:**
- `dev` - Vim (50%) + terminal (25%) + logs (25%)
- `ops` - 4-pane monitoring grid
- `ssh-multi` - 4 panes for multi-server management
- `debug` - 2 panes: main (70%) + helper (30%)
- `full` - Single full-screen pane
- `review` - Side-by-side code review panes

## 🌐 SSH Session Manager

Save and manage SSH connections with automatic tmux integration:

```bash
ssh-save prod user@prod.example.com 22 ~/.ssh/prod_key
ssh-connect prod                       # Auto-creates/attaches tmux session
ssh-list                               # List all profiles
sshf                                   # Fuzzy search and connect
ssh-sync-dotfiles prod                 # Deploy dotfiles to remote
```

## 🐍 Python Project Templates

Quick project scaffolding with virtual environments:

```bash
py-new myproject               # Basic Python project
py-django myblog               # Django web app
py-flask myapp                 # Flask web app
py-fastapi myapi               # FastAPI REST API
py-data analysis                # Data science project
py-cli mytool                  # CLI tool with Click
```

All include virtual environment setup, git initialization, and project structure.

## ⌨️ Command Aliases

All dotfiles commands have convenient aliases:

| Alias | Command | Description |
|-------|---------|-------------|
| `dfd` | `dotfiles-doctor.sh` | Health check |
| `dffix` | `dotfiles-doctor.sh --fix` | Auto-fix issues |
| `dfs` | `dotfiles-sync.sh` | Sync dotfiles |
| `dfpush` | `dotfiles-sync.sh --push` | Push changes |
| `dfpull` | `dotfiles-sync.sh --pull` | Pull changes |
| `dfu` | `dotfiles-update.sh` | Update dotfiles |
| `dfv` | `dotfiles-version.sh` | Version info |
| `dfstats` | `dotfiles-stats.sh` | Shell analytics |
| `vault` | `dotfiles-vault.sh` | Secrets manager |
| `pw` | LastPass password manager | Get/list passwords |
| `tw` | Tmux workspace manager | Quick workspace access |
| `reload` | `source ~/.zshrc` | Reload shell config |

## 🩺 Health Check

```bash
dotfiles-doctor.sh             # Run diagnostics
dotfiles-doctor.sh --fix       # Auto-fix issues
# Aliases: dfd, doctor, dffix
```

Checks: symlinks, zsh plugins, git config, optional tools, and more

## ⚙️ Configuration

Edit `~/.dotfiles/dotfiles.conf` to customize:

```bash
# Identity
USER_FULLNAME="Your Name"
USER_EMAIL="you@example.com"
USER_GITHUB="yourusername"

# Features
INSTALL_ZSH_PLUGINS="true"
INSTALL_FZF="ask"
INSTALL_NEOVIM="ask"
SET_ZSH_DEFAULT="ask"

# Advanced
ENABLE_SMART_SUGGESTIONS="true"
ENABLE_COMMAND_PALETTE="true"
ENABLE_VAULT="true"
DOTFILES_AUTO_SYNC_CHECK="true"
```

## 🔄 Updating

```bash
dotfiles-update.sh
# or aliases:
dfu
dfupdate
```

Check version:
```bash
dotfiles-version.sh
# or: dfv
```

## 🗑️ Uninstalling

```bash
./install.sh --uninstall            # Remove symlinks
./install.sh --uninstall --purge    # Also delete ~/.dotfiles
```

## 📚 Documentation

- [SETUP_GUIDE.md](docs/SETUP_GUIDE.md) - Detailed installation and configuration
- [ESPANSO.md](docs/ESPANSO.md) - Text expansion snippets reference
- [SNAPPER.md](docs/SNAPPER.md) - Btrfs snapshot management guide
- [SSH_TMUX_INTEGRATION.md](docs/SSH_TMUX_INTEGRATION.md) - SSH + Tmux workflow

## 🛠️ Install Options

```bash
./install.sh                    # Standard install
./install.sh --wizard           # Interactive TUI wizard
./install.sh --skip-deps        # Re-run without checking deps
./install.sh --uninstall        # Remove symlinks
./install.sh --help             # Show all options
```

## 🤝 Forking

1. Fork the repo
2. Edit `dotfiles.conf` with your settings
3. Customize files as needed
4. The installer will use your fork's URLs

## 📄 License

MIT – See [LICENSE](LICENSE)

---

**Author:** Aaron D. Lee  
**Repository:** https://github.com/adlee-was-taken/dotfiles  
**Arch/CachyOS Only Edition**
