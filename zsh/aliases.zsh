# ============================================================================
# Dotfiles Command Aliases
# ============================================================================
# All dotfiles-*.sh script aliases and the unified dotfiles-cli interface.
#
# Scripts covered:
#   - dotfiles-doctor.sh      Health check and auto-fix
#   - dotfiles-sync.sh        Git sync operations
#   - dotfiles-update.sh      Pull and reinstall
#   - dotfiles-version.sh     Version information
#   - dotfiles-stats.sh       Basic shell statistics
#   - dotfiles-compile.sh     Compile zsh files
#   - dotfiles-vault.sh       Secrets management
#   - dotfiles-analytics.sh   Enhanced history analytics
#   - dotfiles-profile.sh     Startup time profiling
#   - dotfiles-diff.sh        Diff and security audit
#   - dotfiles-tour.sh        Interactive tour / first-run
# ============================================================================

# Dotfiles directory reference
_df_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
_df_bin="$_df_dir/bin"

# ============================================================================
# Helper Function
# ============================================================================

# Run dotfiles script with fallback
_df_run() {
    local script="$1"
    shift
    if [[ -x "$_df_bin/$script" ]]; then
        "$_df_bin/$script" "$@"
    elif [[ -x "$HOME/.local/bin/$script" ]]; then
        "$HOME/.local/bin/$script" "$@"
    elif command -v "$script" &>/dev/null; then
        "$script" "$@"
    else
        echo "Error: $script not found in $_df_bin or PATH" >&2
        return 1
    fi
}

# ============================================================================
# Navigation Aliases
# ============================================================================

alias dfdir='cd $HOME/.dotfiles'
alias c.='cd $HOME/.dotfiles'

# ============================================================================
# Doctor - Health Check
# ============================================================================

dfd()    { _df_run dotfiles-doctor.sh "$@"; }
doctor() { _df_run dotfiles-doctor.sh "$@"; }
dffix()  { _df_run dotfiles-doctor.sh --fix "$@"; }

# ============================================================================
# Sync - Git Operations
# ============================================================================

dfs()      { _df_run dotfiles-sync.sh "$@"; }
dfpush()   { _df_run dotfiles-sync.sh push "${1:-Dotfiles update $(date '+%Y-%m-%d %H:%M')}"; }
dfpull()   { _df_run dotfiles-sync.sh pull "$@"; }
dfstatus() { _df_run dotfiles-sync.sh status "$@"; }

# ============================================================================
# Update - Pull & Reinstall
# ============================================================================

dfu()      { _df_run dotfiles-update.sh "$@"; }
dfupdate() { _df_run dotfiles-update.sh "$@"; }

# ============================================================================
# Version
# ============================================================================

dfv()       { _df_run dotfiles-version.sh "$@"; }
dfversion() { _df_run dotfiles-version.sh "$@"; }

# ============================================================================
# Stats - Basic Statistics
# ============================================================================

dfstats() { _df_run dotfiles-stats.sh "$@"; }

# ============================================================================
# Compile - Zsh Compilation
# ============================================================================

dfcompile() { _df_run dotfiles-compile.sh "$@"; }

# ============================================================================
# Vault - Secrets Management
# ============================================================================

vault() { _df_run dotfiles-vault.sh "$@"; }
vls()   { _df_run dotfiles-vault.sh list "$@"; }
vget()  { _df_run dotfiles-vault.sh get "$@"; }
vset()  { _df_run dotfiles-vault.sh set "$@"; }

# ============================================================================
# Analytics - Enhanced History Analytics
# ============================================================================

dfanalytics() { _df_run dotfiles-analytics.sh "$@"; }
alias analytics='dfanalytics'

# Analytics subcommands
alias dfan='dfanalytics'
alias dfan-hourly='dfanalytics hourly'
alias dfan-weekly='dfanalytics weekly'
alias dfan-projects='dfanalytics projects'
alias dfan-trends='dfanalytics trends'
alias dfan-tools='dfanalytics tools'
alias dfan-suggest='dfanalytics suggestions'

# ============================================================================
# Profile - Startup Time Profiling
# ============================================================================

dfprofile() { _df_run dotfiles-profile.sh "$@"; }
alias profile='dfprofile'
alias startup-time='dfprofile --quick'
alias dfprof='dfprofile'

# Profile subcommands
alias dfprof-detailed='dfprofile --detailed'
alias dfprof-benchmark='dfprofile --benchmark'
alias dfprof-compare='dfprofile --compare'
alias dfprof-tips='dfprofile --tips'

# ============================================================================
# Diff - Changes & Security Audit
# ============================================================================

dfdiff()  { _df_run dotfiles-diff.sh "$@"; }
dfaudit() { _df_run dotfiles-diff.sh --audit "$@"; }
alias audit='dfaudit'

# Diff subcommands
alias dfdiff-installed='dfdiff --installed'
alias dfdiff-symlinks='dfdiff --symlinks'
alias dfdiff-secrets='dfdiff --secrets'
alias dfdiff-permissions='dfdiff --permissions'
alias dfdiff-machines='dfdiff --machines'

# ============================================================================
# Tour - Interactive Help & First-Run
# ============================================================================

dftour() { _df_run dotfiles-tour.sh "$@"; }
alias tour='dftour'
alias quickref='dftour --quick'
alias dfchangelog='dftour --changelog'

# ============================================================================
# Testing
# ============================================================================

dftest() {
    local test_dir="${DOTFILES_DIR:-$HOME/.dotfiles}/tests"
    if [[ -f "$test_dir/run-tests.zsh" ]]; then
        zsh "$test_dir/run-tests.zsh" "$@"
    else
        echo "Test runner not found at $test_dir/run-tests.zsh" >&2
        return 1
    fi
}
alias test-dotfiles='dftest'

# ============================================================================
# Quick Edit Aliases
# ============================================================================

alias v.zshrc='${EDITOR:-vim} ~/.zshrc'
alias v.conf='${EDITOR:-vim} ~/.dotfiles/dotfiles.conf'
alias v.edit='cd ~/.dotfiles && ${EDITOR:-vim} .'
alias v.alias='${EDITOR:-vim} ~/.dotfiles/zsh/aliases.zsh'
alias v.motd='${EDITOR:-vim} ~/.dotfiles/zsh/functions/motd.zsh'
alias v.theme='${EDITOR:-vim} ~/.dotfiles/zsh/themes/adlee.zsh-theme'
alias v.machine='${EDITOR:-vim} ~/.dotfiles/machines/${DF_HOSTNAME:-$(hostname -s)}.zsh'

if [[ ${DEFAULT_EDITOR} = "nvim" ]]; then
    alias vim='nvim'
    alias vimc='/usr/bin/vim'
else
    alias vim='/usr/bin/vim'
fi

# ============================================================================
# Reload
# ============================================================================

alias reload='source ~/.zshrc'
alias rl='source ~/.zshrc'

# ============================================================================
# Dotfiles CLI - Unified Interface
# ============================================================================

dotfiles-cli() {
    case "${1:-help}" in
        # Core commands
        doctor|doc|d)
            shift; _df_run dotfiles-doctor.sh "$@" ;;
        sync|s)
            shift; _df_run dotfiles-sync.sh "$@" ;;
        update|up|u)
            shift; _df_run dotfiles-update.sh "$@" ;;
        version|ver|v)
            shift; _df_run dotfiles-version.sh "$@" ;;
        stats|st)
            shift; _df_run dotfiles-stats.sh "$@" ;;
        compile|comp|c)
            shift; _df_run dotfiles-compile.sh "$@" ;;
        vault|vlt)
            shift; _df_run dotfiles-vault.sh "$@" ;;

        # New commands
        analytics|an)
            shift; _df_run dotfiles-analytics.sh "$@" ;;
        profile|prof|p)
            shift; _df_run dotfiles-profile.sh "$@" ;;
        diff|df)
            shift; _df_run dotfiles-diff.sh "$@" ;;
        audit|aud|a)
            shift; _df_run dotfiles-diff.sh --audit "$@" ;;
        tour|t)
            shift; _df_run dotfiles-tour.sh "$@" ;;
        test)
            shift; dftest "$@" ;;

        # Navigation
        edit|e)
            cd "${DOTFILES_DIR:-$HOME/.dotfiles}" && ${EDITOR:-vim} . ;;
        cd)
            cd "${DOTFILES_DIR:-$HOME/.dotfiles}" ;;

        # Help
        help|--help|-h|*)
            cat << 'EOF'
Dotfiles CLI - Unified Interface

Usage: dotfiles-cli <command> [args]
       dfc <command> [args]

Core Commands:
  doctor, d       Health check (--fix to repair)
  sync, s         Git sync (push/pull/status)
  update, u       Pull latest and reinstall
  version, v      Show version info
  stats, st       Basic shell statistics
  compile, c      Compile zsh files for speed
  vault, vlt      Secrets management

Analytics & Diagnostics:
  analytics, an   Enhanced history analytics
                    Subcommands: hourly, weekly, projects, trends, tools, suggestions
  profile, p      Startup time profiling
                    Options: --quick, --detailed, --benchmark, --compare, --tips
  diff, df        Show uncommitted changes
                    Options: --installed, --symlinks, --secrets, --permissions
  audit, a        Full security audit

Help & Testing:
  tour, t         Interactive tour / first-run experience
                    Options: --quick (reference card), --changelog
  test            Run test suite

Navigation:
  edit, e         Open dotfiles in editor
  cd              Change to dotfiles directory

Quick Aliases:
  dfd             doctor
  dffix           doctor --fix
  dfs             sync
  dfpush          sync push
  dfpull          sync pull
  dfu             update
  dfv             version
  dfstats         stats
  dfcompile       compile
  vault           vault
  dfanalytics     analytics
  dfprofile       profile
  dfdiff          diff
  dfaudit         audit
  dftour          tour
  dftest          test

Examples:
  dfc doctor --fix      # Health check with auto-fix
  dfc sync push         # Push changes to remote
  dfc analytics weekly  # Show weekly usage patterns
  dfc profile --tips    # Get startup optimization tips
  dfc audit             # Run full security audit
  dfc tour --quick      # Show quick reference card

EOF
            ;;
    esac
}

# Short alias for dotfiles-cli
alias dfc='dotfiles-cli'

# ============================================================================
# Convenience Aliases
# ============================================================================

# Quality of life
alias hist="history"
alias cls="clear"
alias q="exit"
alias vm="mv"

# Docker Stuff
dkr-rbld() {
    sudo docker-compose down
    sudo docker-compose up --build -d
}


# Markdown viewer with glow
if command -v glow &>/dev/null; then
    alias glow='glow -p'
    less() {
        if [[ $# -eq 1 && "$1" == *.md ]]; then
            glow -p "$1"
        else
            command less "$@"
        fi
    }
fi
