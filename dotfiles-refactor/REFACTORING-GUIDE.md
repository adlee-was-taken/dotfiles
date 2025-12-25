# Dotfiles Refactoring Guide

This document explains the refactoring changes made to eliminate code duplication and improve maintainability.

## Summary of Changes

| Change | Impact | Lines Saved |
|--------|--------|-------------|
| Centralized header with `bootstrap.zsh` | All scripts use one source pattern | ~150 lines |
| Template-driven Python projects | `python-templates.zsh` refactored | ~60 lines |
| Unified config/color loading | Single entry point for dependencies | ~80 lines |

**Total estimated reduction: ~290 lines of duplicated code**

---

## 1. New File: `zsh/lib/bootstrap.zsh`

### Purpose
Single entry point for all scripts to source. Handles loading config, colors, and utils in the correct order with proper fallbacks.

### Usage

**In bash scripts:**
```bash
#!/usr/bin/env bash
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    # Minimal fallback only if bootstrap unavailable
    df_print_header() { echo "=== $1 ==="; }
}
```

**In zsh functions:**
```zsh
source "${0:A:h}/../lib/bootstrap.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/bootstrap.zsh" 2>/dev/null
```

### What It Provides
After sourcing `bootstrap.zsh`, you have access to:
- All `DF_*` color variables
- All `df_print_*` functions
- All `df_*` utility functions  
- All config variables from `dotfiles.conf`

---

## 2. Enhanced: `zsh/lib/utils.zsh`

### New Functions Added

```zsh
# Build a horizontal line
_df_hline "═" 66  # Returns: ══════════...

# Print MOTD-style header for scripts
df_print_header "script-name"
# Output:
# ╒══════════════════════════════════════════════════════════════════╕
# │ ✦ user@hostname          script-name          Thu Dec 25 14:30 │
# ╘══════════════════════════════════════════════════════════════════╛

# Print simpler header for functions
df_print_func_name "Function Name"
# Output:
# ╒══════════════════════════════════════════════════════════════════╕
# │ Function Name                                  Thu Dec 25 14:30 │
# ╘══════════════════════════════════════════════════════════════════╛

# Print divider line
df_print_divider
```

---

## 3. Refactored: `zsh/functions/python-templates.zsh`

### Before (Duplicated Pattern)
Each function repeated ~15 lines:
```zsh
py-flask() {
    _py_check_name "$1" || return 1
    df_print_func_name "Flask Project: $1"
    mkdir -p "$1"/{app,tests}
    # ... flask-specific setup ...
    _py_venv "$1"
    _py_gitignore "$1"
    _py_git "$1"
    df_print_success "Created: $1"
    _py_next "$1"
}
```

### After (Template-Driven)
```zsh
# Common creation function handles all boilerplate
_py_create_project() {
    local name="$1" template="$2" display_name="$3" extra_info="$4"
    
    _py_check_name "$name" || return 1
    df_print_func_name "${display_name}: ${name}"
    mkdir -p "$name"
    
    # Run template-specific setup
    local packages=$("_py_template_${template}" "$name")
    
    # Common finalization
    _py_venv "$name"
    [[ -n "$packages" ]] && _py_install "$name" $packages
    _py_gitignore "$name"
    _py_git "$name"
    df_print_success "Created: $name"
    _py_next_steps "$name" "$extra_info"
}

# Each public function is now one line
py-flask() { _py_create_project "$1" "flask" "Flask Project" "Run: python app.py"; }
py-fastapi() { _py_create_project "$1" "fastapi" "FastAPI Project" "Docs: localhost:8000/docs"; }
```

### New Features Added
- `py-templates` - List all available templates
- Better pyproject.toml support for CLI projects
- Improved file templates with more comments

---

## 4. Refactored Bin Scripts

All scripts in `bin/` now follow this pattern:

```bash
#!/usr/bin/env bash
# ============================================================================
# Script Name
# ============================================================================

# Source bootstrap (provides colors, config, and utility functions)
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    # Minimal fallback if bootstrap unavailable
    DF_GREEN=$'\033[0;32m' DF_NC=$'\033[0m'
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
}

# Script logic...

main() {
    df_print_header "script-name"
    # ...
}

main "$@"
```

### Scripts Updated
- `dotfiles-doctor.sh`
- `dotfiles-sync.sh`
- `dotfiles-update.sh`
- `dotfiles-version.sh`
- `dotfiles-stats.sh`
- `dotfiles-vault.sh`
- `dotfiles-compile.sh`
- `setup/setup-espanso.sh`
- `setup/setup-wizard.sh`

---

## How to Apply These Changes

### Option 1: Replace Files
Copy the refactored files over your existing ones:

```bash
# Backup first
cp -r ~/.dotfiles ~/.dotfiles.backup.$(date +%Y%m%d)

# Copy new lib files
cp /path/to/refactor/zsh/lib/*.zsh ~/.dotfiles/zsh/lib/

# Copy new bin scripts
cp /path/to/refactor/bin/*.sh ~/.dotfiles/bin/

# Copy new function file
cp /path/to/refactor/zsh/functions/python-templates.zsh ~/.dotfiles/zsh/functions/

# Copy new setup scripts
cp /path/to/refactor/setup/*.sh ~/.dotfiles/setup/
```

### Option 2: Gradual Migration
1. First add `bootstrap.zsh` - it won't break anything
2. Update one script at a time to use bootstrap
3. Update `python-templates.zsh` last

---

## Verification

After applying changes, verify everything works:

```bash
# Reload shell
source ~/.zshrc

# Test health check
dfd

# Test version
dfv

# Test Python templates
py-templates
py-new test-project
rm -rf test-project

# Test that headers display correctly
dotfiles-doctor.sh
dotfiles-stats.sh
```

---

## File Structure After Refactoring

```
~/.dotfiles/
├── zsh/
│   ├── lib/
│   │   ├── bootstrap.zsh    # NEW: Single entry point
│   │   ├── config.zsh       # Loads dotfiles.conf
│   │   ├── colors.zsh       # Color definitions
│   │   └── utils.zsh        # ENHANCED: Centralized headers
│   └── functions/
│       └── python-templates.zsh  # REFACTORED: Template-driven
├── bin/
│   ├── dotfiles-doctor.sh   # REFACTORED: Uses bootstrap
│   ├── dotfiles-sync.sh     # REFACTORED: Uses bootstrap
│   ├── dotfiles-update.sh   # REFACTORED: Uses bootstrap
│   ├── dotfiles-version.sh  # REFACTORED: Uses bootstrap
│   ├── dotfiles-stats.sh    # REFACTORED: Uses bootstrap
│   ├── dotfiles-vault.sh    # REFACTORED: Uses bootstrap
│   └── dotfiles-compile.sh  # REFACTORED: Uses bootstrap
└── setup/
    ├── setup-espanso.sh     # REFACTORED: Uses bootstrap
    └── setup-wizard.sh      # REFACTORED: Uses bootstrap
```

---

## Benefits

1. **Single Source of Truth**: Header formatting defined once in `utils.zsh`
2. **Easier Maintenance**: Change header style in one place, affects all scripts
3. **Consistent Appearance**: All scripts look the same
4. **Smaller Files**: Each bin script is ~30-50 lines shorter
5. **Better Fallbacks**: `bootstrap.zsh` handles missing files gracefully
6. **Template System**: Adding new Python project types is now trivial
