# ADLee's Dotfiles

Personal configuration files for a fast, consistent dev environment across Linux/macOS.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)

```
┌[alee@catchthesethighs]─[~/.dotfiles ⎇ main]
└%
```

## What's Included

| Component | Description |
|-----------|-------------|
| **Zsh Theme** | Git status, command timer, smart path truncation |
| **Espanso** | 100+ text snippets (`..date`, `..gst`, `..dps`) |
| **CLI Tools** | fzf, bat, eza integrations |
| **Snapper** | Btrfs snapshot helpers for CachyOS/Arch |

## Quick Start

```bash
# One-liner
curl -fsSL https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main/install.sh | bash

# Or clone first
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

The installer backs up existing configs, installs oh-my-zsh + plugins, configures git, and creates symlinks.

### Install Options

```bash
./install.sh --skip-deps        # Skip dependency check (re-runs)
./install.sh --uninstall        # Remove symlinks
./install.sh --uninstall --purge # Remove everything
```

## Repository Layout

```
dotfiles/
├── install.sh              # Main installer
├── dotfiles.conf           # Configuration (fork-friendly)
├── zsh/
│   ├── .zshrc              # Shell config
│   ├── themes/adlee.zsh-theme
│   └── functions/snapper.zsh
├── espanso/
│   ├── config/default.yml
│   └── match/base.yml      # 100+ snippets
├── git/.gitconfig.template # Git config template
├── vim/.vimrc
├── tmux/.tmux.conf
├── bin/                    # Helper scripts
│   ├── dotfiles-doctor.sh  # Health checker
│   ├── dotfiles-version.sh # Version checker
│   └── update-dotfiles.sh
└── docs/                   # Extended docs
```

## Health Check

Verify your installation:

```bash
dotfiles-doctor.sh          # Run diagnostics
dotfiles-doctor.sh --fix    # Auto-fix issues
dotfiles-version.sh         # Check for updates
```

## Espanso Snippets

All triggers use `..` prefix to avoid accidents.

| Category | Examples |
|----------|----------|
| **Time** | `..date` → 2025-12-14, `..ts` → ISO timestamp, `..epoch` |
| **Git** | `..gstat`, `..gcm`, `..branch` (current branch) |
| **Docker** | `..dps`, `..dcup`, `..dlog` |
| **Symbols** | `..shrug` → ¯\\\_(ツ)\_/¯, `..check` → ✓ |

Full list: [docs/ESPANSO.md](docs/ESPANSO.md)

## Theme Features

- **Git integration** – `⎇ branch` with dirty indicator (`*`)
- **Command timer** – shows elapsed time for commands >10s
- **Smart paths** – truncates long directories
- **User detection** – blue prompt for users, red for root

## Customization

```bash
# Edit theme
vim ~/.dotfiles/zsh/themes/adlee.zsh-theme
source ~/.zshrc

# Add espanso snippets
vim ~/.dotfiles/espanso/match/base.yml
espanso restart

# Add aliases
vim ~/.dotfiles/zsh/.zshrc
```

## System-Wide Theme Deployment

Share the theme across all users:

```bash
sudo ./bin/deploy-zshtheme-systemwide.sh --all     # All users
sudo ./bin/deploy-zshtheme-systemwide.sh --status  # Check status
```

## Updating

```bash
cd ~/.dotfiles
git pull origin main
./install.sh
```

## Snapper Integration (CachyOS/Arch)

For btrfs systems with limine-snapper-sync:

```bash
snap-create "Before update"   # Create + validate limine entry
snap-list                     # Recent snapshots
snap-check-limine             # Verify boot menu sync
```

## Troubleshooting

```bash
dotfiles-doctor.sh --fix    # Auto-diagnose and fix
```

| Issue | Fix |
|-------|-----|
| Theme not loading | `dotfiles-doctor.sh --fix` |
| Zsh plugins missing | `./install.sh` (auto-installs now) |
| Espanso not working | `espanso status`, then `espanso restart` |
| Broken symlinks | `./install.sh` |
| Want to uninstall | `./install.sh --uninstall` |

## License

MIT – See [LICENSE](LICENSE)

---

**Author**: Aaron D. Lee  
**Repo**: https://github.com/adlee-was-taken/dotfiles
