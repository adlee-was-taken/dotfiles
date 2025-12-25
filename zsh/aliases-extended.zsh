# ============================================================================
# Dotfiles Command Aliases - Extended Version
# ============================================================================
# Includes all original aliases plus new improvement aliases.
# ============================================================================

# Dotfiles directory
_df_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
_df_bin="$_df_dir/bin"

# Helper to run dotfiles scripts
_df_run() {
    local script="$1"
    shift
    if [[ -x "$_df_bin/$script" ]]; then
        "$_df_bin/$script" "$@"
    elif command -v "$script" &>/dev/null; then
        "$script" "$@"
    else
        echo "Error: $script not found" >&2
        return 1
    fi
}

# ============================================================================
# Quality of Life Aliases
# ============================================================================

alias hist="history"
alias cls="clear"
alias q="exit"

# ============================================================================
# Core Dotfiles Commands
# ============================================================================

alias dfdir='cd $HOME/.dotfiles'
alias c.='cd $HOME/.dotfiles'

# Doctor - health check
dfd()    { _df_run dotfiles-doctor.sh "$@"; }
doctor() { _df_run dotfiles-doctor.sh "$@"; }
dffix()  { _df_run dotfiles-doctor.sh --fix "$@"; }

# Sync
dfs()      { _df_run dotfiles-sync.sh "$@"; }
dfpush()   { _df_run dotfiles-sync.sh push "${1:-Dotfiles update $(date '+%Y-%m-%d %H:%M')}"; }
dfpull()   { _df_run dotfiles-sync.sh pull "$@"; }
dfstatus() { _df_run dotfiles-sync.sh status "$@"; }

# Update
dfu()      { _df_run dotfiles-update.sh "$@"; }
dfupdate() { _df_run dotfiles-update.sh "$@"; }

# Version
dfv()       { _df_run dotfiles-version.sh "$@"; }
dfversion() { _df_run dotfiles-version.sh "$@"; }

# Stats / Analytics
dfstats()     { _df_run dotfiles-stats.sh "$@"; }
dfanalytics() { _df_run dotfiles-analytics.sh "$@"; }

# Vault
vault() { _df_run dotfiles-vault.sh "$@"; }
vls()   { _df_run dotfiles-vault.sh list "$@"; }
vget()  { _df_run dotfiles-vault.sh get "$@"; }
vset()  { _df_run dotfiles-vault.sh set "$@"; }

# Compile
dfcompile() { _df_run dotfiles-compile.sh "$@"; }

# ============================================================================
# NEW: Profile & Performance
# ============================================================================

dfprofile() { _df_run dotfiles-profile.sh "$@"; }
alias profile='dfprofile'
alias startup-time='dfprofile --quick'

# ============================================================================
# NEW: Diff & Audit
# ============================================================================

dfdiff()  { _df_run dotfiles-diff.sh "$@"; }
dfaudit() { _df_run dotfiles-diff.sh --audit "$@"; }
alias audit='dfaudit'

# ============================================================================
# NEW: Tour & First-Run
# ============================================================================

dftour() { _df_run dotfiles-tour.sh "$@"; }
alias tour='dftour'
alias quickref='dftour --quick'

# ============================================================================
# Quick Edit Aliases
# ============================================================================

alias v.zshrc='${EDITOR:-vim} ~/.zshrc'
alias v.conf='${EDITOR:-vim} ~/.dotfiles/dotfiles.conf'
alias v.edit='cd ~/.dotfiles && ${EDITOR:-vim} .'
alias v.alias='${EDITOR:-vim} ~/.dotfiles/zsh/aliases.zsh'
alias v.motd='${EDITOR:-vim} ~/.dotfiles/zsh/functions/motd.zsh'
alias v.theme='${EDITOR:-vim} ~/.dotfiles/zsh/themes/adlee.zsh-theme'

# NEW: Edit machine config
alias v.machine='${EDITOR:-vim} ~/.dotfiles/machines/${DF_HOSTNAME:-$(hostname -s)}.zsh'

# ============================================================================
# Reload Aliases
# ============================================================================

alias reload='source ~/.zshrc'
alias rl='source ~/.zshrc'

# ============================================================================
# Dotfiles CLI
# ============================================================================

dotfiles-cli() {
    case "${1:-help}" in
        doctor|doc|d)    shift; _df_run dotfiles-doctor.sh "$@" ;;
        sync|s)          shift; _df_run dotfiles-sync.sh "$@" ;;
        update|up|u)     shift; _df_run dotfiles-update.sh "$@" ;;
        version|ver|v)   shift; _df_run dotfiles-version.sh "$@" ;;
        stats|st)        shift; _df_run dotfiles-stats.sh "$@" ;;
        analytics|an)    shift; _df_run dotfiles-analytics.sh "$@" ;;
        vault|vlt)       shift; _df_run dotfiles-vault.sh "$@" ;;
        compile|comp)    shift; _df_run dotfiles-compile.sh "$@" ;;
        profile|prof)    shift; _df_run dotfiles-profile.sh "$@" ;;
        diff|df)         shift; _df_run dotfiles-diff.sh "$@" ;;
        audit|aud)       shift; _df_run dotfiles-diff.sh --audit "$@" ;;
        tour|t)          shift; _df_run dotfiles-tour.sh "$@" ;;
        test)            shift; zsh ~/.dotfiles/tests/run-tests.zsh "$@" ;;
        edit|e)          cd ~/.dotfiles && ${EDITOR:-vim} . ;;
        cd)              cd ~/.dotfiles ;;
        help|--help|-h|*)
            cat << 'EOF'
Dotfiles CLI - Extended

Usage: dotfiles-cli <command> [args]

Core Commands:
  doctor, d       Health check (--fix to repair)
  sync, s         Sync dotfiles across machines
  update, u       Pull latest and reinstall
  version, v      Show version info
  stats, st       Basic shell analytics
  vault, vlt      Secrets management
  compile         Compile zsh files for speed

New Commands:
  analytics, an   Enhanced shell analytics
  profile, prof   Startup time profiling
  diff, df        Show changes and compare
  audit, aud      Security audit
  tour, t         Interactive tour / help
  test            Run test suite

Navigation:
  edit, e         Open dotfiles in editor
  cd              Change to dotfiles directory

Aliases: dfd, dffix, dfs, dfpush, dfpull, dfu, dfv, dfstats, vault
         dfprofile, dfdiff, dfaudit, dftour

EOF
            ;;
    esac
}

alias dfc='dotfiles-cli'

# ============================================================================
# System Utilities
# ============================================================================

# Use glow for markdown
alias glow='glow -p'
less() {
    if command -v glow &>/dev/null && [[ $# -eq 1 && "$1" == *.md ]]; then
        glow -p "$1"
    else
        command less "$@"
    fi
}

# Arch system upgrade with snapper
sys-update() {
    local update_date=$(date +"%Y-%m-%d %H:%M")
    if command -v snapper &>/dev/null; then
        sudo snapper -c root create --description "System Update ${update_date}" --command "sudo pacman -Syu"
    else
        sudo pacman -Syu
    fi
    # Update package count for prompt
    command -v checkupdates &>/dev/null && export UPDATE_PKG_COUNT=$(checkupdates 2>/dev/null | wc -l)
}

# ============================================================================
# Testing
# ============================================================================

alias dftest='zsh ~/.dotfiles/tests/run-tests.zsh'
alias test-dotfiles='dftest'
