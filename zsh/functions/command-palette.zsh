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
#
# Add to .zshrc:
#   source ~/.dotfiles/zsh/functions/command-palette.zsh
# ============================================================================

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
    alias | sed 's/^alias //' | while IFS='=' read -r name cmd; do
        cmd="${cmd#\'}"
        cmd="${cmd%\'}"
        cmd="${cmd#\"}"
        cmd="${cmd%\"}"
        printf "%s\t%s\t%s\t%s\n" "$ICON_ALIAS" "alias" "$name" "$cmd"
    done
}

_palette_get_functions() {
    # Get user-defined functions (not starting with _)
    print -l ${(ok)functions} | grep -v '^_' | while read -r name; do
        printf "%s\t%s\t%s\t%s\n" "$ICON_FUNC" "func" "$name" "function"
    done
}

_palette_get_history() {
    fc -ln -$PALETTE_HISTORY_SIZE | tac | awk '!seen[$0]++' | head -30 | while read -r cmd; do
        [[ -n "$cmd" ]] && printf "%s\t%s\t%s\t%s\n" "$ICON_HIST" "history" "${cmd:0:50}" "$cmd"
    done
}

_palette_get_bookmarks() {
    [[ ! -f "$PALETTE_BOOKMARKS_FILE" ]] && return
    
    while IFS='|' read -r name path; do
        [[ -n "$name" && -n "$path" ]] && printf "%s\t%s\t%s\t%s\n" "$ICON_DIR" "bookmark" "$name" "cd $path"
    done < "$PALETTE_BOOKMARKS_FILE"
}

_palette_get_scripts() {
    [[ ! -d "$DOTFILES_DIR/bin" ]] && return
    
    for script in "$DOTFILES_DIR/bin"/*.sh; do
        [[ -f "$script" ]] || continue
        local name=$(basename "$script" .sh)
        printf "%s\t%s\t%s\t%s\n" "$ICON_SCRIPT" "script" "$name" "$script"
    done
}

_palette_get_git_commands() {
    # Only show if in git repo
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
    # Recent directories from dirstack
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
            # Edit mode - put command on line without executing
            print -z "$cmd"
            ;;
        ctrl-y)
            # Yank - copy to clipboard
            echo -n "$cmd" | pbcopy 2>/dev/null || echo -n "$cmd" | xclip -selection clipboard 2>/dev/null
            echo "Copied: $cmd"
            ;;
        *)
            # Default - execute
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
    local name="$1"
    local path="${2:-$(pwd)}"
    
    if [[ -z "$name" ]]; then
        echo "Usage: bookmark <name> [path]"
        echo "       bookmark list"
        echo "       bookmark delete <name>"
        return 1
    fi
    
    case "$name" in
        list|ls)
            if [[ -f "$PALETTE_BOOKMARKS_FILE" ]]; then
                echo "Bookmarks:"
                while IFS='|' read -r n p; do
                    echo "  $n → $p"
                done < "$PALETTE_BOOKMARKS_FILE"
            else
                echo "No bookmarks yet"
            fi
            ;;
        delete|rm)
            local to_delete="$2"
            [[ -z "$to_delete" ]] && { echo "Specify bookmark to delete"; return 1; }
            [[ -f "$PALETTE_BOOKMARKS_FILE" ]] && {
                grep -v "^$to_delete|" "$PALETTE_BOOKMARKS_FILE" > "${PALETTE_BOOKMARKS_FILE}.tmp"
                mv "${PALETTE_BOOKMARKS_FILE}.tmp" "$PALETTE_BOOKMARKS_FILE"
                echo "Deleted: $to_delete"
            }
            ;;
        *)
            mkdir -p "$(dirname "$PALETTE_BOOKMARKS_FILE")"
            # Remove existing bookmark with same name
            [[ -f "$PALETTE_BOOKMARKS_FILE" ]] && {
                grep -v "^$name|" "$PALETTE_BOOKMARKS_FILE" > "${PALETTE_BOOKMARKS_FILE}.tmp"
                mv "${PALETTE_BOOKMARKS_FILE}.tmp" "$PALETTE_BOOKMARKS_FILE"
            }
            echo "$name|$path" >> "$PALETTE_BOOKMARKS_FILE"
            echo "Bookmarked: $name → $path"
            ;;
    esac
}

# Quick jump to bookmark
jump() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        # Fuzzy select bookmark
        [[ ! -f "$PALETTE_BOOKMARKS_FILE" ]] && { echo "No bookmarks"; return 1; }
        
        local selection=$(cat "$PALETTE_BOOKMARKS_FILE" | \
            fzf --height=40% --layout=reverse --delimiter='|' --with-nth=1 \
                --preview='echo "Path: $(echo {} | cut -d"|" -f2)"')
        
        [[ -n "$selection" ]] && {
            local path=$(echo "$selection" | cut -d'|' -f2)
            cd "$path" && echo "→ $path"
        }
    else
        # Direct jump
        local path=$(grep "^$name|" "$PALETTE_BOOKMARKS_FILE" 2>/dev/null | cut -d'|' -f2)
        [[ -n "$path" ]] && cd "$path" || echo "Bookmark not found: $name"
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

# ============================================================================
# Initialization Message
# ============================================================================

# Uncomment to show on load:
# echo "Command palette loaded. Press Ctrl+Space or Ctrl+P to open."
