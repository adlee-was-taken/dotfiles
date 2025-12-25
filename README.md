# ADLee's Dotfiles

Personal configuration for a productive development environment on **Arch Linux** and **CachyOS**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![OS](https://img.shields.io/badge/OS-Arch%20%2F%20CachyOS-blue.svg)](https://archlinux.org/)

```
┌[alee@battlestation]─[~/.dotfiles ⎇ main]─[⇑3]
└%
```

## Quick Start

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

See [INSTALL.md](INSTALL.md) for detailed instructions.

---

## Features

| Feature | Description |
|---------|-------------|
| **Dynamic MOTD** | System info on shell start |
| **Two-Line Prompt** | Git status, command timer, update indicator |
| **Command Palette** | Fuzzy launcher (`Ctrl+Space`) |
| **Tmux Workspaces** | Simple templates + tmuxinator integration |
| **Systemd Helpers** | Quick service management |
| **Btrfs/Snapper** | Filesystem health + snapshot management |
| **Secrets Vault** | Encrypted storage (age/gpg) |
| **Password Manager** | LastPass CLI integration |
| **Python Templates** | Project scaffolding (Flask, FastAPI, CLI, etc.) |

---

## Dotfiles Management

| Command | Alias | Description |
|---------|-------|-------------|
| `dotfiles-doctor.sh` | `dfd` | Health check |
| `dotfiles-doctor.sh --fix` | `dffix` | Auto-fix issues |
| `dotfiles-sync.sh push` | `dfpush` | Push changes |
| `dotfiles-sync.sh pull` | `dfpull` | Pull changes |
| `dotfiles-update.sh` | `dfu` | Update dotfiles |
| `dotfiles-vault.sh` | `vault` | Secrets manager |
| `source ~/.zshrc` | `reload` | Reload config |

**Quick Edit:** `v.zshrc`, `v.conf`, `v.alias`, `v.motd`

---

## Systemd Helpers

| Command | Description |
|---------|-------------|
| `sc <args>` | `sudo systemctl <args>` |
| `scr <service>` | Restart + show status |
| `sce <service>` | Enable + start |
| `scd <service>` | Disable + stop |
| `sclog <service>` | Follow journal logs |
| `sc-failed` | Show failed services |
| `sc-boot` | Boot time analysis |
| `scf` | Interactive manager (fzf) |

**Aliases:** `scs` (status), `scstart`, `scstop`, `screload`, `jctl`, `jctlf`

---

## Btrfs & Snapper

### Btrfs Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `btrfs-usage` | `btru` | Filesystem usage |
| `btrfs-health` | `btrh` | Quick health check |
| `btrfs-scrub` | - | Start integrity check |
| `btrfs-balance` | - | Balance operation |
| `btrfs-compress` | `btrc` | Compression stats |

### Snapper Snapshots

| Command | Alias | Description |
|---------|-------|-------------|
| `snap-create "desc"` | `snap` | Create snapshot |
| `snap-list` | `snapls` | List snapshots |
| `snap-check` | `snapcheck` | Verify limine sync |
| `sys-update` | - | Update with pre/post snapshot |

---

## Tmux Workspaces

Manage tmux sessions with simple templates or full tmuxinator projects.

### Quick Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `tw <name> [template]` | - | Create/attach workspace |
| `tw-list` | `twl` | List active workspaces |
| `tw-templates` | `twt` | Show available templates |
| `tw-save <name>` | `tws` | Save current layout |
| `twf` | - | Fuzzy search workspaces |

### Built-in Templates

| Template | Description |
|----------|-------------|
| `dev` | Editor (50%) + terminal + logs |
| `ops` | 4-pane monitoring grid |
| `ssh-multi` | 4 panes for multi-server |
| `debug` | Main (70%) + helper (30%) |
| `review` | Side-by-side comparison |

### Tmuxinator Integration

For complex projects with per-pane commands and startup scripts:

```bash
# Install
sudo pacman -S tmuxinator

# Create project from template
txi-new myproject dev

# Edit configuration
txi-edit myproject

# Start project
txi myproject
```

| Command | Alias | Description |
|---------|-------|-------------|
| `txi <name>` | - | Start/attach project |
| `txi-new <n> [tmpl]` | `txin` | Create project |
| `txi-edit <name>` | `txie` | Edit YAML config |
| `txi-list` | `txil` | List projects |
| `txif` | - | Fuzzy search projects |

**Templates:** `dev`, `ops`, `web`, `data`, `minimal`

The `tw` command auto-detects: running session → tmuxinator project → simple template.

---

## Command Palette

Press **`Ctrl+Space`** for the fuzzy command launcher.

Searches aliases, functions, history, git commands, bookmarks, and quick actions.

### Directory Bookmarks

| Command | Alias | Description |
|---------|-------|-------------|
| `bookmark <name> [path]` | `bm` | Save bookmark |
| `bookmark list` | `bm list` | List bookmarks |
| `jump <name>` | `j` | Go to bookmark |

---

## Secrets Vault

Encrypted storage for API keys using `age` or `gpg`.

| Command | Description |
|---------|-------------|
| `vault init` | Initialize |
| `vault set <key>` | Store secret |
| `vault get <key>` | Retrieve secret |
| `vault list` | List keys |
| `vault shell` | Export to environment |

---

## Password Manager (LastPass)

| Command | Description |
|---------|-------------|
| `pw <query>` | Search and copy password |
| `pw show <item>` | Show entry details |
| `pw list` | List all entries |
| `pw gen [len]` | Generate password |
| `pwf` | Fuzzy search (fzf) |

---

## Python Templates

| Command | Alias | Description |
|---------|-------|-------------|
| `py-new <name>` | `pynew` | Basic project |
| `py-flask <name>` | `pyflask` | Flask web app |
| `py-fastapi <name>` | `pyfast` | FastAPI REST API |
| `py-cli <name>` | `pycli` | CLI with Click |
| `py-data <name>` | `pydata` | Data science |
| `venv` | - | Activate virtualenv |

---

## SSH Manager

| Command | Alias | Description |
|---------|-------|-------------|
| `ssh-save <n> <user@host>` | `sshs` | Save profile |
| `ssh-connect <name>` | `sshc` | Connect (auto tmux) |
| `ssh-list` | `sshl` | List profiles |
| `sshf` | - | Fuzzy search |

---

## Common Aliases

### Navigation
`..`, `...`, `....`, `~`, `c.` (dotfiles dir)

### Git
`g`, `gs` (status), `ga` (add), `gc` (commit), `gp` (push), `gl` (pull), `gd` (diff), `gco` (checkout), `glog`

### Docker
`d`, `dc` (compose), `dps`, `dpa`, `di` (images), `dex` (exec -it)

### Tools (conditional)
- `ls`/`ll`/`la`/`lt` → `eza` (if installed)
- `cat` → `bat` (if installed)

---

## Zsh Theme

The `adlee` theme provides:
- Two-line prompt with git branch + dirty indicator
- Command timer for commands >10s (color-coded by duration)
- Package update count indicator
- Root detection (red `#` vs blue `%`)

---

## Configuration

Edit `~/.dotfiles/dotfiles.conf`:

```bash
# Display
DF_WIDTH="74"
MOTD_STYLE="compact"          # compact, mini, full, none

# Features
ENABLE_SMART_SUGGESTIONS="true"
ENABLE_COMMAND_PALETTE="true"

# Tmuxinator
TMUXINATOR_ENABLED="auto"
TW_PREFER_TMUXINATOR="true"
```

### Local Overrides

Create `~/.zshrc.local` for machine-specific settings.

---

## Repository Structure

```
~/.dotfiles/
├── install.sh              # Installer
├── dotfiles.conf           # Configuration
├── bin/                    # Scripts → ~/.local/bin
├── zsh/
│   ├── .zshrc
│   ├── aliases.zsh
│   ├── lib/                # colors, config, utils, bootstrap
│   ├── themes/adlee.zsh-theme
│   └── functions/          # Feature modules
├── vim/.vimrc
├── tmux/.tmux.conf
├── espanso/                # Text expansion
└── .tmux-templates/        # Workspace layouts
```

---

## License

MIT – See [LICENSE](LICENSE)

**Author:** Aaron D. Lee  
**Repository:** https://github.com/adlee-was-taken/dotfiles
