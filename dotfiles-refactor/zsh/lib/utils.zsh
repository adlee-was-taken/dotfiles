# ============================================================================
# Shared Utility Functions for Zsh Dotfiles
# ============================================================================
# Common helper functions used across multiple function files.
#
# This file is typically sourced via bootstrap.zsh, which handles loading
# config.zsh and colors.zsh first.
#
# Direct usage (if needed):
#   source "${0:A:h}/../lib/utils.zsh"
# ============================================================================

# Prevent double-sourcing
[[ -n "$_DF_UTILS_LOADED" ]] && return 0
typeset -g _DF_UTILS_LOADED=1

# ============================================================================
# Source Dependencies (if not already loaded via bootstrap)
# ============================================================================

_df_lib_dir="${0:A:h}"
[[ ! -d "$_df_lib_dir" ]] && _df_lib_dir="$HOME/.dotfiles/zsh/lib"

# Source config if not already loaded
[[ -z "$_DF_CONFIG_LOADED" ]] && {
    source "${_df_lib_dir}/config.zsh" 2>/dev/null || \
    source "$HOME/.dotfiles/zsh/lib/config.zsh" 2>/dev/null || {
        typeset -g DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
        typeset -g DOTFILES_HOME="${DOTFILES_HOME:-$DOTFILES_DIR}"
        typeset -g DOTFILES_VERSION="${DOTFILES_VERSION:-unknown}"
        typeset -g DF_WIDTH="${DF_WIDTH:-66}"
    }
}

# Source colors if not already loaded
[[ -z "$_DF_COLORS_LOADED" ]] && {
    source "${_df_lib_dir}/colors.zsh" 2>/dev/null || \
    source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
        typeset -g DF_RED=$'\033[0;31m' DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
        typeset -g DF_BLUE=$'\033[0;34m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
        typeset -g DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
        typeset -g DF_LIGHT_GREEN=$'\033[38;5;82m' DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
    }
}

unset _df_lib_dir

# ============================================================================
# Header Box Drawing (Centralized Implementation)
# ============================================================================
# These functions eliminate header duplication across all scripts.

# Build a horizontal line of specified character and width
# Usage: _df_hline "═" 66
_df_hline() {
    local char="${1:-═}"
    local width="${2:-$DF_WIDTH}"
    local line=""
    for ((i=0; i<width; i++)); do line+="$char"; done
    echo "$line"
}

# Print a MOTD-style header box for scripts
# Usage: df_print_header "script-name"
df_print_header() {
    local script_name="${1:-script}"
    local user="${USER:-root}"
    local hostname="${HOST:-${HOSTNAME:-$(hostname -s 2>/dev/null)}}"
    local datetime=$(date '+%a %b %d %H:%M')
    local width="${DF_WIDTH:-66}"

    # Build horizontal line
    local hline=$(_df_hline "═" "$width")
    local inner=$((width - 2))

    # Header content
    local h_left="✦ ${user}@${hostname}"
    local h_center="${script_name}"
    local h_right="${datetime}"
    
    # Calculate padding (distribute space evenly)
    local content_len=$((${#h_left} + ${#h_center} + ${#h_right}))
    local total_padding=$((inner - content_len))
    local left_pad=$((total_padding / 2))
    local right_pad=$((total_padding - left_pad))
    
    # Build padding strings
    local left_spaces="" right_spaces=""
    for ((i=0; i<left_pad; i++)); do left_spaces+=" "; done
    for ((i=0; i<right_pad; i++)); do right_spaces+=" "; done

    # Use red for root, light blue for normal users
    local user_color="${DF_LIGHT_BLUE}"
    [[ "${EUID:-$(id -u)}" -eq 0 ]] && user_color="${DF_RED}"

    echo ""
    echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
    echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${user_color}${h_left}${DF_NC}${left_spaces}${DF_LIGHT_GREEN}${h_center}${right_spaces}${DF_NC}${DF_BOLD}${h_right}${DF_NC} ${DF_GREY}│${DF_NC}"
    echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
    echo ""
}

# Print a header box for functions (simpler, no user@host)
# Usage: df_print_func_name "Function Name"
df_print_func_name() {
    local func_name="${1:-func}"
    local datetime=$(date '+%a %b %d %H:%M')
    local width="${DF_WIDTH:-66}"

    # Build horizontal line
    local hline=$(_df_hline "═" "$width")
    local inner=$((width - 2))

    # Header content (function name on left, datetime on right)
    local h_left="${func_name}"
    local h_right="${datetime}"
    local h_pad=$((inner - ${#h_left} - ${#h_right}))
    
    local h_spaces=""
    for ((i=0; i<h_pad; i++)); do h_spaces+=" "; done

    echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
    echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}${h_left}${DF_NC}${h_spaces}${DF_BOLD}${h_right}${DF_NC} ${DF_GREY}│${DF_NC}"
    echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
}

# Print a simple section divider line
# Usage: df_print_divider
df_print_divider() {
    local width="${DF_WIDTH:-66}"
    local line=$(_df_hline "─" "$width")
    echo -e "${DF_CYAN}${line}${DF_NC}"
}

# ============================================================================
# Output Formatting Functions
# ============================================================================

df_print_step() { echo -e "${DF_BLUE}==>${DF_NC} $1"; }
df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
df_print_info() { echo -e "${DF_CYAN}ℹ${DF_NC} $1"; }
df_print_section() { echo -e "${DF_CYAN}$1:${DF_NC}"; }
df_print_indent() { echo "  $1"; }

# ============================================================================
# Command Dependency Checking
# ============================================================================

df_cmd_exists() { command -v "$1" &>/dev/null; }

df_require_cmd() {
    local cmd="$1"
    local package="${2:-$1}"
    
    if ! command -v "$cmd" &>/dev/null; then
        df_print_error "$cmd not installed"
        echo "Install: sudo pacman -S $package"
        return 1
    fi
    return 0
}

# ============================================================================
# User Confirmation
# ============================================================================

df_confirm() {
    local prompt="$1"
    local response
    
    if [[ -n "$ZSH_VERSION" ]]; then
        read -q "response?$prompt [y/N]: "
        echo
        [[ "$response" =~ ^[Yy]$ ]]
    else
        read -p "$prompt [y/N]: " response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

df_confirm_warning() {
    df_print_warning "$1"
    df_confirm "Continue?"
}

# ============================================================================
# File/Directory Helpers
# ============================================================================

df_in_git_repo() { git rev-parse --git-dir &>/dev/null 2>&1; }
df_git_root() { git rev-parse --show-toplevel 2>/dev/null; }
df_ensure_dir() { [[ ! -d "$1" ]] && mkdir -p "$1"; }

df_ensure_file() {
    local file="$1" content="${2:-}"
    if [[ ! -f "$file" ]]; then
        df_ensure_dir "$(dirname "$file")"
        [[ -n "$content" ]] && echo "$content" > "$file" || touch "$file"
    fi
}

# ============================================================================
# Environment Checks
# ============================================================================

df_in_tmux() { [[ -n "$TMUX" ]]; }
df_is_btrfs() { [[ "$(df -T / 2>/dev/null | awk 'NR==2 {print $2}')" == "btrfs" ]]; }

# ============================================================================
# FZF Helpers
# ============================================================================

df_fzf_opts() { echo "--height=50% --layout=reverse --border=rounded"; }
