# Changelog - Version 1.2.0

## [1.2.0] - 2025-12-16

### Added

#### Python Project Templates
- **`py-new`** - Basic Python project with venv, tests, and proper structure
- **`py-django`** - Django web application template with best practices
- **`py-flask`** - Flask web application with blueprints and templates
- **`py-fastapi`** - FastAPI REST API with automatic documentation
- **`py-data`** - Data science project with Jupyter, pandas, and structured data directories
- **`py-cli`** - Command-line tool template using Click framework

**Features:**
- Automatic virtual environment creation
- Poetry support (configurable via `PY_TEMPLATE_USE_POETRY`)
- Pre-configured .gitignore for Python projects
- README with setup instructions
- Requirements.txt with common dependencies
- Project structure following best practices
- Optional git initialization
- Quick aliases: `pynew`, `pydjango`, `pyflask`, `pyfast`, `pydata`, `pycli`
- `venv` function to quickly activate virtual environments

#### SSH Session Manager with Tmux Integration
- **Save SSH connection profiles** with aliases for quick access
- **Automatic tmux session attachment** on remote hosts
- **Auto-create named sessions** per server connection
- **Fuzzy search connections** with fzf integration
- **Dotfiles sync** to remote servers
- **Quick reconnect** to last used connection

**Commands:**
- `ssh-save <n> <connection>` - Save connection profile
- `ssh-connect <n>` - Connect with auto-tmux attach
- `ssh-list` - List all saved profiles
- `sshf` - Fuzzy search and connect
- `ssh-reconnect` - Quick reconnect to last/specific connection
- `ssh-sync-dotfiles <n>` - Deploy dotfiles to remote

**Aliases:**
- `sshl`, `sshs`, `sshc`, `sshd`, `sshr`, `sshsync`

#### Tmux Workspace Manager
- **Pre-configured workspace templates** for different workflows
- **Quick workspace creation** from templates
- **Session management** with persistence across disconnects
- **Custom template creation** by saving current layouts
- **Fuzzy search workspaces** with fzf
- **Pane synchronization toggle** for multi-server commands

**Templates:**
- `dev` - 3 panes: vim (50%), terminal (25%), logs (25%)
- `ops` - 4 panes in grid for monitoring
- `ssh-multi` - 4 panes for multi-server management
- `debug` - 2 panes: main (70%), helper (30%)
- `full` - Single full-screen pane
- `review` - Side-by-side comparison

**Commands:**
- `tw <n>` - Quick attach or create workspace
- `tw-create <n> [template]` - Create from template
- `tw-list` - List all workspaces
- `tw-save <n>` - Save current layout as template
- `tw-sync` - Toggle pane synchronization
- `twf` - Fuzzy search workspaces

**Aliases:**
- `twl`, `twc`, `twa`, `twd`, `tws`, `twt`, `twe`, `twf`

### Changed

#### Alias System Cleanup
- **Removed `stats` alias** - Forces explicit `dfstats` usage to avoid conflicts with other tools
- Updated help text in `dotfiles-cli` to reflect removal
- Added clarifying comments in aliases.zsh

### Configuration

#### New Python Template Settings (dotfiles.conf)
```bash
# Python Project Templates
PY_TEMPLATE_BASE_DIR="$HOME/projects"     # Where to create projects
PY_TEMPLATE_PYTHON="python3"              # Python executable
PY_TEMPLATE_VENV_NAME="venv"              # Virtual environment name
PY_TEMPLATE_USE_POETRY="false"            # Use Poetry instead of venv
PY_TEMPLATE_GIT_INIT="true"               # Auto-initialize git repos
```

#### New SSH Manager Settings (dotfiles.conf)
```bash
# SSH Session Manager
SSH_AUTO_TMUX="true"                      # Auto-attach to tmux on connect
SSH_TMUX_SESSION_PREFIX="ssh"             # Tmux session prefix
SSH_SYNC_DOTFILES="ask"                   # ask, true, or false
```

#### New Tmux Workspace Settings (dotfiles.conf)
```bash
# Tmux Workspace Manager
TW_SESSION_PREFIX="work"                  # Session name prefix
TW_DEFAULT_TEMPLATE="dev"                 # Default template
```

---

## Breaking Changes

- **`stats` alias removed** - Use `dfstats` instead
  - **Reason:** Potential conflicts with other tools/scripts
  - **Migration:** Replace `stats` with `dfstats` in any scripts or muscle memory

---

## File Structure

### New Files
```
zsh/functions/
├── python-templates.zsh       # Python project templates
├── ssh-manager.zsh            # SSH session manager
└── tmux-workspaces.zsh        # Tmux workspace manager

docs/
└── SSH_TMUX_INTEGRATION.md    # Complete integration guide

.ssh-profiles                  # SSH connection profiles (generated)
.tmux-templates/               # Tmux workspace templates (generated)
├── dev.tmux
├── ops.tmux
├── ssh-multi.tmux
├── debug.tmux
├── full.tmux
└── review.tmux
```

### Modified Files
- `zsh/aliases.zsh` - Removed `stats` alias
- `dotfiles.conf` - New configuration sections (optional)

---

## Integration Instructions

### 1. Add to .zshrc

Add to the deferred loading section in `.zshrc`:

```bash
_deferred_load() {
    # ... existing code ...
    
    # Python project templates
    [[ -f "$_dotfiles_dir/zsh/functions/python-templates.zsh" ]] && \
        source "$_dotfiles_dir/zsh/functions/python-templates.zsh"
    
    # SSH Session Manager
    [[ -f "$_dotfiles_dir/zsh/functions/ssh-manager.zsh" ]] && \
        source "$_dotfiles_dir/zsh/functions/ssh-manager.zsh"
    
    # Tmux Workspace Manager
    [[ -f "$_dotfiles_dir/zsh/functions/tmux-workspaces.zsh" ]] && \
        source "$_dotfiles_dir/zsh/functions/tmux-workspaces.zsh"
}
```

### 2. Reload Shell

```bash
source ~/.zshrc
# or
exec zsh
```

---

## Usage Examples

### Python Templates

**Basic project:**
```bash
py-new myproject
cd myproject
source venv/bin/activate
```

**Django:**
```bash
py-django myblog
cd myblog
source venv/bin/activate
python manage.py runserver
```

**Data Science:**
```bash
py-data analysis
cd analysis
source venv/bin/activate
jupyter notebook
```

### SSH + Tmux Workflow

**Save and connect:**
```bash
# Save connection
ssh-save prod user@prod.example.com 22 ~/.ssh/prod_key

# Connect (auto-attaches to tmux)
ssh-connect prod
```

**Multi-server monitoring:**
```bash
# Create workspace
tw-create monitoring ssh-multi

# In each pane, connect to different server
# Enable sync to run commands on all
tw-sync
```

### Tmux Workspaces

**Quick project setup:**
```bash
# One command creates workspace with dev template
tw myproject

# Panes ready:
# 1. Vim/editor
# 2. Terminal
# 3. Logs
```

**Custom workflow:**
```bash
# Create with specific template
tw-create backend ops

# Save current layout for reuse
tw-save my-custom-template
```

---

## Testing Checklist

- [ ] Python templates create correct structure
- [ ] Virtual environments activate properly
- [ ] SSH profiles save and load correctly
- [ ] SSH auto-tmux attachment works on remote
- [ ] Tmux templates create expected layouts
- [ ] Workspace persistence across sessions
- [ ] Fuzzy search works (requires fzf)
- [ ] `stats` alias is removed
- [ ] `dfstats` still works correctly
- [ ] All new aliases function properly

---

## Documentation Updates

### Created
- `docs/SSH_TMUX_INTEGRATION.md` - Complete guide for SSH and Tmux features

### Update Needed
- `README.md` - Add Python Templates, SSH Manager, and Tmux Workspaces sections
- `README.md` - Update aliases table (remove `stats`)
- `SETUP_GUIDE.md` - Add integration instructions
- `SETUP_GUIDE.md` - Document configuration options

---

## Future Enhancements (v1.3.0)

### Python Templates
- Add `py-test` template for testing frameworks
- Add `py-package` for PyPI package development
- Add `py-ml` for ML projects with more ML tools
- Interactive template customization wizard
- Pyenv integration for version management
- GitHub Actions workflow templates
- Docker support for projects

### SSH & Tmux
- SSH connection health monitoring
- Auto-reconnect on network drop
- Tmux session backup/restore
- Remote tmux session discovery
- Multi-hop SSH connections
- SSH tunnel management
- Tmux plugin recommendations

---

## Known Issues

None reported yet.

---

## Credits

- SSH Manager: Inspired by SSH config management tools
- Tmux Workspaces: Inspired by tmuxinator and teamocil
- Python Templates: Best practices from Python community

---

## Upgrade Notes

This is a **minor version** update with new features. No breaking changes except the intentional removal of the `stats` alias.

**Recommended upgrade path:**
1. Pull latest dotfiles
2. Review new configuration options in `dotfiles.conf`
3. Add integration code to `.zshrc` (see above)
4. Reload shell
5. Test new features

**Optional:**
- Customize Python template settings
- Set up SSH profiles for your servers
- Create custom tmux templates
