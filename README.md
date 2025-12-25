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
