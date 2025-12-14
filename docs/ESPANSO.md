# Espanso Quick Reference

Text expansion with 100+ pre-configured snippets using `..trigger` syntax.

## Controls

| Action | Shortcut |
|--------|----------|
| Toggle on/off | `ALT+SHIFT+E` |
| Search snippets | `ALT+SPACE` |
| Restart | `espanso restart` |
| Status | `espanso status` |

## Snippet Reference

### Date & Time

| Trigger | Output |
|---------|--------|
| `..date` | 2025-12-14 |
| `..sds` | 20251214 (filename-safe) |
| `..time` | 14:30:45 |
| `..ts` | 2025-12-14T14:30:45.123Z |
| `..utc` | 2025-12-14 14:30:45.123 UTC |
| `..dt` | 2025-12-14 14:30:45 EST |
| `..epoch` | 1702573845 |
| `..epochms` | 1702573845123 |
| `..month` | December |
| `..day` | Saturday |
| `..week` | Week 50 |

### Git

| Trigger | Output |
|---------|--------|
| `..gstat` | `git status` |
| `..gco` | `git checkout ` |
| `..gcm` | `git commit -m ""` |
| `..glog` | `git log --oneline --graph --decorate --all` |
| `..gpush` | `git push origin ` |
| `..gpull` | `git pull origin ` |
| `..gadd` | `git add .` |
| `..branch` | Current branch name (dynamic) |

### Docker

| Trigger | Output |
|---------|--------|
| `..dps` | `docker ps` |
| `..dpsa` | `docker ps -a` |
| `..dcup` | `docker-compose up -d` |
| `..dcdown` | `docker-compose down` |
| `..dlog` | `docker logs -f ` |
| `..dexec` | `docker exec -it ` |
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
| `..mdcode` | Code block |
| `..mdbash` | Bash code block |
| `..mdpy` | Python code block |
| `..mdtable` | Table template |
| `..mdlink` | Link (prompts for text/url) |

### Comments

| Trigger | Output |
|---------|--------|
| `..todo` | `// TODO: ` |
| `..fixme` | `// FIXME: ` |
| `..note` | `// NOTE: ` |
| `..hack` | `// HACK: ` |

### Quick Commands

| Trigger | Output |
|---------|--------|
| `..ll` | `ls -lah` |
| `..grep` | `grep -rni "" .` |
| `..find` | `find . -name ""` |
| `..port` | `lsof -i :` |
| `..proc` | `ps aux | grep ` |
| `..disk` | `df -h` |
| `..mem` | `free -h` |

### Emoticons

| Trigger | Output |
|---------|--------|
| `..shrug` | ¯\\\_(ツ)\_/¯ |
| `..flip` | (╯°□°)╯︵ ┻━┻ |
| `..unflip` | ┬─┬ ノ( ゜-゜ノ) |
| `..lenny` | ( ͡° ͜ʖ ͡°) |
| `..check` | ✓ |
| `..cross` | ✗ |
| `..arrow` | → |

### Quick Responses

| Trigger | Output |
|---------|--------|
| `..brb` | Be right back |
| `..lgtm` | Looks good to me |
| `..wfm` | Works for me |
| `..tyvm` | Thank you very much |

### Auto-Corrections

These work without `..` prefix:

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

## Adding Custom Snippets

Edit `~/.config/espanso/match/base.yml`:

```yaml
matches:
  # Simple replacement
  - trigger: "..hw"
    replace: "Hello, World!"

  # With shell command
  - trigger: "..uptime"
    replace: "{{output}}"
    vars:
      - name: output
        type: shell
        params:
          cmd: 'uptime -p'

  # With date
  - trigger: "..today"
    replace: "Today is {{mydate}}"
    vars:
      - name: mydate
        type: date
        params:
          format: "%B %d, %Y"
```

After editing: `espanso restart`

## Config Locations

```
~/.config/espanso/
├── config/default.yml    # Settings
└── match/
    ├── base.yml          # Main snippets
    └── personal.yml      # Your info
```

## Troubleshooting

```bash
espanso status          # Check if running
espanso restart         # Restart service
espanso log             # View logs
espanso match list      # List all triggers
```

## Installing Packages

```bash
espanso install emoji          # :smile: → 😊
espanso install greek-letters  # :alpha: → α
espanso install math           # :sum: → ∑
espanso package list           # Show installed
```

Browse more: https://hub.espanso.org/
