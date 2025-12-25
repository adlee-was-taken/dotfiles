# ============================================================================
# Python Project Template Functions
# ============================================================================
# Template-driven project scaffolding for Python applications.
# Eliminates code duplication by using a common creation function.
# ============================================================================

# Source bootstrap (handles all dependencies)
source "${0:A:h}/../lib/bootstrap.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/bootstrap.zsh" 2>/dev/null

# ============================================================================
# Configuration
# ============================================================================

typeset -g PY_PYTHON="${PY_PYTHON:-python3}"
typeset -g PY_VENV="${PY_VENV:-venv}"
typeset -g PY_GIT_INIT="${PY_GIT_INIT:-true}"

# ============================================================================
# Internal Helper Functions
# ============================================================================

# Validate project name and ensure directory doesn't exist
_py_check_name() {
    [[ -z "$1" ]] && { df_print_warning "Project name required"; return 1; }
    [[ -d "$1" ]] && { df_print_warning "Directory '$1' already exists"; return 1; }
    return 0
}

# Create and activate virtual environment
_py_venv() {
    local project_dir="$1"
    df_print_step "Creating virtual environment"
    "$PY_PYTHON" -m venv "$project_dir/$PY_VENV"
    df_print_success "Created: $PY_VENV"
}

# Install packages into project's venv
_py_install() {
    local project_dir="$1"
    shift
    local packages=("$@")
    
    [[ ${#packages[@]} -eq 0 ]] && return 0
    
    df_print_step "Installing: ${packages[*]}"
    "$project_dir/$PY_VENV/bin/pip" install "${packages[@]}" -q
}

# Create standard .gitignore for Python projects
_py_gitignore() {
    local project_dir="$1"
    cat > "$project_dir/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
.venv/
ENV/
env/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.nox/

# Type checking
.mypy_cache/
.dmypy.json

# Environment
.env
.env.*
*.log

# Distribution
*.manifest
*.spec
EOF
    df_print_success "Created .gitignore"
}

# Initialize git repository
_py_git() {
    local project_dir="$1"
    [[ "$PY_GIT_INIT" != "true" ]] && return 0
    
    (
        cd "$project_dir"
        git init -q
        git add .
        git commit -q -m "Initial commit"
    )
    df_print_success "Git initialized"
}

# Print next steps for user
_py_next_steps() {
    local project_dir="$1"
    local extra_info="$2"
    
    echo ""
    df_print_section "Next steps"
    df_print_indent "cd $project_dir"
    df_print_indent "source $PY_VENV/bin/activate"
    [[ -n "$extra_info" ]] && df_print_indent "$extra_info"
}

# ============================================================================
# Template Definitions
# ============================================================================
# Each template function creates type-specific files and returns packages to install

_py_template_basic() {
    local name="$1"
    
    # Create directory structure
    mkdir -p "$name"/{src,tests}
    touch "$name/src/__init__.py" "$name/tests/__init__.py"
    
    # Create main.py
    cat > "$name/src/main.py" << 'EOF'
#!/usr/bin/env python3
"""Main entry point."""


def main():
    """Main function."""
    print("Hello, World!")


if __name__ == "__main__":
    main()
EOF

    # Create requirements.txt
    cat > "$name/requirements.txt" << 'EOF'
# Project dependencies
# Add your dependencies here
EOF

    # Return packages to install (none for basic)
    echo ""
}

_py_template_flask() {
    local name="$1"
    
    # Create directory structure
    mkdir -p "$name"/{app/{templates,static/css},tests}
    
    # Create app/__init__.py
    cat > "$name/app/__init__.py" << 'EOF'
"""Flask application factory."""
from flask import Flask


def create_app(config_name=None):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    
    # Load configuration
    app.config.from_mapping(
        SECRET_KEY='dev',
        DEBUG=True,
    )
    
    # Register blueprints
    from app.routes import main
    app.register_blueprint(main)
    
    return app
EOF

    # Create app/routes.py
    cat > "$name/app/routes.py" << 'EOF'
"""Main application routes."""
from flask import Blueprint, render_template

main = Blueprint('main', __name__)


@main.route('/')
def index():
    """Home page."""
    return render_template('index.html')


@main.route('/health')
def health():
    """Health check endpoint."""
    return {'status': 'ok'}
EOF

    # Create template
    cat > "$name/app/templates/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flask App</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <h1>Welcome to Flask</h1>
    <p>Your application is running!</p>
</body>
</html>
EOF

    # Create basic CSS
    cat > "$name/app/static/css/style.css" << 'EOF'
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    max-width: 800px;
    margin: 0 auto;
    padding: 2rem;
}
EOF

    # Create run script
    cat > "$name/app.py" << 'EOF'
#!/usr/bin/env python3
"""Application entry point."""
from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF

    # Create requirements.txt
    cat > "$name/requirements.txt" << 'EOF'
Flask>=3.0.0
python-dotenv>=1.0.0
EOF

    # Return packages to install
    echo "flask python-dotenv"
}

_py_template_fastapi() {
    local name="$1"
    
    # Create directory structure
    mkdir -p "$name"/{app/{routers,models},tests}
    touch "$name/app/__init__.py" "$name/app/routers/__init__.py" "$name/app/models/__init__.py"
    
    # Create app/main.py
    cat > "$name/app/main.py" << 'EOF'
"""FastAPI application."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="FastAPI App",
    description="A FastAPI application",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Hello, World!"}


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok"}
EOF

    # Create run script
    cat > "$name/run.py" << 'EOF'
#!/usr/bin/env python3
"""Development server entry point."""
import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
EOF

    # Create requirements.txt
    cat > "$name/requirements.txt" << 'EOF'
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
python-dotenv>=1.0.0
EOF

    # Return packages to install
    echo "fastapi uvicorn python-dotenv"
}

_py_template_cli() {
    local name="$1"
    local pkg_name="${name//-/_}"  # Replace hyphens with underscores for Python
    
    # Create directory structure
    mkdir -p "$name"/{src/"$pkg_name",tests}
    
    # Create package __init__.py
    cat > "$name/src/$pkg_name/__init__.py" << EOF
"""${name} - A command-line tool."""
__version__ = "0.1.0"
EOF

    # Create CLI entry point
    cat > "$name/src/$pkg_name/cli.py" << 'EOF'
#!/usr/bin/env python3
"""Command-line interface."""
import click


@click.group()
@click.version_option()
def cli():
    """A command-line tool."""
    pass


@cli.command()
@click.argument('name', default='World')
def greet(name):
    """Greet someone by name."""
    click.echo(f"Hello, {name}!")


@cli.command()
@click.option('--verbose', '-v', is_flag=True, help='Enable verbose output')
def info(verbose):
    """Show application information."""
    click.echo("CLI Application v0.1.0")
    if verbose:
        click.echo("Built with Click")


if __name__ == '__main__':
    cli()
EOF

    # Create pyproject.toml for modern packaging
    cat > "$name/pyproject.toml" << EOF
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "$name"
version = "0.1.0"
description = "A command-line tool"
readme = "README.md"
requires-python = ">=3.8"
dependencies = [
    "click>=8.1.0",
]

[project.scripts]
$name = "${pkg_name}.cli:cli"

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "pytest-cov",
]
EOF

    # Create requirements.txt (for compatibility)
    cat > "$name/requirements.txt" << 'EOF'
click>=8.1.0
EOF

    # Create README
    cat > "$name/README.md" << EOF
# ${name}

A command-line tool.

## Installation

\`\`\`bash
pip install -e .
\`\`\`

## Usage

\`\`\`bash
${name} --help
${name} greet World
\`\`\`
EOF

    # Return packages to install
    echo "click"
}

_py_template_data() {
    local name="$1"
    
    # Create directory structure
    mkdir -p "$name"/{notebooks,data/{raw,processed},src,tests}
    touch "$name/src/__init__.py"
    
    # Create main analysis script
    cat > "$name/src/analysis.py" << 'EOF'
#!/usr/bin/env python3
"""Data analysis module."""
import pandas as pd
import numpy as np


def load_data(filepath):
    """Load data from CSV file."""
    return pd.read_csv(filepath)


def basic_stats(df):
    """Calculate basic statistics."""
    return df.describe()


if __name__ == "__main__":
    print("Data Science Project")
    print(f"NumPy version: {np.__version__}")
    print(f"Pandas version: {pd.__version__}")
EOF

    # Create sample notebook
    cat > "$name/notebooks/01_exploration.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": ["# Data Exploration\n", "\n", "Initial data exploration notebook."]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": ["import pandas as pd\n", "import numpy as np\n", "import matplotlib.pyplot as plt\n", "\n", "%matplotlib inline"]
  }
 ],
 "metadata": {
  "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
  "language_info": {"name": "python", "version": "3.10.0"}
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Create requirements.txt
    cat > "$name/requirements.txt" << 'EOF'
pandas>=2.0.0
numpy>=1.24.0
matplotlib>=3.7.0
seaborn>=0.12.0
jupyter>=1.0.0
scikit-learn>=1.3.0
EOF

    # Create .gitkeep files
    touch "$name/data/raw/.gitkeep" "$name/data/processed/.gitkeep"

    # Return packages to install
    echo "pandas numpy matplotlib seaborn jupyter scikit-learn"
}

# ============================================================================
# Main Project Creation Function
# ============================================================================

_py_create_project() {
    local name="$1"
    local template="$2"
    local display_name="$3"
    local extra_info="$4"
    
    # Validate
    _py_check_name "$name" || return 1
    
    # Print header
    df_print_func_name "${display_name}: ${name}"
    
    # Create base directory
    mkdir -p "$name"
    
    # Run template-specific setup and capture packages
    local packages
    packages=$("_py_template_${template}" "$name")
    
    # Common setup steps
    _py_venv "$name"
    
    # Install template-specific packages
    if [[ -n "$packages" ]]; then
        _py_install "$name" $packages
    fi
    
    # Finalization
    _py_gitignore "$name"
    _py_git "$name"
    
    df_print_success "Created: $name"
    _py_next_steps "$name" "$extra_info"
}

# ============================================================================
# Public API Functions
# ============================================================================

py-new() {
    _py_create_project "$1" "basic" "Python Project"
}

py-flask() {
    _py_create_project "$1" "flask" "Flask Project" "Run: python app.py"
}

py-fastapi() {
    _py_create_project "$1" "fastapi" "FastAPI Project" "Run: python run.py  |  Docs: http://localhost:8000/docs"
}

py-cli() {
    _py_create_project "$1" "cli" "CLI Project" "Install: pip install -e ."
}

py-data() {
    _py_create_project "$1" "data" "Data Science Project" "Start Jupyter: jupyter notebook"
}

# Quick venv activation helper
venv() {
    local venv_dirs=("venv" ".venv" "env" ".env")
    for dir in "${venv_dirs[@]}"; do
        if [[ -f "$dir/bin/activate" ]]; then
            source "$dir/bin/activate"
            df_print_success "Activated: $dir"
            return 0
        fi
    done
    df_print_error "No virtual environment found"
    df_print_info "Create one with: python -m venv venv"
    return 1
}

# List available templates
py-templates() {
    df_print_func_name "Python Project Templates"
    echo ""
    df_print_indent "py-new <name>      Basic Python project"
    df_print_indent "py-flask <name>    Flask web application"
    df_print_indent "py-fastapi <name>  FastAPI REST API"
    df_print_indent "py-cli <name>      CLI tool with Click"
    df_print_indent "py-data <name>     Data science project"
    echo ""
    df_print_info "Example: py-flask mywebapp"
}

# ============================================================================
# Aliases
# ============================================================================

alias pynew='py-new'
alias pyflask='py-flask'
alias pyfast='py-fastapi'
alias pycli='py-cli'
alias pydata='py-data'
alias pytemplates='py-templates'
