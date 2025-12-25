# Tmuxinator Integration

The dotfiles now include seamless integration with [tmuxinator](https://github.com/tmuxinator/tmuxinator) for complex project configurations, while maintaining backward compatibility with simple `.tmux` templates.

## Installation

```bash
# Arch/CachyOS
sudo pacman -S tmuxinator

# Or via Ruby gems
gem install tmuxinator
```

## Quick Start

```bash
# Create a new tmuxinator project
txi-new myproject dev

# Edit the configuration
txi-edit myproject

# Start the project
txi myproject

# Or use the unified tw command (auto-detects tmuxinator)
tw myproject
```

## Command Reference

### Tmuxinator Commands (txi-*)

| Command | Alias | Description |
|---------|-------|-------------|
| `txi <name>` | - | Start/attach to tmuxinator project |
| `txi-new <name> [template]` | `txin` | Create new project |
| `txi-edit <name>` | `txie` | Edit project YAML file |
| `txi-list` | `txil` | List all tmuxinator projects |
| `txi-delete <name>` | `txid` | Delete project |
| `txi-stop <name>` | `txis` | Stop running session |
| `txi-templates` | `txit` | Show available templates |
| `txi-import <template> [name]` | - | Convert .tmux to tmuxinator |
| `txif` | - | Fuzzy search and start |
| `txi-help` | `txih` | Show help |

### Available Templates

| Template | Description |
|----------|-------------|
| `dev` | Development: editor + terminal + server + logs |
| `ops` | Operations: monitoring grid + services + SSH |
| `web` | Web development: editor + server + frontend + db |
| `data` | Data science: jupyter + code + data + terminal |
| `minimal` | Single window, single pane |

### Integration with tw-* Commands

The existing `tw` commands automatically detect tmuxinator:

```bash
# If "myproject.yml" exists in ~/.config/tmuxinator/, uses tmuxinator
# Otherwise, uses simple .tmux template
tw myproject
```

**Priority order:**
1. Running tmux session with matching name
2. Tmuxinator project (if exists)
3. Simple `.tmux` template

### Example Tmuxinator Project

```yaml
# ~/.config/tmuxinator/webapp.yml
name: webapp
root: ~/projects/webapp

# Activate virtualenv before all windows
pre_window: source venv/bin/activate

windows:
  - editor:
      layout: main-vertical
      panes:
        - vim .
        - # terminal
        
  - server:
      panes:
        - python manage.py runserver
        
  - frontend:
      layout: even-horizontal
      panes:
        - npm run watch
        - npm run tailwind
        
  - database:
      panes:
        - pgcli mydb
```

### Configuration

Add to `dotfiles.conf`:

```bash
# ============================================================================
# Tmuxinator Settings
# ============================================================================

TMUXINATOR_ENABLED="auto"             # auto, true, false
TMUXINATOR_CONFIG_DIR="$HOME/.config/tmuxinator"
TW_PREFER_TMUXINATOR="true"           # Prefer tmuxinator over simple templates
```

### Simple Templates vs Tmuxinator

| Feature | Simple (.tmux) | Tmuxinator (.yml) |
|---------|---------------|-------------------|
| Learning curve | Minimal | Moderate |
| Per-pane commands | No | Yes |
| Environment variables | No | Yes |
| Pre/post hooks | No | Yes |
| Window names | No | Yes |
| Complex layouts | Limited | Full support |
| Startup speed | Fast | Slightly slower |

**Use simple templates for:**
- Quick, ad-hoc layouts
- Simple split configurations
- Layouts you'll customize each time

**Use tmuxinator for:**
- Persistent project configurations
- Projects with specific startup commands
- Complex multi-window setups
- Team-shared configurations

### Import Existing Templates

Convert your simple `.tmux` templates to tmuxinator format:

```bash
# Import the 'dev' template as a tmuxinator project
txi-import dev myproject

# Then customize it
txi-edit myproject
```

### Tips

1. **Project Discovery**: The `tw` and `twf` commands show both active sessions and available tmuxinator projects

2. **Git Integration**: When starting a workspace in a git repo, the first pane automatically `cd`s to the repo root

3. **Synchronized Input**: Toggle with `tw-sync` to type in all panes simultaneously

4. **Fuzzy Finding**: Use `twf` or `txif` for quick project selection with fzf
