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
#
# Add to .zshrc:
#   source ~/.dotfiles/zsh/functions/python-templates.zsh
# ============================================================================

# ============================================================================
# Configuration
# ============================================================================

typeset -g PY_TEMPLATE_BASE_DIR="${PY_TEMPLATE_BASE_DIR:-$HOME/projects}"
typeset -g PY_TEMPLATE_PYTHON="${PY_TEMPLATE_PYTHON:-python3}"
typeset -g PY_TEMPLATE_VENV_NAME="${PY_TEMPLATE_VENV_NAME:-venv}"
typeset -g PY_TEMPLATE_USE_POETRY="${PY_TEMPLATE_USE_POETRY:-false}"
typeset -g PY_TEMPLATE_GIT_INIT="${PY_TEMPLATE_GIT_INIT:-true}"

# Colors
typeset -g PY_GREEN=$'\033[0;32m'
typeset -g PY_BLUE=$'\033[0;34m'
typeset -g PY_YELLOW=$'\033[1;33m'
typeset -g PY_CYAN=$'\033[0;36m'
typeset -g PY_NC=$'\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

_py_print_step() {
    echo -e "${PY_BLUE}==>${PY_NC} $1"
}

_py_print_success() {
    echo -e "${PY_GREEN}✓${PY_NC} $1"
}

_py_print_info() {
    echo -e "${PY_CYAN}ℹ${PY_NC} $1"
}

_py_check_project_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo -e "${PY_YELLOW}⚠${PY_NC} Project name required"
        return 1
    fi
    if [[ -d "$name" ]]; then
        echo -e "${PY_YELLOW}⚠${PY_NC} Directory '$name' already exists"
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

# Virtual Environment
venv/
env/
ENV/
.venv

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.hypothesis/

# Environment variables
.env
.env.local
.env.*.local

# Logs
*.log
logs/

# Database
*.db
*.sqlite
*.sqlite3

# Distribution / packaging
.Python
build/
dist/
*.egg-info/

# Poetry
poetry.lock

# Jupyter Notebook
.ipynb_checkpoints
*.ipynb

# MyPy
.mypy_cache/
.dmypy.json
dmypy.json

# Type checking
.pyre/
.pytype/
EOF
    
    _py_print_success "Created .gitignore"
}

_py_create_readme() {
    local project_name="$1"
    local project_dir="$2"
    local description="$3"
    
    cat > "$project_dir/README.md" << EOF
# $project_name

$description

## Setup

### Using venv

\`\`\`bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/Mac
# or
venv\\Scripts\\activate  # Windows

# Install dependencies
pip install -r requirements.txt
\`\`\`

### Using Poetry (alternative)

\`\`\`bash
poetry install
poetry shell
\`\`\`

## Development

\`\`\`bash
# Activate virtual environment
source venv/bin/activate

# Run the application
python main.py
\`\`\`

## Testing

\`\`\`bash
# Install dev dependencies
pip install pytest pytest-cov

# Run tests
pytest

# Run tests with coverage
pytest --cov=src tests/
\`\`\`

## Project Structure

\`\`\`
$project_name/
├── src/              # Source code
├── tests/            # Test files
├── docs/             # Documentation
├── .gitignore
├── README.md
├── requirements.txt
└── setup.py
\`\`\`

## License

MIT
EOF
    
    _py_print_success "Created README.md"
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
    echo -e "${PY_CYAN}Next steps:${PY_NC}"
    echo
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
    local project_type="${2:-basic}"
    
    _py_check_project_name "$project_name" || return 1
    
    echo -e "${PY_BLUE}╔════════════════════════════════════════════════════════════╗${PY_NC}"
    echo -e "${PY_BLUE}║${PY_NC}  Creating Python Project: $project_name"
    echo -e "${PY_BLUE}╚════════════════════════════════════════════════════════════╝${PY_NC}"
    echo
    
    # Create project structure
    _py_print_step "Creating project structure"
    mkdir -p "$project_name"/{src,tests,docs}
    
    # Create __init__.py files
    touch "$project_name/src/__init__.py"
    touch "$project_name/tests/__init__.py"
    
    # Create main.py
    cat > "$project_name/src/main.py" << 'EOF'
#!/usr/bin/env python3
"""
Main module for the application.
"""

def main():
    """Main entry point."""
    print("Hello from Python!")

if __name__ == "__main__":
    main()
EOF
    
    # Create basic test
    cat > "$project_name/tests/test_main.py" << 'EOF'
"""Tests for main module."""
import pytest
from src.main import main

def test_main():
    """Test main function runs without error."""
    main()
EOF
    
    # Create requirements.txt
    cat > "$project_name/requirements.txt" << 'EOF'
# Production dependencies

# Development dependencies (uncomment as needed)
# pytest>=7.0.0
# pytest-cov>=4.0.0
# black>=23.0.0
# flake8>=6.0.0
# mypy>=1.0.0
# pylint>=2.17.0
EOF
    
    # Create setup.py
    cat > "$project_name/setup.py" << EOF
from setuptools import setup, find_packages

setup(
    name="$project_name",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[],
    python_requires=">=3.8",
)
EOF
    
    _py_print_success "Project structure created"
    
    # Create virtual environment
    _py_create_venv "$project_name"
    
    # Create .gitignore
    _py_create_gitignore "$project_name"
    
    # Create README
    _py_create_readme "$project_name" "$project_name" "A Python project"
    
    # Initialize git
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
    
    echo -e "${PY_BLUE}╔════════════════════════════════════════════════════════════╗${PY_NC}"
    echo -e "${PY_BLUE}║${PY_NC}  Creating Django Project: $project_name"
    echo -e "${PY_BLUE}╚════════════════════════════════════════════════════════════╝${PY_NC}"
    echo
    
    # Create project directory
    mkdir -p "$project_name"
    
    # Create virtual environment first
    _py_create_venv "$project_name"
    
    # Install Django
    _py_print_step "Installing Django"
    cd "$project_name"
    
    if [[ "$PY_TEMPLATE_USE_POETRY" == "true" ]]; then
        poetry add django
    else
        "$PY_TEMPLATE_VENV_NAME/bin/pip" install django
    fi
    
    # Create Django project
    _py_print_step "Creating Django project structure"
    
    if [[ "$PY_TEMPLATE_USE_POETRY" == "true" ]]; then
        poetry run django-admin startproject config .
    else
        "$PY_TEMPLATE_VENV_NAME/bin/django-admin" startproject config .
    fi
    
    # Create requirements.txt
    cat > "requirements.txt" << 'EOF'
Django>=4.2.0
python-decouple>=3.8
psycopg2-binary>=2.9.0  # PostgreSQL adapter
django-environ>=0.11.0

# Development
django-debug-toolbar>=4.2.0
django-extensions>=3.2.0
EOF
    
    # Create .env.example
    cat > ".env.example" << 'EOF'
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=sqlite:///db.sqlite3
# DATABASE_URL=postgresql://user:password@localhost:5432/dbname
EOF
    
    # Create README
    cat > "README.md" << EOF
# $project_name

A Django web application.

## Setup

\`\`\`bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env with your settings

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
\`\`\`

## Development

\`\`\`bash
# Create a new app
python manage.py startapp myapp

# Make migrations
python manage.py makemigrations

# Run tests
python manage.py test

# Collect static files
python manage.py collectstatic
\`\`\`

## Project Structure

\`\`\`
$project_name/
├── config/           # Django settings
├── apps/             # Django apps
├── static/           # Static files
├── templates/        # HTML templates
├── media/            # Uploaded files
├── manage.py
└── requirements.txt
\`\`\`
EOF
    
    # Create directories
    mkdir -p apps static templates media
    
    _py_create_gitignore "."
    _py_init_git "."
    
    cd ..
    
    echo
    _py_print_success "Django project '$project_name' created!"
    _py_print_info "Don't forget to set SECRET_KEY in .env"
    _py_show_next_steps "$project_name" "true"
}

# ============================================================================
# Flask Project Template
# ============================================================================

py-flask() {
    local project_name="$1"
    
    _py_check_project_name "$project_name" || return 1
    
    echo -e "${PY_BLUE}╔════════════════════════════════════════════════════════════╗${PY_NC}"
    echo -e "${PY_BLUE}║${PY_NC}  Creating Flask Project: $project_name"
    echo -e "${PY_BLUE}╚════════════════════════════════════════════════════════════╝${PY_NC}"
    echo
    
    # Create project structure
    mkdir -p "$project_name"/{app/{templates,static/{css,js,img}},tests}
    
    # Create virtual environment
    _py_create_venv "$project_name"
    
    cd "$project_name"
    
    # Install Flask
    _py_print_step "Installing Flask"
    if [[ "$PY_TEMPLATE_USE_POETRY" == "true" ]]; then
        poetry add flask
    else
        "$PY_TEMPLATE_VENV_NAME/bin/pip" install flask
    fi
    
    # Create app/__init__.py
    cat > "app/__init__.py" << 'EOF'
"""Flask application factory."""
from flask import Flask

def create_app(config=None):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    
    if config:
        app.config.from_object(config)
    
    # Register blueprints
    from app.routes import main
    app.register_blueprint(main)
    
    return app
EOF
    
    # Create app/routes.py
    cat > "app/routes.py" << 'EOF'
"""Application routes."""
from flask import Blueprint, render_template

main = Blueprint('main', __name__)

@main.route('/')
def index():
    """Home page."""
    return render_template('index.html')

@main.route('/api/health')
def health():
    """Health check endpoint."""
    return {'status': 'healthy'}
EOF
    
    # Create app.py
    cat > "app.py" << 'EOF'
#!/usr/bin/env python3
"""Flask application entry point."""
from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF
    chmod +x app.py
    
    # Create base template
    cat > "app/templates/base.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Flask App{% endblock %}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <main>
        {% block content %}{% endblock %}
    </main>
    <script src="{{ url_for('static', filename='js/main.js') }}"></script>
</body>
</html>
EOF
    
    # Create index template
    cat > "app/templates/index.html" << 'EOF'
{% extends "base.html" %}

{% block title %}Home{% endblock %}

{% block content %}
<h1>Welcome to Flask!</h1>
<p>Your app is running.</p>
{% endblock %}
EOF
    
    # Create basic CSS
    cat > "app/static/css/style.css" << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    line-height: 1.6;
    padding: 2rem;
}

main {
    max-width: 1200px;
    margin: 0 auto;
}
EOF
    
    # Create basic JS
    cat > "app/static/js/main.js" << 'EOF'
console.log('Flask app loaded');
EOF
    
    # Create requirements.txt
    cat > "requirements.txt" << 'EOF'
Flask>=3.0.0
python-decouple>=3.8

# Development
flask-debugtoolbar>=0.14.0
EOF
    
    # Create .env.example
    cat > ".env.example" << 'EOF'
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=your-secret-key-here
EOF
    
    # Create README
    cat > "README.md" << EOF
# $project_name

A Flask web application.

## Setup

\`\`\`bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Run the application
python app.py
\`\`\`

Visit: http://localhost:5000

## Development

\`\`\`bash
# Run with auto-reload
export FLASK_ENV=development
python app.py

# Run tests
pytest
\`\`\`

## Project Structure

\`\`\`
$project_name/
├── app/
│   ├── __init__.py
│   ├── routes.py
│   ├── templates/
│   └── static/
├── tests/
├── app.py
└── requirements.txt
\`\`\`
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
    
    echo -e "${PY_BLUE}╔════════════════════════════════════════════════════════════╗${PY_NC}"
    echo -e "${PY_BLUE}║${PY_NC}  Creating FastAPI Project: $project_name"
    echo -e "${PY_BLUE}╚════════════════════════════════════════════════════════════╝${PY_NC}"
    echo
    
    # Create project structure
    mkdir -p "$project_name"/{app/{api,models,schemas,services},tests}
    
    # Create virtual environment
    _py_create_venv "$project_name"
    
    cd "$project_name"
    
    # Install FastAPI
    _py_print_step "Installing FastAPI and dependencies"
    if [[ "$PY_TEMPLATE_USE_POETRY" == "true" ]]; then
        poetry add fastapi uvicorn pydantic
    else
        "$PY_TEMPLATE_VENV_NAME/bin/pip" install fastapi uvicorn[standard] pydantic
    fi
    
    # Create app/__init__.py
    touch "app/__init__.py"
    
    # Create main.py
    cat > "app/main.py" << 'EOF'
"""FastAPI application."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import router

app = FastAPI(
    title="My API",
    description="FastAPI application",
    version="0.1.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(router, prefix="/api")

@app.get("/")
def root():
    """Root endpoint."""
    return {"message": "Welcome to FastAPI"}

@app.get("/health")
def health():
    """Health check."""
    return {"status": "healthy"}
EOF
    
    # Create api/__init__.py
    cat > "app/api/__init__.py" << 'EOF'
"""API routes."""
from fastapi import APIRouter

router = APIRouter()

@router.get("/items")
def list_items():
    """List all items."""
    return {"items": []}

@router.get("/items/{item_id}")
def get_item(item_id: int):
    """Get a specific item."""
    return {"id": item_id, "name": f"Item {item_id}"}
EOF
    
    # Create schemas/__init__.py
    cat > "app/schemas/__init__.py" << 'EOF'
"""Pydantic schemas."""
from pydantic import BaseModel

class ItemBase(BaseModel):
    """Base item schema."""
    name: str
    description: str | None = None

class ItemCreate(ItemBase):
    """Schema for creating items."""
    pass

class Item(ItemBase):
    """Full item schema."""
    id: int
    
    class Config:
        from_attributes = True
EOF
    
    # Create models, services __init__.py
    touch "app/models/__init__.py"
    touch "app/services/__init__.py"
    
    # Create requirements.txt
    cat > "requirements.txt" << 'EOF'
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.5.0
python-decouple>=3.8

# Optional
# sqlalchemy>=2.0.0
# alembic>=1.12.0
# python-jose[cryptography]>=3.3.0
# passlib[bcrypt]>=1.7.4

# Development
pytest>=7.4.0
httpx>=0.25.0
EOF
    
    # Create run.py
    cat > "run.py" << 'EOF'
#!/usr/bin/env python3
"""Run the FastAPI application."""
import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
EOF
    chmod +x run.py
    
    # Create .env.example
    cat > ".env.example" << 'EOF'
API_KEY=your-api-key
DATABASE_URL=sqlite:///./app.db
SECRET_KEY=your-secret-key
EOF
    
    # Create README
    cat > "README.md" << EOF
# $project_name

A FastAPI application.

## Setup

\`\`\`bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Run the application
python run.py
\`\`\`

Visit:
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Development

\`\`\`bash
# Run with auto-reload
uvicorn app.main:app --reload

# Run tests
pytest
\`\`\`

## Project Structure

\`\`\`
$project_name/
├── app/
│   ├── api/          # API routes
│   ├── models/       # Database models
│   ├── schemas/      # Pydantic schemas
│   ├── services/     # Business logic
│   └── main.py
├── tests/
├── run.py
└── requirements.txt
\`\`\`
EOF
    
    _py_create_gitignore "."
    _py_init_git "."
    
    cd ..
    
    echo
    _py_print_success "FastAPI project '$project_name' created!"
    _py_print_info "Docs will be at: http://localhost:8000/docs"
    _py_show_next_steps "$project_name" "true"
}

# ============================================================================
# Data Science Project Template
# ============================================================================

py-data() {
    local project_name="$1"
    
    _py_check_project_name "$project_name" || return 1
    
    echo -e "${PY_BLUE}╔════════════════════════════════════════════════════════════╗${PY_NC}"
    echo -e "${PY_BLUE}║${PY_NC}  Creating Data Science Project: $project_name"
    echo -e "${PY_BLUE}╚════════════════════════════════════════════════════════════╝${PY_NC}"
    echo
    
    # Create project structure
    mkdir -p "$project_name"/{data/{raw,processed,external},notebooks,src,models,reports/{figures}}
    
    # Create virtual environment
    _py_create_venv "$project_name"
    
    cd "$project_name"
    
    # Install data science packages
    _py_print_step "Installing data science packages"
    if [[ "$PY_TEMPLATE_USE_POETRY" == "true" ]]; then
        poetry add pandas numpy matplotlib seaborn jupyter
    else
        "$PY_TEMPLATE_VENV_NAME/bin/pip" install pandas numpy matplotlib seaborn jupyter notebook
    fi
    
    # Create requirements.txt
    cat > "requirements.txt" << 'EOF'
# Core
pandas>=2.1.0
numpy>=1.24.0
matplotlib>=3.8.0
seaborn>=0.13.0

# Machine Learning
scikit-learn>=1.3.0
# tensorflow>=2.14.0
# torch>=2.1.0

# Jupyter
jupyter>=1.0.0
notebook>=7.0.0
ipykernel>=6.25.0

# Utilities
python-decouple>=3.8

# Development
pytest>=7.4.0
black>=23.9.0
pylint>=2.17.0
EOF
    
    # Create starter notebook
    cat > "notebooks/01_exploration.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Exploration\n",
    "\n",
    "Initial data exploration and analysis."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "%matplotlib inline\n",
    "sns.set_style('whitegrid')"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load data\n",
    "# df = pd.read_csv('../data/raw/data.csv')"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF
    
    # Create src/__init__.py
    touch "src/__init__.py"
    
    # Create example processing script
    cat > "src/process_data.py" << 'EOF'
#!/usr/bin/env python3
"""Data processing utilities."""
import pandas as pd

def load_raw_data(filepath):
    """Load raw data from file."""
    return pd.read_csv(filepath)

def clean_data(df):
    """Clean and preprocess data."""
    # Remove duplicates
    df = df.drop_duplicates()
    
    # Handle missing values
    df = df.dropna()
    
    return df

def main():
    """Main processing pipeline."""
    # Load data
    df = load_raw_data('data/raw/data.csv')
    
    # Clean data
    df = clean_data(df)
    
    # Save processed data
    df.to_csv('data/processed/data_clean.csv', index=False)
    print(f"Processed {len(df)} rows")

if __name__ == '__main__':
    main()
EOF
    
    # Create README
    cat > "README.md" << EOF
# $project_name

A data science project.

## Setup

\`\`\`bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install Jupyter kernel
python -m ipykernel install --user --name=$project_name
\`\`\`

## Usage

\`\`\`bash
# Start Jupyter Notebook
jupyter notebook

# Run processing script
python src/process_data.py
\`\`\`

## Project Structure

\`\`\`
$project_name/
├── data/
│   ├── raw/          # Original, immutable data
│   ├── processed/    # Cleaned, processed data
│   └── external/     # External data sources
├── notebooks/        # Jupyter notebooks
├── src/              # Source code
├── models/           # Trained models
├── reports/          # Analysis reports
│   └── figures/      # Generated graphics
└── requirements.txt
\`\`\`

## Data

Place your raw data files in \`data/raw/\`.

## Notebooks

1. \`01_exploration.ipynb\` - Initial data exploration
2. Add more notebooks as needed

## Guidelines

- Keep raw data immutable
- Document your analysis in notebooks
- Extract reusable code to \`src/\`
- Save processed data to \`data/processed/\`
- Save figures to \`reports/figures/\`
EOF
    
    # Create data README
    cat > "data/README.md" << 'EOF'
# Data Directory

## Structure

- `raw/` - Original, immutable data dump
- `processed/` - Cleaned and processed data
- `external/` - Data from third party sources

## Guidelines

- Never modify files in `raw/`
- Document data sources
- Include data dictionaries where applicable
EOF
    
    _py_create_gitignore "."
    
    # Update gitignore for data science
    cat >> ".gitignore" << 'EOF'

# Data Science specific
*.pkl
*.h5
*.hdf5
*.parquet

# Data files (comment out if you want to track them)
data/raw/*
data/processed/*
!data/raw/.gitkeep
!data/processed/.gitkeep

# Model files
models/*.pkl
models/*.h5

# Jupyter
.ipynb_checkpoints

# Large files
*.csv
*.tsv
*.dat
EOF
    
    # Create .gitkeep files
    touch data/raw/.gitkeep data/processed/.gitkeep data/external/.gitkeep
    
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
    
    echo -e "${PY_BLUE}╔════════════════════════════════════════════════════════════╗${PY_NC}"
    echo -e "${PY_BLUE}║${PY_NC}  Creating CLI Tool Project: $project_name"
    echo -e "${PY_BLUE}╚════════════════════════════════════════════════════════════╝${PY_NC}"
    echo
    
    # Create project structure
    mkdir -p "$project_name"/{src/$project_name,tests}
    
    # Create virtual environment
    _py_create_venv "$project_name"
    
    cd "$project_name"
    
    # Install click
    _py_print_step "Installing click for CLI"
    if [[ "$PY_TEMPLATE_USE_POETRY" == "true" ]]; then
        poetry add click
    else
        "$PY_TEMPLATE_VENV_NAME/bin/pip" install click
    fi
    
    # Create package __init__.py
    cat > "src/$project_name/__init__.py" << 'EOF'
"""CLI tool package."""
__version__ = "0.1.0"
EOF
    
    # Create cli.py
    cat > "src/$project_name/cli.py" << 'EOF'
#!/usr/bin/env python3
"""Command-line interface."""
import click

@click.group()
@click.version_option()
def cli():
    """CLI tool - A command-line utility."""
    pass

@cli.command()
@click.argument('name', default='World')
@click.option('--greeting', default='Hello', help='Greeting to use')
def greet(name, greeting):
    """Greet someone."""
    click.echo(f"{greeting}, {name}!")

@cli.command()
@click.option('--count', default=1, help='Number of times to repeat')
@click.argument('message')
def repeat(message, count):
    """Repeat a message."""
    for _ in range(count):
        click.echo(message)

if __name__ == '__main__':
    cli()
EOF
    chmod +x "src/$project_name/cli.py"
    
    # Create __main__.py
    cat > "src/$project_name/__main__.py" << EOF
"""Allow running as python -m $project_name"""
from $project_name.cli import cli

if __name__ == '__main__':
    cli()
EOF
    
    # Create setup.py
    cat > "setup.py" << EOF
from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="$project_name",
    version="0.1.0",
    author="Your Name",
    author_email="you@example.com",
    description="A command-line tool",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/$project_name",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.8",
    install_requires=[
        "click>=8.0.0",
    ],
    entry_points={
        "console_scripts": [
            "$project_name=$project_name.cli:cli",
        ],
    },
)
EOF
    
    # Create requirements.txt
    cat > "requirements.txt" << 'EOF'
click>=8.1.0

# Development
pytest>=7.4.0
black>=23.9.0
EOF
    
    # Create README
    cat > "README.md" << EOF
# $project_name

A command-line tool built with Python and Click.

## Installation

\`\`\`bash
# Development installation
pip install -e .

# Or install from source
pip install .
\`\`\`

## Usage

\`\`\`bash
# Show help
$project_name --help

# Example commands
$project_name greet
$project_name greet Alice
$project_name greet --greeting "Hi" Bob
$project_name repeat "Hello" --count 3
\`\`\`

## Development

\`\`\`bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install in development mode
pip install -e .

# Run tests
pytest

# Format code
black src/
\`\`\`

## Project Structure

\`\`\`
$project_name/
├── src/
│   └── $project_name/
│       ├── __init__.py
│       ├── __main__.py
│       └── cli.py
├── tests/
├── setup.py
└── requirements.txt
\`\`\`

## Adding Commands

Add new commands to \`src/$project_name/cli.py\`:

\`\`\`python
@cli.command()
@click.argument('arg')
def mycommand(arg):
    """Description of command."""
    click.echo(f"Running with: {arg}")
\`\`\`
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

# ============================================================================
# Initialization Message
# ============================================================================

# Uncomment to show on load:
# echo "Python templates loaded. Use: py-new, py-django, py-flask, py-fastapi, py-data, py-cli"
