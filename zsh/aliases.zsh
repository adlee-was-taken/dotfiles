# ============================================================================
# Dotfiles Command Aliases
# ============================================================================
# Convenient shortcuts for dotfiles management scripts
#
# Source this file in .zshrc (already included by default)
# ============================================================================

# --- Core Dotfiles Commands ---
alias dotfiles='cd ~/.dotfiles'
alias df='cd ~/.dotfiles'

# Doctor - health check
alias dfd='dotfiles-doctor.sh'
alias doctor='dotfiles-doctor.sh'
alias dffix='dotfiles-doctor.sh --fix'

# Sync - multi-machine synchronization
alias dfs='dotfiles-sync.sh'
alias dfsync='dotfiles-sync.sh'
alias dfpush='dotfiles-sync.sh --push'
alias dfpull='dotfiles-sync.sh --pull'
alias dfstatus='dotfiles-sync.sh --status'

# Update - pull latest and reinstall
alias dfu='dotfiles-update.sh'
alias dfupdate='dotfiles-update.sh'

# Version - check version info
alias dfv='dotfiles-version.sh'
alias dfversion='dotfiles-version.sh'

# Stats - shell analytics
alias dfstats='dotfiles-stats.sh'
alias stats='dotfiles-stats.sh'
alias tophist='dotfiles-stats.sh --top'
alias suggest='dotfiles-stats.sh --suggest'

# Vault - secrets management
alias vault='dotfiles-vault.sh'
alias vls='dotfiles-vault.sh list'
alias vget='dotfiles-vault.sh get'
alias vset='dotfiles-vault.sh set'

# Compile - compile zsh files for speed
alias dfcompile='dotfiles-compile.sh'

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
        doctor|doc|d)   shift; dotfiles-doctor.sh "$@" ;;
        sync|s)         shift; dotfiles-sync.sh "$@" ;;
        update|up|u)    shift; dotfiles-update.sh "$@" ;;
        version|ver|v)  shift; dotfiles-version.sh "$@" ;;
        stats|st)       shift; dotfiles-stats.sh "$@" ;;
        vault|vlt)      shift; dotfiles-vault.sh "$@" ;;
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
            echo "  edit, e       Open dotfiles in editor"
            echo "  cd            Change to dotfiles directory"
            echo
            echo "Aliases:"
            echo "  dfd, dffix, dfs, dfpush, dfpull, dfu, dfv, dfstats, vault"
            ;;
    esac
}

# Short alias for the CLI
alias dfc='dotfiles-cli'
