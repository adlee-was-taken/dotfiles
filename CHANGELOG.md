# Changelog

All notable changes to this dotfiles project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-12-16

### Added

#### Shell Startup Optimization
- **Deferred Loading** - Heavy plugins and functions load after first prompt displays
- **Cached Command Checks** - `_has_cmd()` function caches `command -v` results for faster lookups
- **Lazy kubectl** - kubectl completions only load when first used (saves ~200-500ms)
- **Background Tasks** - Dotfiles sync check runs fully async with `&!`
- **Compile Script** (`dotfiles-compile.sh`) - Pre-compile zsh files to `.zwc` bytecode for 20-50ms speedup

#### Smart Path Resolution
- **`_df_run()` Helper** - All aliases use full path with fallback to PATH
- Fixes "command not found" errors on fresh installs
- Scripts work even before symlinks are created or PATH is set

#### New Aliases
- `dfcompile` - Compile zsh files for faster startup
- `dfcd` - Navigate to dotfiles directory (replaces `df` to avoid disk utility conflict)

### Changed

#### Script Reorganization
- Renamed `bin/shell-stats.sh` → `bin/dotfiles-stats.sh`
- Renamed `bin/vault.sh` → `bin/dotfiles-vault.sh`
- Renamed `bin/update-dotfiles.sh` → `bin/dotfiles-update.sh`
- Moved `bin/setup-wizard.sh` → `setup/setup-wizard.sh`
- Moved `bin/setup-espanso.sh` → `setup/setup-espanso.sh`
- Removed deprecated `bin/deploy-zshtheme-systemwide.sh`

#### Alias System Overhaul
- All command aliases now use `_df_run()` function wrapper
- Uses full path `$_df_dir/bin/script.sh` with fallback to PATH lookup
- Better error messages when scripts not found
- Removed `df` alias (conflicts with disk free utility)

#### .zshrc Optimizations
- Reduced default plugins (removed `docker`, `docker-compose`, `kubectl` from immediate load)
- Disabled oh-my-zsh auto-update check on every load (`DISABLE_AUTO_UPDATE="true"`)
- Tool aliases (eza, bat) now set up in deferred loading
- FZF configuration deferred until after prompt
- Vault secrets loaded with full path to avoid command_not_found issues
- Background sync check uses full script path

### Fixed

- **Fresh Install Bug** - "Command not found: dotfiles-sync.sh" error on new user accounts
- **Path Resolution** - Scripts now work before `~/.local/bin` is in PATH
- **Smart Suggest Conflicts** - Background tasks no longer trigger `command_not_found_handler`

### Removed

- `df` alias (conflicted with `df` disk utility)
- Heavy plugins from default load (now lazy-loaded)
- `bin/deploy-zshtheme-systemwide.sh` (redundant with installer)

---

## [1.0.0] - 2025-12-15

### Added

#### Core Features
- **Interactive Setup Wizard** (`setup-wizard.sh`) - Beautiful TUI installer using `gum` with fallback to basic prompts
- **Dynamic MOTD** (`motd.zsh`) - Compact system info on shell start (uptime, CPU, memory, docker, git status)
- **Command Palette** (`command-palette.zsh`) - Raycast-style fuzzy launcher triggered by Ctrl+Space or Ctrl+P
- **Smart Suggestions** (`smart-suggest.zsh`) - Typo correction for 100+ common mistakes + alias recommendations
- **Shell Analytics** (`dotfiles-stats.sh`) - Dashboard showing command usage, suggestions, and activity heatmap
- **Secrets Vault** (`dotfiles-vault.sh`) - Encrypted storage for API keys using age/gpg
- **Password Manager Integration** (`password-manager.zsh`) - Unified CLI for 1Password, LastPass, Bitwarden
- **Dotfiles Sync** (`dotfiles-sync.sh`) - Multi-machine synchronization with watch mode
- **Dotfiles Doctor** (`dotfiles-doctor.sh`) - Health checker with auto-fix capability
- **Version Tracking** (`dotfiles-version.sh`) - Compare local vs remote versions

#### Password Manager Support
- 1Password CLI (`op`) installation and integration
- LastPass CLI (`lpass`) installation and integration
- Bitwarden CLI (`bw`) installation and integration
- Unified `pw` command with fuzzy search support

#### Configuration
- Centralized `dotfiles.conf` for all settings
- Git identity configuration (generated, not hardcoded)
- Feature toggles for all optional components
- Machine-specific config support via `.zshrc.local`

#### Installation
- `--wizard` flag for interactive TUI installation
- `--uninstall` flag to remove symlinks and restore backups
- `--purge` flag to completely remove dotfiles
- `--skip-deps` flag for faster re-runs
- Auto-detection of installed dependencies
- Automatic zsh plugin installation

#### Zsh Theme
- Two-line prompt with git integration
- Command timer for long-running commands
- Root detection (red prompt for root)
- Smart path truncation

#### Espanso
- 100+ text expansion snippets
- Personal snippet template
- Setup script for personalization

#### Snapper (Arch/CachyOS)
- Btrfs snapshot management functions
- limine-snapper-sync integration
- Boot menu validation

#### Documentation
- Comprehensive README with feature overview
- Detailed SETUP_GUIDE with troubleshooting
- ESPANSO reference with all snippets
- SNAPPER guide for btrfs users

### Changed
- Optimized `.zshrc` with lazy-loading for NVM and virtualenvwrapper
- Streamlined `adlee.zsh-theme` (removed unused functions)
- Git config now generated from `dotfiles.conf` instead of hardcoded

### Removed
- Hardcoded git credentials from `.gitconfig`
- Redundant code in theme file
- Duplicate `export ZSH=` statements

---

## Version History

### Versioning Scheme

- **Major** (1.x.x): Breaking changes, major feature additions
- **Minor** (x.1.x): New features, non-breaking changes
- **Patch** (x.x.1): Bug fixes, documentation updates

### Checking Your Version

```bash
dfv
# or
dotfiles-version.sh
```

### Updating

```bash
dfu
# or
dotfiles-update.sh
```

---

## Roadmap

### Planned for 1.2.0
- [ ] Multiple theme support with live preview
- [ ] Project scaffolding templates
- [ ] SSH key generation helper
- [ ] Machine profiles (work, personal, server)

### Planned for 1.3.0
- [ ] Remote machine bootstrap script
- [ ] Neovim configuration support

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Update CHANGELOG.md
5. Bump version in `dotfiles.conf`
6. Submit a pull request
