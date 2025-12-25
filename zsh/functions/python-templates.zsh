# ============================================================================
# Python Project Template Functions
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

typeset -g PY_PYTHON="${PY_PYTHON:-python3}"
typeset -g PY_VENV="${PY_VENV:-venv}"
typeset -g PY_GIT_INIT="${PY_GIT_INIT:-true}"

_py_check_name() {
    [[ -z "$1" ]] && { df_print_warning "Project name required"; return 1; }
    [[ -d "$1" ]] && { df_print_warning "Directory '$1' exists"; return 1; }
    return 0
}

_py_venv() {
    df_print_step "Creating virtual environment"
    "$PY_PYTHON" -m venv "$1/$PY_VENV"
    df_print_success "Created: $PY_VENV"
}

_py_gitignore() {
    cat > "$1/.gitignore" << 'EOF'
__pycache__/
*.py[cod]
*.so
build/
dist/
*.egg-info/
venv/
.venv/
.env
*.log
.pytest_cache/
.mypy_cache/
EOF
    df_print_success "Created .gitignore"
}

_py_git() {
    [[ "$PY_GIT_INIT" == "true" ]] && { cd "$1"; git init; git add .; git commit -m "Initial commit"; df_print_success "Git initialized"; }
}

_py_next() {
    echo ""
    df_print_section "Next steps"
    df_print_indent "cd $1"
    df_print_indent "source $PY_VENV/bin/activate"
}

py-new() {
    _py_check_name "$1" || return 1
    df_print_func_name "Python Project: $1"
    mkdir -p "$1"/{src,tests}
    touch "$1/src/__init__.py" "$1/tests/__init__.py"
    cat > "$1/src/main.py" << 'EOF'
#!/usr/bin/env python3
def main():
    print("Hello!")

if __name__ == "__main__":
    main()
EOF
    echo "# Dependencies" > "$1/requirements.txt"
    _py_venv "$1"; _py_gitignore "$1"; _py_git "$1"
    df_print_success "Created: $1"
    _py_next "$1"
}

py-flask() {
    _py_check_name "$1" || return 1
    df_print_func_name "Flask Project: $1"
    mkdir -p "$1"/{app/{templates,static},tests}
    _py_venv "$1"
    df_print_step "Installing Flask"
    "$1/$PY_VENV/bin/pip" install flask -q
    cat > "$1/app/__init__.py" << 'EOF'
from flask import Flask
def create_app():
    app = Flask(__name__)
    from app.routes import main
    app.register_blueprint(main)
    return app
EOF
    cat > "$1/app/routes.py" << 'EOF'
from flask import Blueprint, render_template
main = Blueprint('main', __name__)
@main.route('/')
def index():
    return render_template('index.html')
EOF
    echo '<!DOCTYPE html><html><body><h1>Flask</h1></body></html>' > "$1/app/templates/index.html"
    cat > "$1/app.py" << 'EOF'
#!/usr/bin/env python3
from app import create_app
app = create_app()
if __name__ == '__main__':
    app.run(debug=True)
EOF
    echo "Flask>=3.0.0" > "$1/requirements.txt"
    _py_gitignore "$1"; _py_git "$1"
    df_print_success "Created: $1"
    _py_next "$1"
}

py-fastapi() {
    _py_check_name "$1" || return 1
    df_print_func_name "FastAPI Project: $1"
    mkdir -p "$1"/{app,tests}
    _py_venv "$1"
    df_print_step "Installing FastAPI"
    "$1/$PY_VENV/bin/pip" install fastapi uvicorn -q
    cat > "$1/app/main.py" << 'EOF'
from fastapi import FastAPI
app = FastAPI()
@app.get("/")
def root():
    return {"message": "Hello"}
@app.get("/health")
def health():
    return {"status": "ok"}
EOF
    cat > "$1/run.py" << 'EOF'
#!/usr/bin/env python3
import uvicorn
if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
EOF
    echo -e "fastapi>=0.104.0\nuvicorn>=0.24.0" > "$1/requirements.txt"
    _py_gitignore "$1"; _py_git "$1"
    df_print_success "Created: $1"
    df_print_info "Docs: http://localhost:8000/docs"
    _py_next "$1"
}

py-cli() {
    _py_check_name "$1" || return 1
    df_print_func_name "CLI Project: $1"
    mkdir -p "$1"/{src/$1,tests}
    _py_venv "$1"
    df_print_step "Installing click"
    "$1/$PY_VENV/bin/pip" install click -q
    echo '__version__ = "0.1.0"' > "$1/src/$1/__init__.py"
    cat > "$1/src/$1/cli.py" << 'EOF'
#!/usr/bin/env python3
import click
@click.group()
@click.version_option()
def cli():
    pass
@cli.command()
@click.argument('name', default='World')
def greet(name):
    click.echo(f"Hello, {name}!")
if __name__ == '__main__':
    cli()
EOF
    echo "click>=8.1.0" > "$1/requirements.txt"
    _py_gitignore "$1"; _py_git "$1"
    df_print_success "Created: $1"
    df_print_info "Install: pip install -e $1"
    _py_next "$1"
}

venv() {
    [[ -d "venv" ]] && source venv/bin/activate && return
    [[ -d ".venv" ]] && source .venv/bin/activate && return
    df_print_error "No venv found"
}

alias pynew='py-new' pyflask='py-flask' pyfast='py-fastapi' pycli='py-cli'
