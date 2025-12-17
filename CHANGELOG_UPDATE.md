# Changelog Update for v1.2.0

## [1.2.0] - 2025-12-16

### Added

#### Python Project Templates
- **`py-new`** - Create basic Python project with venv, tests, and structure
- **`py-django`** - Django web application template with best practices
- **`py-flask`** - Flask web application with blueprints and templates
- **`py-fastapi`** - FastAPI REST API with automatic docs
- **`py-data`** - Data science project with Jupyter, pandas, and proper data directory structure
- **`py-cli`** - Command-line tool template using Click framework

#### Python Template Features
- Automatic virtual environment creation
- Poetry support (configurable via `PY_TEMPLATE_USE_POETRY`)
- Pre-configured .gitignore for Python projects
- README with setup instructions
- Requirements.txt with common dependencies
- Project structure following best practices
- Optional git initialization
- Quick aliases: `pynew`, `pydjango`, `pyflask`, `pyfast`, `pydata`, `pycli`
- `venv` function to quickly activate virtual environments

### Changed

#### Alias System Cleanup
- **Removed `stats` alias** - Forces explicit `dfstats` usage to avoid conflicts
- Updated help text in `dotfiles-cli` to reflect removal
- Clarified that `stats` removal is intentional in documentation

### Configuration

New Python template settings in `dotfiles.conf`:

```bash
# Python Project Templates
PY_TEMPLATE_BASE_DIR="$HOME/projects"     # Where to create projects
PY_TEMPLATE_PYTHON="python3"              # Python executable
PY_TEMPLATE_VENV_NAME="venv"              # Virtual environment name
PY_TEMPLATE_USE_POETRY="false"            # Use Poetry instead of venv
PY_TEMPLATE_GIT_INIT="true"               # Auto-initialize git repos
```

### Usage Examples

#### Basic Python Project
```bash
py-new myproject
cd myproject
source venv/bin/activate
# Start coding!
```

#### Django Project
```bash
py-django myblog
cd myblog
source venv/bin/activate
python manage.py runserver
# Visit: http://localhost:8000
```

#### FastAPI Project
```bash
py-fastapi myapi
cd myapi
source venv/bin/activate
python run.py
# Docs at: http://localhost:8000/docs
```

#### Data Science Project
```bash
py-data analysis
cd analysis
source venv/bin/activate
jupyter notebook
```

#### CLI Tool
```bash
py-cli mytool
cd mytool
pip install -e .
mytool --help
```

---

## Breaking Changes

- **`stats` alias removed** - Use `dfstats` instead
  - Reason: Potential conflicts with other tools/scripts
  - Migration: Replace `stats` with `dfstats` in any scripts or muscle memory

---

## File Changes

### New Files
- `zsh/functions/python-templates.zsh` - Python project template functions

### Modified Files
- `zsh/aliases.zsh` - Removed `stats` alias, added cleanup notes
- `dotfiles.conf` - New Python template configuration section (optional)
- `.zshrc` - Sources `python-templates.zsh` (needs manual addition)

### To Enable Python Templates

Add to your `.zshrc`:

```bash
# Python project templates
[[ -f "$_dotfiles_dir/zsh/functions/python-templates.zsh" ]] && \
    source "$_dotfiles_dir/zsh/functions/python-templates.zsh"
```

Or add to deferred loading section:

```bash
_deferred_load() {
    # ... existing code ...
    
    # Python templates
    [[ -f "$_dotfiles_dir/zsh/functions/python-templates.zsh" ]] && \
        source "$_dotfiles_dir/zsh/functions/python-templates.zsh"
}
```

---

## Documentation Updates Needed

### README.md
- Add Python Templates section
- Update aliases table (remove `stats`, add `dfstats`)
- Add examples of template usage

### SETUP_GUIDE.md
- Add Python project templates section
- Document template configuration options

### New Documentation
- Consider creating `docs/PYTHON_TEMPLATES.md` with detailed examples

---

## Testing Checklist

- [ ] Test each template type creates correct structure
- [ ] Verify virtual environment creation works
- [ ] Test with both venv and Poetry modes
- [ ] Confirm git initialization works
- [ ] Check that `stats` alias is truly removed
- [ ] Verify `dfstats` still works correctly
- [ ] Test on fresh installation

---

## Future Enhancements (v1.3.0)

- Add `py-test` template for testing frameworks
- Add `py-package` for PyPI package development
- Add `py-ml` for machine learning projects (with more ML tools)
- Add interactive template customization wizard
- Support for different Python versions (pyenv integration)
- Add GitHub Actions workflow templates
- Add Docker support for projects
