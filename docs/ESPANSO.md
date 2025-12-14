# Espanso Quick Reference Guide

A comprehensive guide to using espanso text expansion in your dotfiles setup.

## 🚀 Getting Started

### Installation

Espanso is automatically installed when you run the main install script:

```bash
./install.sh
```

Or install it separately:

```bash
# Ubuntu/Debian
wget https://github.com/espanso/espanso/releases/latest/download/espanso-debian-x11-amd64.deb
sudo apt install ./espanso-debian-x11-amd64.deb
espanso service register

# macOS
brew tap espanso/espanso
brew install espanso
espanso service register

# Fedora
# See: https://espanso.org/install/
```

### Initial Setup

Run the setup wizard to personalize your configuration:

```bash
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

## 📝 Built-in Snippets

### Date & Time

| Trigger | Output | Example |
|---------|--------|---------|
| `:date` | Current date | 2024-12-13 |
| `:time` | Current time | 14:30:45 |
| `:datetime` | Date and time | 2024-12-13 14:30:45 |
| `:now` | Formatted datetime | December 13, 2024 at 02:30 PM |

### Emoticons & Symbols

| Trigger | Output |
|---------|--------|
| `:shrug` | ¯\\\_(ツ)_/¯ |
| `:flip` | (╯°□°)╯︵ ┻━┻ |
| `:unflip` | ┬─┬ ノ( ゜-゜ノ) |
| `:lenny` | ( ͡° ͜ʖ ͡°) |
| `:arrow` | → |
| `:larrow` | ← |
| `:check` | ✓ |
| `:cross` | ✗ |
| `:star` | ★ |
| `:heart` | ♥ |

### Code Templates

| Trigger | Output |
|---------|--------|
| `:bash` | Bash script template with shebang |
| `:python` | Python script template |
| `:shebang` | `#!/usr/bin/env bash` |
| `:gitignore` | Complete .gitignore template |
| `:mdcode` | Markdown code block |
| `:mdtable` | Markdown table template |

### Git Shortcuts

| Trigger | Output |
|---------|--------|
| `:gst` | `git status` |
| `:gco` | `git checkout ` |
| `:gcm` | `git commit -m ""` |
| `:glog` | `git log --oneline --graph --decorate --all` |

### Docker Shortcuts

| Trigger | Output |
|---------|--------|
| `:dps` | `docker ps` |
| `:dcup` | `docker-compose up -d` |
| `:dcdown` | `docker-compose down` |

### Personal Information (Customizable)

| Trigger | Output |
|---------|--------|
| `:myemail` | Your email address |
| `:myname` | Your full name |
| `:myphone` | Your phone number |
| `:mywebsite` | Your website URL |
| `:mygithub` | Your GitHub profile |
| `:sig` | Your email signature |

### Text Templates

| Trigger | Output |
|---------|--------|
| `:lorem` | Lorem ipsum paragraph |
| `:loremlong` | Extended lorem ipsum |
| `:emailhi` | Email greeting template |
| `:emailthanks` | Thank you email template |
| `:mdheader` | Markdown document header |
| `:meeting` | Meeting notes template |

## 🎨 Creating Custom Snippets

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
  - trigger: ":hw"
    replace: "Hello, World!"
```

### With Variables (Dynamic Content)

```yaml
matches:
  - trigger: ":mydate"
    replace: "Today is {{mydate}}"
    vars:
      - name: mydate
        type: date
        params:
          format: "%B %d, %Y"
```

### Multi-line Templates

```yaml
matches:
  - trigger: ":email"
    replace: |
      Dear {{name}},
      
      
      
      Best regards,
      Your Name
    vars:
      - name: name
        type: form
        params:
          layout: "Recipient name: {{name}}"
```

### With Shell Commands

```yaml
matches:
  - trigger: ":myip"
    replace: "{{output}}"
    vars:
      - name: output
        type: shell
        params:
          cmd: "curl -s ifconfig.me"
```

### Cursor Positioning

```yaml
matches:
  - trigger: ":func"
    replace: "function {{name}}() {\n    {{cursor}}\n}"
    vars:
      - name: name
        type: form
        params:
          layout: "Function name: {{name}}"
```

## 📦 Package Management

### List Installed Packages

```bash
espanso package list
```

### Install Packages

```bash
# Emoji support
espanso install emoji --force

# Greek letters
espanso install greek-letters --force

# Math symbols
espanso install math --force

# All emojis
espanso install all-emojis --force
```

### Browse Available Packages

Visit: https://hub.espanso.org/

## 🔧 Configuration

### Main Configuration File

Location: `~/.config/espanso/config/default.yml`

Key settings:

```yaml
# Toggle key
toggle_key: ALT+SHIFT+E

# Search shortcut
search_shortcut: ALT+SPACE

# Backend (Auto, Clipboard, or Inject)
backend: Auto

# Show notifications
show_notifications: true

# Auto-restart on config changes
auto_restart: true
```

### Application-Specific Configs

Create configs for specific applications:

```bash
# Only in terminal
vim ~/.config/espanso/match/terminal.yml
```

```yaml
filter_title: "Terminal|Konsole|iTerm"

matches:
  - trigger: ":ll"
    replace: "ls -lah"
```

## 🛠️ Troubleshooting

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
3. Ensure espanso is enabled (not toggled off with ALT+SHIFT+E)

### Conflicts with Other Apps

Some applications may conflict with espanso. Add them to the filter:

```yaml
# In config/default.yml
filter_exec: "application_name"
```

### Clipboard Issues

Try changing the backend:

```yaml
# In config/default.yml
backend: Clipboard
```

## 📚 Advanced Features

### Forms (Interactive Inputs)

```yaml
matches:
  - trigger: ":invoice"
    replace: |
      Invoice #{{number}}
      Client: {{client}}
      Amount: ${{amount}}
      Due: {{date}}
    vars:
      - name: number
        type: form
        params:
          layout: |
            Invoice Number: {{number}}
            Client Name: {{client}}
            Amount: {{amount}}
            Due Date: {{date}}
```

### Choice Variables

```yaml
matches:
  - trigger: ":env"
    replace: "{{env}}"
    vars:
      - name: env
        type: choice
        params:
          values:
            - development
            - staging
            - production
```

### Script Variables

```yaml
matches:
  - trigger: ":weather"
    replace: "{{output}}"
    vars:
      - name: output
        type: script
        params:
          args:
            - python
            - /path/to/weather_script.py
```

## 🔄 Backup and Sync

### Backup Your Config

```bash
# Using the dotfiles system
cd ~/.dotfiles
git add espanso/
git commit -m "Update espanso config"
git push
```

### Restore on New System

```bash
# Clone dotfiles
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install
./install.sh

# Personalize
./bin/setup-espanso.sh
```

## 📖 Resources

- [Official Documentation](https://espanso.org/docs/)
- [Package Hub](https://hub.espanso.org/)
- [GitHub Repository](https://github.com/espanso/espanso)
- [Community Forum](https://github.com/espanso/espanso/discussions)

## 💡 Tips & Best Practices

1. **Use consistent prefixes**: Start all triggers with `:` to avoid accidents
2. **Keep it organized**: Separate snippets by category in different files
3. **Test before committing**: Verify new snippets work before adding to git
4. **Use descriptive triggers**: Make triggers memorable and logical
5. **Leverage forms**: Use forms for snippets that need customization
6. **Back up regularly**: Keep your config in version control
7. **Share useful snippets**: Contribute to the community hub

## 🎯 Common Use Cases

### Developer Workflow

```yaml
:fixme    → // FIXME: 
:todo     → // TODO: 
:note     → // NOTE: 
:debug    → console.log('DEBUG:', );
```

### Writing & Documentation

```yaml
:doc      → Documentation template
:readme   → README.md template
:license  → MIT License text
:quote    → > Blockquote
```

### Communication

```yaml
:ty       → Thank you
:yw       → You're welcome
:lgtm     → Looks good to me
:wip      → Work in progress
```

---

**Happy expanding!** 🚀

For questions or issues, check the [espanso documentation](https://espanso.org/docs/) or open an issue in your dotfiles repository.
