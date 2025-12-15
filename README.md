# ADLee's Dotfiles

Personal configuration files for a fast, consistent dev environment across Linux/macOS.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)

```
┌[alee@battlestation]─[~/.dotfiles ⎇ main]
└%
```

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Setup Wizard** | Beautiful TUI installer with feature selection |
| **Zsh Theme** | Git status, command timer, root detection |
| **Command Palette** | Raycast-style fuzzy launcher (Ctrl+Space) |
| **Smart Suggestions** | Typo correction + alias recommendations |
| **Shell Analytics** | Track command usage, get insights |
| **Secrets Vault** | Encrypted storage for API keys |
| **Dotfiles Sync** | Auto-sync across machines |
| **Espanso** | 100+ text expansion snippets |
| **Snapper** | Btrfs snapshot helpers (Arch/CachyOS) |

## 🚀 Quick Start

### One-liner Install

```bash
curl -fsSL https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main/install.sh | bash
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

## 📁 Repository Layout

```
dotfiles/
├── install.sh                 # Main installer
├── dotfiles.conf              # Central configuration
├── zsh/
│   ├── .zshrc                 # Shell config
│   ├── themes/adlee.zsh-theme
│   └── functions/
│       ├── snapper.zsh        # Btrfs snapshots
│       ├── smart-suggest.zsh  # Typo correction
│       └── command-palette.zsh
├── espanso/                   # Text expansion
│   └── match/base.yml         # 100+ snippets
├── bin/                       # Utility scripts
│   ├── setup-wizard.sh        # TUI installer
│   ├── dotfiles-doctor.sh     # Health checker
│   ├── dotfiles-sync.sh       # Multi-machine sync
│   ├── shell-stats.sh         # Analytics
│   └── vault.sh               # Secrets manager
├── git/.gitconfig.template
├── vim/.vimrc
├── tmux/.tmux.conf
└── docs/
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

**Searches:** aliases, functions, history, bookmarks, git commands, docker commands, quick actions

**Keybindings:**
- `Enter` - Execute
- `Ctrl+E` - Edit before running
- `Ctrl+Y` - Copy to clipboard

### Directory Bookmarks

```bash
bookmark projects ~/projects    # Save
bookmark list                   # List all
jump projects                   # Go to bookmark
j                               # Fuzzy select
```

## 🔧 Smart Suggestions

Automatic typo correction:

```bash
$ gti status
✗ Command not found: gti
→ Did you mean: git?

$ dokcer ps
✗ Command not found: dokcer
→ Did you mean: docker?
```

Alias recommendations:

```bash
💡 Tip: You've typed 'docker-compose up -d' 15 times
   Consider adding: alias dcu='docker-compose up -d'
```

Quick fix with `fuck`:

```bash
$ gti status
✗ Command not found: gti
$ fuck
Running: git status
```

## 📊 Shell Analytics

```bash
shell-stats.sh
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

```bash
shell-stats.sh --suggest    # Alias suggestions
shell-stats.sh --heatmap    # Activity by hour
shell-stats.sh --git        # Git breakdown
shell-stats.sh --dirs       # Most visited directories
```

## 🔐 Secrets Vault

Encrypted storage for API keys and tokens:

```bash
vault set GITHUB_TOKEN ghp_xxxxxxxxxxxx
vault set AWS_SECRET_KEY              # Prompts (hidden input)
vault get GITHUB_TOKEN
vault list                            # Shows keys only
vault delete OLD_KEY
```

Export to environment:

```bash
eval $(vault shell)                   # Load all secrets
```

Uses `age` or `gpg` encryption. Secrets auto-load on shell start.

## 🔄 Dotfiles Sync

Keep dotfiles synchronized across machines:

```bash
dotfiles-sync.sh              # Interactive sync
dotfiles-sync.sh --status     # Show status
dotfiles-sync.sh --push       # Push changes
dotfiles-sync.sh --pull       # Pull changes
dotfiles-sync.sh --watch 300  # Auto-sync every 5 min
```

On shell start, you'll see:

```
⚠ Dotfiles: 3 update(s) available
  Run: dotfiles-sync.sh --pull
```

## ⌨️ Espanso Snippets

All triggers use `..` prefix:

| Category | Examples |
|----------|----------|
| **Date/Time** | `..date` → 2025-12-15, `..ts` → ISO timestamp |
| **Git** | `..gstat`, `..gcm`, `..branch` (current branch) |
| **Docker** | `..dps`, `..dcup`, `..dlog` |
| **Symbols** | `..shrug` → ¯\\\_(ツ)\_/¯, `..check` → ✓ |
| **Code** | `..bash` → script template, `..python` → main template |

Full list: [docs/ESPANSO.md](docs/ESPANSO.md)

## 🎨 Theme Features

```
┌[user@hostname]─[~/projects ⎇ main *]
└%
```

- **Git integration** – Branch name with dirty indicator (`*`)
- **Command timer** – Shows elapsed time for commands >10s
- **Smart paths** – Truncates long directories
- **Root detection** – Red prompt for root, blue for users

## 🩺 Health Check

```bash
dotfiles-doctor.sh              # Run diagnostics
dotfiles-doctor.sh --fix        # Auto-fix issues
```

```
━━━ Symlinks ━━━
✓ Symlink valid: .zshrc
✓ Symlink valid: .gitconfig
✓ Symlink valid: adlee.zsh-theme

━━━ Zsh Plugins ━━━
✓ Plugin installed: zsh-autosuggestions
✓ Plugin installed: zsh-syntax-highlighting

━━━ Summary ━━━
  Passed:   12
  Warnings: 1
  Failed:   0
```

## ⚙️ Configuration

All settings in `dotfiles.conf`:

```bash
# Identity
USER_FULLNAME="Your Name"
USER_EMAIL="you@example.com"
GIT_USER_NAME=""              # Falls back to USER_FULLNAME

# Features
INSTALL_ZSH_PLUGINS="true"
INSTALL_FZF="ask"
INSTALL_ESPANSO="ask"

# Advanced
ENABLE_SMART_SUGGESTIONS="true"
ENABLE_COMMAND_PALETTE="true"
ENABLE_VAULT="true"
DOTFILES_AUTO_SYNC_CHECK="true"
```

## 🔄 Updating

```bash
cd ~/.dotfiles && git pull && ./install.sh
# or
update-dotfiles.sh
```

Check version:

```bash
dotfiles-version.sh
```

## 🗑️ Uninstalling

```bash
./install.sh --uninstall            # Remove symlinks
./install.sh --uninstall --purge    # Also delete ~/.dotfiles
```

## 📚 Documentation

- [Setup Guide](docs/SETUP_GUIDE.md) - Detailed installation instructions
- [Espanso Reference](docs/ESPANSO.md) - All text expansion snippets
- [Snapper Guide](docs/SNAPPER.md) - Btrfs snapshot management

## 🛠️ Install Options

```bash
./install.sh                    # Standard install
./install.sh --wizard           # Interactive TUI
./install.sh --skip-deps        # Skip dependency check
./install.sh --uninstall        # Remove symlinks
./install.sh --help             # All options
```

## 📋 Requirements

- **OS:** Linux (Ubuntu, Arch, Fedora) or macOS
- **Shell:** Zsh (installed automatically)
- **Optional:** fzf (for command palette), age/gpg (for vault)

## 🤝 Forking

1. Fork the repo
2. Edit `dotfiles.conf` with your settings
3. Customize files as needed
4. The installer will use your fork's URLs

## 📄 License

MIT – See [LICENSE](LICENSE)

---

**Author:** Aaron D. Lee  
**Repo:** https://github.com/adlee-was-taken/dotfiles
