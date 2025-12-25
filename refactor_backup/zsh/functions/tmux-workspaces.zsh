# ============================================================================
# Tmux Workspace Manager - Project Templates & Layouts
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

typeset -g TW_TEMPLATES="${TW_TEMPLATES:-$HOME/.dotfiles/.tmux-templates}"
typeset -g TW_PREFIX="${TW_PREFIX:-work}"
typeset -g TW_DEFAULT="${TW_DEFAULT:-dev}"

_tw_check() { df_require_cmd tmux || return 1; }

_tw_init() {
    df_ensure_dir "$TW_TEMPLATES"
    [[ ! -f "$TW_TEMPLATES/dev.tmux" ]] && {
        echo -e "# Dev layout\nsplit-window -h -p 50\nsplit-window -v -p 50\nselect-pane -t 0" > "$TW_TEMPLATES/dev.tmux"
        echo -e "# Ops layout\nsplit-window -h\nsplit-window -v\nselect-pane -t 0\nsplit-window -v\nselect-pane -t 0" > "$TW_TEMPLATES/ops.tmux"
        echo "# Full\n" > "$TW_TEMPLATES/full.tmux"
        df_print_success "Created default templates"
    }
}

tw-templates() {
    _tw_init
    df_print_func_name "Tmux Templates"
    for t in "$TW_TEMPLATES"/*.tmux; do
        [[ -f "$t" ]] && df_print_indent "● $(basename "$t" .tmux)"
    done
    echo ""
    df_print_info "Create: tw-create <name> <template>"
}

tw-create() {
    local name="$1" tmpl="${2:-$TW_DEFAULT}"
    [[ -z "$name" ]] && { tw-templates; return 1; }
    _tw_check || return 1
    _tw_init
    
    local session="${TW_PREFIX}-${name}"
    tmux has-session -t "$session" 2>/dev/null && { df_print_error "'$name' exists"; return 1; }
    
    local tfile="$TW_TEMPLATES/${tmpl}.tmux"
    [[ ! -f "$tfile" ]] && { df_print_error "Template '$tmpl' not found"; tw-templates; return 1; }
    
    df_print_step "Creating: $name (template: $tmpl)"
    tmux new-session -d -s "$session"
    tmux source-file "$tfile" -t "$session"
    
    df_in_git_repo && {
        local root=$(df_git_root)
        df_print_info "Git root: $root"
        tmux send-keys -t "$session:0" "cd $root" C-m
    }
    
    df_print_success "Created: $name"
    [[ -z "$TMUX" ]] && tmux attach -t "$session" || df_print_info "Switch: tmux switch -t $session"
}

tw-list() {
    _tw_check || return 1
    df_print_func_name "Tmux Workspaces"
    local found=false
    tmux list-sessions 2>/dev/null | while IFS=: read -r sess rest; do
        [[ "$sess" == ${TW_PREFIX}-* ]] && { found=true; df_print_indent "● ${sess#${TW_PREFIX}-}"; }
    done
    [[ "$found" != true ]] && df_print_info "No workspaces. Use: tw-create <name>"
}

tw-attach() {
    local name="$1"
    [[ -z "$name" ]] && { tw-list; return 1; }
    _tw_check || return 1
    local session="${TW_PREFIX}-${name}"
    tmux has-session -t "$session" 2>/dev/null || { df_print_error "'$name' not found"; return 1; }
    [[ -z "$TMUX" ]] && tmux attach -t "$session" || tmux switch -t "$session"
}

tw-delete() {
    [[ -z "$1" ]] && { tw-list; return 1; }
    _tw_check || return 1
    local session="${TW_PREFIX}-${1}"
    tmux has-session -t "$session" 2>/dev/null || { df_print_error "'$1' not found"; return 1; }
    tmux kill-session -t "$session"
    df_print_success "Deleted: $1"
}

tw() {
    local name="$1" tmpl="${2:-$TW_DEFAULT}"
    [[ -z "$name" ]] && { tw-list; return; }
    _tw_check || return 1
    local session="${TW_PREFIX}-${name}"
    tmux has-session -t "$session" 2>/dev/null && tw-attach "$name" || tw-create "$name" "$tmpl"
}

twf() {
    df_require_cmd fzf || return 1
    _tw_check || return 1
    local sessions=()
    tmux list-sessions 2>/dev/null | while IFS=: read -r sess rest; do
        [[ "$sess" == ${TW_PREFIX}-* ]] && sessions+=("${sess#${TW_PREFIX}-}")
    done
    [[ ${#sessions[@]} -eq 0 ]] && { df_print_info "No workspaces"; return 1; }
    local sel=$(printf '%s\n' "${sessions[@]}" | fzf $(df_fzf_opts) --prompt='Workspace > ')
    [[ -n "$sel" ]] && tw-attach "$sel"
}

tw-sync() {
    [[ -z "$TMUX" ]] && { df_print_error "Must be in tmux"; return 1; }
    local cur=$(tmux show-window-option -v synchronize-panes 2>/dev/null)
    [[ "$cur" == "on" ]] && { tmux set-window-option synchronize-panes off; df_print_info "Sync: OFF"; } || \
        { tmux set-window-option synchronize-panes on; df_print_info "Sync: ON"; }
}

alias twl='tw-list' twc='tw-create' twa='tw-attach' twd='tw-delete' twt='tw-templates'
_tw_init
