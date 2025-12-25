# ============================================================================
# Tmux Workspace Manager - Project Templates & Layouts
# ============================================================================
# Quick project workspace setup with pre-configured tmux layouts
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

typeset -g TW_TEMPLATES_DIR="${TW_TEMPLATES_DIR:-$HOME/.dotfiles/.tmux-templates}"
typeset -g TW_SESSION_PREFIX="${TW_SESSION_PREFIX:-work}"
typeset -g TW_DEFAULT_TEMPLATE="${TW_DEFAULT_TEMPLATE:-dev}"

# ============================================================================
# Helper Functions
# ============================================================================

_tw_print_step() { echo -e "${DF_BLUE}==>${DF_NC} $1"; }
_tw_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
_tw_print_error() { echo -e "${DF_RED}✗${DF_NC} $1"; }
_tw_print_info() { echo -e "${DF_CYAN}ℹ${DF_NC} $1"; }

_tw_check_tmux() {
    if ! command -v tmux &>/dev/null; then
        _tw_print_error "tmux not installed"
        return 1
    fi
    return 0
}

_tw_init_templates() {
    mkdir -p "$TW_TEMPLATES_DIR"
    [[ ! -f "$TW_TEMPLATES_DIR/dev.tmux" ]] && _tw_create_default_templates
}

# ============================================================================
# Default Template Definitions
# ============================================================================

_tw_create_default_templates() {
    _tw_print_step "Creating default templates..."
    
    cat > "$TW_TEMPLATES_DIR/dev.tmux" << 'EOF'
# Development workspace
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
EOF
    
    cat > "$TW_TEMPLATES_DIR/ops.tmux" << 'EOF'
# Operations workspace - 4 panes
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50
select-pane -t 0
EOF
    
    cat > "$TW_TEMPLATES_DIR/ssh-multi.tmux" << 'EOF'
# Multi-server SSH workspace
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50
select-pane -t 0
EOF
    
    cat > "$TW_TEMPLATES_DIR/debug.tmux" << 'EOF'
# Debug workspace
split-window -h -p 30
select-pane -t 0
EOF
    
    cat > "$TW_TEMPLATES_DIR/full.tmux" << 'EOF'
# Full workspace - single pane
EOF
    
    cat > "$TW_TEMPLATES_DIR/review.tmux" << 'EOF'
# Code Review workspace
split-window -h -p 50
select-pane -t 0
EOF
    
    _tw_print_success "Created default templates in: $TW_TEMPLATES_DIR"
}

# ============================================================================
# Template Management
# ============================================================================

tw-templates() {
    _tw_init_templates
    
    df_print_func_name "Available Tmux Templates"
    
    for template in "$TW_TEMPLATES_DIR"/*.tmux; do
        [[ ! -f "$template" ]] && continue
        local name=$(basename "$template" .tmux)
        local description=$(grep "^#" "$template" | head -2 | tail -1 | sed 's/^# *//')
        echo -e "${DF_GREEN}●${DF_NC} ${DF_CYAN}$name${DF_NC}"
        [[ -n "$description" ]] && echo "  $description"
    done
    
    echo
    echo "Create workspace: ${DF_CYAN}tw-create myproject dev${DF_NC}"
    echo "Quick attach:     ${DF_CYAN}tw myproject${DF_NC}"
}

tw-template-edit() {
    local template_name="$1"
    [[ -z "$template_name" ]] && { echo "Usage: tw-template-edit <template_name>"; tw-templates; return 1; }
    _tw_init_templates
    ${EDITOR:-vim} "$TW_TEMPLATES_DIR/${template_name}.tmux"
    _tw_print_success "Template edited: $template_name"
}

# ============================================================================
# Workspace Management
# ============================================================================

tw-create() {
    local workspace_name="$1"
    local template="${2:-$TW_DEFAULT_TEMPLATE}"
    
    [[ -z "$workspace_name" ]] && { echo "Usage: tw-create <workspace_name> [template]"; tw-templates; return 1; }
    
    _tw_check_tmux || return 1
    _tw_init_templates
    
    local session_name="${TW_SESSION_PREFIX}-${workspace_name}"
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        _tw_print_error "Workspace '$workspace_name' already exists"
        echo "Use: ${DF_CYAN}tw $workspace_name${DF_NC} to attach"
        return 1
    fi
    
    local template_file="$TW_TEMPLATES_DIR/${template}.tmux"
    if [[ ! -f "$template_file" ]]; then
        _tw_print_error "Template '$template' not found"
        tw-templates
        return 1
    fi
    
    _tw_print_step "Creating workspace: $workspace_name (template: $template)"
    
    tmux new-session -d -s "$session_name"
    _tw_print_step "Applying template: $template"
    tmux source-file "$template_file" -t "$session_name"
    
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        local git_root=$(git rev-parse --show-toplevel)
        _tw_print_info "Setting workspace directory to: $git_root"
        tmux send-keys -t "$session_name:0" "cd $git_root" C-m
    fi
    
    _tw_print_success "Workspace created: $workspace_name"
    
    if [[ -z "$TMUX" ]]; then
        _tw_print_step "Attaching to workspace..."
        tmux attach-session -t "$session_name"
    else
        _tw_print_info "Switch with: ${DF_CYAN}tmux switch-client -t $session_name${DF_NC}"
    fi
}

tw-attach() {
    local workspace_name="$1"
    [[ -z "$workspace_name" ]] && { echo "Usage: tw-attach <workspace_name>"; tw-list; return 1; }
    
    _tw_check_tmux || return 1
    
    local session_name="${TW_SESSION_PREFIX}-${workspace_name}"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        _tw_print_error "Workspace '$workspace_name' not found"
        echo "Create it with: ${DF_CYAN}tw-create $workspace_name${DF_NC}"
        return 1
    fi
    
    if [[ -z "$TMUX" ]]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

tw-list() {
    _tw_check_tmux || return 1
    
    df_print_func_name "Active Tmux Workspaces"
    
    local has_workspaces=false
    
    tmux list-sessions 2>/dev/null | while IFS=: read -r session_full rest; do
        if [[ "$session_full" == ${TW_SESSION_PREFIX}-* ]]; then
            has_workspaces=true
            local workspace_name="${session_full#${TW_SESSION_PREFIX}-}"
            local attached=""
            
            if [[ -n "$TMUX" ]]; then
                local current_session=$(tmux display-message -p '#S')
                [[ "$current_session" == "$session_full" ]] && attached=" ${DF_GREEN}(current)${DF_NC}"
            fi
            
            echo -e "${DF_GREEN}●${DF_NC} ${DF_CYAN}$workspace_name${DF_NC}$attached"
            echo "  Session: $session_full"
        fi
    done
    
    if [[ "$has_workspaces" != true ]]; then
        _tw_print_info "No active workspaces"
        echo "Create one with: ${DF_CYAN}tw-create myproject${DF_NC}"
    fi
}

tw-delete() {
    local workspace_name="$1"
    [[ -z "$workspace_name" ]] && { echo "Usage: tw-delete <workspace_name>"; tw-list; return 1; }
    
    _tw_check_tmux || return 1
    
    local session_name="${TW_SESSION_PREFIX}-${workspace_name}"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        _tw_print_error "Workspace '$workspace_name' not found"
        return 1
    fi
    
    tmux kill-session -t "$session_name"
    _tw_print_success "Deleted workspace: $workspace_name"
}

tw-save() {
    local template_name="$1"
    [[ -z "$template_name" ]] && { echo "Usage: tw-save <template_name>"; return 1; }
    
    _tw_check_tmux || return 1
    [[ -z "$TMUX" ]] && { _tw_print_error "Must be run from inside tmux"; return 1; }
    
    _tw_init_templates
    
    local template_file="$TW_TEMPLATES_DIR/${template_name}.tmux"
    [[ -f "$template_file" ]] && {
        read -q "REPLY?Template '$template_name' exists. Overwrite? [y/N]: "
        echo
        [[ ! "$REPLY" =~ ^[Yy]$ ]] && return 1
    }
    
    _tw_print_step "Saving current layout as template: $template_name"
    local pane_count=$(tmux display-message -p '#{window_panes}')
    
    cat > "$template_file" << EOF
# Custom template: $template_name
# Saved: $(date)
# Panes: $pane_count
EOF
    
    if (( pane_count == 2 )); then
        echo "split-window -h -p 50" >> "$template_file"
    elif (( pane_count == 3 )); then
        echo "split-window -h -p 50" >> "$template_file"
        echo "split-window -v -p 50" >> "$template_file"
    elif (( pane_count == 4 )); then
        echo "split-window -h -p 50" >> "$template_file"
        echo "split-window -v -p 50" >> "$template_file"
        echo "select-pane -t 0" >> "$template_file"
        echo "split-window -v -p 50" >> "$template_file"
    fi
    
    echo "" >> "$template_file"
    echo "select-pane -t 0" >> "$template_file"
    
    _tw_print_success "Template saved: $template_name"
    echo "  File: $template_file"
    echo "  Edit: ${DF_CYAN}tw-template-edit $template_name${DF_NC}"
}

tw() {
    local workspace_name="$1"
    local template="${2:-$TW_DEFAULT_TEMPLATE}"
    
    [[ -z "$workspace_name" ]] && { tw-list; return 0; }
    
    _tw_check_tmux || return 1
    
    local session_name="${TW_SESSION_PREFIX}-${workspace_name}"
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        tw-attach "$workspace_name"
    else
        _tw_print_info "Workspace doesn't exist. Creating with template: $template"
        tw-create "$workspace_name" "$template"
    fi
}

twf() {
    if ! command -v fzf &>/dev/null; then
        _tw_print_error "fzf not installed"
        return 1
    fi
    
    _tw_check_tmux || return 1
    
    local sessions=()
    tmux list-sessions 2>/dev/null | while IFS=: read -r session_full rest; do
        if [[ "$session_full" == ${TW_SESSION_PREFIX}-* ]]; then
            local workspace_name="${session_full#${TW_SESSION_PREFIX}-}"
            sessions+=("$workspace_name")
        fi
    done
    
    [[ ${#sessions[@]} -eq 0 ]] && { _tw_print_info "No workspaces found"; return 1; }
    
    local selection=$(printf '%s\n' "${sessions[@]}" | \
        fzf --height=40% --layout=reverse --border=rounded --prompt='Workspace > ')
    
    [[ -n "$selection" ]] && tw-attach "$selection"
}

tw-sync() {
    [[ -z "$TMUX" ]] && { _tw_print_error "Must be run from inside tmux"; return 1; }
    
    local current=$(tmux show-window-option -v synchronize-panes 2>/dev/null)
    
    if [[ "$current" == "on" ]]; then
        tmux set-window-option synchronize-panes off
        _tw_print_info "Pane synchronization: ${DF_RED}OFF${DF_NC}"
    else
        tmux set-window-option synchronize-panes on
        _tw_print_info "Pane synchronization: ${DF_GREEN}ON${DF_NC}"
    fi
}

tw-rename() {
    local old_name="$1"
    local new_name="$2"
    
    [[ -z "$old_name" || -z "$new_name" ]] && { echo "Usage: tw-rename <old_name> <new_name>"; return 1; }
    
    _tw_check_tmux || return 1
    
    local old_session="${TW_SESSION_PREFIX}-${old_name}"
    local new_session="${TW_SESSION_PREFIX}-${new_name}"
    
    if ! tmux has-session -t "$old_session" 2>/dev/null; then
        _tw_print_error "Workspace '$old_name' not found"
        return 1
    fi
    
    tmux rename-session -t "$old_session" "$new_session"
    _tw_print_success "Renamed: $old_name → $new_name"
}

# ============================================================================
# Aliases
# ============================================================================

alias twl='tw-list'
alias twc='tw-create'
alias twa='tw-attach'
alias twd='tw-delete'
alias tws='tw-save'
alias twt='tw-templates'
alias twe='tw-template-edit'

# ============================================================================
# Initialization
# ============================================================================

_tw_init_templates
