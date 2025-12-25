# ============================================================================
# Tmuxinator Integration for Dotfiles
# ============================================================================
# Extends tmux-workspaces with tmuxinator support for more powerful
# project configurations with per-pane commands, environment variables,
# and complex layouts.
#
# Features:
#   - Seamless integration with existing tw-* commands
#   - Auto-detection: uses tmuxinator if project exists, falls back to templates
#   - Project scaffolding with sensible defaults
#   - Import/export between tmuxinator and simple templates
#
# Requirements:
#   - tmuxinator (gem install tmuxinator or pacman -S tmuxinator)
#   - tmux
# ============================================================================

source "${0:A:h}/../lib/bootstrap.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/bootstrap.zsh" 2>/dev/null

# ============================================================================
# Configuration
# ============================================================================

typeset -g TMUXINATOR_CONFIG_DIR="${TMUXINATOR_CONFIG_DIR:-$HOME/.config/tmuxinator}"
typeset -g TMUXINATOR_ENABLED="${TMUXINATOR_ENABLED:-auto}"  # auto, true, false

# ============================================================================
# Detection & Initialization
# ============================================================================

_txi_check() {
    [[ "$TMUXINATOR_ENABLED" == "false" ]] && return 1
    df_require_cmd tmuxinator "tmuxinator (gem install tmuxinator)" 2>/dev/null || return 1
    return 0
}

_txi_init() {
    df_ensure_dir "$TMUXINATOR_CONFIG_DIR"
}

_txi_project_exists() {
    local name="$1"
    [[ -f "$TMUXINATOR_CONFIG_DIR/${name}.yml" ]]
}

# ============================================================================
# Project Management
# ============================================================================

# Create a new tmuxinator project
# Usage: txi-new <name> [template]
txi-new() {
    local name="$1"
    local template="${2:-dev}"
    
    [[ -z "$name" ]] && { echo "Usage: txi-new <name> [template]"; return 1; }
    _txi_check || return 1
    _txi_init
    
    if _txi_project_exists "$name"; then
        df_print_warning "Project '$name' already exists"
        df_confirm "Overwrite?" || return 1
    fi
    
    df_print_func_name "New Tmuxinator Project: ${name}"
    
    local project_file="$TMUXINATOR_CONFIG_DIR/${name}.yml"
    
    case "$template" in
        dev)
            _txi_template_dev "$name" > "$project_file"
            ;;
        ops)
            _txi_template_ops "$name" > "$project_file"
            ;;
        web)
            _txi_template_web "$name" > "$project_file"
            ;;
        data)
            _txi_template_data "$name" > "$project_file"
            ;;
        minimal)
            _txi_template_minimal "$name" > "$project_file"
            ;;
        *)
            df_print_warning "Unknown template: $template"
            df_print_info "Available: dev, ops, web, data, minimal"
            _txi_template_dev "$name" > "$project_file"
            ;;
    esac
    
    df_print_success "Created: $project_file"
    df_print_info "Edit with: txi-edit $name"
    df_print_info "Start with: txi $name"
}

# Edit a tmuxinator project
# Usage: txi-edit <name>
txi-edit() {
    local name="$1"
    [[ -z "$name" ]] && { txi-list; return 1; }
    _txi_check || return 1
    
    local project_file="$TMUXINATOR_CONFIG_DIR/${name}.yml"
    
    if [[ ! -f "$project_file" ]]; then
        df_print_error "Project not found: $name"
        df_confirm "Create it?" && txi-new "$name" || return 1
    fi
    
    ${EDITOR:-vim} "$project_file"
}

# List tmuxinator projects
txi-list() {
    _txi_check || return 1
    _txi_init
    
    df_print_func_name "Tmuxinator Projects"
    
    local found=false
    for project in "$TMUXINATOR_CONFIG_DIR"/*.yml(N); do
        [[ -f "$project" ]] || continue
        found=true
        local name=$(basename "$project" .yml)
        local root=$(grep -m1 "^root:" "$project" 2>/dev/null | sed 's/root:[[:space:]]*//')
        df_print_indent "● $name"
        [[ -n "$root" && "$root" != "~" ]] && df_print_indent "  └─ $root"
    done
    
    [[ "$found" != true ]] && df_print_info "No projects. Create with: txi-new <name>"
}

# Delete a tmuxinator project
# Usage: txi-delete <name>
txi-delete() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: txi-delete <name>"; return 1; }
    _txi_check || return 1
    
    local project_file="$TMUXINATOR_CONFIG_DIR/${name}.yml"
    
    if [[ ! -f "$project_file" ]]; then
        df_print_error "Project not found: $name"
        return 1
    fi
    
    df_confirm "Delete project '$name'?" || return 1
    rm "$project_file"
    df_print_success "Deleted: $name"
}

# Start/attach to a tmuxinator project
# Usage: txi <name>
txi() {
    local name="$1"
    [[ -z "$name" ]] && { txi-list; return 1; }
    _txi_check || return 1
    
    if ! _txi_project_exists "$name"; then
        df_print_error "Project not found: $name"
        df_print_info "Create with: txi-new $name"
        return 1
    fi
    
    # Check if session already exists
    if tmux has-session -t "$name" 2>/dev/null; then
        df_print_info "Attaching to existing session: $name"
        if [[ -z "$TMUX" ]]; then
            tmux attach -t "$name"
        else
            tmux switch-client -t "$name"
        fi
    else
        df_print_step "Starting project: $name"
        tmuxinator start "$name"
    fi
}

# Stop a tmuxinator session
# Usage: txi-stop <name>
txi-stop() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: txi-stop <name>"; return 1; }
    _txi_check || return 1
    
    tmuxinator stop "$name" 2>/dev/null && df_print_success "Stopped: $name" || df_print_error "Session not running: $name"
}

# Fuzzy search and start project
txif() {
    _txi_check || return 1
    df_require_cmd fzf || return 1
    _txi_init
    
    local projects=()
    for project in "$TMUXINATOR_CONFIG_DIR"/*.yml(N); do
        [[ -f "$project" ]] && projects+=("$(basename "$project" .yml)")
    done
    
    [[ ${#projects[@]} -eq 0 ]] && { df_print_info "No projects"; return 1; }
    
    local sel=$(printf '%s\n' "${projects[@]}" | fzf $(df_fzf_opts) --prompt='Tmuxinator > ')
    [[ -n "$sel" ]] && txi "$sel"
}

# ============================================================================
# Template Generators
# ============================================================================

_txi_template_dev() {
    local name="$1"
    cat << EOF
# ${name} - Development Workspace
name: ${name}
root: ~/projects/${name}

# Optional: pre-commands before windows are created
# pre_window: nvm use default

windows:
  - editor:
      layout: main-vertical
      panes:
        - # Editor pane - opens vim/nvim
        - # Terminal pane
        
  - server:
      panes:
        - # Server/dev server pane
        
  - logs:
      panes:
        - # Log watching pane
        - # Additional monitoring
EOF
}

_txi_template_ops() {
    local name="$1"
    cat << EOF
# ${name} - Operations/Monitoring Workspace
name: ${name}
root: ~

windows:
  - monitoring:
      layout: tiled
      panes:
        - htop
        - # System logs
        - # Network monitoring
        - # Disk usage
        
  - services:
      layout: even-horizontal
      panes:
        - # Service management
        - # Container management
        
  - ssh:
      layout: tiled
      panes:
        - # SSH session 1
        - # SSH session 2
        - # SSH session 3
        - # SSH session 4
EOF
}

_txi_template_web() {
    local name="$1"
    cat << EOF
# ${name} - Web Development Workspace
name: ${name}
root: ~/projects/${name}

# Uncomment and adjust for your stack
# pre_window: nvm use 18

windows:
  - editor:
      layout: main-vertical
      panes:
        - # \${EDITOR:-vim} .
        - # Terminal
        
  - server:
      panes:
        - # npm run dev  # or: python manage.py runserver
        
  - frontend:
      layout: even-horizontal
      panes:
        - # npm run watch
        - # Browser sync / tailwind watch
        
  - database:
      panes:
        - # Database client or psql/mysql
        
  - git:
      panes:
        - # Git operations
EOF
}

_txi_template_data() {
    local name="$1"
    cat << EOF
# ${name} - Data Science Workspace
name: ${name}
root: ~/projects/${name}

# Uncomment to activate conda/venv
# pre_window: source venv/bin/activate

windows:
  - jupyter:
      panes:
        - # jupyter lab
        
  - code:
      layout: main-vertical
      panes:
        - # Editor
        - # Python REPL: python or ipython
        
  - data:
      panes:
        - # Data exploration / file management
        
  - terminal:
      panes:
        - # General terminal
EOF
}

_txi_template_minimal() {
    local name="$1"
    cat << EOF
# ${name} - Minimal Workspace
name: ${name}
root: ~

windows:
  - main:
      panes:
        - # Main pane
EOF
}

# ============================================================================
# Integration with tw-* Commands
# ============================================================================

# Enhanced tw function that checks tmuxinator first
_txi_tw_enhanced() {
    local name="$1"
    local template="${2:-}"
    
    [[ -z "$name" ]] && {
        # List both tw workspaces and tmuxinator projects
        tw-list 2>/dev/null
        echo ""
        txi-list 2>/dev/null
        return
    }
    
    # Check if tmuxinator project exists
    if _txi_check 2>/dev/null && _txi_project_exists "$name"; then
        txi "$name"
        return
    fi
    
    # Fall back to tw
    tw "$name" "$template"
}

# ============================================================================
# Import/Export
# ============================================================================

# Import a simple .tmux template to tmuxinator format
# Usage: txi-import <template-name> [new-project-name]
txi-import() {
    local tmpl_name="$1"
    local project_name="${2:-$tmpl_name}"
    
    [[ -z "$tmpl_name" ]] && { echo "Usage: txi-import <template-name> [project-name]"; return 1; }
    _txi_check || return 1
    
    local tmpl_file="${TW_TEMPLATES:-$HOME/.dotfiles/.tmux-templates}/${tmpl_name}.tmux"
    
    if [[ ! -f "$tmpl_file" ]]; then
        df_print_error "Template not found: $tmpl_name"
        return 1
    fi
    
    df_print_func_name "Import Template: ${tmpl_name}"
    
    _txi_init
    local project_file="$TMUXINATOR_CONFIG_DIR/${project_name}.yml"
    
    if _txi_project_exists "$project_name"; then
        df_confirm "Overwrite existing project '$project_name'?" || return 1
    fi
    
    # Parse the simple template and convert to tmuxinator format
    local pane_count=0
    local panes=""
    
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        
        if [[ "$line" =~ split-window ]]; then
            ((pane_count++))
        fi
    done < "$tmpl_file"
    
    # Generate panes list
    panes="        - # Pane 1"
    for ((i=1; i<=pane_count; i++)); do
        panes+="\n        - # Pane $((i+1))"
    done
    
    # Create the project file
    cat > "$project_file" << EOF
# Imported from template: ${tmpl_name}
name: ${project_name}
root: ~

windows:
  - main:
      layout: tiled
      panes:
$(echo -e "$panes")
EOF

    df_print_success "Imported: $project_file"
    df_print_info "Edit to customize: txi-edit $project_name"
}

# ============================================================================
# Available Templates
# ============================================================================

txi-templates() {
    df_print_func_name "Tmuxinator Templates"
    echo ""
    df_print_indent "dev      Development (editor + terminal + server + logs)"
    df_print_indent "ops      Operations (monitoring + services + SSH grid)"
    df_print_indent "web      Web development (editor + server + frontend + db)"
    df_print_indent "data     Data science (jupyter + code + data + terminal)"
    df_print_indent "minimal  Single window, single pane"
    echo ""
    df_print_info "Usage: txi-new myproject dev"
}

# ============================================================================
# Help
# ============================================================================

txi-help() {
    df_print_func_name "Tmuxinator Commands"
    cat << 'EOF'

  Project Management:
    txi <name>           Start/attach to project
    txi-new <n> [tmpl]   Create new project (templates: dev, ops, web, data, minimal)
    txi-edit <name>      Edit project configuration
    txi-list             List all projects
    txi-delete <name>    Delete project
    txi-stop <name>      Stop running session
    txif                 Fuzzy search and start

  Templates:
    txi-templates        Show available templates
    txi-import <t> [n]   Import simple .tmux template to tmuxinator

  Configuration:
    Projects stored in: ~/.config/tmuxinator/

  Integration:
    Tmuxinator projects are automatically detected by tw commands.
    If a tmuxinator project exists with the same name, it takes precedence.

EOF
}

# ============================================================================
# Aliases
# ============================================================================

alias txil='txi-list'
alias txin='txi-new'
alias txie='txi-edit'
alias txid='txi-delete'
alias txis='txi-stop'
alias txit='txi-templates'
alias txih='txi-help'

# ============================================================================
# Initialize
# ============================================================================

_txi_init
