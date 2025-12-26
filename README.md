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


# Dotfiles Improvements

This directory contains suggested improvements for your dotfiles project. These additions enhance functionality, maintainability, and user experience.

## Summary of Additions

| Category | Files Added | Description |
|----------|-------------|-------------|
| Machine Config | `zsh/lib/machines.zsh`, `machines/*.zsh` | Per-machine configuration support |
| Performance | `bin/dotfiles-profile.sh` | Startup time profiling |
| Notifications | `zsh/functions/notifications.zsh` | Long-running command notifications |
| Security | `bin/dotfiles-diff.sh` | Diff, audit, and secret detection |
| Project Env | `zsh/functions/project-env.zsh` | Auto-load project environments |
| Analytics | `bin/dotfiles-analytics.sh` | Enhanced history analytics |
| Testing | `tests/run-tests.zsh`, `tests/test_*.zsh` | Unit testing framework |
| First-Run | `bin/dotfiles-tour.sh` | Interactive tour and changelog |
| FZF Extras | `zsh/functions/fzf-extras.zsh` | Additional fuzzy finders |
| Plugin Mgr | `zsh/lib/plugins.zsh` | Lightweight plugin management |

---

## Installation

### Option 1: Copy All Files

```bash
# Backup first
cp -r ~/.dotfiles ~/.dotfiles.backup.$(date +%Y%m%d)

# Copy improvements
cp -r /path/to/improvements/* ~/.dotfiles/
```

### Option 2: Selective Installation

Copy only the features you want:

```bash
# Machine-specific configs
cp zsh/lib/machines.zsh ~/.dotfiles/zsh/lib/
mkdir -p ~/.dotfiles/machines
cp machines/*.zsh ~/.dotfiles/machines/

# Notifications
cp zsh/functions/notifications.zsh ~/.dotfiles/zsh/functions/

# Profiling
cp bin/dotfiles-profile.sh ~/.dotfiles/bin/
chmod +x ~/.dotfiles/bin/dotfiles-profile.sh
```

### Option 3: Integration

Add to your `.zshrc` to load new features:

```zsh
# In ~/.dotfiles/zsh/.zshrc, add after other sources:

# Load machine-specific configuration
[[ -f "$DOTFILES_DIR/zsh/lib/machines.zsh" ]] && \
    source "$DOTFILES_DIR/zsh/lib/machines.zsh"

# Load notifications
[[ -f "$DOTFILES_DIR/zsh/functions/notifications.zsh" ]] && \
    source "$DOTFILES_DIR/zsh/functions/notifications.zsh"

# Load project environments
[[ -f "$DOTFILES_DIR/zsh/functions/project-env.zsh" ]] && \
    source "$DOTFILES_DIR/zsh/functions/project-env.zsh"

# Load FZF extras
[[ -f "$DOTFILES_DIR/zsh/functions/fzf-extras.zsh" ]] && \
    source "$DOTFILES_DIR/zsh/functions/fzf-extras.zsh"
```

---

## Feature Details

### 1. Machine-Specific Configuration

**Files:** `zsh/lib/machines.zsh`, `machines/*.zsh`

Automatically loads different settings based on hostname or machine type.

```bash
# See current machine detection
machine-info

# Create config for this machine
machine-create

# Edit machine config
machine-edit

# List all machine configs
machines
```

**Configuration hierarchy:**
1. `dotfiles.conf` (base)
2. `machines/default.zsh` (shared overrides)
3. `machines/type-<type>.zsh` (laptop/desktop/server/virtual)
4. `machines/<hostname>.zsh` (machine-specific)
5. `~/.zshrc.local` (local, not synced)

---

### 2. Startup Profiling

**File:** `bin/dotfiles-profile.sh`

Measure and optimize shell startup time.

```bash
dotfiles-profile.sh              # Quick timing (5 runs)
dotfiles-profile.sh --detailed   # zprof function-level analysis
dotfiles-profile.sh --benchmark  # Hyperfine benchmark
dotfiles-profile.sh --compare    # Full vs minimal shell
dotfiles-profile.sh --tips       # Optimization suggestions
dotfiles-profile.sh --all        # Run everything
```

---

### 3. Long-Running Command Notifications

**File:** `zsh/functions/notifications.zsh`

Get notified when commands taking longer than 60 seconds complete.

```bash
# Toggle notifications
notify-toggle

# Test notification
notify-test

# Show status
notify-status

# Adjust threshold
df_notify_threshold 120  # 2 minutes
```

**Configuration in `dotfiles.conf`:**
```bash
DF_NOTIFY_ENABLED="true"
DF_NOTIFY_THRESHOLD="60"
DF_NOTIFY_METHODS="desktop bell"
```

---

### 4. Diff & Security Audit

**File:** `bin/dotfiles-diff.sh`

Compare configurations and audit for security issues.

```bash
dotfiles-diff.sh              # Show uncommitted changes
dotfiles-diff.sh --installed  # Compare installed vs source
dotfiles-diff.sh --symlinks   # Verify symlink integrity
dotfiles-diff.sh --secrets    # Scan for exposed secrets
dotfiles-diff.sh --permissions # Check file permissions
dotfiles-diff.sh --audit      # Full security audit
```

---

### 5. Project-Local Environments

**File:** `zsh/functions/project-env.zsh`

Auto-load project settings when entering directories (like direnv).

```bash
# Create project env file
project-env create

# Edit current project's env
project-env edit

# Show status
project-env status

# Allow/deny files
project-env allow .dotfiles-local
project-env deny .dotfiles-local
```

**Features:**
- Auto-loads `.dotfiles-local`, `.envrc`, or `.env.local`
- Auto-activates Python virtualenvs
- Auto-switches Node versions via `.nvmrc`
- Security prompts for untrusted directories

---

### 6. Enhanced Shell Analytics

**File:** `bin/dotfiles-analytics.sh`

Advanced command history analysis.

```bash
dotfiles-analytics.sh             # Dashboard
dotfiles-analytics.sh hourly      # Commands by hour
dotfiles-analytics.sh weekly      # Usage by day of week
dotfiles-analytics.sh projects    # Group by directory
dotfiles-analytics.sh trends      # 30-day trends
dotfiles-analytics.sh complexity  # Command complexity
dotfiles-analytics.sh tools       # Tool usage breakdown
dotfiles-analytics.sh suggestions # Alias suggestions
```

---

### 7. Testing Framework

**Files:** `tests/run-tests.zsh`, `tests/test_*.zsh`

Simple unit testing for shell functions.

```bash
# Run all tests
./tests/run-tests.zsh

# Run specific test file
./tests/run-tests.zsh utils

# Or use alias
dftest
```

**Writing tests:**
```zsh
describe "my function"

it "should do something"
assert_eq "$(my_func)" "expected"

it "should handle errors"
assert_fail "my_func invalid_arg"
```

---

### 8. First-Run Experience & Tour

**File:** `bin/dotfiles-tour.sh`

Interactive introduction for new users.

```bash
dotfiles-tour.sh           # Interactive tour
dotfiles-tour.sh --quick   # Quick reference card
dotfiles-tour.sh --changelog # Recent changes
```

---

### 9. FZF Extras

**File:** `zsh/functions/fzf-extras.zsh`

Additional fuzzy finders.

| Command | Description |
|---------|-------------|
| `envf` | Browse environment variables |
| `pathf` | Explore PATH directories |
| `procf` | Process manager |
| `killf` | Fuzzy kill processes |
| `aliasf` | Browse aliases |
| `funcf` | Browse functions |
| `histf` | Enhanced history search |
| `ff` | Find files |
| `fdir` | Find directories |
| `gbf` | Git branch switcher |
| `glogf` | Git commit browser |

---

### 10. Plugin Manager

**File:** `zsh/lib/plugins.zsh`

Lightweight plugin management without heavy frameworks.

```bash
# Install a plugin
plugin install zsh-users/zsh-autosuggestions

# List plugins
plugin list

# Update all plugins
plugin update

# Remove a plugin
plugin remove zsh-autosuggestions

# Show recommended plugins
plugin recommended

# Lazy-load a plugin
plugin lazy zsh-nvm nvm node npm
```

---

## New Aliases Reference

| Alias | Command | Description |
|-------|---------|-------------|
| `dfprofile` | `dotfiles-profile.sh` | Startup profiling |
| `dfdiff` | `dotfiles-diff.sh` | Show changes |
| `dfaudit` | `dotfiles-diff.sh --audit` | Security audit |
| `dftour` | `dotfiles-tour.sh` | Interactive tour |
| `dfanalytics` | `dotfiles-analytics.sh` | Enhanced analytics |
| `dftest` | `tests/run-tests.zsh` | Run tests |
| `quickref` | `dotfiles-tour.sh --quick` | Quick reference |
| `profile` | `dotfiles-profile.sh` | Startup profiling |
| `audit` | `dotfiles-diff.sh --audit` | Security audit |
| `tour` | `dotfiles-tour.sh` | Interactive tour |

---

## Configuration Options

Add to `dotfiles.conf`:

```bash
# === NEW: Notification Settings ===
DF_NOTIFY_ENABLED="true"
DF_NOTIFY_THRESHOLD="60"
DF_NOTIFY_METHODS="desktop bell"
DF_NOTIFY_SOUND="/usr/share/sounds/freedesktop/stereo/complete.oga"
DF_NOTIFY_ONLY_FAILURES="false"

# === NEW: Project Environment ===
DF_PROJECT_ENV_ENABLED="true"
DF_PROJECT_ENV_FILES=".dotfiles-local .envrc .env.local"
DF_PROJECT_ENV_TRUSTED_DIRS="$HOME/projects $HOME/work"
DF_PROJECT_AUTO_VENV="true"
DF_PROJECT_AUTO_NVM="true"

# === NEW: Plugin Manager ===
DF_PLUGIN_DIR="$HOME/.dotfiles/zsh/plugins"
```

---

## Verification

After installation, verify everything works:

```bash
# Health check
dfd

# Run tests
dftest

# Profile startup
dfprofile

# Security audit
dfaudit

# Take the tour
dftour
```

---

## File Structure

```
dotfiles-improvements/
├── bin/
│   ├── dotfiles-analytics.sh    # Enhanced history analytics
│   ├── dotfiles-diff.sh         # Diff and security audit
│   ├── dotfiles-profile.sh      # Startup profiling
│   └── dotfiles-tour.sh         # First-run experience
├── machines/
│   ├── default.zsh              # Shared machine config
│   ├── type-laptop.zsh          # Laptop-specific
│   └── type-server.zsh          # Server-specific
├── tests/
│   ├── run-tests.zsh            # Test runner
│   ├── test_config.zsh          # Config tests
│   └── test_utils.zsh           # Utils tests
├── zsh/
│   ├── aliases-extended.zsh     # Extended aliases
│   ├── functions/
│   │   ├── fzf-extras.zsh       # Additional fzf utilities
│   │   ├── notifications.zsh    # Command notifications
│   │   └── project-env.zsh      # Project environments
│   └── lib/
│       ├── machines.zsh         # Machine detection
│       └── plugins.zsh          # Plugin manager
└── README.md                    # This file
```
