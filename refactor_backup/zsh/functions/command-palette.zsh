# ============================================================================
# Command Palette - Fuzzy Command Launcher for Zsh
# ============================================================================
# A Raycast/Alfred-style command palette for the terminal
# Keybinding: Ctrl+Space (configurable)
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

typeset -g PALETTE_HOTKEY="${PALETTE_HOTKEY:-^@}"
typeset -g PALETTE_HISTORY_SIZE=50
typeset -g PALETTE_BOOKMARKS_FILE="$HOME/.dotfiles/.bookmarks"
typeset -g DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

typeset -g ICON_ALIAS="⚡" ICON_FUNC="λ" ICON_HIST="↺" ICON_DIR="📁"
typeset -g ICON_SCRIPT="⚙" ICON_ACTION="★" ICON_GIT="⎇"

_palette_get_aliases() {
    alias | sed 's/^alias //' | while IFS='=' read -r name cmd; do
        cmd="${cmd#\'}"; cmd="${cmd%\'}"; cmd="${cmd#\"}"; cmd="${cmd%\"}"
        printf "%s\t%s\t%s\t%s\n" "$ICON_ALIAS" "alias" "$name" "$cmd"
    done
}

_palette_get_functions() {
    print -l ${(ok)functions} | grep -v "^_" | while read -r name; do
        printf "%s\t%s\t%s\t%s\n" "$ICON_FUNC" "function" "$name" ""
    done
}

_palette_get_history() {
    fc -ln -"$PALETTE_HISTORY_SIZE" 2>/dev/null | awk '!seen[$0]++' | while read -r cmd; do
        [[ -n "$cmd" ]] && printf "%s\t%s\t%s\t%s\n" "$ICON_HIST" "history" "$cmd" ""
    done
}

_palette_get_bookmarks() {
    [[ ! -f "$PALETTE_BOOKMARKS_FILE" ]] && return
    while IFS='|' read -r name path desc; do
        [[ "$name" =~ ^# || -z "$name" ]] && continue
        printf "%s\t%s\t%s\t%s\n" "$ICON_DIR" "bookmark" "$name" "$path"
    done < "$PALETTE_BOOKMARKS_FILE"
}

_palette_get_actions() {
    cat << 'EOF'
★	action	reload-shell	Reload zsh configuration
★	action	edit-zshrc	Edit ~/.zshrc
★	action	dotfiles-update	Update dotfiles
EOF
    df_in_git_repo && cat << 'EOF'
⎇	git	git-status	Show git status
⎇	git	git-pull	Pull latest
⎇	git	git-push	Push commits
EOF
}

_palette_run_action() {
    case "$1" in
        reload-shell) source ~/.zshrc; df_print_success "Shell reloaded" ;;
        edit-zshrc) ${EDITOR:-vim} ~/.zshrc ;;
        dotfiles-update) cd "$DOTFILES_DIR" && git pull ;;
        git-status) git status ;;
        git-pull) git pull ;;
        git-push) git push ;;
        *) df_print_error "Unknown action: $1" ;;
    esac
}

palette() {
    df_require_cmd fzf || return 1
    local items=$(_palette_get_actions; _palette_get_aliases; _palette_get_functions; _palette_get_bookmarks; _palette_get_history)
    local sel=$(echo "$items" | fzf --ansi --delimiter='\t' --with-nth=1,3,4 $(df_fzf_opts) --prompt='> ')
    [[ -z "$sel" ]] && return
    local type=$(echo "$sel" | cut -f2) name=$(echo "$sel" | cut -f3) detail=$(echo "$sel" | cut -f4)
    case "$type" in
        alias|history) print -z "$name" ;;
        function) print -z "$name " ;;
        bookmark) cd "$detail" && pwd ;;
        action|git) _palette_run_action "$name" ;;
    esac
}

bookmark() {
    local cmd="${1:-list}"; shift 2>/dev/null
    case "$cmd" in
        add)
            local name="$1" path="${2:-$(pwd)}" desc="$3"
            [[ -z "$name" ]] && { echo "Usage: bookmark add <name> [path]"; return 1; }
            df_ensure_file "$PALETTE_BOOKMARKS_FILE" "# Bookmarks: name|path|description"
            grep -q "^${name}|" "$PALETTE_BOOKMARKS_FILE" 2>/dev/null && {
                df_confirm "Overwrite '$name'?" || return 1
                grep -v "^${name}|" "$PALETTE_BOOKMARKS_FILE" > "${PALETTE_BOOKMARKS_FILE}.tmp"
                mv "${PALETTE_BOOKMARKS_FILE}.tmp" "$PALETTE_BOOKMARKS_FILE"
            }
            echo "${name}|${path}|${desc}" >> "$PALETTE_BOOKMARKS_FILE"
            df_print_success "Bookmarked: $name → $path"
            ;;
        delete|rm)
            [[ -z "$1" ]] && { echo "Usage: bookmark delete <name>"; return 1; }
            grep -q "^${1}|" "$PALETTE_BOOKMARKS_FILE" 2>/dev/null || { df_print_error "Not found: $1"; return 1; }
            grep -v "^${1}|" "$PALETTE_BOOKMARKS_FILE" > "${PALETTE_BOOKMARKS_FILE}.tmp"
            mv "${PALETTE_BOOKMARKS_FILE}.tmp" "$PALETTE_BOOKMARKS_FILE"
            df_print_success "Deleted: $1"
            ;;
        list|ls)
            df_print_func_name "Bookmarks"
            [[ ! -f "$PALETTE_BOOKMARKS_FILE" ]] && { df_print_info "No bookmarks"; return; }
            while IFS='|' read -r name path desc; do
                [[ "$name" =~ ^# || -z "$name" ]] && continue
                df_print_indent "● $name → $path"
            done < "$PALETTE_BOOKMARKS_FILE"
            ;;
        go)
            [[ -z "$1" ]] && { echo "Usage: bookmark go <name>"; return 1; }
            local path=$(grep "^${1}|" "$PALETTE_BOOKMARKS_FILE" 2>/dev/null | cut -d'|' -f2)
            [[ -n "$path" ]] && cd "$path" || df_print_error "Not found: $1"
            ;;
        *) echo "Usage: bookmark <add|delete|list|go>" ;;
    esac
}

bm() {
    df_require_cmd fzf || return 1
    [[ ! -f "$PALETTE_BOOKMARKS_FILE" ]] && { df_print_info "No bookmarks"; return 1; }
    local sel=$(grep -v "^#" "$PALETTE_BOOKMARKS_FILE" | grep -v "^$" | \
        fzf $(df_fzf_opts) --delimiter='|' --with-nth=1,2 --prompt='Bookmark > ')
    [[ -n "$sel" ]] && cd "$(echo "$sel" | cut -d'|' -f2)"
}

_palette_widget() { BUFFER=""; zle redisplay; palette; zle reset-prompt; }
zle -N _palette_widget
bindkey "$PALETTE_HOTKEY" _palette_widget

alias p='palette' bml='bookmark list' bma='bookmark add' bmg='bookmark go'
