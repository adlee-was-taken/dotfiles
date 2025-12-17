# SSH & Tmux Integration Guide

Complete guide for integrating the new SSH Session Manager and Tmux Workspace Manager into your dotfiles.

## Quick Start

### 1. Add to .zshrc

Add to the deferred loading section in `.zshrc`:

```bash
_deferred_load() {
    # ... existing code ...
    
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

## SSH Session Manager

### Basic Usage

**Save a connection:**
```bash
ssh-save prod user@prod.example.com
ssh-save dev user@dev.example.com 2222 ~/.ssh/dev_key
```

**Connect with auto-tmux:**
```bash
ssh-connect prod
# Automatically attaches to or creates tmux session "ssh-prod"
```

**List all profiles:**
```bash
ssh-list
```

**Fuzzy search and connect:**
```bash
sshf
# Requires fzf
```

### Advanced Features

**With port forwarding:**
```bash
ssh-save vpn user@vpn.com 22 '' '-D 9090' 'VPN with SOCKS proxy'
```

**Edit existing profile:**
```bash
ssh-edit prod
```

**Quick reconnect:**
```bash
ssh-reconnect        # Reconnects to last connection
ssh-reconnect prod   # Reconnect to specific profile
```

**Sync dotfiles to remote:**
```bash
ssh-sync-dotfiles prod
# Syncs ~/.dotfiles to remote host
```

### Configuration

Add to `dotfiles.conf`:

```bash
# SSH Session Manager
SSH_AUTO_TMUX="true"                    # Auto-attach to tmux on connect
SSH_TMUX_SESSION_PREFIX="ssh"           # Tmux session prefix
SSH_SYNC_DOTFILES="ask"                 # ask, true, or false
```

### Aliases

```bash
sshl        # ssh-list
sshs        # ssh-save
sshc        # ssh-connect
sshd        # ssh-delete
sshr        # ssh-reconnect
sshsync     # ssh-sync-dotfiles
sshf        # Fuzzy search
```

---

## Tmux Workspace Manager

### Basic Usage

**Create a workspace:**
```bash
tw-create myproject         # Uses default 'dev' template
tw-create backend ops       # Uses 'ops' template
```

**Quick attach (or create if not exists):**
```bash
tw myproject
```

**List workspaces:**
```bash
tw-list
# or
tw
```

**Delete workspace:**
```bash
tw-delete myproject
```

### Available Templates

**dev** - Development (3 panes)
- Vim/editor (50% left)
- Terminal (25% top-right)
- Logs (25% bottom-right)

**ops** - Operations (4 panes in grid)
- Perfect for monitoring multiple things

**ssh-multi** - Multi-server (4 panes)
- Manage multiple SSH connections
- Optional pane synchronization

**debug** - Debugging (2 panes)
- Main pane (70%)
- Helper pane (30%)

**full** - Single pane
- Just one full-screen pane

**review** - Code review (2 equal panes)
- Side-by-side comparison

### Working with Templates

**List available templates:**
```bash
tw-templates
```

**Edit a template:**
```bash
tw-template-edit dev
```

**Save current layout as template:**
```bash
# Inside tmux, arrange your panes how you want
tw-save my-custom-layout
```

### Advanced Features

**Fuzzy search workspaces:**
```bash
twf
# Requires fzf
```

**Rename workspace:**
```bash
tw-rename old-name new-name
```

**Toggle pane synchronization:**
```bash
tw-sync
# Sends same input to all panes - great for multi-server commands
```

### Configuration

Add to `dotfiles.conf`:

```bash
# Tmux Workspace Manager
TW_SESSION_PREFIX="work"                # Session name prefix
TW_DEFAULT_TEMPLATE="dev"               # Default template
```

### Aliases

```bash
tw          # Quick attach/create
twl         # tw-list
twc         # tw-create
twa         # tw-attach
twd         # tw-delete
tws         # tw-save
twt         # tw-templates
twe         # tw-template-edit
twf         # Fuzzy search
```

---

## Integration Examples

### Combined Workflow

**1. Create a workspace for remote work:**
```bash
# Save SSH connection
ssh-save backend-prod user@backend.prod.com 22 ~/.ssh/prod_key

# Create local workspace to track what you're doing
tw-create backend-work dev

# Connect to remote with auto-tmux
ssh-connect backend-prod
# Now on remote server in tmux session "ssh-backend-prod"
```

**2. Multi-server monitoring:**
```bash
# Create workspace for ops
tw-create monitoring ops

# In each pane, connect to different server:
# Pane 1: ssh-connect server1
# Pane 2: ssh-connect server2
# Pane 3: ssh-connect server3
# Pane 4: local monitoring

# Enable synchronization for commands across all
tw-sync
```

**3. Development workflow:**
```bash
# Morning routine - one command:
tw myproject

# If workspace exists: attaches
# If not: creates with dev template

# Inside workspace:
# - Pane 1: vim
# - Pane 2: run dev server
# - Pane 3: tail -f logs/development.log
```

### Custom Template Example

Create a template for your specific workflow:

**File:** `~/.dotfiles/.tmux-templates/webdev.tmux`
```tmux
# Web development workspace
# Vim (left) + Dev server (top-right) + Browser sync (bottom-right)

split-window -h -p 50
split-window -v -p 50

# Auto-start commands
send-keys -t 0 'vim' C-m
send-keys -t 1 'npm run dev' C-m
send-keys -t 2 'npm run watch' C-m

select-pane -t 0
```

Usage:
```bash
tw-create my-webapp webdev
```

---

## Tips & Tricks

### SSH Manager

**1. Auto-sync dotfiles on first connect:**
```bash
ssh-save newserver user@new.com
ssh-sync-dotfiles newserver
ssh-connect newserver
```

**2. Use descriptive names:**
```bash
ssh-save aws-prod-db "user@prod-db.amazonaws.com" 22 ~/.ssh/aws-prod.pem "" "Production Database"
```

**3. Port forwarding shorthand:**
```bash
# Local port 8080 → Remote port 80
ssh-save webapp "user@server.com" 22 "" "-L 8080:localhost:80"
```

### Tmux Workspaces

**1. Project-specific setup:**
Create `.tmux-project` in project root with workspace commands:
```bash
#!/bin/bash
tw-create ${PWD##*/} dev
tw ${PWD##*/}
```

**2. Quick workspace switching:**
Add to your `.zshrc`:
```bash
# Switch to workspace by number
alias tw1='tw project1'
alias tw2='tw project2'
alias tw3='tw project3'
```

**3. Persistent sessions:**
Workspaces survive reboots if you use `tmux-resurrect` or `tmux-continuum` plugins.

**4. Multi-pane commands:**
```bash
# Send command to all panes
tw-sync                              # Enable sync
echo "Running on all panes"          # Typed in all
tw-sync                              # Disable sync
```

---

## Tmux Configuration Enhancements

Add to `~/.tmux.conf` for better integration:

```tmux
# Better pane navigation (vim-style)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Quick pane resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Split panes using | and -
bind | split-window -h
bind - split-window -v

# Reload config
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# Enable mouse support
set -g mouse on

# Status bar
set -g status-position bottom
set -g status-style 'bg=colour234 fg=colour137'
set -g status-left '#[fg=colour233,bg=colour245,bold] #S '
set -g status-right '#[fg=colour233,bg=colour245,bold] %d/%m %H:%M '

# Pane borders
set -g pane-border-style 'fg=colour238'
set -g pane-active-border-style 'fg=colour51'
```

---

## Troubleshooting

### SSH Issues

**Connection fails:**
```bash
# Test connection directly
ssh -v user@host

# Check profile
ssh-list
ssh-edit myprofile
```

**Tmux not attaching on remote:**
```bash
# Check if tmux is installed on remote
ssh user@host 'which tmux'

# Disable auto-tmux for specific connection
SSH_AUTO_TMUX=false ssh-connect myprofile
```

### Tmux Issues

**Workspace not found:**
```bash
# List all tmux sessions
tmux ls

# Check session prefix
echo $TW_SESSION_PREFIX
```

**Template not working:**
```bash
# Validate template syntax
cat ~/.dotfiles/.tmux-templates/dev.tmux

# Recreate default templates
rm ~/.dotfiles/.tmux-templates/*
source ~/.zshrc  # Will regenerate
```

**Panes not splitting correctly:**
```bash
# Check tmux version
tmux -V

# Update tmux if < 3.0
# Some split options may not work on older versions
```

---

## Migration from Existing Setup

### If you already use SSH config:

Convert `~/.ssh/config` entries to profiles:

```bash
# Old ~/.ssh/config:
# Host prod
#   HostName prod.example.com
#   User ubuntu
#   Port 22
#   IdentityFile ~/.ssh/prod.pem

# New:
ssh-save prod ubuntu@prod.example.com 22 ~/.ssh/prod.pem
```

### If you already use tmux:

Existing sessions aren't affected. The workspace manager only manages sessions with the `work-` prefix (configurable).

---

## Next Steps

1. Save your most-used SSH connections
2. Create workspaces for your projects
3. Customize templates for your workflow
4. Set up project-specific workspace scripts
5. Add fuzzy search shortcuts to your workflow

Enjoy your enhanced terminal productivity!
