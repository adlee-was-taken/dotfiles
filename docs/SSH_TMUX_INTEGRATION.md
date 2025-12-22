# SSH + Tmux Integration Guide

Advanced workflows for managing SSH connections and tmux workspaces on Arch/CachyOS.

## Table of Contents

- [SSH Manager Overview](#ssh-manager-overview)
- [Basic SSH Management](#basic-ssh-management)
- [Tmux Workspace Basics](#tmux-workspace-basics)
- [SSH + Tmux Integration](#ssh--tmux-integration)
- [Workflow Examples](#workflow-examples)
- [Advanced Features](#advanced-features)
- [Multi-Server Management](#multi-server-management)
- [Troubleshooting](#troubleshooting)

---

## SSH Manager Overview

The SSH manager stores connection profiles and integrates seamlessly with tmux for session management.

**Features:**
- Save and organize SSH connections
- Auto-create tmux sessions per connection
- Quick fuzzy search and connect
- Deploy dotfiles to remote machines
- Support for custom SSH options
- No external dependencies (pure bash)

---

## Basic SSH Management

### Saving Connections

```bash
ssh-save <profile> <connection> [port] [key] [description]
```

**Examples:**

```bash
# Basic SSH
ssh-save prod user@prod.example.com

# With custom port
ssh-save prod user@prod.example.com 2222

# With SSH key
ssh-save prod user@prod.example.com 22 ~/.ssh/prod_key

# With description
ssh-save prod user@prod.example.com 22 ~/.ssh/prod_key "Production server"

# With SSH options
ssh-save prod user@prod.example.com 22 ~/.ssh/prod_key "Production" "-v -o ConnectTimeout=5"
```

### Listing Profiles

```bash
ssh-list
```

Output:
```
SSH Profiles:
  prod        user@prod.example.com:22 [~/.ssh/prod_key]
  staging     user@staging.example.com:22 [~/.ssh/staging_key]
  dev         user@dev.example.com:2222 [~/.ssh/dev_key]
  backup      user@backup.example.com:22 [default]
```

### Connecting to Profiles

```bash
ssh-connect <profile>
# or
ssh <profile>
```

### Fuzzy Search and Connect

```bash
sshf
```

Opens fuzzy selector:
```
  prod        user@prod.example.com:22
> staging     user@staging.example.com:22
  dev         user@dev.example.com:2222
  backup      user@backup.example.com:22
```

Select with arrows, press Enter to connect.

### Deleting Profiles

```bash
ssh-delete <profile>
```

### Syncing Dotfiles to Remote

```bash
ssh-sync-dotfiles <profile>
```

This will:
1. SSH into the remote machine
2. Clone your dotfiles repo
3. Run the installer
4. Validate installation

**With custom repo:**

```bash
ssh-sync-dotfiles prod --repo https://github.com/myuser/dotfiles.git
```

### Quick Reconnect

```bash
ssh-reconnect
```

Reconnects to the last SSH connection.

---

## Tmux Workspace Basics

### Quick Workspace Access

```bash
tw <name>
```

Creates or attaches to tmux session. If session exists, attaches. If not, creates with default layout.

### Creating with Templates

```bash
tw-create <name> [template]
tw-create myproject dev
tw-create monitoring ops
tw-create review review
```

**Available Templates:**

| Template | Layout | Use Case |
|----------|--------|----------|
| `dev` | vim (50%) + terminal (25%) + logs (25%) | Development |
| `ops` | 4-pane grid | Monitoring |
| `ssh-multi` | 4 panes (synchronized) | Multi-server ops |
| `debug` | 2 panes: main (70%), helper (30%) | Debugging |
| `full` | Single pane | Fullscreen work |
| `review` | Side-by-side panes | Code review |

### Listing Workspaces

```bash
tw-list
```

Output:
```
Tmux Workspaces:
  myproject    3 windows, 7 panes
  monitoring   1 window, 4 panes
  ssh-ops      2 windows, 5 panes
```

### Deleting Workspaces

```bash
tw-delete <name>
```

### Saving Custom Layout

Current window layout as a reusable template:

```bash
tw-save mytemplate
```

Then use it:

```bash
tw-create newproject mytemplate
```

### Fuzzy Workspace Selection

```bash
twf
```

Fuzzy search all tmux sessions and attach.

### Pane Synchronization

Send commands to all panes simultaneously:

```bash
tw-sync                    # Toggle on/off
```

When enabled, your typing goes to all panes. Useful for:
- Running same command on multiple servers
- Updating configs in parallel
- Monitoring multiple streams

---

## SSH + Tmux Integration

### Automatic Tmux Session on SSH

When you connect via `ssh-connect`, a tmux session is automatically created:

```bash
ssh-connect prod
# Creates tmux session: ssh_prod
# Loads ssh_prod template if available
# Attaches you to the session
```

**Session naming:** `ssh_<profile>`

### Accessing Your Session

From the remote machine:

```bash
# Attach to your session
tmux attach -t ssh_prod

# Detach (leave session running)
Ctrl+B, D
```

### Pre-configured Remote Tmux

If the remote has tmux installed, you can use its features:

```bash
# In your SSH session, create new window
Ctrl+B, C

# Navigate windows
Ctrl+B, <number>
```

### Deploy Dotfiles + Setup Tmux Remotely

```bash
ssh-sync-dotfiles prod
# Installs dotfiles on remote
# Remote will have same tmux config
```

---

## Workflow Examples

### Example 1: Web Development

**Setup:**

```bash
ssh-save staging deploy@staging.example.com 22 ~/.ssh/staging_key

tw-create webdev dev
# Now in tmux with vim ready
```

**Workflow:**

```
Pane 1 (50%): vim/nvim
  - Edit code locally
  
Pane 2 (25%): Dev terminal
  - npm start, python manage.py runserver, etc.
  
Pane 3 (25%): Logs
  - tail -f logs/debug.log
```

**Keybindings:**

```bash
# Move between panes
Ctrl+B, Left/Right/Up/Down

# Zoom pane
Ctrl+B, Z

# Create new window
Ctrl+B, C

# Switch window
Ctrl+B, 0-9
```

### Example 2: Multi-Server Monitoring

```bash
ssh-save web1 ubuntu@web1.prod.com
ssh-save web2 ubuntu@web2.prod.com
ssh-save web3 ubuntu@web3.prod.com

tw-create monitoring ops
```

**Setup in tmux:**

```bash
# In window, split into 4 panes
Ctrl+B, %           # Split left/right
Ctrl+B, "           # Split top/bottom

# In each pane, open SSH connection
ssh web1
ssh web2
ssh web3
(one more)

# Enable sync for parallel commands
tw-sync
```

Now you can run commands on all 4 servers simultaneously.

### Example 3: Database Backup + Restore

```bash
# Save DB server
ssh-save dbserver ubuntu@db.prod.com 22 ~/.ssh/db_key

# Create workspace
tw-create dbops debug
```

**Workflow:**

```
Pane 1 (70%): Main operations
  - mysqldump commands
  - pg_dump commands
  - Restore operations
  
Pane 2 (30%): Helper
  - Monitoring commands
  - Disk space checks
  - Backup status
```

### Example 4: Deployment Pipeline

```bash
ssh-save deploy user@deploy.prod.com

tw-create deploy ssh-multi
# Creates 4 synchronized panes
```

**In each pane:**

```bash
ssh-connect prod      # Pane 1
ssh-connect staging   # Pane 2
ssh-connect dev       # Pane 3
ssh-connect backup    # Pane 4

# Enable sync
tw-sync

# Now run deployment commands on all
./deploy.sh v1.2.3
```

---

## Advanced Features

### Custom SSH Options

```bash
# Verbose SSH
ssh-save prod user@prod.com 22 ~/.ssh/key "Production" "-v"

# Connection timeout
ssh-save unreliable user@unreliable.com 22 ~/.ssh/key "Unreliable" "-o ConnectTimeout=10"

# Jump host / Bastion
ssh-save internal user@internal.prod.com 22 ~/.ssh/key "Internal" "-o ProxyCommand='ssh -W %h:%p user@bastion.example.com'"

# Multiple options
ssh-save strict user@strict.com 22 ~/.ssh/key "Strict" "-v -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"
```

### SSH Config Integration

The SSH manager creates entries in `~/.ssh/config`. View them:

```bash
cat ~/.ssh/config
```

Example:
```
Host prod
    HostName prod.example.com
    User ubuntu
    IdentityFile ~/.ssh/prod_key
    Port 22
    ConnectTimeout 10
```

Use directly:

```bash
ssh prod
# Uses the saved profile from SSH config
```

### Batch Operations

Create a script for multi-server operations:

```bash
#!/bin/bash
# deploy-to-all.sh

servers=("prod" "staging" "dev")

for server in "${servers[@]}"; do
    echo "Deploying to $server..."
    ssh-connect $server << 'EOF'
        cd /app
        git pull origin main
        ./deploy.sh
        echo "✓ Deployed to $server"
        exit
EOF
done
```

Run:

```bash
chmod +x deploy-to-all.sh
./deploy-to-all.sh
```

---

## Multi-Server Management

### Save Multiple Servers

```bash
# Web servers
ssh-save web1 ubuntu@web1.prod.com
ssh-save web2 ubuntu@web2.prod.com
ssh-save web3 ubuntu@web3.prod.com

# Database servers
ssh-save db-primary ubuntu@db-primary.prod.com
ssh-save db-replica ubuntu@db-replica.prod.com

# Cache servers
ssh-save redis1 ubuntu@redis1.prod.com
ssh-save redis2 ubuntu@redis2.prod.com
```

### Create Management Workspace

```bash
tw-create prod-ops ssh-multi
# Creates workspace with 4 synchronized panes
```

### Connect to All Web Servers

```bash
# In 4 panes of the workspace
ssh-connect web1
ssh-connect web2
ssh-connect web3
# (one extra pane)

# Enable sync
tw-sync

# Run command on all
sudo systemctl restart nginx
# Command runs on all 3 web servers
```

### Monitor All Servers

```bash
tw-create monitoring ops

# Configure 4 panes for monitoring
# Pane 1: web1 - htop
# Pane 2: web2 - htop
# Pane 3: db-primary - iostat -x 1
# Pane 4: redis1 - redis-cli monitor
```

### Environment-Specific Workspaces

```bash
# Production
tw-create prod-dev dev
ssh-sync-dotfiles prod

# Staging
tw-create staging-dev dev
ssh-sync-dotfiles staging

# Development
tw-create dev-local full
```

---

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connection
ssh -vvv <profile>

# View saved connection details
ssh-list

# Delete and re-save
ssh-delete <profile>
ssh-save <profile> <connection> [options]
```

### Tmux Session Issues

```bash
# List all tmux sessions
tmux ls

# Kill a session
tmux kill-session -t <name>

# Attach to detached session
tmux attach -t <name>

# Kill all sessions
tmux kill-server
```

### SSH Sync Issues

```bash
# Test dotfiles deployment
ssh-sync-dotfiles <profile> --test

# View detailed output
ssh-sync-dotfiles <profile> --verbose

# Deploy specific branch
ssh-sync-dotfiles <profile> --branch develop
```

### Key Permission Issues

```bash
# Fix SSH key permissions
chmod 600 ~/.ssh/your_key
chmod 700 ~/.ssh

# List keys
ssh-add -l

# Add key to agent
ssh-add ~/.ssh/your_key
```

### Pane Sync Issues

```bash
# Verify sync is enabled
tmux show-window-options synchronize-panes

# Toggle sync manually
Ctrl+B, Shift+X

# Or use script
tw-sync
```

---

## Best Practices

1. **Use Descriptive Profile Names**
   ```bash
   # Good
   ssh-save prod-web-01 ubuntu@web01.prod.example.com
   ssh-save staging-db ubuntu@db.staging.example.com
   
   # Bad
   ssh-save server1 ubuntu@192.168.1.10
   ```

2. **Store Keys Securely**
   ```bash
   chmod 600 ~/.ssh/your_key
   chmod 700 ~/.ssh
   ```

3. **Use SSH Agent**
   ```bash
   eval $(ssh-agent)
   ssh-add ~/.ssh/key
   ```

4. **Enable Agent Forwarding for Nested SSH**
   ```bash
   ssh-save jumphost user@jump.example.com 22 ~/.ssh/key "" "-A"
   ```

5. **Test Connections**
   ```bash
   ssh -T <profile>
   ```

6. **Document Complex Workflows**
   ```bash
   # Create README in ~/.dotfiles/ssh-workflows/README.md
   # Document your multi-server setups
   ```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `ssh-save` | Save SSH profile |
| `ssh-list` | List all profiles |
| `ssh-connect` | Connect and create tmux session |
| `sshf` | Fuzzy search and connect |
| `ssh-delete` | Delete profile |
| `ssh-sync-dotfiles` | Deploy dotfiles to remote |
| `tw` | Quick workspace attach/create |
| `tw-create` | Create workspace with template |
| `tw-list` | List all workspaces |
| `tw-delete` | Delete workspace |
| `tw-save` | Save current layout as template |
| `tw-sync` | Toggle pane synchronization |
| `twf` | Fuzzy select workspace |
| `ssh-reconnect` | Quick reconnect to last SSH |

---

For more information on individual features, see:
- [README.md](../README.md) - Main documentation
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Installation and basic configuration
