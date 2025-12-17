# ============================================================================
# Dotfiles Command Aliases
# ============================================================================
# Convenient shortcuts for dotfiles management scripts
#
# Source this file in .zshrc (already included by default)
# ============================================================================

# Dotfiles directory
_df_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
_df_bin="$_df_dir/bin"

# Helper to run dotfiles scripts (uses full path with fallback to PATH)
_df_run() {
    local script="$1"
    shift
    if [[ -x "$_df_bin/$script" ]]; then
        "$_df_bin/$script" "$@"
    elif command -v "$script" &>/dev/null; then
        "$script" "$@"
    else
        echo "Error: $script not found" >&2
        echo "Run the installer: ~/.dotfiles/install.sh" >&2
        return 1
    fi
}

# --- Core Dotfiles Commands ---
alias dotfiles='cd ~/.dotfiles'
alias dfcd='cd ~/.dotfiles'
# Note: 'df' not aliased to avoid conflict with disk free utility

# Doctor - health check
dfd()    { _df_run dotfiles-doctor.sh "$@"; }
doctor() { _df_run dotfiles-doctor.sh "$@"; }
dffix()  { _df_run dotfiles-doctor.sh --fix "$@"; }

# Sync - multi-machine synchronization
dfs()      { _df_run dotfiles-sync.sh "$@"; }
dfsync()   { _df_run dotfiles-sync.sh "$@"; }
dfpush()   { _df_run dotfiles-sync.sh --push "$@"; }
dfpull()   { _df_run dotfiles-sync.sh --pull "$@"; }
dfstatus() { _df_run dotfiles-sync.sh --status "$@"; }

# Update - pull latest and reinstall
dfu()      { _df_run dotfiles-update.sh "$@"; }
dfupdate() { _df_run dotfiles-update.sh "$@"; }

# Version - check version info
dfv()        { _df_run dotfiles-version.sh "$@"; }
dfversion()  { _df_run dotfiles-version.sh "$@"; }

# Stats - shell analytics (removed short 'stats' alias to force explicit usage)
dfstats() { _df_run dotfiles-stats.sh "$@"; }
tophist() { _df_run dotfiles-stats.sh --top "$@"; }
suggest() { _df_run dotfiles-stats.sh --suggest "$@"; }

# Vault - secrets management
vault() { _df_run dotfiles-vault.sh "$@"; }
vls()   { _df_run dotfiles-vault.sh list "$@"; }
vget()  { _df_run dotfiles-vault.sh get "$@"; }
vset()  { _df_run dotfiles-vault.sh set "$@"; }

# Compile - compile zsh files for speed
dfcompile() { _df_run dotfiles-compile.sh "$@"; }

# --- Quick Edit Aliases ---
alias zshrc='${EDITOR:-vim} ~/.zshrc'
alias dfconf='${EDITOR:-vim} ~/.dotfiles/dotfiles.conf'
alias dfedit='cd ~/.dotfiles && ${EDITOR:-vim} .'

# --- Reload Aliases ---
alias reload='source ~/.zshrc'
alias rl='source ~/.zshrc'

# ============================================================================
# Function Wrappers (for tab completion)
# ============================================================================

# Dotfiles main command with subcommands
dotfiles-cli() {
    case "${1:-help}" in
        doctor|doc|d)   shift; _df_run dotfiles-doctor.sh "$@" ;;
        sync|s)         shift; _df_run dotfiles-sync.sh "$@" ;;
        update|up|u)    shift; _df_run dotfiles-update.sh "$@" ;;
        version|ver|v)  shift; _df_run dotfiles-version.sh "$@" ;;
        stats|st)       shift; _df_run dotfiles-stats.sh "$@" ;;
        vault|vlt)      shift; _df_run dotfiles-vault.sh "$@" ;;
        compile|comp)   shift; _df_run dotfiles-compile.sh "$@" ;;
        edit|e)         cd ~/.dotfiles && ${EDITOR:-vim} . ;;
        cd)             cd ~/.dotfiles ;;
        help|--help|-h|*)
            echo "Dotfiles CLI"
            echo
            echo "Usage: dotfiles-cli <command> [args]"
            echo
            echo "Commands:"
            echo "  doctor, d     Run health check (--fix to auto-repair)"
            echo "  sync, s       Sync dotfiles across machines"
            echo "  update, u     Pull latest and reinstall"
            echo "  version, v    Show version info"
            echo "  stats, st     Shell analytics dashboard"
            echo "  vault, vlt    Secrets management"
            echo "  compile       Compile zsh files for speed"
            echo "  edit, e       Open dotfiles in editor"
            echo "  cd            Change to dotfiles directory"
            echo
            echo "Aliases:"
            echo "  dfd, dffix, dfs, dfpush, dfpull, dfu, dfv, dfstats, vault"
            echo
            echo "Note: 'stats' alias removed - use 'dfstats' instead"
            ;;
    esac
}

# Short alias for the CLI
alias dfc='dotfiles-cli'
