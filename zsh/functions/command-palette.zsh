# ============================================================================
# Command Palette - Fuzzy Command Launcher for Zsh
# ============================================================================
# A Raycast/Alfred-style command palette for the terminal
#
# Features:
#   - Search aliases, functions, recent commands
#   - Search bookmarked directories
#   - Search dotfiles scripts
#   - Quick actions (edit config, reload shell, etc.)
#
# Keybinding: Ctrl+Space (configurable)
#
# Requirements: fzf
# ============================================================================

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_GREEN=$'\033[0;32m' DF_BLUE=$'\033[0;34m'
    typeset -g DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
}

# ============================================================================
# Configuration
# ============================================================================

typeset -g PALETTE_HOTKEY="${PALETTE_HOTKEY:-^@}"  # Ctrl+Space
typeset -g PALETTE_HISTORY_SIZE=50
typeset -g PALETTE_BOOKMARKS_FILE="$HOME/.dotfiles/.bookmarks"
typeset -g DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Icons (works with most terminals)
typeset -g ICON_ALIAS="⚡"
typeset -g ICON_FUNC="λ"
typeset -g ICON_HIST="↺"
typeset -g ICON_DIR="📁"
typeset -g ICON_SCRIPT="⚙"
typeset -g ICON_ACTION="★"
typeset -g ICON_GIT="⎇"
typeset -g ICON_DOCKER="◉"
typeset -g ICON_EDIT="✎"
typeset -g ICON_RUN="▶"

# ============================================================================
# Check Dependencies
# ============================================================================

_palette_check_deps() {
    if ! command -v fzf &>/dev/null; then
        echo "Command palette requires fzf."
        echo "Install: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install"
        return 1
    fi
    return 0
}

# ============================================================================
# Data Sources
# ============================================================================

_palette_get_aliases() {
    alias | sed 's/^alias //' | while IFS='=' read -r alias_name cmd; do
        cmd="${cmd#\'}"
        cmd="${cmd%\'}"
        cmd="${cmd#\"}"
        cmd="${cmd%\"}"
        printf "%s\t%s\t%s\t%s\n" "$ICON_ALIAS" "alias" "$alias_name" "$cmd"
    done
}

_palette_get_functions() {
    print -l ${(ok)functions} | grep -v '^_' | while read -r func_name; do
        printf "%s\t%s\t%s\t%s\n" "$ICON_FUNC" "func" "$func_name" "function"
    done
}

_palette_get_history() {
    fc -ln -$PALETTE_HISTORY_SIZE | tac | awk '!seen[$0]++' | head -30 | while read -r cmd; do
        [[ -n "$cmd" ]] && printf "%s\t%s\t%s\t%s\n" "$ICON_HIST" "history" "${cmd:0:50}" "$cmd"
    done
}

_palette_get_bookmarks() {
    [[ ! -f "$PALETTE_BOOKMARKS_FILE" ]] && return
    
    while IFS='|' read -r bm_name bm_path; do
        [[ -n "$bm_name" && -n "$bm_path" ]] && printf "%s\t%s\t%s\t%s\n" "$ICON_DIR" "bookmark" "$bm_name" "cd $bm_path"
    done < "$PALETTE_BOOKMARKS_FILE"
}

_palette_get_scripts() {
    [[ ! -d "$DOTFILES_DIR/bin" ]] && return
    
    for script in "$DOTFILES_DIR/bin"/*.sh; do
        [[ -f "$script" ]] || continue
        local script_name=$(basename "$script" .sh)
        printf "%s\t%s\t%s\t%s\n" "$ICON_SCRIPT" "script" "$script_name" "$script"
    done
}

_palette_get_git_commands() {
    git rev-parse --git-dir &>/dev/null || return
    
    local branch=$(git branch --show-current 2>/dev/null)
    
    printf "%s\t%s\t%s\t%s\n" "$ICON_GIT" "git" "status" "git status"
    printf "%s\t%s\t%s\t%s\n" "$ICON_GIT" "git" "pull $branch" "git pull origin $branch"
    printf "%s\t%s\t%s\t%s\n" "$ICON_GIT" "git" "push $branch" "git push origin $branch"
    printf "%s\t%s\t%s\t%s\n" "$ICON_GIT" "git" "diff" "git diff"
    printf "%s\t%s\t%s\t%s\n" "$ICON_GIT" "git" "log" "git log --oneline -20"
    printf "%s\t%s\t%s\t%s\n" "$ICON_GIT" "git" "stash" "git stash"
    printf "%s\t%s\t%s\t%s\n" "$ICON_GIT" "git" "stash pop" "git stash pop"
}

_palette_get_docker_commands() {
    command -v docker &>/dev/null || return
    
    printf "%s\t%s\t%s\t%s\n" "$ICON_DOCKER" "docker" "ps" "docker ps"
    printf "%s\t%s\t%s\t%s\n" "$ICON_DOCKER" "docker" "ps -a" "docker ps -a"
    printf "%s\t%s\t%s\t%s\n" "$ICON_DOCKER" "docker" "images" "docker images"
    printf "%s\t%s\t%s\t%s\n" "$ICON_DOCKER" "docker" "compose up" "docker-compose up -d"
    printf "%s\t%s\t%s\t%s\n" "$ICON_DOCKER" "docker" "compose down" "docker-compose down"
    printf "%s\t%s\t%s\t%s\n" "$ICON_DOCKER" "docker" "prune" "docker system prune -af"
}

_palette_get_actions() {
    printf "%s\t%s\t%s\t%s\n" "$ICON_ACTION" "action" "Reload shell" "exec zsh"
    printf "%s\t%s\t%s\t%s\n" "$ICON_EDIT" "action" "Edit .zshrc" "${EDITOR:-vim} ~/.zshrc"
    printf "%s\t%s\t%s\t%s\n" "$ICON_EDIT" "action" "Edit dotfiles.conf" "${EDITOR:-vim} $DOTFILES_DIR/dotfiles.conf"
    printf "%s\t%s\t%s\t%s\n" "$ICON_EDIT" "action" "Edit theme" "${EDITOR:-vim} $DOTFILES_DIR/zsh/themes/adlee.zsh-theme"
    printf "%s\t%s\t%s\t%s\n" "$ICON_SCRIPT" "action" "Dotfiles doctor" "dfd"
    printf "%s\t%s\t%s\t%s\n" "$ICON_SCRIPT" "action" "Dotfiles sync" "dfs"
    printf "%s\t%s\t%s\t%s\n" "$ICON_SCRIPT" "action" "Shell stats" "dfstats"
    printf "%s\t%s\t%s\t%s\n" "$ICON_SCRIPT" "action" "Compile zsh" "dfcompile"
    printf "%s\t%s\t%s\t%s\n" "$ICON_SCRIPT" "action" "Vault list" "vault list"
    printf "%s\t%s\t%s\t%s\n" "$ICON_ACTION" "action" "Clear screen" "clear"
    printf "%s\t%s\t%s\t%s\n" "$ICON_DIR" "action" "Home" "cd ~"
    printf "%s\t%s\t%s\t%s\n" "$ICON_DIR" "action" "Dotfiles" "cd $DOTFILES_DIR"
    printf "%s\t%s\t%s\t%s\n" "$ICON_DIR" "action" "Projects" "cd ~/projects 2>/dev/null || cd ~"
}

_palette_get_directories() {
    dirs -v 2>/dev/null | tail -n +2 | head -10 | while read -r num dir; do
        [[ -n "$dir" ]] && printf "%s\t%s\t%s\t%s\n" "$ICON_DIR" "recent" "$dir" "cd $dir"
    done
}

# ============================================================================
# Main Palette Function
# ============================================================================

_palette_generate_entries() {
    _palette_get_actions
    _palette_get_git_commands
    _palette_get_docker_commands
    _palette_get_aliases
    _palette_get_bookmarks
    _palette_get_scripts
    _palette_get_directories
    _palette_get_history
    _palette_get_functions
}

command_palette() {
    _palette_check_deps || return 1
    
    local selection
    selection=$(_palette_generate_entries | \
        fzf --height=60% \
            --layout=reverse \
            --border=rounded \
            --prompt='❯ ' \
            --pointer='▶' \
            --header='Command Palette (ESC to cancel)' \
            --preview-window=hidden \
            --delimiter=$'\t' \
            --with-nth=1,3 \
            --tabstop=2 \
            --ansi \
            --bind='ctrl-r:reload(_palette_generate_entries)' \
            --expect=ctrl-e,ctrl-y)
    
    [[ -z "$selection" ]] && return
    
    local key=$(echo "$selection" | head -1)
    local line=$(echo "$selection" | tail -1)
    local cmd=$(echo "$line" | cut -f4)
    
    [[ -z "$cmd" ]] && return
    
    case "$key" in
        ctrl-e)
            print -z "$cmd"
            ;;
        ctrl-y)
            echo -n "$cmd" | pbcopy 2>/dev/null || echo -n "$cmd" | xclip -selection clipboard 2>/dev/null
            echo "Copied: $cmd"
            ;;
        *)
            echo "❯ $cmd"
            eval "$cmd"
            ;;
    esac
}

# Alias for easier access
palette() { command_palette; }
p() { command_palette; }

# ============================================================================
# Bookmark Management
# ============================================================================

bookmark() {
    local bm_name="$1"
    local bm_path="${2:-$(pwd)}"
    
    # Ensure bookmarks file parent directory exists
    mkdir -p "$(dirname "$PALETTE_BOOKMARKS_FILE")" 2>/dev/null
    
    # Create bookmarks file if it doesn't exist
    [[ ! -f "$PALETTE_BOOKMARKS_FILE" ]] && touch "$PALETTE_BOOKMARKS_FILE"
    
    if [[ -z "$bm_name" ]]; then
        echo "Usage: bookmark <name> [path]"
        echo "       bookmark list"
        echo "       bookmark delete <name>"
        return 1
    fi
    
    case "$bm_name" in
        list|ls)
            if [[ -s "$PALETTE_BOOKMARKS_FILE" ]]; then
                echo "Bookmarks:"
                while IFS='|' read -r stored_name stored_path || [[ -n "$stored_name" ]]; do
                    [[ -n "$stored_name" ]] && echo "  $stored_name → $stored_path"
                done < "$PALETTE_BOOKMARKS_FILE"
            else
                echo "No bookmarks yet"
            fi
            ;;
        delete|rm)
            local to_delete="$2"
            if [[ -z "$to_delete" ]]; then
                echo "Specify bookmark to delete"
                return 1
            fi
            if [[ -s "$PALETTE_BOOKMARKS_FILE" ]]; then
                # Use a temp file approach that won't hang
                local temp_file="${PALETTE_BOOKMARKS_FILE}.tmp.$$"
                grep -v "^${to_delete}|" "$PALETTE_BOOKMARKS_FILE" > "$temp_file" 2>/dev/null || true
                mv -f "$temp_file" "$PALETTE_BOOKMARKS_FILE"
                echo "Deleted: $to_delete"
            else
                echo "No bookmarks to delete"
            fi
            ;;
        *)
            # Remove existing bookmark with same name (if file has content)
            if [[ -s "$PALETTE_BOOKMARKS_FILE" ]]; then
                local temp_file="${PALETTE_BOOKMARKS_FILE}.tmp.$$"
                grep -v "^${bm_name}|" "$PALETTE_BOOKMARKS_FILE" > "$temp_file" 2>/dev/null || true
                mv -f "$temp_file" "$PALETTE_BOOKMARKS_FILE"
            fi
            # Add new bookmark
            echo "${bm_name}|${bm_path}" >> "$PALETTE_BOOKMARKS_FILE"
            echo "Bookmarked: $bm_name → $bm_path"
            ;;
    esac
}

# Quick jump to bookmark
jump() {
    local bm_name="$1"
    
    if [[ -z "$bm_name" ]]; then
        # Fuzzy select bookmark
        if [[ ! -s "$PALETTE_BOOKMARKS_FILE" ]]; then
            echo "No bookmarks"
            return 1
        fi
        
        local selection=$(cat "$PALETTE_BOOKMARKS_FILE" | \
            fzf --height=40% --layout=reverse --delimiter='|' --with-nth=1 \
                --preview='echo "Path: $(echo {} | cut -d"|" -f2)"')
        
        if [[ -n "$selection" ]]; then
            local jump_path=$(echo "$selection" | cut -d'|' -f2)
            cd "$jump_path" && echo "→ $jump_path"
        fi
    else
        # Direct jump
        local jump_path=$(grep "^${bm_name}|" "$PALETTE_BOOKMARKS_FILE" 2>/dev/null | cut -d'|' -f2)
        if [[ -n "$jump_path" ]]; then
            cd "$jump_path" && echo "→ $jump_path"
        else
            echo "Bookmark not found: $bm_name"
        fi
    fi
}

# Aliases
bm() { bookmark "$@"; }
j() { jump "$@"; }

# ============================================================================
# Widget for Keybinding
# ============================================================================

_palette_widget() {
    command_palette
    zle reset-prompt
}

# Register widget
zle -N _palette_widget

# Bind to Ctrl+Space (^@)
bindkey "$PALETTE_HOTKEY" _palette_widget

# Alternative binding: Ctrl+P
bindkey '^P' _palette_widget
