# ============================================================================
# Dotfiles Plugin Manager
# ============================================================================
# A thin wrapper for managing zsh plugins without heavy frameworks.
#
# Features:
#   - Simple git-based plugin installation
#   - Automatic updates
#   - Lazy loading support
#   - Oh-My-Zsh plugin compatibility
# ============================================================================

# Prevent double-sourcing
[[ -n "$_DF_PLUGINS_LOADED" ]] && return 0
typeset -g _DF_PLUGINS_LOADED=1

# ============================================================================
# Configuration
# ============================================================================

typeset -g DF_PLUGIN_DIR="${DF_PLUGIN_DIR:-$HOME/.dotfiles/zsh/plugins}"
typeset -g DF_PLUGIN_REPOS_FILE="${DF_PLUGIN_DIR}/.repos"

# Track loaded plugins
typeset -ga DF_LOADED_PLUGINS=()

# ============================================================================
# Core Functions
# ============================================================================

# Install a plugin from GitHub
# Usage: df_plugin "zsh-users/zsh-autosuggestions" [branch]
df_plugin() {
    local repo="$1"
    local branch="${2:-master}"
    local name="${repo##*/}"
    local dir="$DF_PLUGIN_DIR/$name"
    
    # Ensure plugin directory exists
    [[ ! -d "$DF_PLUGIN_DIR" ]] && mkdir -p "$DF_PLUGIN_DIR"
    
    # Clone if not exists
    if [[ ! -d "$dir" ]]; then
        echo "Installing plugin: $name..."
        git clone --depth 1 --branch "$branch" "https://github.com/$repo.git" "$dir" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "✓ Installed: $name"
            # Track the repo
            echo "$repo|$branch" >> "$DF_PLUGIN_REPOS_FILE"
        else
            echo "✗ Failed to install: $name"
            return 1
        fi
    fi
    
    # Source the plugin
    df_plugin_load "$name"
}

# Load a plugin by name
df_plugin_load() {
    local name="$1"
    local dir="$DF_PLUGIN_DIR/$name"
    
    # Check if already loaded
    [[ " ${DF_LOADED_PLUGINS[*]} " =~ " $name " ]] && return 0
    
    if [[ -d "$dir" ]]; then
        # Try common plugin file names
        local plugin_files=(
            "$dir/$name.plugin.zsh"
            "$dir/$name.zsh"
            "$dir/init.zsh"
            "$dir/$name.sh"
        )
        
        for file in "${plugin_files[@]}"; do
            if [[ -f "$file" ]]; then
                source "$file"
                DF_LOADED_PLUGINS+=("$name")
                return 0
            fi
        done
        
        echo "Warning: Could not find plugin entry point for $name"
        return 1
    else
        echo "Plugin not found: $name"
        return 1
    fi
}

# Lazy load a plugin (load on first use of command)
# Usage: df_plugin_lazy "plugin-name" "command1" "command2"
df_plugin_lazy() {
    local plugin="$1"
    shift
    local commands=("$@")
    
    for cmd in "${commands[@]}"; do
        eval "
            $cmd() {
                unfunction $cmd 2>/dev/null
                df_plugin_load '$plugin'
                $cmd \"\$@\"
            }
        "
    done
}

# Update all plugins
df_plugin_update() {
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
    
    df_print_func_name "Plugin Update"
    echo ""
    
    for dir in "$DF_PLUGIN_DIR"/*/; do
        [[ -d "$dir/.git" ]] || continue
        
        local name=$(basename "$dir")
        df_print_step "Updating: $name"
        
        (
            cd "$dir"
            git pull --quiet 2>/dev/null && \
                df_print_success "$name updated" || \
                df_print_warning "$name: update failed"
        )
    done
}

# List installed plugins
df_plugin_list() {
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
    
    df_print_func_name "Installed Plugins"
    echo ""
    
    if [[ ! -d "$DF_PLUGIN_DIR" ]] || [[ -z "$(ls -A "$DF_PLUGIN_DIR" 2>/dev/null)" ]]; then
        df_print_info "No plugins installed"
        return
    fi
    
    for dir in "$DF_PLUGIN_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        
        local name=$(basename "$dir")
        local loaded=""
        [[ " ${DF_LOADED_PLUGINS[*]} " =~ " $name " ]] && loaded=" ${DF_GREEN}(loaded)${DF_NC}"
        
        # Get repo info if available
        local repo_info=""
        if [[ -d "$dir/.git" ]]; then
            local remote=$(cd "$dir" && git remote get-url origin 2>/dev/null)
            repo_info=" ${DF_DIM}${remote##*github.com/}${DF_NC}"
        fi
        
        df_print_indent "● ${name}${loaded}${repo_info}"
    done
    
    echo ""
    df_print_section "Loaded Plugins"
    if [[ ${#DF_LOADED_PLUGINS[@]} -gt 0 ]]; then
        df_print_indent "${DF_LOADED_PLUGINS[*]}"
    else
        df_print_indent "(none)"
    fi
}

# Remove a plugin
df_plugin_remove() {
    local name="$1"
    local dir="$DF_PLUGIN_DIR/$name"
    
    [[ -z "$name" ]] && { echo "Usage: df_plugin_remove <name>"; return 1; }
    
    if [[ ! -d "$dir" ]]; then
        echo "Plugin not found: $name"
        return 1
    fi
    
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
    
    df_confirm "Remove plugin '$name'?" || return 1
    
    rm -rf "$dir"
    
    # Remove from repos file
    if [[ -f "$DF_PLUGIN_REPOS_FILE" ]]; then
        grep -v "/$name|" "$DF_PLUGIN_REPOS_FILE" > "${DF_PLUGIN_REPOS_FILE}.tmp" 2>/dev/null || true
        mv "${DF_PLUGIN_REPOS_FILE}.tmp" "$DF_PLUGIN_REPOS_FILE"
    fi
    
    df_print_success "Removed: $name"
    df_print_info "Restart shell to fully unload"
}

# Install recommended plugins
df_plugin_recommended() {
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
    
    df_print_func_name "Recommended Plugins"
    echo ""
    
    local plugins=(
        "zsh-users/zsh-autosuggestions:Fish-like autosuggestions"
        "zsh-users/zsh-syntax-highlighting:Syntax highlighting"
        "zsh-users/zsh-completions:Additional completions"
        "romkatv/zsh-defer:Deferred loading for faster startup"
        "Aloxaf/fzf-tab:FZF-powered tab completion"
    )
    
    for plugin_info in "${plugins[@]}"; do
        local repo="${plugin_info%%:*}"
        local desc="${plugin_info#*:}"
        local name="${repo##*/}"
        local status=""
        
        if [[ -d "$DF_PLUGIN_DIR/$name" ]]; then
            status="${DF_GREEN}(installed)${DF_NC}"
        else
            status="${DF_DIM}(not installed)${DF_NC}"
        fi
        
        echo -e "  ${DF_CYAN}$name${DF_NC} $status"
        echo -e "    ${DF_DIM}$desc${DF_NC}"
        echo -e "    ${DF_DIM}Install: df_plugin $repo${DF_NC}"
        echo ""
    done
}

# ============================================================================
# Command Interface
# ============================================================================

# Main plugin command
plugin() {
    local cmd="${1:-list}"
    shift 2>/dev/null || true
    
    case "$cmd" in
        install|add|i)
            [[ -z "$1" ]] && { echo "Usage: plugin install <github-user/repo>"; return 1; }
            df_plugin "$@"
            ;;
        load|l)
            df_plugin_load "$@"
            ;;
        lazy)
            df_plugin_lazy "$@"
            ;;
        update|up|u)
            df_plugin_update
            ;;
        list|ls)
            df_plugin_list
            ;;
        remove|rm|r)
            df_plugin_remove "$@"
            ;;
        recommended|rec)
            df_plugin_recommended
            ;;
        help|--help|-h)
            cat << 'EOF'
Dotfiles Plugin Manager

Usage: plugin <command> [args]

Commands:
  install <repo>   Install plugin from GitHub (e.g., zsh-users/zsh-autosuggestions)
  load <name>      Load an installed plugin
  lazy <n> <cmds>  Lazy-load plugin on command use
  update           Update all plugins
  list             List installed plugins
  remove <name>    Remove a plugin
  recommended      Show recommended plugins

Examples:
  plugin install zsh-users/zsh-autosuggestions
  plugin lazy zsh-nvm nvm node npm
  plugin update
  plugin remove zsh-autosuggestions

EOF
            ;;
        *)
            echo "Unknown command: $cmd"
            echo "Use 'plugin help' for usage"
            return 1
            ;;
    esac
}

# ============================================================================
# Initialize
# ============================================================================

# Ensure plugin directory exists
[[ ! -d "$DF_PLUGIN_DIR" ]] && mkdir -p "$DF_PLUGIN_DIR"
