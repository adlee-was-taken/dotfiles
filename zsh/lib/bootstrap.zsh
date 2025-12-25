# ============================================================================
# Dotfiles Bootstrap - Single Entry Point
# ============================================================================
# This is the ONE file to source in all scripts and functions.
# It handles loading config, colors, and utils in the correct order with
# proper fallbacks.
#
# Usage in zsh functions:
#   source "${0:A:h}/../lib/bootstrap.zsh"
#
# Usage in bash scripts:
#   source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh"
#
# After sourcing, you have access to:
#   - All DF_* color variables
#   - All df_print_* functions
#   - All df_* utility functions
#   - All config variables from dotfiles.conf
# ============================================================================

# Prevent double-sourcing (works in both bash and zsh)
[[ -n "$_DF_BOOTSTRAP_LOADED" ]] && return 0

# ============================================================================
# Determine Dotfiles Root
# ============================================================================

_df_find_root() {
    # Check common locations in order of preference
    local locations=(
        "${DOTFILES_DIR}"
        "${DOTFILES_HOME}"
        "$HOME/.dotfiles"
    )
    
    for loc in "${locations[@]}"; do
        [[ -n "$loc" && -d "$loc" && -f "$loc/dotfiles.conf" ]] && {
            echo "$loc"
            return 0
        }
    done
    
    # Fallback: try to find from script location (zsh)
    if [[ -n "$ZSH_VERSION" ]]; then
        local script_dir="${0:A:h}"
        # Walk up looking for dotfiles.conf
        while [[ "$script_dir" != "/" ]]; do
            [[ -f "$script_dir/dotfiles.conf" ]] && { echo "$script_dir"; return 0; }
            script_dir="${script_dir:h}"
        done
    fi
    
    # Last resort
    echo "$HOME/.dotfiles"
}

# Set the root directory
typeset -g _DF_ROOT="$(_df_find_root)"
typeset -g DOTFILES_DIR="$_DF_ROOT"
typeset -g DOTFILES_HOME="$_DF_ROOT"

# ============================================================================
# Source Core Files (in correct order)
# ============================================================================

# 1. Config first (sets DF_WIDTH, MOTD_STYLE, etc.)
if [[ -f "$_DF_ROOT/zsh/lib/config.zsh" ]]; then
    source "$_DF_ROOT/zsh/lib/config.zsh"
else
    # Minimal fallback config
    typeset -g DOTFILES_VERSION="${DOTFILES_VERSION:-1.0.0}"
    typeset -g DF_WIDTH="${DF_WIDTH:-66}"
    typeset -g MOTD_STYLE="${MOTD_STYLE:-compact}"
    typeset -g DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
fi

# 2. Colors second
if [[ -f "$_DF_ROOT/zsh/lib/colors.zsh" ]]; then
    source "$_DF_ROOT/zsh/lib/colors.zsh"
else
    # Minimal fallback colors
    typeset -g DF_RED=$'\033[0;31m'
    typeset -g DF_GREEN=$'\033[0;32m'
    typeset -g DF_YELLOW=$'\033[1;33m'
    typeset -g DF_BLUE=$'\033[0;34m'
    typeset -g DF_CYAN=$'\033[0;36m'
    typeset -g DF_NC=$'\033[0m'
    typeset -g DF_GREY=$'\033[38;5;242m'
    typeset -g DF_LIGHT_BLUE=$'\033[38;5;39m'
    typeset -g DF_LIGHT_GREEN=$'\033[38;5;82m'
    typeset -g DF_BOLD=$'\033[1m'
    typeset -g DF_DIM=$'\033[2m'
fi

# 3. Utils last (depends on config and colors)
if [[ -f "$_DF_ROOT/zsh/lib/utils.zsh" ]]; then
    source "$_DF_ROOT/zsh/lib/utils.zsh"
fi

# ============================================================================
# Ensure Critical Functions Exist
# ============================================================================
# If utils.zsh failed to load, provide minimal implementations

if ! declare -f df_print_header &>/dev/null; then
    df_print_header() {
        local name="${1:-script}"
        echo ""
        echo "=== ${name} ==="
        echo ""
    }
fi

if ! declare -f df_print_func_name &>/dev/null; then
    df_print_func_name() {
        echo "--- ${1:-function} ---"
    }
fi

if ! declare -f df_print_success &>/dev/null; then
    df_print_success() { echo "✓ $1"; }
    df_print_error() { echo "✗ $1" >&2; }
    df_print_warning() { echo "⚠ $1"; }
    df_print_info() { echo "ℹ $1"; }
    df_print_step() { echo "==> $1"; }
fi

# ============================================================================
# Mark as Loaded
# ============================================================================

typeset -g _DF_BOOTSTRAP_LOADED=1

# Export for subshells (bash compatibility)
export DOTFILES_DIR DOTFILES_HOME DOTFILES_VERSION DF_WIDTH
