# ============================================================================
# Python Project Template Functions
# ============================================================================
# Quick project scaffolding with virtual environments
#
# Usage:
#   py-new <project_name>          # Create new Python project
#   py-django <project_name>       # Create Django project
#   py-flask <project_name>        # Create Flask project
#   py-fastapi <project_name>      # Create FastAPI project
#   py-data <project_name>         # Create data science project
#   py-cli <project_name>          # Create CLI tool project
# ============================================================================

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_GREEN=$'\033[0;32m' DF_BLUE=$'\033[0;34m'
    typeset -g DF_YELLOW=$'\033[1;33m' DF_CYAN=$'\033[0;36m'
    typeset -g DF_RED=$'\033[0;31m' DF_NC=$'\033[0m'
}

# ============================================================================
# Configuration
# ============================================================================

typeset -g PY_TEMPLATE_BASE_DIR="${PY_TEMPLATE_BASE_DIR:-$HOME/projects}"
typeset -g PY_TEMPLATE_PYTHON="${PY_TEMPLATE_PYTHON:-python3}"
typeset -g PY_TEMPLATE_VENV_NAME="${PY_TEMPLATE_VENV_NAME:-venv}"
typeset -g PY_TEMPLATE_USE_POETRY="${PY_TEMPLATE_USE_POETRY:-false}"
typeset -g PY_TEMPLATE_GIT_INIT="${PY_TEMPLATE_GIT_INIT:-true}"

# ============================================================================
# Helper Functions
# ============================================================================

_py_print_step() {
    echo -e "${DF_BLUE}==>${DF_NC} $1"
}

_py_print_success() {
    echo -e "${DF_GREEN}✓${DF_NC} $1"
}

_py_print_info() {
    echo -e "${DF_CYAN}ℹ${DF_NC} $1"
}

_py_check_project_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo -e "${DF_YELLOW}⚠${DF_NC} Project name required"
        return 1
    fi
    if [[ -d "$name" ]]; then
        echo -e "${DF_YELLOW}⚠${DF_NC} Directory '$name' already exists"
        return 1
    fi
    return 0
}

_py_create_venv() {
    local project_dir="$1"
    _py_print_step "Creating virtual environment"
    
    if [[ "$PY_TEMPLATE_USE_POETRY" == "true" ]] && command -v poetry &>/dev/null; then
        cd "$project_dir"
        poetry init --no-interaction
        poetry env use "$PY_TEMPLATE_PYTHON"
        _py_print_success "Poetry environment created"
    else
        "$PY_TEMPLATE_PYTHON" -m venv "$project_dir/$PY_TEMPLATE_VENV_NAME"
        _py_print_success "Virtual environment created: $PY_TEMPLATE_VENV_NAME"
    fi
}

_py_create_gitignore() {
    local project_dir="$1"
    cat > "$project_dir/.gitignore" << 'EOF'
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
dist/
*.egg-info/
venv/
env/
.venv
.vscode/
.idea/
*.swp
.pytest_cache/
.coverage
htmlcov/
.env
*.log
*.db
*.sqlite3
.mypy_cache/
EOF
    _py_print_success "Created .gitignore"
}

_py_init_git() {
    local project_dir="$1"
    if [[ "$PY_TEMPLATE_GIT_INIT" == "true" ]]; then
        cd "$project_dir"
        git init
        git add .
        git commit -m "Initial commit: project scaffolding"
        _py_print_success "Git repository initialized"
    fi
}

_py_show_next_steps() {
    local project_name="$1"
    local has_venv="$2"
    echo
    echo -e "${DF_CYAN}Next steps:${DF_NC}"
    echo "  cd $project_name"
    if [[ "$has_venv" == "true" ]]; then
        if [[ "$PY_TEMPLATE_USE_POETRY" == "true" ]]; then
            echo "  poetry shell"
        else
            echo "  source $PY_TEMPLATE_VENV_NAME/bin/activate"
        fi
    fi
    echo "  # Start coding!"
    echo
}

# ============================================================================
# Base Python Project Template
# ============================================================================

py-new() {
    local project_name="$1"
    _py_check_project_name "$project_name" || return 1
    
    df_print_func_name "Python Project: $project_name"
    
    _py_print_step "Creating project structure"
    mkdir -p "$project_name"/{src,tests,docs}
    touch "$project_name/src/__init__.py"
    touch "$project_name/tests/__init__.py"
    
    cat > "$project_name/src/main.py" << 'EOF'
#!/usr/bin/env python3
"""Main module."""

def main():
    print("Hello from Python!")

if __name__ == "__main__":
    main()
EOF
    
    cat > "$project_name/requirements.txt" << 'EOF'
# Production dependencies
# Development: pytest, black, flake8, mypy
EOF
    
    _py_print_success "Project structure created"
    _py_create_venv "$project_name"
    _py_create_gitignore "$project_name"
    _py_init_git "$project_name"
    
    echo
    _py_print_success "Project '$project_name' created successfully!"
    _py_show_next_steps "$project_name" "true"
}

# ============================================================================
# Django Project Template
# ============================================================================

py-django() {
    local project_name="$1"
    _py_check_project_name "$project_name" || return 1
    
    df_print_func_name "Django Project: $project_name"
    
    mkdir -p "$project_name"
    _py_create_venv "$project_name"
    
    _py_print_step "Installing Django"
    cd "$project_name"
    "$PY_TEMPLATE_VENV_NAME/bin/pip" install django
    
    _py_print_step "Creating Django project structure"
    "$PY_TEMPLATE_VENV_NAME/bin/django-admin" startproject config .
    
    cat > "requirements.txt" << 'EOF'
Django>=4.2.0
python-decouple>=3.8
EOF
    
    mkdir -p apps static templates media
    _py_create_gitignore "."
    _py_init_git "."
    cd ..
    
    echo
    _py_print_success "Django project '$project_name' created!"
    _py_show_next_steps "$project_name" "true"
}

# ============================================================================
# Flask Project Template
# ============================================================================

py-flask() {
    local project_name="$1"
    _py_check_project_name "$project_name" || return 1
    
    df_print_func_name "Flask Project: $project_name"
    
    mkdir -p "$project_name"/{app/{templates,static/{css,js}},tests}
    _py_create_venv "$project_name"
    
    cd "$project_name"
    _py_print_step "Installing Flask"
    "$PY_TEMPLATE_VENV_NAME/bin/pip" install flask
    
    cat > "app/__init__.py" << 'EOF'
from flask import Flask

def create_app(config=None):
    app = Flask(__name__)
    if config:
        app.config.from_object(config)
    from app.routes import main
    app.register_blueprint(main)
    return app
EOF
    
    cat > "app/routes.py" << 'EOF'
from flask import Blueprint, render_template

main = Blueprint('main', __name__)

@main.route('/')
def index():
    return render_template('index.html')
EOF
    
    cat > "app.py" << 'EOF'
#!/usr/bin/env python3
from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF
    chmod +x app.py
    
    cat > "app/templates/index.html" << 'EOF'
<!DOCTYPE html>
<html><head><title>Flask App</title></head>
<body><h1>Welcome to Flask!</h1></body></html>
EOF
    
    cat > "requirements.txt" << 'EOF'
Flask>=3.0.0
python-decouple>=3.8
EOF
    
    _py_create_gitignore "."
    _py_init_git "."
    cd ..
    
    echo
    _py_print_success "Flask project '$project_name' created!"
    _py_show_next_steps "$project_name" "true"
}

# ============================================================================
# FastAPI Project Template
# ============================================================================

py-fastapi() {
    local project_name="$1"
    _py_check_project_name "$project_name" || return 1
    
    df_print_func_name "FastAPI Project: $project_name"
    
    mkdir -p "$project_name"/{app/{api,models,schemas},tests}
    _py_create_venv "$project_name"
    
    cd "$project_name"
    _py_print_step "Installing FastAPI"
    "$PY_TEMPLATE_VENV_NAME/bin/pip" install fastapi uvicorn[standard] pydantic
    
    touch "app/__init__.py"
    
    cat > "app/main.py" << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="My API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "Welcome to FastAPI"}

@app.get("/health")
def health():
    return {"status": "healthy"}
EOF
    
    cat > "run.py" << 'EOF'
#!/usr/bin/env python3
import uvicorn

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
EOF
    chmod +x run.py
    
    cat > "requirements.txt" << 'EOF'
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.5.0
EOF
    
    _py_create_gitignore "."
    _py_init_git "."
    cd ..
    
    echo
    _py_print_success "FastAPI project '$project_name' created!"
    _py_print_info "Docs at: http://localhost:8000/docs"
    _py_show_next_steps "$project_name" "true"
}

# ============================================================================
# Data Science Project Template
# ============================================================================

py-data() {
    local project_name="$1"
    _py_check_project_name "$project_name" || return 1
    
    df_print_func_name "Data Science Project: $project_name"
    
    mkdir -p "$project_name"/{data/{raw,processed},notebooks,src,models,reports/figures}
    _py_create_venv "$project_name"
    
    cd "$project_name"
    _py_print_step "Installing data science packages"
    "$PY_TEMPLATE_VENV_NAME/bin/pip" install pandas numpy matplotlib seaborn jupyter
    
    touch "src/__init__.py"
    touch data/raw/.gitkeep data/processed/.gitkeep
    
    cat > "requirements.txt" << 'EOF'
pandas>=2.1.0
numpy>=1.24.0
matplotlib>=3.8.0
seaborn>=0.13.0
jupyter>=1.0.0
scikit-learn>=1.3.0
EOF
    
    _py_create_gitignore "."
    cat >> ".gitignore" << 'EOF'
*.pkl
*.h5
*.parquet
data/raw/*
data/processed/*
!data/raw/.gitkeep
!data/processed/.gitkeep
models/*.pkl
.ipynb_checkpoints
EOF
    
    _py_init_git "."
    cd ..
    
    echo
    _py_print_success "Data science project '$project_name' created!"
    _py_print_info "Start Jupyter: jupyter notebook"
    _py_show_next_steps "$project_name" "true"
}

# ============================================================================
# CLI Tool Project Template
# ============================================================================

py-cli() {
    local project_name="$1"
    _py_check_project_name "$project_name" || return 1
    
    df_print_func_name "CLI Tool Project: $project_name"
    
    mkdir -p "$project_name"/{src/$project_name,tests}
    _py_create_venv "$project_name"
    
    cd "$project_name"
    _py_print_step "Installing click"
    "$PY_TEMPLATE_VENV_NAME/bin/pip" install click
    
    cat > "src/$project_name/__init__.py" << 'EOF'
__version__ = "0.1.0"
EOF
    
    cat > "src/$project_name/cli.py" << 'EOF'
#!/usr/bin/env python3
import click

@click.group()
@click.version_option()
def cli():
    """CLI tool - A command-line utility."""
    pass

@cli.command()
@click.argument('name', default='World')
def greet(name):
    """Greet someone."""
    click.echo(f"Hello, {name}!")

if __name__ == '__main__':
    cli()
EOF
    
    cat > "setup.py" << EOF
from setuptools import setup, find_packages

setup(
    name="$project_name",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=["click>=8.0.0"],
    entry_points={"console_scripts": ["$project_name=$project_name.cli:cli"]},
)
EOF
    
    cat > "requirements.txt" << 'EOF'
click>=8.1.0
EOF
    
    _py_create_gitignore "."
    _py_init_git "."
    cd ..
    
    echo
    _py_print_success "CLI tool project '$project_name' created!"
    _py_print_info "Install with: pip install -e $project_name"
    _py_show_next_steps "$project_name" "true"
}

# ============================================================================
# Aliases
# ============================================================================

alias pynew='py-new'
alias pydjango='py-django'
alias pyflask='py-flask'
alias pyfast='py-fastapi'
alias pydata='py-data'
alias pycli='py-cli'

# Quick venv activation
venv() {
    if [[ -d "venv" ]]; then
        source venv/bin/activate
    elif [[ -d ".venv" ]]; then
        source .venv/bin/activate
    elif [[ -d "env" ]]; then
        source env/bin/activate
    else
        echo "No virtual environment found (venv, .venv, or env)"
        return 1
    fi
}
