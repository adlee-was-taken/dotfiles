# ============================================================================
# Shared Utility Functions for Zsh Dotfiles
# ============================================================================
# Common helper functions used across multiple function files
# Note: colors.zsh provides: DF_* color variables and df_print_func_name
#
# Source this file in function files:
#   source "${0:A:h}/../lib/utils.zsh"
# ============================================================================

# Ensure colors are loaded first (provides DF_* vars and df_print_func_name)
source "${0:A:h}/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null

# ============================================================================
# Output Formatting Functions
# ============================================================================

# Print a step/action indicator (blue arrow)
df_print_step() { echo -e "${DF_BLUE}==>${DF_NC} $1"; }

# Print a success message (green checkmark)
df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }

# Print an error message (red X)
df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1"; }

# Print a warning message (yellow warning sign)
df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }

# Print an info message (cyan info icon)
df_print_info() { echo -e "${DF_CYAN}ℹ${DF_NC} $1"; }

# Print a section header (cyan label)
df_print_section() { echo -e "${DF_CYAN}$1:${DF_NC}"; }

# Print indented content
df_print_indent() { echo "  $1"; }

# ============================================================================
# Command Dependency Checking
# ============================================================================

# Check if a command exists
df_cmd_exists() { command -v "$1" &>/dev/null; }

# Require a command, show install hint if missing
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

# Ask for yes/no confirmation (defaults to no)
df_confirm() {
    local prompt="$1"
    read -q "REPLY?$prompt [y/N]: "
    echo
    [[ "$REPLY" =~ ^[Yy]$ ]]
}

# Confirm with warning prefix
df_confirm_warning() {
    df_print_warning "$1"
    df_confirm "Continue?"
}

# ============================================================================
# File/Directory Helpers
# ============================================================================

# Check if in a git repo
df_in_git_repo() { git rev-parse --git-dir &>/dev/null 2>&1; }

# Get git root directory
df_git_root() { git rev-parse --show-toplevel 2>/dev/null; }

# Ensure directory exists
df_ensure_dir() { [[ ! -d "$1" ]] && mkdir -p "$1"; }

# Ensure file exists with optional default content
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
