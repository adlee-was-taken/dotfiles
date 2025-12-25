# ============================================================================
# Shared Color Definitions for Dotfiles
# ============================================================================
# Source this file in scripts and functions to get consistent color support.
#
# Usage in zsh functions:
#   source "${0:A:h}/../lib/colors.zsh"
#
# Usage in bash scripts:
#   source "$HOME/.dotfiles/zsh/lib/colors.zsh"
#
# All variables are prefixed with DF_ (dotfiles) to avoid conflicts.
# ============================================================================

# Prevent double-sourcing
[[ -n "$_DF_COLORS_LOADED" ]] && return 0
typeset -g _DF_COLORS_LOADED=1

# ============================================================================
# Standard Colors (ANSI escape codes)
# ============================================================================

typeset -g DF_RED=$'\033[0;31m'
typeset -g DF_GREEN=$'\033[0;32m'
typeset -g DF_YELLOW=$'\033[1;33m'
typeset -g DF_BLUE=$'\033[0;34m'
typeset -g DF_MAGENTA=$'\033[0;35m'
typeset -g DF_CYAN=$'\033[0;36m'
typeset -g DF_WHITE=$'\033[0;37m'

# Bold variants
typeset -g DF_BOLD_RED=$'\033[1;31m'
typeset -g DF_BOLD_GREEN=$'\033[1;32m'
typeset -g DF_BOLD_YELLOW=$'\033[1;33m'
typeset -g DF_BOLD_BLUE=$'\033[1;34m'
typeset -g DF_BOLD_MAGENTA=$'\033[1;35m'
typeset -g DF_BOLD_CYAN=$'\033[1;36m'
typeset -g DF_BOLD_WHITE=$'\033[1;37m'

# Text styles
typeset -g DF_BOLD=$'\033[1m'
typeset -g DF_DIM=$'\033[2m'
typeset -g DF_ITALIC=$'\033[3m'
typeset -g DF_UNDERLINE=$'\033[4m'
typeset -g DF_RESET=$'\033[0m'
typeset -g DF_NC=$'\033[0m'  # Alias for reset (No Color)

# ============================================================================
# 256-Color Palette (used in theme and MOTD)
# ============================================================================

typeset -g DF_GREY=$'\033[38;5;242m'
typeset -g DF_LIGHT_GREY=$'\033[38;5;248m'
typeset -g DF_DARK_GREY=$'\033[38;5;239m'
typeset -g DF_ORANGE=$'\033[38;5;208m'
typeset -g DF_LIGHT_ORANGE=$'\033[38;5;220m'
typeset -g DF_PINK=$'\033[38;5;213m'
typeset -g DF_PURPLE=$'\033[38;5;141m'
typeset -g DF_LIGHT_BLUE=$'\033[38;5;39m'
typeset -g DF_LIGHT_GREEN=$'\033[38;5;82m'
typeset -g DF_BRIGHT_GREEN=$'\033[38;5;118m'
typeset -g DF_TEAL=$'\033[38;5;51m'

# ============================================================================
# Semantic Colors (for consistent UI)
# ============================================================================

typeset -g DF_SUCCESS="$DF_GREEN"
typeset -g DF_ERROR="$DF_RED"
typeset -g DF_WARNING="$DF_YELLOW"
typeset -g DF_INFO="$DF_CYAN"
typeset -g DF_HINT="$DF_DIM"
typeset -g DF_ACCENT="$DF_BLUE"
typeset -g DF_MUTED="$DF_GREY"

# ============================================================================
# Bash Compatibility
# ============================================================================

# For bash scripts, export as regular variables too
if [[ -n "$BASH_VERSION" ]]; then
    export DF_RED DF_GREEN DF_YELLOW DF_BLUE DF_MAGENTA DF_CYAN DF_WHITE
    export DF_BOLD DF_DIM DF_RESET DF_NC
    export DF_GREY DF_LIGHT_BLUE DF_LIGHT_GREEN
    export DF_SUCCESS DF_ERROR DF_WARNING DF_INFO
fi
