# Dotfiles Repository Setup Checklist

Use this checklist to ensure your dotfiles repository is complete and ready to use.

## 📋 File Structure

### Core Files
- [ ] `README.md` - Main documentation (use the artifact provided)
- [ ] `LICENSE` - MIT License file
- [ ] `.gitignore` - Git ignore rules
- [ ] `install.sh` - Main installation script

### Zsh Configuration
- [ ] `zsh/.zshrc` - Main zsh config
- [ ] `zsh/themes/adlee.zsh-theme` - Custom theme
- [ ] `zsh/.zshrc.local.example` - Template for local settings (optional)

### Espanso Configuration
- [ ] `espanso/config/default.yml` - Espanso settings
- [ ] `espanso/match/base.yml` - Base snippets
- [ ] `espanso/match/personal.yml` - Personal snippets

### Git Configuration
- [ ] `git/.gitconfig` - Git settings
- [ ] `git/.gitignore_global` - Global gitignore (optional)

### Other Configs
- [ ] `vim/.vimrc` - Vim config (if you use vim)
- [ ] `tmux/.tmux.conf` - Tmux config (if you use tmux)

### Utility Scripts
- [ ] `bin/update-dotfiles` - Update script
- [ ] `bin/setup-espanso.sh` - Espanso wizard
- [ ] `bin/deploy-zshtheme-systemwide.sh` - System-wide deployment

### Documentation
- [ ] `docs/SETUP_GUIDE.md` - Detailed setup guide
- [ ] `docs/ESPANSO.md` - Espanso reference
- [ ] `CHECKLIST.md` - This file

## 🔧 Setup Steps

### 1. Create Directory Structure
```bash
cd ~/.dotfiles
mkdir -p zsh/themes
mkdir -p espanso/config espanso/match
mkdir -p git
mkdir -p vim
mkdir -p tmux
mkdir -p bin
mkdir -p docs
```

### 2. Create/Copy Configuration Files

- [ ] Copy your existing `.zshrc` to `zsh/.zshrc`
- [ ] Copy your theme to `zsh/themes/adlee.zsh-theme`
- [ ] Copy espanso configs from `~/.config/espanso/` to `espanso/`
- [ ] Copy `.gitconfig` to `git/.gitconfig`
- [ ] Copy `.vimrc` to `vim/.vimrc` (if exists)
- [ ] Copy `.tmux.conf` to `tmux/.tmux.conf` (if exists)

### 3. Create Scripts

Download or create these scripts from the artifacts:
- [ ] `install.sh`
- [ ] `bin/update-dotfiles`
- [ ] `bin/setup-espanso.sh`
- [ ] `bin/deploy-zshtheme-systemwide.sh`

Make them executable:
```bash
chmod +x install.sh
chmod +x bin/*
```

### 4. Create Documentation

- [ ] Create `README.md` (use artifact provided)
- [ ] Create `docs/SETUP_GUIDE.md` (artifact provided earlier)
- [ ] Create `docs/ESPANSO.md` (artifact provided earlier)

### 5. Create .gitignore

```bash
cat > .gitignore << 'EOF'
# OS files
.DS_Store
Thumbs.db

# Backup files
*.backup
*.bak
*~

# Local machine-specific configs
*.local
.zshrc.local

# Sensitive information
.env
.env.*
secrets/

# Optional: Uncomment if personal espanso info is sensitive
# espanso/match/personal.yml

# Espanso backup files
espanso/match/*.backup
EOF
```

### 6. Create LICENSE

```bash
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2025 Aaron D. Lee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
```

## 🐙 GitHub Setup

### 1. Create Repository
- [ ] Go to https://github.com/new
- [ ] Name: `dotfiles`
- [ ] Description: "Personal configuration files and automation scripts"
- [ ] Visibility: Public or Private
- [ ] Don't initialize with README (you already have one)
- [ ] Click "Create repository"

### 2. Initialize Git
```bash
cd ~/.dotfiles
git init
git add .
git commit -m "Initial commit: Add dotfiles and custom zsh theme"
```

### 3. Add Remote and Push
```bash
# Replace adlee-was-taken with your GitHub username
git remote add origin https://github.com/adlee-was-taken/dotfiles.git
git branch -M main
git push -u origin main
```

### 4. Update URLs in Files
- [ ] Update `install.sh` - Replace `adlee-was-taken` in `DOTFILES_REPO`
- [ ] Update `README.md` - Replace all `adlee-was-taken` references
- [ ] Update `docs/SETUP_GUIDE.md` - Replace `adlee-was-taken`

```bash
# Quick find all instances
grep -r "adlee-was-taken" .
```

## ✅ Verification

### Test Local Installation
- [ ] Test install script on local machine
  ```bash
  # Dry run first
  bash -n install.sh  # Check for syntax errors
  
  # Then test (will backup existing configs)
  ./install.sh
  ```

- [ ] Verify symlinks were created correctly
  ```bash
  ls -la ~ | grep "^l"  # Show all symlinks in home
  ```

- [ ] Test zsh theme
  ```bash
  source ~/.zshrc
  # Check if prompt looks correct
  ```

- [ ] Test espanso
  ```bash
  espanso status
  # Try typing: ..date
  ```

### Test GitHub Setup
- [ ] Clone on a test directory
  ```bash
  cd /tmp
  git clone https://github.com/adlee-was-taken/dotfiles.git test-dotfiles
  cd test-dotfiles
  ./install.sh
  ```

### Test System-wide Deployment
- [ ] Check current status
  ```bash
  sudo ./bin/deploy-zshtheme-systemwide.sh --status
  ```

- [ ] Test deployment
  ```bash
  sudo ./bin/deploy-zshtheme-systemwide.sh --current
  ```

## 📝 Final Touches

### Customize Personal Info
- [ ] Edit `espanso/match/personal.yml` with your info
- [ ] Edit `git/.gitconfig` with your name and email
- [ ] Update `README.md` with your GitHub username
- [ ] Update any other personal references

### Optional Enhancements
- [ ] Add GitHub Actions for linting (optional)
- [ ] Add screenshots to README
- [ ] Create a demo GIF of the theme
- [ ] Add more espanso snippets for your workflow
- [ ] Create shell aliases in `.zshrc`

### Security Check
- [ ] Ensure no sensitive info in committed files
  ```bash
  # Search for potential secrets
  grep -rE '(password|secret|token|key)' . --exclude-dir=.git
  ```

- [ ] Verify `.gitignore` is working
  ```bash
  git status  # Should not show .local files or sensitive data
  ```

## 🎉 You're Done!

Once all items are checked:
- [ ] Commit any final changes
  ```bash
  git add .
  git commit -m "Complete repository setup"
  git push
  ```

- [ ] Test on a second machine (if available)
- [ ] Star your own repo (you deserve it! 😄)
- [ ] Share with others who might find it useful

## 📚 Next Steps

- Read through `docs/SETUP_GUIDE.md` for detailed usage
- Explore `docs/ESPANSO.md` for all available snippets
- Customize the theme colors in `zsh/themes/adlee.zsh-theme`
- Add more aliases to `.zshrc`
- Consider contributing to the espanso community hub

---

**Need help?** Open an issue in your repository or check the documentation files.
