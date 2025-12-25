# ============================================================================
# Tmux Workspace Manager - Project Templates & Layouts
# ============================================================================
# Enhanced with optional tmuxinator integration for complex projects.
#
# Simple templates (.tmux files) for quick layouts
# Tmuxinator (optional) for full project configurations with commands
#
# Priority: tmuxinator project > simple template > create new
# ============================================================================

source "${0:A:h}/../lib/bootstrap.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/bootstrap.zsh" 2>/dev/null

# ============================================================================
# Configuration
# ============================================================================

typeset -g TW_TEMPLATES="${TW_TEMPLATES:-$HOME/.dotfiles/.tmux-templates}"
typeset -g TW_PREFIX="${TW_PREFIX:-work}"
typeset -g TW_DEFAULT="${TW_DEFAULT:-dev}"

# Tmuxinator integration (auto-detect if available)
typeset -g TW_USE_TMUXINATOR="${TW_USE_TMUXINATOR:-auto}"
typeset -g TMUXINATOR_CONFIG_DIR="${TMUXINATOR_CONFIG_DIR:-$HOME/.config/tmuxinator}"

# ============================================================================
# Internal Functions
# ============================================================================

_tw_check() { df_require_cmd tmux || return 1; }

_tw_has_tmuxinator() {
    [[ "$TW_USE_TMUXINATOR" == "false" ]] && return 1
    command -v tmuxinator &>/dev/null
}

_tw_tmuxinator_project_exists() {
    [[ -f "$TMUXINATOR_CONFIG_DIR/${1}.yml" ]]
}

_tw_init() {
    df_ensure_dir "$TW_TEMPLATES"
    
    # Create default templates if they don't exist
    [[ ! -f "$TW_TEMPLATES/dev.tmux" ]] && {
        cat > "$TW_TEMPLATES/dev.tmux" << 'EOF'
# Development workspace
# Layout: Editor (50%) | Terminal (25%) / Logs (25%)
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
EOF

        cat > "$TW_TEMPLATES/ops.tmux" << 'EOF'
# Operations workspace - 2x2 grid
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50
select-pane -t 0
EOF

        cat > "$TW_TEMPLATES/full.tmux" << 'EOF'
# Full screen - single pane (default)
EOF

        cat > "$TW_TEMPLATES/review.tmux" << 'EOF'
# Code review - side by side
split-window -h -p 50
select-pane -t 0
EOF

        cat > "$TW_TEMPLATES/debug.tmux" << 'EOF'
# Debug workspace - main (70%) + helper (30%)
split-window -h -p 30
select-pane -t 0
EOF

        cat > "$TW_TEMPLATES/ssh-multi.tmux" << 'EOF'
# Multi-server SSH - 4 panes with sync option
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50
# Uncomment to enable synchronized input:
# set-window-option synchronize-panes on
select-pane -t 0
EOF

        df_print_success "Created default templates in $TW_TEMPLATES"
    }
}

# ============================================================================
# Template Functions
# ============================================================================

tw-templates() {
    _tw_init
    df_print_func_name "Workspace Templates"
    
    echo ""
    df_print_section "Simple Templates (.tmux)"
    for t in "$TW_TEMPLATES"/*.tmux(N); do
        [[ -f "$t" ]] || continue
        local name=$(basename "$t" .tmux)
        local desc=$(head -1 "$t" | sed 's/^#[[:space:]]*//')
        df_print_indent "● $name"
        [[ -n "$desc" ]] && df_print_indent "  └─ $desc"
    done
    
    if _tw_has_tmuxinator; then
        echo ""
        df_print_section "Tmuxinator Projects"
        local found=false
        for p in "$TMUXINATOR_CONFIG_DIR"/*.yml(N); do
            [[ -f "$p" ]] || continue
            found=true
            local name=$(basename "$p" .yml)
            df_print_indent "● $name (tmuxinator)"
        done
        [[ "$found" != true ]] && df_print_indent "(none - create with txi-new)"
    fi
    
    echo ""
    df_print_info "Create workspace: tw-create <name> <template>"
}

# ============================================================================
# Workspace Management
# ============================================================================

tw-create() {
    local name="$1"
    local tmpl="${2:-$TW_DEFAULT}"
    
    [[ -z "$name" ]] && { tw-templates; return 1; }
    _tw_check || return 1
    _tw_init
    
    local session="${TW_PREFIX}-${name}"
    
    # Check if session exists
    if tmux has-session -t "$session" 2>/dev/null; then
        df_print_warning "Workspace '$name' already exists"
        df_confirm "Attach to it?" && tw-attach "$name"
        return
    fi
    
    # Check for tmuxinator project first
    if _tw_has_tmuxinator && _tw_tmuxinator_project_exists "$name"; then
        df_print_step "Starting tmuxinator project: $name"
        tmuxinator start "$name"
        return
    fi
    
    # Check for simple template
    local tfile="$TW_TEMPLATES/${tmpl}.tmux"
    if [[ ! -f "$tfile" ]]; then
        df_print_error "Template not found: $tmpl"
        tw-templates
        return 1
    fi
    
    df_print_step "Creating workspace: $name (template: $tmpl)"
    
    # Create session and apply template
    tmux new-session -d -s "$session"
    
    # Source the template file in the context of the session
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        tmux $line -t "$session" 2>/dev/null
    done < "$tfile"
    
    # If in a git repo, cd to root in first pane
    if df_in_git_repo; then
        local root=$(df_git_root)
        df_print_info "Git root: $root"
        tmux send-keys -t "$session:0.0" "cd '$root'" C-m
    fi
    
    df_print_success "Created: $name"
    
    # Attach or switch
    if [[ -z "$TMUX" ]]; then
        tmux attach -t "$session"
    else
        df_print_info "Switch with: tmux switch -t $session"
    fi
}

tw-list() {
    _tw_check || return 1
    df_print_func_name "Active Workspaces"
    
    local found=false
    tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null | while IFS='|' read -r sess windows attached; do
        [[ "$sess" == ${TW_PREFIX}-* ]] || continue
        found=true
        local name="${sess#${TW_PREFIX}-}"
        local status=""
        [[ "$attached" == "1" ]] && status=" (attached)"
        df_print_indent "● $name [${windows} window(s)]${status}"
    done
    
    [[ "$found" != true ]] && df_print_info "No active workspaces"
    
    # Also show tmuxinator projects if available
    if _tw_has_tmuxinator; then
        local txi_projects=()
        for p in "$TMUXINATOR_CONFIG_DIR"/*.yml(N); do
            [[ -f "$p" ]] && txi_projects+=("$(basename "$p" .yml)")
        done
        if [[ ${#txi_projects[@]} -gt 0 ]]; then
            echo ""
            df_print_section "Available Tmuxinator Projects"
            printf '  %s\n' "${txi_projects[@]}"
        fi
    fi
}

tw-attach() {
    local name="$1"
    [[ -z "$name" ]] && { tw-list; return 1; }
    _tw_check || return 1
    
    local session="${TW_PREFIX}-${name}"
    
    # Check for tmuxinator project
    if _tw_has_tmuxinator && _tw_tmuxinator_project_exists "$name"; then
        if tmux has-session -t "$name" 2>/dev/null; then
            [[ -z "$TMUX" ]] && tmux attach -t "$name" || tmux switch-client -t "$name"
        else
            df_print_step "Starting tmuxinator project: $name"
            tmuxinator start "$name"
        fi
        return
    fi
    
    # Regular workspace
    if ! tmux has-session -t "$session" 2>/dev/null; then
        df_print_error "Workspace '$name' not found"
        df_confirm "Create it?" && tw-create "$name"
        return 1
    fi
    
    [[ -z "$TMUX" ]] && tmux attach -t "$session" || tmux switch-client -t "$session"
}

tw-delete() {
    local name="$1"
    [[ -z "$name" ]] && { tw-list; return 1; }
    _tw_check || return 1
    
    local session="${TW_PREFIX}-${name}"
    
    # Handle tmuxinator project
    if _tw_has_tmuxinator && _tw_tmuxinator_project_exists "$name"; then
        tmuxinator stop "$name" 2>/dev/null
        df_print_success "Stopped tmuxinator session: $name"
        return
    fi
    
    if ! tmux has-session -t "$session" 2>/dev/null; then
        df_print_error "Workspace '$name' not found"
        return 1
    fi
    
    tmux kill-session -t "$session"
    df_print_success "Deleted: $name"
}

# Main entry point - intelligent routing
tw() {
    local name="$1"
    local tmpl="${2:-$TW_DEFAULT}"
    
    [[ -z "$name" ]] && { tw-list; return; }
    _tw_check || return 1
    
    local session="${TW_PREFIX}-${name}"
    
    # Priority 1: Running tmux session
    if tmux has-session -t "$session" 2>/dev/null; then
        tw-attach "$name"
        return
    fi
    
    # Priority 2: Tmuxinator project (if available)
    if _tw_has_tmuxinator && _tw_tmuxinator_project_exists "$name"; then
        if tmux has-session -t "$name" 2>/dev/null; then
            tw-attach "$name"
        else
            df_print_step "Starting tmuxinator project: $name"
            tmuxinator start "$name"
        fi
        return
    fi
    
    # Priority 3: Create new with template
    tw-create "$name" "$tmpl"
}

# Fuzzy finder
twf() {
    df_require_cmd fzf || return 1
    _tw_check || return 1
    
    local entries=()
    
    # Add running sessions
    tmux list-sessions -F "#{session_name}" 2>/dev/null | while read -r sess; do
        [[ "$sess" == ${TW_PREFIX}-* ]] && entries+=("${sess#${TW_PREFIX}-}|session")
    done
    
    # Add tmuxinator projects
    if _tw_has_tmuxinator; then
        for p in "$TMUXINATOR_CONFIG_DIR"/*.yml(N); do
            [[ -f "$p" ]] && entries+=("$(basename "$p" .yml)|tmuxinator")
        done
    fi
    
    [[ ${#entries[@]} -eq 0 ]] && { df_print_info "No workspaces or projects"; return 1; }
    
    local sel=$(printf '%s\n' "${entries[@]}" | fzf $(df_fzf_opts) --delimiter='|' --with-nth=1 --prompt='Workspace > ')
    [[ -n "$sel" ]] && tw "${sel%%|*}"
}

# Save current layout as template
tw-save() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: tw-save <template-name>"; return 1; }
    [[ -z "$TMUX" ]] && { df_print_error "Must be inside tmux"; return 1; }
    
    _tw_init
    local outfile="$TW_TEMPLATES/${name}.tmux"
    
    df_print_func_name "Save Template: ${name}"
    
    # Get current layout info
    local pane_count=$(tmux list-panes | wc -l)
    local layout=$(tmux display-message -p '#{window_layout}')
    
    cat > "$outfile" << EOF
# Custom template: ${name}
# Saved: $(date)
# Panes: ${pane_count}
EOF

    # Generate split commands based on pane count
    # This is a simplified approach - complex layouts need manual adjustment
    case $pane_count in
        2)
            echo "split-window -h -p 50" >> "$outfile"
            ;;
        3)
            echo "split-window -h -p 50" >> "$outfile"
            echo "split-window -v -p 50" >> "$outfile"
            ;;
        4)
            echo "split-window -h -p 50" >> "$outfile"
            echo "split-window -v -p 50" >> "$outfile"
            echo "select-pane -t 0" >> "$outfile"
            echo "split-window -v -p 50" >> "$outfile"
            ;;
        *)
            df_print_warning "Complex layout - manual adjustment may be needed"
            for ((i=1; i<pane_count; i++)); do
                echo "split-window -h -p 50" >> "$outfile"
            done
            ;;
    esac
    
    echo "" >> "$outfile"
    echo "select-pane -t 0" >> "$outfile"
    
    df_print_success "Saved: $outfile"
    df_print_info "Edit to refine: ${EDITOR:-vim} $outfile"
}

tw-template-edit() {
    local name="$1"
    [[ -z "$name" ]] && { tw-templates; return 1; }
    
    local tfile="$TW_TEMPLATES/${name}.tmux"
    [[ ! -f "$tfile" ]] && { df_print_error "Template not found: $name"; return 1; }
    
    ${EDITOR:-vim} "$tfile"
}

tw-sync() {
    [[ -z "$TMUX" ]] && { df_print_error "Must be inside tmux"; return 1; }
    
    local current=$(tmux show-window-option -v synchronize-panes 2>/dev/null)
    if [[ "$current" == "on" ]]; then
        tmux set-window-option synchronize-panes off
        df_print_info "Pane sync: OFF"
    else
        tmux set-window-option synchronize-panes on
        df_print_info "Pane sync: ON"
    fi
}

tw-rename() {
    local old="$1" new="$2"
    [[ -z "$old" || -z "$new" ]] && { echo "Usage: tw-rename <old> <new>"; return 1; }
    _tw_check || return 1
    
    local old_session="${TW_PREFIX}-${old}"
    local new_session="${TW_PREFIX}-${new}"
    
    tmux has-session -t "$old_session" 2>/dev/null || { df_print_error "Not found: $old"; return 1; }
    tmux rename-session -t "$old_session" "$new_session"
    df_print_success "Renamed: $old → $new"
}

# ============================================================================
# Help
# ============================================================================

tw-help() {
    df_print_func_name "Tmux Workspace Manager"
    cat << 'EOF'

  Quick Commands:
    tw <name> [tmpl]     Create/attach to workspace
    twf                  Fuzzy search workspaces

  Workspace Management:
    tw-create <n> [t]    Create with template
    tw-attach <n>        Attach to workspace
    tw-list              List active workspaces
    tw-delete <n>        Delete workspace
    tw-rename <old> <new>   Rename workspace

  Templates:
    tw-templates         Show available templates
    tw-save <n>          Save current layout as template
    tw-template-edit <n>    Edit template file

  Pane Control:
    tw-sync              Toggle synchronized panes

  Tmuxinator Integration:
    If tmuxinator is installed, projects in ~/.config/tmuxinator/
    are automatically detected. Use txi-* commands for management.

EOF
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
alias twh='tw-help'

# ============================================================================
# Initialize
# ============================================================================

_tw_init
