# ADLee's Dotfiles

Personal configuration for a productive development environment on **Arch Linux** and **CachyOS**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![OS](https://img.shields.io/badge/OS-Arch%20%2F%20CachyOS-blue.svg)](https://archlinux.org/)
[![Version](https://img.shields.io/badge/Version-1.2.4-blue.svg)](https://github.com/adlee-was-taken/dotfiles)

## ADLee Theme Prompt

```
┌｢alee@catchthesethighs｣ ｢~/.dotfiles ⎇ main｣ ｢⇑3｣ 
└%
```

## Quick Start

```bash
git clone https://github.com/adlee-was-taken/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

See [INSTALL.md](INSTALL.md) for detailed instructions.

---

## Features Overview

| Category | Features |
|----------|----------|
| **Shell** | Two-line prompt • Command timer • Git integration • Smart suggestions • Command palette (Ctrl+Space) |
| **Automation** | Auto-load project environments • Long-running command notifications • Machine-specific configs |
| **Diagnostics** | Enhanced analytics • Startup profiling • Security audits • Health checks • Testing framework |
| **Tmux** | Simple templates • Tmuxinator integration • Workspace management • Layout saving |
| **System** | Systemd helpers • Btrfs utilities • Snapper snapshots with limine integration |
| **Development** | Python project templates • SSH manager • Password manager • Secrets vault |
| **Tools** | Plugin manager • FZF extras • Directory bookmarks • Custom MOTD |

---

## Core Commands

### Dotfiles Management

| Command | Alias | Description |
|---------|-------|-------------|
| `dotfiles-doctor.sh` | `dfd` | Health check and diagnostics |
| `dotfiles-doctor.sh --fix` | `dffix` | Auto-fix common issues |
| `dotfiles-sync.sh push` | `dfpush` | Push changes to git |
| `dotfiles-sync.sh pull` | `dfpull` | Pull latest changes |
| `dotfiles-update.sh` | `dfu` | Update dotfiles from repo |
| `dotfiles-vault.sh` | `vault` | Manage encrypted secrets |
| `source ~/.zshrc` | `reload` | Reload shell configuration |

**Quick Edit:** `v.zshrc`, `v.conf`, `v.alias`, `v.motd`, `v.theme`

### New Commands

| Command | Description |
|---------|-------------|
| `dotfiles-analytics.sh` | Enhanced history analytics (hourly, weekly, trends, suggestions) |
| `dotfiles-profile.sh` | Startup time profiling and optimization tips |
| `dotfiles-diff.sh` | Show changes, audit security, check permissions |
| `dotfiles-tour.sh` | Interactive tour and feature walkthrough |
| `dotfiles-compile.sh` | Compile zsh files for faster startup |
| `dftest` | Run test suite |

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
| `sc-search <query>` | Search for services |
| `scf` | Interactive manager (fzf) |

**Additional:** `scs` (status), `scstart`, `scstop`, `screload`, `sc-timers`, `jctl`, `jctlf`

---

## Btrfs & Snapper

### Btrfs Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `btrfs-usage` | `btru` | Filesystem usage statistics |
| `btrfs-health` | `btrh` | Quick health check |
| `btrfs-scrub` | - | Start data integrity check |
| `btrfs-balance` | - | Balance filesystem |
| `btrfs-compress` | `btrc` | Compression statistics |
| `btrfs-info` | `btri` | Full filesystem information |

### Snapper Snapshots

| Command | Alias | Description |
|---------|-------|-------------|
| `snap-create "desc"` | `snap` | Create snapshot |
| `snap-list` | `snapls` | List recent snapshots |
| `snap-check` | `snapcheck` | Verify limine boot menu sync |
| `sys-update` | - | System update with pre/post snapshots |
| `sys-rollback <num>` | `rollback` | Rollback to snapshot |

**Note:** Snapshots automatically sync to limine boot menu via `limine-snapper-sync` service.

---

## Tmux Workspaces

Dual-mode system: simple templates for quick layouts OR tmuxinator for complex projects.

### Quick Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `tw <name> [template]` | - | Create/attach workspace (auto-detects mode) |
| `tw-list` | `twl` | List active workspaces |
| `tw-templates` | `twt` | Show available templates |
| `tw-save <name>` | `tws` | Save current layout as template |
| `twf` | - | Fuzzy search workspaces |
| `tw-sync` | - | Toggle synchronized panes |

### Simple Templates (.tmux files)

| Template | Layout Description |
|----------|-------------------|
| `dev` | Editor (50%) + terminal (25%) + logs (25%) |
| `ops` | 4-pane monitoring grid |
| `ssh-multi` | 4 panes for multi-server management |
| `debug` | Main workspace (70%) + helper (30%) |
| `review` | Side-by-side comparison |
| `full` | Single full-screen pane |

### Tmuxinator Integration

For projects requiring per-pane commands, environment variables, and startup scripts:

| Command | Alias | Description |
|---------|-------|-------------|
| `txi <name>` | - | Start/attach tmuxinator project |
| `txi-new <n> [tmpl]` | `txin` | Create project (dev, ops, web, data, minimal) |
| `txi-edit <name>` | `txie` | Edit project YAML |
| `txi-list` | `txil` | List projects |
| `txif` | - | Fuzzy search projects |
| `txi-templates` | `txit` | Show available templates |

**Smart Detection:** `tw` automatically uses tmuxinator if a project exists, otherwise creates simple workspace.

---

## Machine-Specific Configuration

Per-machine settings that sync via git without conflicts.

### Commands

| Command | Description |
|---------|-------------|
| `machine-info` | Show current machine detection |
| `machine-create` | Create config for this machine |
| `machine-edit` | Edit machine config |
| `machines` | List all machine configs |

### Configuration Hierarchy

1. `dotfiles.conf` (base settings)
2. `machines/default.zsh` (shared overrides)
3. `machines/type-<type>.zsh` (laptop/desktop/server/virtual)
4. `machines/<hostname>.zsh` (machine-specific)
5. `~/.zshrc.local` (local, not synced)

**Auto-Detection:** Automatically loads correct config based on hostname and hardware.

---

## Project Environments

Automatically activates project-specific settings when entering directories.

### Commands

| Command | Description |
|---------|-------------|
| `project-env status` | Show current configuration |
| `project-env create` | Create `.dotfiles-local` in current directory |
| `project-env edit` | Edit current project's settings |
| `project-env allow <file>` | Trust a project environment file |
| `project-env on/off` | Enable/disable auto-loading |

### Features

- Auto-loads `.dotfiles-local`, `.envrc`, or `.env.local` files
- Auto-activates Python virtualenvs
- Auto-switches Node versions via `.nvmrc`
- Security prompts for untrusted directories
- Trusted directory configuration

---

## Command Palette & Bookmarks

### Command Palette (Ctrl+Space)

Fuzzy search through:
- Aliases and functions
- Command history
- Git commands
- Bookmarks
- Quick actions

### Directory Bookmarks

| Command | Alias | Description |
|---------|-------|-------------|
| `bookmark add <name> [path]` | `bm` | Save bookmark |
| `bookmark list` | `bm list` | List bookmarks |
| `bookmark go <name>` | `bmg` | Jump to bookmark |
| `bm` | - | Fuzzy search bookmarks (fzf) |

---

## Enhanced Analytics & Profiling

### Analytics Commands

| Command | Description |
|---------|-------------|
| `dotfiles-analytics.sh` | Dashboard with top commands |
| `dfanalytics hourly` | Commands by hour of day |
| `dfanalytics weekly` | Usage by day of week |
| `dfanalytics projects` | Commands grouped by directory |
| `dfanalytics trends` | 30-day usage trends |
| `dfanalytics tools` | Tool usage breakdown (Git, Docker, etc.) |
| `dfanalytics suggestions` | Alias suggestions and typo detection |

### Profiling Commands

| Command | Description |
|---------|-------------|
| `dotfiles-profile.sh` | Quick startup time measurement (5 runs) |
| `dfprofile --detailed` | Function-level analysis with zprof |
| `dfprofile --benchmark` | Hyperfine benchmark (if installed) |
| `dfprofile --compare` | Compare full shell vs minimal |
| `dfprofile --tips` | Optimization suggestions |

---

## Security & Diagnostics

### Diff & Audit

| Command | Description |
|---------|-------------|
| `dotfiles-diff.sh` | Show uncommitted git changes |
| `dfdiff --installed` | Compare installed vs source files |
| `dfdiff --symlinks` | Verify symlink integrity |
| `dfdiff --secrets` | Scan for exposed secrets |
| `dfdiff --permissions` | Check file permissions |
| `dfdiff --audit` | Full security audit |

### Notifications

| Command | Description |
|---------|-------------|
| `notify-toggle` | Enable/disable notifications |
| `notify-status` | Show configuration and capabilities |
| `notify-test` | Send test notification |

**Configuration:** Desktop notifications + terminal bell for commands >60s (configurable).

---

## Plugin Manager

Lightweight plugin management without heavy frameworks.

| Command | Description |
|---------|-------------|
| `plugin install <repo>` | Install from GitHub (e.g., zsh-users/zsh-autosuggestions) |
| `plugin load <name>` | Load installed plugin |
| `plugin lazy <n> <cmds>` | Lazy-load plugin on command use |
| `plugin update` | Update all plugins |
| `plugin list` | List installed plugins |
| `plugin remove <name>` | Remove plugin |
| `plugin recommended` | Show recommended plugins |

---

## FZF Extras

Enhanced fuzzy finders for system exploration.

| Command | Description |
|---------|-------------|
| `envf` | Browse environment variables |
| `pathf` | Explore PATH directories |
| `procf` | Process manager with actions |
| `killf` | Fuzzy kill processes |
| `aliasf` | Browse aliases |
| `funcf` | Browse functions |
| `histf` | Enhanced history search |
| `ff [dir]` | Find files |
| `ffo [dir]` | Find and open file |
| `fdir [dir]` | Find and cd to directory |
| `gbf` | Git branch switcher |
| `glogf` | Git commit browser |

---

## Secrets & Passwords

### Vault (Encrypted Storage)

| Command | Description |
|---------|-------------|
| `vault init` | Initialize encrypted vault |
| `vault set <key>` | Store secret |
| `vault get <key>` | Retrieve secret |
| `vault list` | List stored keys |
| `vault shell` | Export secrets to environment |

### Password Manager (LastPass)

| Command | Description |
|---------|-------------|
| `pw <query>` | Search and copy password |
| `pw show <item>` | Show entry details |
| `pw list` | List all entries |
| `pw gen [len]` | Generate password (default: 20 chars) |
| `pwf` | Fuzzy search (fzf) |

---

## Python Project Templates

| Command | Alias | Template |
|---------|-------|----------|
| `py-new <name>` | `pynew` | Basic Python project |
| `py-flask <name>` | `pyflask` | Flask web application |
| `py-fastapi <name>` | `pyfast` | FastAPI REST API |
| `py-cli <name>` | `pycli` | CLI tool with Click |
| `py-data <name>` | `pydata` | Data science project with Jupyter |
| `venv` | - | Activate virtualenv (auto-detects) |

All templates include: virtual environment, `.gitignore`, git initialization, and dependencies.

---

## SSH Manager

| Command | Alias | Description |
|---------|-------|-------------|
| `ssh-save <n> <user@host>` | `sshs` | Save connection profile |
| `ssh-connect <name>` | `sshc` | Connect (auto-creates tmux session) |
| `ssh-list` | `sshl` | List saved profiles |
| `sshf` | - | Fuzzy search connections |

Profiles support: custom ports, SSH keys, options, and auto-tmux integration.

---

## Testing Framework

Simple unit testing for shell functions.

```bash
# Run all tests
dftest

# Run specific test file
dftest utils

# Write tests (tests/test_*.zsh)
describe "my function"
it "should do something"
assert_eq "$(my_func)" "expected"
```

---

## Common Aliases

### Navigation
`..`, `...`, `....`, `~`, `c.` (dotfiles dir)

### Git
`g`, `gs` (status), `ga` (add), `gc` (commit), `gp` (push), `gl` (pull), `gd` (diff), `gco` (checkout), `gb` (branch), `glog`

### Docker
`d`, `dc` (compose), `dps`, `dpa`, `di` (images), `dex` (exec -it)

### System
`h` (history), `c` (clear), `myip`, `ports`

### Tool Integration
- `ls`/`ll`/`la`/`lt` → `eza` (if installed)
- `cat` → `bat` (if installed)

---

## Configuration

Edit `~/.dotfiles/dotfiles.conf` for global settings:

```bash
# Display
DF_WIDTH="74"
MOTD_STYLE="compact"          # compact, mini, full, none

# Features
ENABLE_SMART_SUGGESTIONS="true"
ENABLE_COMMAND_PALETTE="true"
ENABLE_SHELL_ANALYTICS="false"

# Notifications
DF_NOTIFY_ENABLED="true"
DF_NOTIFY_THRESHOLD="60"
DF_NOTIFY_METHODS="desktop bell"

# Project Environments
DF_PROJECT_ENV_ENABLED="true"
DF_PROJECT_AUTO_VENV="true"
DF_PROJECT_AUTO_NVM="true"

# Tmuxinator
TMUXINATOR_ENABLED="auto"
TW_PREFER_TMUXINATOR="true"

# Plugin Manager
DF_PLUGIN_DIR="$HOME/.dotfiles/zsh/plugins"
```

### Local Overrides

- `~/.zshrc.local` - User-specific settings (not synced)
- `machines/<hostname>.zsh` - Machine-specific config (synced)

---

## Repository Structure

```
~/.dotfiles/
├── install.sh              # Main installer
├── dotfiles.conf           # Central configuration
├── bin/                    # Management scripts
│   ├── dotfiles-doctor.sh
│   ├── dotfiles-sync.sh
│   ├── dotfiles-analytics.sh
│   ├── dotfiles-profile.sh
│   ├── dotfiles-diff.sh
│   ├── dotfiles-tour.sh
│   └── ...
├── zsh/
│   ├── .zshrc
│   ├── aliases.zsh
│   ├── lib/                # Core libraries
│   │   ├── bootstrap.zsh   # Single entry point
│   │   ├── config.zsh
│   │   ├── colors.zsh
│   │   ├── utils.zsh
│   │   ├── machines.zsh
│   │   └── plugins.zsh
│   ├── themes/adlee.zsh-theme
│   └── functions/          # Feature modules
│       ├── motd.zsh
│       ├── command-palette.zsh
│       ├── tmux-workspaces.zsh
│       ├── tmuxinator.zsh
│       ├── project-env.zsh
│       ├── notifications.zsh
│       ├── fzf-extras.zsh
│       ├── systemd-helpers.zsh
│       ├── btrfs-helpers.zsh
│       ├── snapper.zsh
│       ├── ssh-manager.zsh
│       ├── password-manager.zsh
│       ├── python-templates.zsh
│       └── smart-suggest.zsh
├── machines/               # Per-machine configs
│   ├── default.zsh
│   ├── type-laptop.zsh
│   └── type-server.zsh
├── tests/                  # Test framework
│   ├── run-tests.zsh
│   └── test_*.zsh
├── vim/.vimrc
├── tmux/.tmux.conf
├── espanso/                # Text expansion
├── setup/                  # Setup wizards
└── .tmux-templates/        # Workspace layouts
```

---

## First-Run Experience

After installation, run the interactive tour:

```bash
dotfiles-tour.sh          # Full interactive walkthrough
dotfiles-tour.sh --quick  # Quick reference card
```

Or verify installation:

```bash
dfd              # Health check
dftest           # Run tests
dfprofile        # Check startup time
```

---

## Recommended Workflow

1. **Initial Setup**
   ```bash
   ./install.sh
   dotfiles-tour.sh
   machine-create  # Create machine-specific config
   ```

2. **Daily Use**
   ```bash
   Ctrl+Space      # Command palette
   tw myproject    # Start workspace
   dfd             # Regular health checks
   ```

3. **Customization**
   ```bash
   v.conf          # Edit configuration
   machine-edit    # Edit machine config
   plugin install  # Add plugins
   ```

4. **Maintenance**
   ```bash
   dfupdate        # Pull latest changes
   dfprofile       # Check performance
   dfaudit         # Security audit
   plugin update   # Update plugins
   ```

---

## Optimization Tips

1. **Startup Time**
   ```bash
   dfprofile --tips        # Get optimization suggestions
   dfcompile              # Compile zsh files
   plugin lazy <name>     # Lazy-load heavy plugins
   ```

2. **Analytics**
   ```bash
   dfanalytics suggestions  # Find alias opportunities
   dfanalytics tools       # Identify unused tools
   ```

3. **Machine-Specific**
   - Laptops: Use `MOTD_STYLE="mini"` for faster startup
   - Servers: Disable `DF_NOTIFY_ENABLED="false"`
   - VMs: Use `type-virtual.zsh` for minimal features

---

## License

MIT License - See [LICENSE](LICENSE)

**Author:** Aaron D. Lee  
**Repository:** https://github.com/adlee-was-taken/dotfiles  
**Version:** 1.2.4
