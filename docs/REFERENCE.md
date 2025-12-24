# Reference Guide

Complete reference for ADLee's Dotfiles configuration, Espanso triggers, and advanced features.

## Table of Contents

- [Configuration Reference](#configuration-reference)
- [Espanso Triggers](#espanso-triggers)
- [Vim Configuration](#vim-configuration)
- [Tmux Configuration](#tmux-configuration)
- [Git Aliases](#git-aliases)
- [Function Files Reference](#function-files-reference)
- [Color Reference](#color-reference)

---

## Configuration Reference

### dotfiles.conf Options

Complete list of all configuration options in `~/.dotfiles/dotfiles.conf`:

#### Core Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTFILES_VERSION` | `"1.2.0"` | Dotfiles version |
| `DOTFILES_DIR` | `"$HOME/.dotfiles"` | Installation directory |
| `DOTFILES_BRANCH` | `"main"` | Git branch to use |
| `DOTFILES_BACKUP_PREFIX` | `"$HOME/.dotfiles_backup"` | Backup location prefix |

#### GitHub Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTFILES_GITHUB_USER` | `"adlee-was-taken"` | GitHub username |
| `DOTFILES_REPO_NAME` | `"dotfiles"` | Repository name |

#### User Identity

| Variable | Default | Description |
|----------|---------|-------------|
| `USER_FULLNAME` | `""` | Your full name |
| `USER_EMAIL` | `""` | Your email |
| `USER_GITHUB` | `""` | Your GitHub username |

#### Git Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_USER_NAME` | `""` | Git user.name (falls back to USER_FULLNAME) |
| `GIT_USER_EMAIL` | `""` | Git user.email (falls back to USER_EMAIL) |
| `GIT_DEFAULT_BRANCH` | `"main"` | Default branch name |

#### Feature Toggles

| Variable | Values | Description |
|----------|--------|-------------|
| `INSTALL_DEPS` | `auto/true/false` | Install dependencies |
| `INSTALL_ZSH_PLUGINS` | `true/false` | Install zsh plugins |
| `INSTALL_FZF` | `true/false/ask` | Install fzf |
| `INSTALL_BAT` | `true/false/ask` | Install bat |
| `INSTALL_EZA` | `true/false/ask` | Install eza |
| `INSTALL_NEOVIM` | `true/false/ask` | Install neovim |
| `SET_ZSH_DEFAULT` | `true/false/ask` | Set zsh as default shell |

#### MOTD Settings

| Variable | Values | Description |
|----------|--------|-------------|
| `ENABLE_MOTD` | `true/false` | Enable MOTD display |
| `MOTD_STYLE` | `compact/mini/full/none` | MOTD display style |
| `MOTD_SHOW_FAILED_SERVICES` | `true/false` | Show failed systemd services |
| `MOTD_SHOW_UPDATES` | `true/false` | Show available updates |

#### Theme Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_THEME_NAME` | `"adlee"` | Zsh theme name |
| `THEME_TIMER_THRESHOLD` | `10` | Seconds before showing timer |
| `THEME_PATH_TRUNCATE_LENGTH` | `32` | Max path display length |

#### Advanced Features

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_SMART_SUGGESTIONS` | `true` | Enable typo correction |
| `ENABLE_COMMAND_PALETTE` | `true` | Enable Ctrl+Space palette |
| `ENABLE_SHELL_ANALYTICS` | `false` | Command usage tracking |
| `ENABLE_VAULT` | `true` | Enable secrets vault |
| `DOTFILES_AUTO_SYNC_CHECK` | `true` | Check for updates on start |

#### Btrfs Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `BTRFS_DEFAULT_MOUNT` | `"/"` | Default mount for btrfs commands |

#### Snapper Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SNAPPER_CONFIG` | `"root"` | Snapper config name |
| `LIMINE_CONF` | `"/boot/limine.conf"` | Limine config path |

#### Tmux Workspace Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `TW_SESSION_PREFIX` | `"work"` | Session naming prefix |
| `TW_DEFAULT_TEMPLATE` | `"dev"` | Default workspace template |

#### Python Template Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `PY_TEMPLATE_BASE_DIR` | `"$HOME/projects"` | Project base directory |
| `PY_TEMPLATE_PYTHON` | `"python3"` | Python executable |
| `PY_TEMPLATE_VENV_NAME` | `"venv"` | Virtual env directory name |
| `PY_TEMPLATE_USE_POETRY` | `false` | Use poetry instead of venv |
| `PY_TEMPLATE_GIT_INIT` | `true` | Initialize git repo |

#### SSH Manager Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SSH_AUTO_TMUX` | `true` | Auto-create tmux session |
| `SSH_TMUX_SESSION_PREFIX` | `"ssh"` | Session naming prefix |
| `SSH_SYNC_DOTFILES` | `ask` | Sync dotfiles on connect |

#### Package Manager

| Variable | Values | Description |
|----------|--------|-------------|
| `AUR_HELPER` | `auto/paru/yay` | Preferred AUR helper |

---

## Espanso Triggers

Complete list of text expansion triggers.

### Date and Time

| Trigger | Output | Example |
|---------|--------|---------|
| `..date` | Date (YYYY-MM-DD) | `2025-12-24` |
| `..ds` | Same as `..date` | `2025-12-24` |
| `..sds` | Short date (YYYYMMDD) | `20251224` |
| `..time` | Time (HH:MM:SS) | `14:30:45` |
| `..utime` | UTC time | `19:30:45` |
| `..ztime` | Time with timezone | `14:30:45.123 EST` |
| `..uztime` | UTC time with timezone | `19:30:45.123 UTC` |
| `..dt` | Date + time | `2025-12-24 14:30:45 EST` |
| `..udt` | UTC date + time | `2025-12-24 19:30:45 UTC` |
| `..ts` | ISO 8601 timestamp | `2025-12-24T19:30:45.123Z` |
| `..utc` | UTC with milliseconds | `2025-12-24 19:30:45.123 UTC` |
| `..month` | Month name | `December` |
| `..year` | Year | `2025` |
| `..week` | Week number | `Week 52` |
| `..day` | Day of week | `Wednesday` |
| `..epoch` | Unix timestamp | `1735066245` |
| `..epochms` | Unix timestamp (ms) | `1735066245123` |

### Quick Text

| Trigger | Output |
|---------|--------|
| `..shrug` | `¯\_(ツ)_/¯` |
| `..flip` | `(╯°□°)╯︵ ┻━┻` |
| `..unflip` | `┬─┬ ノ( ゜-゜ノ)` |
| `..lenny` | `( ͡° ͜ʖ ͡°)` |
| `..check` | `✓` |
| `..cross` | `✗` |
| `..arrow` | `→` |
| `..larrow` | `←` |

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

### System Information

| Trigger | Output |
|---------|--------|
| `..ip` | Public IP address |
| `..locip` | Local IP address |
| `..branch` | Current git branch |

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

### Code Templates

| Trigger | Output |
|---------|--------|
| `..bash` | Bash shebang + `set -euo pipefail` |
| `..python` | Python main boilerplate |
| `..she!` | `#!/usr/bin/env bash` |

### Markdown

| Trigger | Output |
|---------|--------|
| `..mdcode` | Code block (generic) |
| `..mdbash` | Bash code block |
| `..mdpy` | Python code block |
| `..mdjs` | JavaScript code block |
| `..mdtable` | Markdown table template |
| `..mdlink` | `[text](url)` (prompts) |
| `..mdimg` | `![alt](url)` (prompts) |

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
| `..proc` | `ps aux \| grep ` |
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

### Lorem Ipsum

| Trigger | Output |
|---------|--------|
| `..lorem` | One paragraph |
| `..loremlong` | Four paragraphs |

### Clipboard

| Trigger | Output |
|---------|--------|
| `..qp` | Primary clipboard (X11 selection) |

### Typo Corrections

| Trigger | Correction |
|---------|------------|
| `teh` | the |
| `recieve` | receive |
| `seperator` | separator |
| `definately` | definitely |
| `occured` | occurred |
| `lenght` | length |
| `wierd` | weird |
| `thier` | their |

### Emoji Package

| Trigger | Emoji |
|---------|-------|
| `:lol` | 😂 |
| `:sad` | ☹ |
| `:sml` | 😊 |
| `:strong` | 💪 |
| `:ba` | 😎 |
| `:ok` | 👍 |
| `:happy` | 😄 |
| `:cry` | 😭 |
| `:wow` | 😮 |

### Personal (in personal.yml)

| Trigger | Output |
|---------|--------|
| `..myemail` | Your email |
| `..myname` | Your full name |
| `..myphone` | Your phone |
| `..myweb` | Your website |
| `..mygithub` | Your GitHub URL |
| `..sig` | Email signature |
| `..sigfull` | Full signature |
| `..myaddr` | Your address |
| `..workemail` | Work email |
| `..worksig` | Work signature |

---

## Vim Configuration

### Leader Key

The leader key is `,` (comma).

### Key Mappings

| Mapping | Action |
|---------|--------|
| `,w` | Fast save (`:w!`) |
| `:W` | Sudo save |
| `Space` | Search (`/`) |
| `Ctrl+Space` | Backward search (`?`) |
| `,<Enter>` | Disable search highlight |
| `Ctrl+j/k/h/l` | Move between windows |
| `,bd` | Close buffer |
| `,ba` | Close all buffers |
| `,l` / `,h` | Next/previous buffer |
| `,tn` | New tab |
| `,to` | Tab only |
| `,tc` | Close tab |
| `,tm` | Move tab |
| `,tl` | Toggle last tab |
| `,te` | Open tab with buffer's path |
| `,cd` | Switch CWD to buffer dir |
| `Alt+j/k` | Move line down/up |
| `,ss` | Toggle spell checking |
| `,sn` / `,sp` | Next/previous misspelling |
| `,sa` | Add to dictionary |
| `,s?` | Suggest corrections |
| `,pp` | Toggle paste mode |
| `,q` | Open scratch buffer |
| `,x` | Open markdown buffer |
| `0` | First non-blank character |

### Settings

- 4 spaces for indentation
- Tabs expanded to spaces
- Smart indentation
- Line wrapping on word boundaries
- Incremental search with highlighting
- Wild menu for command completion

---

## Tmux Configuration

### Key Bindings

| Binding | Action |
|---------|--------|
| `Prefix + U` | Resize pane up 8 lines |
| `Prefix + D` | Resize pane down 8 lines |
| `Prefix + L` | Resize pane left 8 chars |
| `Prefix + R` | Resize pane right 8 chars |

### Settings

- Default shell: `/usr/bin/zsh`
- Terminal: `tmux-256color`
- XTerm keys enabled
- Escape time: 0 (no delay)
- Pane border status: bottom

---

## Git Aliases

Built-in git aliases from `.gitconfig`:

| Alias | Command |
|-------|---------|
| `git st` | `git status` |
| `git co` | `git checkout` |
| `git br` | `git branch` |
| `git ci` | `git commit` |
| `git lg` | `git log --oneline --graph --decorate --all` |
| `git unstage` | `git reset HEAD --` |
| `git last` | `git log -1 HEAD` |
| `git visual` | `gitk` |

---

## Function Files Reference

### btrfs-helpers.zsh

Btrfs filesystem management utilities.

**Exported functions:** `btrfs-usage`, `btrfs-subs`, `btrfs-balance`, `btrfs-balance-status`, `btrfs-balance-cancel`, `btrfs-scrub`, `btrfs-scrub-status`, `btrfs-scrub-cancel`, `btrfs-defrag`, `btrfs-compress`, `btrfs-info`, `btrfs-health`, `btrfs-snap-usage`, `btrfs-maintain`, `btrfs-help`

**Aliases:** `btru`, `btrs`, `btrh`, `btri`, `btrc`

### command-palette.zsh

Fuzzy command launcher.

**Exported functions:** `command_palette`, `palette`, `p`, `bookmark`, `bm`, `jump`, `j`

**Key bindings:** `Ctrl+Space`, `Ctrl+P`

### motd.zsh

Message of the Day display.

**Exported functions:** `show_motd`, `show_motd_mini`, `show_motd_full`, `sysbrief`

**Aliases:** `motd`, `motd-mini`, `motd-full`

### password-manager.zsh

LastPass CLI integration.

**Exported functions:** `pw`, `pwf`, `pwof`

**Aliases:** `pwl`, `pwg`, `pwc`, `pws`

### python-templates.zsh

Python project scaffolding.

**Exported functions:** `py-new`, `py-django`, `py-flask`, `py-fastapi`, `py-data`, `py-cli`, `venv`

**Aliases:** `pynew`, `pydjango`, `pyflask`, `pyfast`, `pydata`, `pycli`

### smart-suggest.zsh

Typo correction and suggestions.

**Exported functions:** `command_not_found_handler`, `fuck`

### snapper.zsh

Btrfs snapshot management.

**Exported functions:** `snap-create`, `snap-list`, `snap-show`, `snap-delete`, `snap-check-limine`, `snap-sync`, `snap-validate-service`

**Aliases:** `snap`, `snapls`, `snaprm`, `snapshow`, `snapcheck`, `snapsync`

### ssh-manager.zsh

SSH profile management.

**Exported functions:** `ssh-save`, `ssh-list`, `ssh-connect`, `ssh-delete`, `ssh-reconnect`, `ssh-sync-dotfiles`, `sshf`

**Aliases:** `sshl`, `sshs`, `sshc`, `sshd`, `sshr`, `sshsync`

### systemd-helpers.zsh

Systemd service management.

**Exported functions:** `sc`, `scu`, `scr`, `sce`, `scd`, `sclog`, `sclogs`, `sc-failed`, `sc-timers`, `sc-recent`, `sc-boot`, `sc-search`, `sc-info`, `scf`, `sclogf`, `sc-help`

**Aliases:** `scs`, `scstart`, `scstop`, `screload`, `scmask`, `scunmask`, `jctl`, `jctlf`, `jctlb`, `jctlerr`

### tmux-workspaces.zsh

Tmux workspace management.

**Exported functions:** `tw`, `tw-create`, `tw-attach`, `tw-list`, `tw-delete`, `tw-save`, `tw-templates`, `tw-template-edit`, `tw-sync`, `tw-rename`, `twf`

**Aliases:** `twl`, `twc`, `twa`, `twd`, `tws`, `twt`, `twe`

---

## Color Reference

Color variables defined in `zsh/lib/colors.zsh`:

### Standard Colors

| Variable | Description |
|----------|-------------|
| `DF_RED` | Red |
| `DF_GREEN` | Green |
| `DF_YELLOW` | Yellow (bold) |
| `DF_BLUE` | Blue |
| `DF_MAGENTA` | Magenta |
| `DF_CYAN` | Cyan |
| `DF_WHITE` | White |

### Bold Variants

`DF_BOLD_RED`, `DF_BOLD_GREEN`, `DF_BOLD_YELLOW`, `DF_BOLD_BLUE`, `DF_BOLD_MAGENTA`, `DF_BOLD_CYAN`, `DF_BOLD_WHITE`

### Text Styles

| Variable | Description |
|----------|-------------|
| `DF_BOLD` | Bold text |
| `DF_DIM` | Dim/faint text |
| `DF_ITALIC` | Italic text |
| `DF_UNDERLINE` | Underlined text |
| `DF_RESET` / `DF_NC` | Reset formatting |

### 256-Color Palette

| Variable | Description |
|----------|-------------|
| `DF_GREY` | Grey (242) |
| `DF_LIGHT_GREY` | Light grey (248) |
| `DF_DARK_GREY` | Dark grey (239) |
| `DF_ORANGE` | Orange (208) |
| `DF_LIGHT_ORANGE` | Light orange (220) |
| `DF_PINK` | Pink (213) |
| `DF_PURPLE` | Purple (141) |
| `DF_LIGHT_BLUE` | Light blue (39) |
| `DF_LIGHT_GREEN` | Light green (82) |
| `DF_BRIGHT_GREEN` | Bright green (118) |
| `DF_TEAL` | Teal (51) |

### Semantic Colors

| Variable | Maps To |
|----------|---------|
| `DF_SUCCESS` | `DF_GREEN` |
| `DF_ERROR` | `DF_RED` |
| `DF_WARNING` | `DF_YELLOW` |
| `DF_INFO` | `DF_CYAN` |
| `DF_HINT` | `DF_DIM` |
| `DF_ACCENT` | `DF_BLUE` |
| `DF_MUTED` | `DF_GREY` |

### Print Functions

| Function | Description |
|----------|-------------|
| `df_print_step "msg"` | Print step with `==>` prefix |
| `df_print_success "msg"` | Print with ✓ prefix |
| `df_print_error "msg"` | Print with ✗ prefix (stderr) |
| `df_print_warning "msg"` | Print with ⚠ prefix |
| `df_print_info "msg"` | Print with ℹ prefix |
| `df_print_section "title"` | Print section divider |
| `df_print_header "name"` | Print MOTD-style header box |

### Usage in Scripts

```bash
# In bash scripts
source "$HOME/.dotfiles/zsh/lib/colors.zsh"
echo -e "${DF_GREEN}Success!${DF_NC}"

# In zsh functions
source "${0:A:h}/../lib/colors.zsh"
df_print_success "Operation completed"
```

---

## Environment Variables

These are set or used by the dotfiles:

| Variable | Description |
|----------|-------------|
| `DOTFILES_DIR` | Dotfiles installation path |
| `UPDATE_PKG_COUNT` | Available package updates (for prompt) |
| `EDITOR` | Default editor (vim) |
| `VISUAL` | Visual editor (vim) |
| `LANG` / `LC_ALL` | Locale (en_US.UTF-8) |
| `FZF_DEFAULT_OPTS` | FZF appearance settings |
| `FZF_DEFAULT_COMMAND` | FZF file finder command |
