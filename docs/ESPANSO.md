# Espanso Quick Reference Guide

A comprehensive guide to using espanso text expansion with Aaron D. Lee's custom configuration.

> **Last Updated**: 2025-12-14

## 🚀 Getting Started

### Installation

Espanso is automatically installed when you run the main install script:

```bash
./install.sh
```

Or install it separately:

```bash
# Arch Linux
paru -S espanso-bin
espanso service register

# Ubuntu/Debian
wget https://github.com/espanso/espanso/releases/latest/download/espanso-debian-x11-amd64.deb
sudo apt install ./espanso-debian-x11-amd64.deb
espanso service register

# macOS
brew tap espanso/espanso
brew install espanso
espanso service register
```

### Initial Setup

Run the setup wizard to personalize your configuration:

```bash
cd ~/.dotfiles
./bin/setup-espanso.sh
```

This will:
- Personalize your snippets with your information
- Install optional espanso packages
- Show you useful triggers and tips

## ⌨️ Basic Controls

| Action | Shortcut |
|--------|----------|
| Toggle espanso on/off | `ALT+SHIFT+E` |
| Open search menu | `ALT+SPACE` |
| Restart espanso | `espanso restart` |
| Check status | `espanso status` |

## Complete Snippet Reference

All triggers use the `..` prefix for consistency and to avoid accidental expansion.

### Date & Time Stamps

| Trigger | Output | Example |
|---------|--------|---------|
| `..date` | Current date | `2025-12-14` |
| `..ds` | Date stamp (alias) | `2025-12-14` |
| `..sds` | Short date (filename safe) | `20251214` |
| `..ts` | UTC ISO 8601 timestamp | `2025-12-14T14:30:45.123Z` |
| `..time` | Current time | `14:30:45` |
| `..utime` | UTC time | `14:30:45` |
| `..ztime` | Time with timezone | `14:30:45.123 EST` |
| `..uztime` | UTC time with timezone | `14:30:45.123 UTC` |
| `..dt` | Date/time with timezone | `2025-12-14 14:30:45 EST` |
| `..udt` | UTC date/time | `2025-12-14 14:30:45 UTC` |
| `..utc` | Full UTC timestamp | `2025-12-14 14:30:45.123 UTC` |
| `..month` | Current month name | `December` |
| `..year` | Current year | `2025` |
| `..week` | Week number | `Week 50` |
| `..day` | Day of week | `Saturday` |

### Unix Timestamps

| Trigger | Output | Example |
|---------|--------|---------|
| `..epoch` | Unix timestamp (seconds) | `1702573845` |
| `..epochms` | Unix timestamp (milliseconds) | `1702573845123` |

### Git Shortcuts

| Trigger | Output |
|---------|--------|
| `..gstat` | `git status` |
| `..gco` | `git checkout ` |
| `..gcm` | `git commit -m ""` |
| `..glog` | `git log --oneline --graph --decorate --all` |
| `..gpush` | `git push origin ` |
| `..gpull` | `git pull origin ` |
| `..gbranch` | `git branch -a` |
| `..gdiff` | `git diff` |
| `..gadd` | `git add .` |
| `..branch` | Current git branch name |

### Docker Shortcuts

| Trigger | Output |
|---------|--------|
| `..dps` | `docker ps` |
| `..dpsa` | `docker ps -a` |
| `..dcup` | `docker-compose up -d` |
| `..dcdown` | `docker-compose down` |
| `..dlog` | `docker logs -f ` |
| `..dexec` | `docker exec -it ` |
| `..dim` | `docker images` |
| `..dprune` | `docker system prune -af` |

### System Information

| Trigger | Output | Description |
|---------|--------|-------------|
| `..ip` | Your public IP | Via ifconfig.me |
| `..locip` | Your local IP | From hostname -i |

### Code Templates

| Trigger | Output |
|---------|--------|
| `..bash` | Bash script template with shebang and error handling |
| `..python` | Python script template with main function |
| `..she!` | `#!/usr/bin/env bash` (shebang only) |

**Bash Template:**
```bash
#!/usr/bin/env bash

set -euo pipefail

```

**Python Template:**
```python
#!/usr/bin/env python3

def main():
    pass

if __name__ == "__main__":
    main()
```

### Markdown Helpers

| Trigger | Output |
|---------|--------|
| `..mdcode` | Markdown code block |
| `..mdbash` | Bash code block |
| `..mdpy` | Python code block |
| `..mdjs` | JavaScript code block |
| `..mdtable` | Markdown table template |
| `..mdlink` | Markdown link (interactive) |
| `..mdimg` | Markdown image (interactive) |

**Table Template:**
```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
```

### Emoticons & Symbols

| Trigger | Output |
|---------|--------|
| `..shrug` | ¯\\\_(ツ)_/¯ |
| `..flip` | (╯°□°)╯︵ ┻━┻ |
| `..unflip` | ┬─┬ ノ( ゜-゜ノ) |
| `..lenny` | ( ͡° ͜ʖ ͡°) |
| `..check` | ✓ |
| `..cross` | ✗ |
| `..arrow` | → |
| `..larrow` | ← |

### Quick Responses

| Trigger | Output |
|---------|--------|
| `..brb` | Be right back |
| `..omw` | On my way |
| `..tyvm` | Thank you very much |
| `..lgtm` | Looks good to me |
| `..wfm` | Works for me |
| `..ack` | Acknowledged |
| `..asap` | As soon as possible |

### File Paths & Navigation

| Trigger | Output |
|---------|--------|
| `..~` | `cd ~` |
| `..tmp` | `cd /tmp/` |
| `..logs` | `cd /var/log/` |

### Common URLs

| Trigger | Output |
|---------|--------|
| `..gh` | https://github.com |
| `..gl` | https://gitlab.com |
| `..gist` | https://gist.github.com |
| `..so` | https://stackoverflow.com |
| `..reddit` | https://reddit.com |

### Programming Comments

| Trigger | Output |
|---------|--------|
| `..todo` | `// TODO: ` |
| `..fixme` | `// FIXME: ` |
| `..note` | `// NOTE: ` |
| `..hack` | `// HACK: ` |
| `..debug` | `// DEBUG: ` |

### Common Commands

| Trigger | Output |
|---------|--------|
| `..ll` | `ls -lah` |
| `..la` | `ls -A` |
| `..grep` | `grep -rni "" .` |
| `..find` | `find . -name ""` |
| `..port` | `lsof -i :` |
| `..kill` | `kill -9 ` |
| `..proc` | `ps aux | grep ` |
| `..disk` | `df -h` |
| `..mem` | `free -h` |

### Lorem Ipsum

| Trigger | Output |
|---------|--------|
| `..lorem` | Single paragraph |
| `..loremlong` | Extended lorem ipsum (4 sentences) |

### Auto-Corrections

These work automatically without the `..` prefix:

| Typo | Correction |
|------|------------|
| `teh` | the |
| `recieve` | receive |
| `seperator` | separator |
| `definately` | definitely |
| `occured` | occurred |
| `lenght` | length |
| `wierd` | weird |
| `thier` | their |

## Creating Custom Snippets

Edit your snippet files:

```bash
# Base snippets (general use)
vim ~/.config/espanso/match/base.yml

# Personal snippets (your info)
vim ~/.config/espanso/match/personal.yml
```

### Simple Text Replacement

```yaml
matches:
  - trigger: "..hw"
    replace: "Hello, World!"
```

### With Date Variables

```yaml
matches:
  - trigger: "..today"
    replace: "Today is {{mydate}}"
    vars:
      - name: mydate
        type: date
        params:
          format: "%B %d, %Y"
```

### With Shell Commands

```yaml
matches:
  - trigger: "..uptime"
    replace: "{{output}}"
    vars:
      - name: output
        type: shell
        params:
          cmd: 'uptime -p'
```

### Multi-line Templates

```yaml
matches:
  - trigger: "..header"
    replace: |
      # ============================================================================
      # {{title}}
      # Author: Aaron D. Lee
      # Date: {{date}}
      # ============================================================================
    vars:
      - name: title
        type: form
        params:
          layout: "Title: {{title}}"
      - name: date
        type: date
        params:
          format: "%Y-%m-%d"
```

## Package Management

### List Installed Packages

```bash
espanso package list
```

### Install Additional Packages

```bash
# Emoji support
espanso install emoji --force

# Greek letters
espanso install greek-letters --force

# Math symbols
espanso install math --force

# Complete emoji collection
espanso install all-emojis --force
```

### Browse Available Packages

Visit: https://hub.espanso.org/

## Configuration

### Main Configuration

Location: `~/.config/espanso/config/default.yml`

Key settings:

```yaml
# Toggle key
toggle_key: ALT+SHIFT+E

# Search shortcut
search_shortcut: ALT+SPACE

# Backend
backend: Auto

# Show notifications
show_notifications: true

# Auto-restart on config changes
auto_restart: true
```

### Match Files

- `~/.config/espanso/match/base.yml` - Main snippets (100+ triggers)
- `~/.config/espanso/match/personal.yml` - Personal information

## Troubleshooting

### Espanso Not Working

1. Check if running:
   ```bash
   espanso status
   ```

2. Restart the service:
   ```bash
   espanso restart
   ```

3. Check logs:
   ```bash
   espanso log
   ```

### Snippets Not Expanding

1. Verify the trigger syntax in your YAML files
2. Check for YAML syntax errors:
   ```bash
   espanso match list
   ```
3. Ensure espanso is enabled (not toggled off with `ALT+SHIFT+E`)

### Test a Specific Trigger

```bash
# List all matches
espanso match list | grep "..date"

# Check if trigger is recognized
espanso match list | grep "trigger"
```

## Pro Tips

1. **Consistent Naming**: All triggers use `..` prefix to avoid accidents
2. **Quick Testing**: Type trigger in any text field to test immediately
3. **Search Feature**: Use `ALT+SPACE` to search all available snippets
4. **Restart After Changes**: `espanso restart` after editing YAML files
5. **Check Logs**: Use `espanso log` to debug issues
6. **Backup Your Config**: Your espanso config is in your dotfiles repo!

## Common Workflows

### Developer Workflow

```
..gstat     → Check git status
..gadd      → Stage all changes
..gcm       → Commit with message
..gpush     → Push to remote
```

### Documentation Writing

```
..date      → Add current date
..mdcode    → Insert code block
..mdtable   → Create table
..todo      → Add TODO comment
```

### System Administration

```
..dps       → Check running containers
..disk      → Check disk usage
..mem       → Check memory usage
..port      → Check port usage
```

## Syncing Across Systems

Your espanso config is part of your dotfiles:

```bash
# On system A (after making changes)
cd ~/.dotfiles
git add espanso/
git commit -m "Update espanso snippets"
git push

# On system B (pull changes)
cd ~/.dotfiles
git pull
espanso restart
```

## Resources

- [Official Documentation](https://espanso.org/docs/)
- [Package Hub](https://hub.espanso.org/)
- [GitHub Repository](https://github.com/espanso/espanso)
- [Community Forum](https://github.com/espanso/espanso/discussions)

---

**Configuration Location**: `~/.config/espanso/`  
**Total Triggers**: 100+ pre-configured  
**Custom Prefix**: `..` (double period)  
**Last Updated**: 2025-12-14

Add your own snippets to `personal.yml` for custom shortcuts!
