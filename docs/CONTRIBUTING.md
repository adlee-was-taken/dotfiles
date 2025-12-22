# Contributing Guide

Thank you for your interest in contributing to the ADLee dotfiles project! This guide explains how to contribute to our Arch/CachyOS-focused dotfiles repository.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Architecture Overview](#architecture-overview)
- [Project Philosophy](#project-philosophy)

---

## Code of Conduct

- Be respectful to all contributors
- Provide constructive feedback
- Ask questions when unclear
- Help others when possible
- Focus on the code, not the person

---

## Getting Started

### Prerequisites

- Arch Linux or CachyOS
- Git
- Bash/Zsh
- Understanding of shell scripting

### Fork and Clone

```bash
# Fork on GitHub (click Fork button)

# Clone your fork
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles-dev
cd ~/.dotfiles-dev

# Add upstream for syncing
git remote add upstream https://github.com/adlee-was-taken/dotfiles.git

# Create feature branch
git checkout -b feature/your-feature
```

---

## Development Setup

### Install in Development Mode

```bash
cd ~/.dotfiles-dev

# Create a test installation in a temporary directory
export DOTFILES_HOME=/tmp/test-dotfiles
mkdir -p $DOTFILES_HOME

# Link your dev dotfiles
ln -s $(pwd) $DOTFILES_HOME/.dotfiles

# Run installer in test mode
DOTFILES_HOME=$DOTFILES_HOME ./install.sh --skip-deps
```

### Testing Without Overwriting

```bash
# Use Docker or chroot to test in isolated environment
docker run -it archlinux:latest bash
# Inside container:
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Validate Changes

```bash
./install.sh --help              # Verify script runs
./install.sh --skip-deps         # Test without dependencies
dotfiles-doctor.sh               # Health check
```

---

## Making Changes

### What to Change

**Good areas for contribution:**
- Bug fixes
- Feature additions for Arch/CachyOS
- Zsh enhancements
- Vim/Neovim configuration improvements
- LastPass integration improvements
- Documentation and guides
- Performance improvements
- Error messages and validation

**Areas to avoid:**
- Adding support for other OS (macOS, Ubuntu, etc.)
- Adding other password managers (1Password, Bitwarden, etc.)
- Adding other editors (Emacs, VS Code, etc.)
- Changes that increase complexity

### Code Organization

```
dotfiles/
├── install.sh              # Main installer - modify carefully
├── dotfiles.conf           # Configuration - add new features here
├── zsh/
│   ├── .zshrc              # Core zsh config
│   ├── aliases.zsh         # Custom aliases
│   ├── themes/             # Prompt themes
│   └── functions/          # Zsh functions (new features go here)
├── vim/                    # Vim configuration
├── nvim/                   # Neovim configuration
├── tmux/                   # Tmux configuration
├── git/                    # Git configuration
├── bin/                    # Shell scripts (utilities and tools)
└── docs/                   # Documentation
```

### Adding a New Feature

**Example: Add a new command palette action**

1. Create function in `zsh/functions/command-palette.zsh`:

```bash
# Add to _command_palette_entries()
case "$entry" in
  "myfeature")
    my-command
    ;;
esac
```

2. Add configuration to `dotfiles.conf`:

```bash
ENABLE_MYFEATURE="ask"
```

3. Add logic to `install.sh`:

```bash
if [[ "$ENABLE_MYFEATURE" == "true" ]]; then
  pacman -S myfeature-package
fi
```

4. Document in `docs/SETUP_GUIDE.md`:

```markdown
### My Feature

Description of feature...
```

5. Test thoroughly before submitting PR.

---

## Coding Standards

### Shell Script Style

```bash
# Good practices
#!/bin/bash
set -euo pipefail

# Use descriptive variable names
local readonly config_file="$HOME/.dotfiles/dotfiles.conf"

# Quote all variables
echo "$variable"

# Use functions with local variables
function my_function() {
  local readonly required_arg="$1"
  local optional_arg="${2:-default}"
  
  # Error handling
  if [[ ! -f "$required_arg" ]]; then
    echo "Error: File not found: $required_arg" >&2
    return 1
  fi
  
  # Return explicitly
  return 0
}

# Use [[ ]] instead of [ ]
if [[ "$condition" == "true" ]]; then
  echo "Good"
fi

# Comment complex logic
# Check if file exists and is readable
if [[ -r "$config_file" ]]; then
  source "$config_file"
fi
```

### Zsh Style

```zsh
# Functions in zsh/functions/
function my-feature() {
  local -a args=("$@")
  
  # Parse arguments
  case "${args[1]}" in
    list)
      # Implementation
      ;;
    *)
      echo "Usage: my-feature {list|create|delete}"
      return 1
      ;;
  esac
}

# Aliases in zsh/aliases.zsh
alias mf='my-feature'

# Set shell options
setopt nocaseglob
setopt noshglob

# Use proper quoting
print -P "%F{blue}%Btext%b%f"
```

### Comments and Documentation

```bash
# Comment Why, not What
# BAD: Add 5 to count
count=$((count + 5))

# GOOD: Increment by hardcoded snapshot count limit per policy
count=$((count + 5))

# Use TODO for future work
# TODO: Add support for encrypted backups

# Document functions
# my_function: Create a backup of the dotfiles
# Arguments:
#   $1: Backup name
# Returns:
#   0 on success, 1 on error
function my_function() {
  # ...
}
```

### Error Handling

```bash
# Always check critical operations
if ! pacman -S package; then
  echo "Error: Failed to install package" >&2
  return 1
fi

# Use set -e with care (only for critical scripts)
set -euo pipefail

# Provide helpful error messages
if [[ ! -d "$DOTFILES_HOME" ]]; then
  echo "Error: Dotfiles not found at $DOTFILES_HOME" >&2
  echo "Please run: git clone <repo> $DOTFILES_HOME" >&2
  return 1
fi
```

---

## Testing

### Manual Testing

```bash
# Test installer
./install.sh --help
./install.sh --skip-deps
dfd          # Run health check

# Test new features
./zsh/functions/my-feature.zsh test
```

### Validation Checklist

- [ ] No errors in `shellcheck` (if available)
- [ ] Script runs without errors
- [ ] `dotfiles-doctor.sh` passes
- [ ] Feature works as documented
- [ ] No breaking changes for existing users
- [ ] Works on both Arch and CachyOS
- [ ] Tested with both bash and zsh

```bash
# Run shellcheck on modified scripts
shellcheck install.sh bin/*.sh zsh/functions/*.zsh
```

### Testing Across Arch/CachyOS

```bash
# Test on Arch Linux
# Test on CachyOS (if available)
# Test on fresh installation
# Test on system with existing dotfiles

# Verify:
# - Installation completes
# - All features work
# - No data loss
# - Can uninstall cleanly
```

---

## Submitting Changes

### Commit Messages

```bash
# Good commit message format
# First line: Brief summary (50 chars max)
# Blank line
# Detailed explanation (if needed)

git commit -m "Add fuzzy search to password manager

- Implement fzf integration for pw command
- Add pwf alias for quick password copy
- Update documentation with examples
- Tested on Arch and CachyOS"
```

### Commit Guidelines

- One logical change per commit
- Commit frequently
- Include related changes together
- Meaningful commit messages

### Before Submitting PR

```bash
# Sync with upstream
git fetch upstream
git rebase upstream/main

# Clean up commits
# (squash, reorder, reword as needed)

# Final validation
./install.sh --help
./install.sh --skip-deps
dotfiles-doctor.sh
```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Performance improvement

## Related Issues
Fixes #123

## Testing
- [ ] Tested on Arch Linux
- [ ] Tested on CachyOS
- [ ] All features work
- [ ] No regressions

## Checklist
- [ ] Code follows style guide
- [ ] Documentation updated
- [ ] Changes are tested
- [ ] No breaking changes
- [ ] Commits are clean
```

### PR Review Process

1. CI/automated checks pass
2. Code review (expect feedback)
3. Revisions made if needed
4. Final approval
5. Merge to main

---

## Architecture Overview

### Installation Flow

```
install.sh
├── Check OS (Arch/CachyOS only)
├── Load dotfiles.conf
├── Check dependencies
├── Install system packages
├── Create symlinks
├── Configure zsh
├── Initialize git config
└── Run post-install setup
```

### Module Structure

Each feature is mostly self-contained:

```
Feature: Password Manager
├── zsh/functions/password-manager.zsh    # Core functions
├── bin/dotfiles-vault.sh                 # Supporting script
├── dotfiles.conf entries                 # Configuration
├── install.sh logic                      # Installation
└── docs/SETUP_GUIDE.md section           # Documentation
```

### Configuration Hierarchy

```
install.sh (defaults)
  ↓
dotfiles.conf (user config)
  ↓
~/.zshrc (shell execution)
  ↓
~/.zshrc.local (machine-specific)
```

---

## Project Philosophy

### Design Principles

1. **Arch/CachyOS First** - Optimize for Arch/CachyOS, not other systems
2. **Simplicity** - Reduce complexity over time
3. **Single Tools** - One password manager, one editor, one shell
4. **User Customization** - Easy to customize without modification
5. **Documentation** - Features need good documentation
6. **Backward Compatibility** - Breaking changes discussed first

### What We Value

- ✅ Productivity
- ✅ Clarity
- ✅ Reliability
- ✅ Minimalism (not bloat)
- ✅ User autonomy

### What We Don't Value

- ❌ Supporting many OSes
- ❌ Supporting many tools
- ❌ Complex configuration
- ❌ Undocumented features
- ❌ Breaking user workflows

---

## Getting Help

### Questions

- Check [README.md](../README.md)
- Check [SETUP_GUIDE.md](SETUP_GUIDE.md)
- Check existing GitHub issues
- Ask in a new GitHub issue

### Feature Requests

1. Check if already requested (GitHub issues)
2. Describe use case clearly
3. Explain why it fits project scope
4. Include examples

### Bug Reports

1. Run `dotfiles-doctor.sh`
2. Include error output
3. Include OS and CachyOS/Arch version
4. Include steps to reproduce
5. Include expected vs actual behavior

---

## Recognition

Contributors are recognized in:
- GitHub Contributors page
- [CONTRIBUTORS.md](CONTRIBUTORS.md) file
- Release notes for significant changes

Thank you for contributing! 🙏

---

For more information:
- [README.md](../README.md)
- [SETUP_GUIDE.md](SETUP_GUIDE.md)
- [GitHub Issues](https://github.com/adlee-was-taken/dotfiles/issues)
