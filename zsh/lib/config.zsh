# ============================================================================
# Dotfiles Configuration Loader
# ============================================================================
# This file loads dotfiles.conf and sets up all configuration variables.
# It serves as the bridge between dotfiles.conf and the rest of the system.
#
# Source this file to get access to all configuration:
#   source "${0:A:h}/config.zsh"
#
# This file:
#   1. Finds and sources dotfiles.conf
#   2. Sets sensible defaults for any missing values
#   3. Exports variables for use in subshells/scripts
# ============================================================================

# Prevent double-sourcing
[[ -n "$_DF_CONFIG_LOADED" ]] && return 0

# ============================================================================
# Find and Source dotfiles.conf
# ============================================================================

_df_find_config() {
    local locations=(
        "${DOTFILES_DIR}/dotfiles.conf"
        "${DOTFILES_HOME}/dotfiles.conf"
        "$HOME/.dotfiles/dotfiles.conf"
        "${0:A:h}/../../dotfiles.conf"
    )
    
    for loc in "${locations[@]}"; do
        [[ -f "$loc" ]] && { echo "$loc"; return 0; }
    done
    return 1
}

_DF_CONFIG_FILE=$(_df_find_config)

if [[ -n "$_DF_CONFIG_FILE" && -f "$_DF_CONFIG_FILE" ]]; then
    source "$_DF_CONFIG_FILE"
    typeset -g _DF_CONFIG_LOADED=1
else
    # Config file not found - set critical defaults
    typeset -g _DF_CONFIG_LOADED=1
fi

# ============================================================================
# Set Defaults for Any Missing Values
# ============================================================================
# These defaults ensure scripts work even if dotfiles.conf is incomplete

# Core Settings
typeset -g DOTFILES_VERSION="${DOTFILES_VERSION:-1.0.0}"
typeset -g DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
typeset -g DOTFILES_HOME="${DOTFILES_HOME:-$DOTFILES_DIR}"  # Alias for compatibility
typeset -g DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
typeset -g DOTFILES_BACKUP_PREFIX="${DOTFILES_BACKUP_PREFIX:-$HOME/.dotfiles_backup}"

# GitHub Settings
typeset -g DOTFILES_GITHUB_USER="${DOTFILES_GITHUB_USER:-adlee-was-taken}"
typeset -g DOTFILES_REPO_NAME="${DOTFILES_REPO_NAME:-dotfiles}"
typeset -g DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/${DOTFILES_GITHUB_USER}/${DOTFILES_REPO_NAME}.git}"
typeset -g DOTFILES_RAW_URL="${DOTFILES_RAW_URL:-https://raw.githubusercontent.com/${DOTFILES_GITHUB_USER}/${DOTFILES_REPO_NAME}/${DOTFILES_BRANCH}}"

# Display Settings
typeset -g DF_WIDTH="${DF_WIDTH:-66}"
typeset -g ENABLE_MOTD="${ENABLE_MOTD:-true}"
typeset -g MOTD_STYLE="${MOTD_STYLE:-compact}"
typeset -g MOTD_SHOW_FAILED_SERVICES="${MOTD_SHOW_FAILED_SERVICES:-true}"
typeset -g MOTD_SHOW_UPDATES="${MOTD_SHOW_UPDATES:-true}"

# Theme Settings
typeset -g ZSH_THEME_NAME="${ZSH_THEME_NAME:-adlee}"
typeset -g THEME_TIMER_THRESHOLD="${THEME_TIMER_THRESHOLD:-10}"
typeset -g THEME_PATH_TRUNCATE_LENGTH="${THEME_PATH_TRUNCATE_LENGTH:-32}"

# Feature Toggles
typeset -g ENABLE_SMART_SUGGESTIONS="${ENABLE_SMART_SUGGESTIONS:-true}"
typeset -g ENABLE_COMMAND_PALETTE="${ENABLE_COMMAND_PALETTE:-true}"
typeset -g ENABLE_SHELL_ANALYTICS="${ENABLE_SHELL_ANALYTICS:-false}"
typeset -g ENABLE_VAULT="${ENABLE_VAULT:-true}"
typeset -g DOTFILES_AUTO_SYNC_CHECK="${DOTFILES_AUTO_SYNC_CHECK:-true}"

# Btrfs Settings
typeset -g BTRFS_DEFAULT_MOUNT="${BTRFS_DEFAULT_MOUNT:-/}"

# Snapper Settings
typeset -g SNAPPER_CONFIG="${SNAPPER_CONFIG:-root}"
typeset -g LIMINE_CONF="${LIMINE_CONF:-/boot/limine.conf}"

# Tmux Settings
typeset -g TW_SESSION_PREFIX="${TW_SESSION_PREFIX:-work}"
typeset -g TW_DEFAULT_TEMPLATE="${TW_DEFAULT_TEMPLATE:-dev}"

# Python Template Settings
typeset -g PY_TEMPLATE_BASE_DIR="${PY_TEMPLATE_BASE_DIR:-$HOME/projects}"
typeset -g PY_TEMPLATE_PYTHON="${PY_TEMPLATE_PYTHON:-python3}"
typeset -g PY_TEMPLATE_VENV_NAME="${PY_TEMPLATE_VENV_NAME:-venv}"
typeset -g PY_TEMPLATE_USE_POETRY="${PY_TEMPLATE_USE_POETRY:-false}"
typeset -g PY_TEMPLATE_GIT_INIT="${PY_TEMPLATE_GIT_INIT:-true}"

# SSH Settings
typeset -g SSH_AUTO_TMUX="${SSH_AUTO_TMUX:-true}"
typeset -g SSH_TMUX_SESSION_PREFIX="${SSH_TMUX_SESSION_PREFIX:-ssh}"
typeset -g SSH_SYNC_DOTFILES="${SSH_SYNC_DOTFILES:-ask}"

# Password Manager Settings
typeset -g PW_CLIP_TIME="${PW_CLIP_TIME:-45}"

# Package Manager
typeset -g AUR_HELPER="${AUR_HELPER:-auto}"

# Git Settings (with fallbacks to user identity)
typeset -g GIT_USER_NAME="${GIT_USER_NAME:-$USER_FULLNAME}"
typeset -g GIT_USER_EMAIL="${GIT_USER_EMAIL:-$USER_EMAIL}"
typeset -g GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-main}"

# ============================================================================
# Export for Bash Scripts
# ============================================================================
# Bash scripts can't see typeset -g, so we export key variables

export DOTFILES_VERSION DOTFILES_DIR DOTFILES_HOME DOTFILES_BRANCH
export DOTFILES_GITHUB_USER DOTFILES_REPO_NAME DOTFILES_REPO_URL DOTFILES_RAW_URL
export DF_WIDTH MOTD_STYLE
export ZSH_THEME_NAME

# ============================================================================
# Helper Function: Get Config Value
# ============================================================================
# Usage: df_config "VARIABLE_NAME" "default_value"

df_config() {
    local var_name="$1"
    local default="$2"
    local value="${(P)var_name}"
    echo "${value:-$default}"
}

# ============================================================================
# Helper Function: Show Config Summary
# ============================================================================

df_show_config() {
    echo "Dotfiles Configuration"
    echo "======================"
    echo "Config File:    ${_DF_CONFIG_FILE:-not found}"
    echo "Version:        $DOTFILES_VERSION"
    echo "Directory:      $DOTFILES_DIR"
    echo "Branch:         $DOTFILES_BRANCH"
    echo "Display Width:  $DF_WIDTH"
    echo "MOTD Style:     $MOTD_STYLE"
    echo "Theme:          $ZSH_THEME_NAME"
}
