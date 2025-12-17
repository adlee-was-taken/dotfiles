# ============================================================================
# Tmux Workspace Manager - Project Templates & Layouts
# ============================================================================
# Quick project workspace setup with pre-configured tmux layouts
#
# Usage:
#   tw-create <name> [template]   # Create workspace from template
#   tw-attach <name>                 # Attach to workspace
#   tw-list                          # List all workspaces
#   tw-delete <name>                 # Delete workspace
#   tw-save <name>                   # Save current layout as template
#   tw <name>                        # Quick attach (or create if not exists)
#
# Templates:
#   dev        - Vim (50%) + terminal (25%) + logs (25%)
#   ops        - 4 panes: htop, logs, shell, monitoring
#   ssh-multi  - 4 panes for managing multiple servers
#   debug      - 2 panes: main (70%) + helper (30%)
#   full       - Just one full pane
#
# Add to .zshrc:
#   source ~/.dotfiles/zsh/functions/tmux-workspaces.zsh
# ============================================================================

# ============================================================================
# Configuration
# ============================================================================

typeset -g TW_TEMPLATES_DIR="${TW_TEMPLATES_DIR:-$HOME/.dotfiles/.tmux-templates}"
typeset -g TW_SESSION_PREFIX="${TW_SESSION_PREFIX:-work}"
typeset -g TW_DEFAULT_TEMPLATE="${TW_DEFAULT_TEMPLATE:-dev}"

# Colors
typeset -g TW_GREEN=$'\033[0;32m'
typeset -g TW_BLUE=$'\033[0;34m'
typeset -g TW_YELLOW=$'\033[1;33m'
typeset -g TW_CYAN=$'\033[0;36m'
typeset -g TW_RED=$'\033[0;31m'
typeset -g TW_NC=$'\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

_tw_print_step() {
    echo -e "${TW_BLUE}==>${TW_NC} $1"
}

_tw_print_success() {
    echo -e "${TW_GREEN}✓${TW_NC} $1"
}

_tw_print_error() {
    echo -e "${TW_RED}✗${TW_NC} $1"
}

_tw_print_info() {
    echo -e "${TW_CYAN}ℹ${TW_NC} $1"
}

_tw_check_tmux() {
    if ! command -v tmux &>/dev/null; then
        _tw_print_error "tmux not installed"
        return 1
    fi
    return 0
}

_tw_init_templates() {
    mkdir -p "$TW_TEMPLATES_DIR"
    
    # Create default templates if they don't exist
    if [[ ! -f "$TW_TEMPLATES_DIR/dev.tmux" ]]; then
        _tw_create_default_templates
    fi
}

# ============================================================================
# Default Template Definitions
# ============================================================================

_tw_create_default_templates() {
    _tw_print_step "Creating default templates..."
    
    # Development template - vim + terminal + logs
    cat > "$TW_TEMPLATES_DIR/dev.tmux" << 'EOF'
# Development workspace
# Usage: tw-create myproject dev

# Split vertically (vim on left 50%, rest on right)
split-window -h -p 50

# Split right pane horizontally (terminal top, logs bottom)
split-window -v -p 50

# Select the first pane (vim)
select-pane -t 0

# Optional: Start vim in first pane
# send-keys -t 0 'vim' C-m

# Optional: Set pane titles
# select-pane -t 0 -T "Editor"
# select-pane -t 1 -T "Terminal"
# select-pane -t 2 -T "Logs"
EOF
    
    # Operations template - 4 panes for monitoring
    cat > "$TW_TEMPLATES_DIR/ops.tmux" << 'EOF'
# Operations workspace
# 4-pane layout for system monitoring

# Create 2x2 grid
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50

# Optional: Auto-start monitoring tools
# send-keys -t 0 'htop' C-m
# send-keys -t 1 'docker ps' C-m
# send-keys -t 2 '' C-m
# send-keys -t 3 'tail -f /var/log/syslog' C-m

select-pane -t 0
EOF
    
    # SSH multi-server template
    cat > "$TW_TEMPLATES_DIR/ssh-multi.tmux" << 'EOF'
# Multi-server SSH workspace
# 4 panes for managing multiple servers

# Create 2x2 grid
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50

# Enable pane synchronization (optional - uncomment to enable)
# set-window-option synchronize-panes on

select-pane -t 0
EOF
    
    # Debug template - main + helper pane
    cat > "$TW_TEMPLATES_DIR/debug.tmux" << 'EOF'
# Debug workspace
# Main pane (70%) + helper pane (30%)

split-window -h -p 30

select-pane -t 0
EOF
    
    # Full template - single pane
    cat > "$TW_TEMPLATES_DIR/full.tmux" << 'EOF'
# Full workspace
# Single full-screen pane (default tmux behavior)
EOF
    
    # Code review template - side-by-side comparison
    cat > "$TW_TEMPLATES_DIR/review.tmux" << 'EOF'
# Code Review workspace
# Two equal panes side-by-side for comparison

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
    
    echo -e "${TW_BLUE}╔════════════════════════════════════════════════════════════╗${TW_NC}"
    echo -e "${TW_BLUE}║${TW_NC}  Available Tmux Templates                                  ${TW_BLUE}║${TW_NC}"
    echo -e "${TW_BLUE}╚════════════════════════════════════════════════════════════╝${TW_NC}"
    echo
    
    for template in "$TW_TEMPLATES_DIR"/*.tmux; do
        [[ ! -f "$template" ]] && continue
        
        local name=$(basename "$template" .tmux)
        local description=$(grep "^#" "$template" | head -2 | tail -1 | sed 's/^# *//')
        
        echo -e "${TW_GREEN}●${TW_NC} ${TW_CYAN}$name${TW_NC}"
        [[ -n "$description" ]] && echo "  $description"
    done
    
    echo
    echo "Create workspace: ${TW_CYAN}tw-create myproject dev${TW_NC}"
    echo "Quick attach:     ${TW_CYAN}tw myproject${TW_NC}"
}

tw-template-edit() {
    local template_name="$1"
    
    if [[ -z "$template_name" ]]; then
        echo "Usage: tw-template-edit <template_name>"
        echo
        tw-templates
        return 1
    fi
    
    _tw_init_templates
    
    local template_file="$TW_TEMPLATES_DIR/${template_name}.tmux"
    
    ${EDITOR:-vim} "$template_file"
    
    _tw_print_success "Template edited: $template_name"
}

# ============================================================================
# Workspace Management
# ============================================================================

tw-create() {
    local workspace_name="$1"
    local template="${2:-$TW_DEFAULT_TEMPLATE}"
    
    if [[ -z "$workspace_name" ]]; then
        echo "Usage: tw-create <workspace_name> [template]"
        echo
        tw-templates
        return 1
    fi
    
    _tw_check_tmux || return 1
    _tw_init_templates
    
    local session_name="${TW_SESSION_PREFIX}-${workspace_name}"
    
    # Check if session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        _tw_print_error "Workspace '$workspace_name' already exists"
        echo "Use: ${TW_CYAN}tw $workspace_name${TW_NC} to attach"
        return 1
    fi
    
    # Check if template exists
    local template_file="$TW_TEMPLATES_DIR/${template}.tmux"
    if [[ ! -f "$template_file" ]]; then
        _tw_print_error "Template '$template' not found"
        tw-templates
        return 1
    fi
    
    _tw_print_step "Creating workspace: $workspace_name (template: $template)"
    
    # Create new tmux session (detached)
    tmux new-session -d -s "$session_name"
    
    # Apply template
    _tw_print_step "Applying template: $template"
    tmux source-file "$template_file" -t "$session_name"
    
    # Set working directory if we're in a git repo or specific directory
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        local git_root=$(git rev-parse --show-toplevel)
        _tw_print_info "Setting workspace directory to: $git_root"
        tmux send-keys -t "$session_name:0" "cd $git_root" C-m
    fi
    
    _tw_print_success "Workspace created: $workspace_name"
    
    # Attach if not already in tmux
    if [[ -z "$TMUX" ]]; then
        _tw_print_step "Attaching to workspace..."
        tmux attach-session -t "$session_name"
    else
        _tw_print_info "Switch with: ${TW_CYAN}tmux switch-client -t $session_name${TW_NC}"
    fi
}

tw-attach() {
    local workspace_name="$1"
    
    if [[ -z "$workspace_name" ]]; then
        echo "Usage: tw-attach <workspace_name>"
        echo
        tw-list
        return 1
    fi
    
    _tw_check_tmux || return 1
    
    local session_name="${TW_SESSION_PREFIX}-${workspace_name}"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        _tw_print_error "Workspace '$workspace_name' not found"
        echo
        echo "Create it with: ${TW_CYAN}tw-create $workspace_name${TW_NC}"
        return 1
    fi
    
    # Attach or switch
    if [[ -z "$TMUX" ]]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

tw-list() {
    _tw_check_tmux || return 1
    
    echo -e "${TW_BLUE}╔════════════════════════════════════════════════════════════╗${TW_NC}"
    echo -e "${TW_BLUE}║${TW_NC}  Active Tmux Workspaces                                    ${TW_BLUE}║${TW_NC}"
    echo -e "${TW_BLUE}╚════════════════════════════════════════════════════════════╝${TW_NC}"
    echo
    
    local has_workspaces=false
    
    # List all tmux sessions
    tmux list-sessions 2>/dev/null | while IFS=: read -r session_full rest; do
        # Only show sessions with our prefix
        if [[ "$session_full" == ${TW_SESSION_PREFIX}-* ]]; then
            has_workspaces=true
            local workspace_name="${session_full#${TW_SESSION_PREFIX}-}"
            local attached=""
            
            # Check if currently attached
            if [[ -n "$TMUX" ]]; then
                local current_session=$(tmux display-message -p '#S')
                [[ "$current_session" == "$session_full" ]] && attached=" ${TW_GREEN}(current)${TW_NC}"
            fi
            
            echo -e "${TW_GREEN}●${TW_NC} ${TW_CYAN}$workspace_name${TW_NC}$attached"
            echo "  Session: $session_full"
        fi
    done
    
    if [[ "$has_workspaces" != true ]]; then
        _tw_print_info "No active workspaces"
        echo
        echo "Create one with: ${TW_CYAN}tw-create myproject${TW_NC}"
    fi
}

tw-delete() {
    local workspace_name="$1"
    
    if [[ -z "$workspace_name" ]]; then
        echo "Usage: tw-delete <workspace_name>"
        echo
        tw-list
        return 1
    fi
    
    _tw_check_tmux || return 1
    
    local session_name="${TW_SESSION_PREFIX}-${workspace_name}"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        _tw_print_error "Workspace '$workspace_name' not found"
        return 1
    fi
    
    # Kill session
    tmux kill-session -t "$session_name"
    
    _tw_print_success "Deleted workspace: $workspace_name"
}

# ============================================================================
# Save Current Layout as Template
# ============================================================================

tw-save() {
    local template_name="$1"
    
    if [[ -z "$template_name" ]]; then
        echo "Usage: tw-save <template_name>"
        echo
        echo "Saves the current tmux window layout as a reusable template"
        return 1
    fi
    
    _tw_check_tmux || return 1
    
    if [[ -z "$TMUX" ]]; then
        _tw_print_error "Must be run from inside tmux"
        return 1
    fi
    
    _tw_init_templates
    
    local template_file="$TW_TEMPLATES_DIR/${template_name}.tmux"
    
    if [[ -f "$template_file" ]]; then
        read -q "REPLY?Template '$template_name' exists. Overwrite? [y/N]: "
        echo
        [[ ! "$REPLY" =~ ^[Yy]$ ]] && return 1
    fi
    
    _tw_print_step "Saving current layout as template: $template_name"
    
    # Get current window layout
    local layout=$(tmux display-message -p '#{window_layout}')
    local pane_count=$(tmux display-message -p '#{window_panes}')
    
    # Create template with layout commands
    cat > "$template_file" << EOF
# Custom template: $template_name
# Saved: $(date)
# Panes: $pane_count

# Note: This is a simplified layout recreation
# You may need to adjust split percentages and commands

EOF
    
    # Generate split commands based on pane count
    if (( pane_count == 2 )); then
        echo "split-window -h -p 50" >> "$template_file"
    elif (( pane_count == 3 )); then
        cat >> "$template_file" << 'EOF'
split-window -h -p 50
split-window -v -p 50
EOF
    elif (( pane_count == 4 )); then
        cat >> "$template_file" << 'EOF'
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50
EOF
    fi
    
    echo "" >> "$template_file"
    echo "select-pane -t 0" >> "$template_file"
    
    _tw_print_success "Template saved: $template_name"
    echo "  File: $template_file"
    echo "  Edit: ${TW_CYAN}tw-template-edit $template_name${TW_NC}"
}

# ============================================================================
# Quick Workspace (attach or create)
# ============================================================================

tw() {
    local workspace_name="$1"
    local template="${2:-$TW_DEFAULT_TEMPLATE}"
    
    if [[ -z "$workspace_name" ]]; then
        tw-list
        return 0
    fi
    
    _tw_check_tmux || return 1
    
    local session_name="${TW_SESSION_PREFIX}-${workspace_name}"
    
    # If session exists, attach. Otherwise create.
    if tmux has-session -t "$session_name" 2>/dev/null; then
        tw-attach "$workspace_name"
    else
        _tw_print_info "Workspace doesn't exist. Creating with template: $template"
        tw-create "$workspace_name" "$template"
    fi
}

# ============================================================================
# Fuzzy Search (requires fzf)
# ============================================================================

twf() {
    if ! command -v fzf &>/dev/null; then
        _tw_print_error "fzf not installed"
        return 1
    fi
    
    _tw_check_tmux || return 1
    
    # Get list of sessions
    local sessions=()
    tmux list-sessions 2>/dev/null | while IFS=: read -r session_full rest; do
        if [[ "$session_full" == ${TW_SESSION_PREFIX}-* ]]; then
            local workspace_name="${session_full#${TW_SESSION_PREFIX}-}"
            sessions+=("$workspace_name")
        fi
    done
    
    if [[ ${#sessions[@]} -eq 0 ]]; then
        _tw_print_info "No workspaces found"
        return 1
    fi
    
    # Fuzzy select
    local selection=$(printf '%s\n' "${sessions[@]}" | \
        fzf --height=40% \
            --layout=reverse \
            --border=rounded \
            --prompt='Workspace > ' \
            --preview='tmux list-windows -t work-{} 2>/dev/null || echo "No preview"')
    
    if [[ -n "$selection" ]]; then
        tw-attach "$selection"
    fi
}

# ============================================================================
# Pane Synchronization Toggle
# ============================================================================

tw-sync() {
    if [[ -z "$TMUX" ]]; then
        _tw_print_error "Must be run from inside tmux"
        return 1
    fi
    
    local current=$(tmux show-window-option -v synchronize-panes 2>/dev/null)
    
    if [[ "$current" == "on" ]]; then
        tmux set-window-option synchronize-panes off
        _tw_print_info "Pane synchronization: ${TW_RED}OFF${TW_NC}"
    else
        tmux set-window-option synchronize-panes on
        _tw_print_info "Pane synchronization: ${TW_GREEN}ON${TW_NC}"
    fi
}

# ============================================================================
# Rename Workspace
# ============================================================================

tw-rename() {
    local old_name="$1"
    local new_name="$2"
    
    if [[ -z "$old_name" || -z "$new_name" ]]; then
        echo "Usage: tw-rename <old_name> <new_name>"
        return 1
    fi
    
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
