# Espanso Quick Reference

Text expansion with 100+ pre-configured snippets using `..trigger` syntax.

## Controls

| Action | Shortcut |
|--------|----------|
| Toggle on/off | `ALT+SHIFT+E` |
| Search snippets | `ALT+SPACE` |
| Restart | `espanso restart` |
| Status | `espanso status` |
| View logs | `espanso log` |

---

## Snippet Categories

### Date & Time

| Trigger | Output | Example |
|---------|--------|---------|
| `..date` | Current date | 2025-12-15 |
| `..sds` | Filename-safe date | 20251215 |
| `..time` | Current time | 14:30:45 |
| `..ts` | ISO timestamp | 2025-12-15T14:30:45.123Z |
| `..utc` | UTC datetime | 2025-12-15 14:30:45.123 UTC |
| `..dt` | Local datetime | 2025-12-15 14:30:45 EST |
| `..udt` | UTC datetime | 2025-12-15 14:30:45 UTC |
| `..ztime` | Time with timezone | 14:30:45.123 EST |
| `..epoch` | Unix timestamp | 1702573845 |
| `..epochms` | Unix ms timestamp | 1702573845123 |
| `..month` | Month name | December |
| `..day` | Day name | Saturday |
| `..week` | Week number | Week 50 |
| `..year` | Year | 2025 |

### Git Commands

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
| `..branch` | Current branch name (dynamic) |

### Docker Commands

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

### System Info

| Trigger | Output |
|---------|--------|
| `..ip` | Public IP (via curl) |
| `..locip` | Local IP |

### Code Templates

| Trigger | Output |
|---------|--------|
| `..bash` | Bash script with shebang + `set -euo pipefail` |
| `..python` | Python script with main() |
| `..she!` | `#!/usr/bin/env bash` |

### Markdown

| Trigger | Output |
|---------|--------|
| `..mdcode` | Code block (triple backticks) |
| `..mdbash` | Bash code block |
| `..mdpy` | Python code block |
| `..mdjs` | JavaScript code block |
| `..mdtable` | Table template |
| `..mdlink` | Link (prompts for text/url) |
| `..mdimg` | Image (prompts for alt/url) |

### Comments

| Trigger | Output |
|---------|--------|
| `..todo` | `// TODO: ` |
| `..fixme` | `// FIXME: ` |
| `..note` | `// NOTE: ` |
| `..hack` | `// HACK: ` |
| `..debug` | `// DEBUG: ` |

### Quick Commands

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

### Navigation

| Trigger | Output |
|---------|--------|
| `..~` | `cd ~` |
| `..tmp` | `cd /tmp/` |
| `..logs` | `cd /var/log/` |

### URLs

| Trigger | Output |
|---------|--------|
| `..gh` | `https://github.com` |
| `..gl` | `https://gitlab.com` |
| `..gist` | `https://gist.github.com` |
| `..so` | `https://stackoverflow.com` |
| `..reddit` | `https://reddit.com` |

### Emoticons & Symbols

| Trigger | Output |
|---------|--------|
| `..shrug` | ¯\\\_(ツ)\_/¯ |
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

### Lorem Ipsum

| Trigger | Output |
|---------|--------|
| `..lorem` | One paragraph |
| `..loremlong` | Four paragraphs |

### Clipboard

| Trigger | Output |
|---------|--------|
| `..qp` | Paste from primary selection (X11/Wayland) |

---

## Auto-Corrections

These work without the `..` prefix:

| Typo | Correction |
|------|------------|
| teh | the |
| recieve | receive |
| definately | definitely |
| seperator | separator |
| occured | occurred |
| lenght | length |
| wierd | weird |
| thier | their |

---

## Personal Snippets

Edit `~/.dotfiles/espanso/match/personal.yml`:

```yaml
matches:
  - trigger: "..myemail"
    replace: "your.email@example.com"

  - trigger: "..myname"
    replace: "Your Full Name"

  - trigger: "..myphone"
    replace: "+1 (555) 123-4567"

  - trigger: "..sig"
    replace: |
      Best regards,
      Your Full Name
      your.email@example.com

  - trigger: "..myaddr"
    replace: |
      123 Main Street
      City, ST 12345
```

Run `setup-espanso.sh` to configure interactively.

---

## Adding Custom Snippets

Edit `~/.dotfiles/espanso/match/base.yml`:

### Simple Replacement

```yaml
matches:
  - trigger: "..hw"
    replace: "Hello, World!"
```

### With Shell Command

```yaml
  - trigger: "..uptime"
    replace: "{{output}}"
    vars:
      - name: output
        type: shell
        params:
          cmd: 'uptime -p'
```

### With Date Formatting

```yaml
  - trigger: "..today"
    replace: "Today is {{mydate}}"
    vars:
      - name: mydate
        type: date
        params:
          format: "%B %d, %Y"
```

### With Form Input

```yaml
  - trigger: "..mailto"
    replace: "<a href=\"mailto:{{email}}\">{{name}}</a>"
    vars:
      - name: email
        type: form
        params:
          layout: "Email: {{email}}"
      - name: name
        type: form
        params:
          layout: "Display name: {{name}}"
```

### With Clipboard

```yaml
  - trigger: "..cliplink"
    replace: "[{{clipboard}}]({{clipboard}})"
    vars:
      - name: clipboard
        type: clipboard
```

After editing: `espanso restart`

---

## Config Files

```
~/.config/espanso/          (symlinked to ~/.dotfiles/espanso/)
├── config/
│   └── default.yml         # Global settings
└── match/
    ├── base.yml            # Main snippets (100+)
    ├── personal.yml        # Your personal info
    └── packages/           # Installed packages
```

---

## Useful Commands

```bash
espanso status              # Check if running
espanso start               # Start service
espanso restart             # Restart service
espanso stop                # Stop service
espanso log                 # View logs
espanso edit                # Open config in editor
espanso match list          # List all triggers
espanso path                # Show config paths
```

---

## Installing Packages

Browse packages: https://hub.espanso.org/

```bash
espanso install emoji          # :smile: → 😊
espanso install greek-letters  # :alpha: → α
espanso install math           # :sum: → ∑
espanso install lorem          # More lorem ipsum options
espanso package list           # Show installed
espanso package uninstall <n>  # Remove package
```

---

## Troubleshooting

### Espanso Not Starting

```bash
espanso service register    # Register as service
espanso start
```

### Snippets Not Expanding

```bash
espanso restart
espanso log                 # Check for errors
```

### Wrong Keyboard Layout

Edit `~/.config/espanso/config/default.yml`:

```yaml
backend: Clipboard          # Try different backend
```

### Check Syntax

```bash
espanso --help              # Will error if YAML is invalid
espanso match list          # Lists triggers if syntax is OK
```

### Wayland Issues

If using Wayland, you may need the Wayland-specific build:

```bash
# Check your session
echo $XDG_SESSION_TYPE

# Install Wayland version if needed
# (varies by distro)
```

---

## Tips

1. **Test snippets** - Type them in any text field
2. **Use search** - `ALT+SPACE` to search all triggers
3. **Escape triggers** - Type slowly or add a space to prevent expansion
4. **Backup config** - It's in your dotfiles, so it syncs automatically
5. **Restart after changes** - `espanso restart`
