# Changelog

All notable changes to this dotfiles project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-15

### Added

#### Core Features
- **Interactive Setup Wizard** (`setup-wizard.sh`) - Beautiful TUI installer using `gum` with fallback to basic prompts
- **Dynamic MOTD** (`motd.zsh`) - Compact system info on shell start (uptime, CPU, memory, docker, git status)
- **Command Palette** (`command-palette.zsh`) - Raycast-style fuzzy launcher triggered by Ctrl+Space or Ctrl+P
- **Smart Suggestions** (`smart-suggest.zsh`) - Typo correction for 100+ common mistakes + alias recommendations
- **Shell Analytics** (`shell-stats.sh`) - Dashboard showing command usage, suggestions, and activity heatmap
- **Secrets Vault** (`vault.sh`) - Encrypted storage for API keys using age/gpg
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
dotfiles-version.sh
```

### Updating

```bash
cd ~/.dotfiles
git pull origin main
./install.sh --skip-deps
```

Or use:

```bash
update-dotfiles.sh
```

---

## Roadmap

### Planned for 1.1.0
- [ ] Multiple theme support with live preview
- [ ] Project scaffolding templates
- [ ] SSH key generation helper
- [ ] Machine profiles (work, personal, server)

### Planned for 1.2.0
- [ ] Dynamic MOTD/welcome screen
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
