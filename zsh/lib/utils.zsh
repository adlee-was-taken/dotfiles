# ============================================================================
# Shared Utility Functions for Zsh Dotfiles
# ============================================================================
# Common helper functions used across multiple function files
#
# Source this file in your .zshrc or in individual function files:
#   source "$HOME/.dotfiles/zsh/lib/utils.zsh"
#
# Provides:
#   - Standardized output formatting (step/success/error/warning/info)
#   - Command dependency checking
#   - User confirmation prompts
#   - Common file/directory operations
# ============================================================================

# Ensure colors are loaded first
source "${0:A:h}/colors.zsh" 2>/dev/null || {
    typeset -g DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m'
    typeset -g DF_RED=$'\033[0;31m' DF_BLUE=$'\033[0;34m'
    typeset -g DF_CYAN=$'\033[0;36m' DF_DIM=$'\033[2m' DF_NC=$'\033[0m'
}

# ============================================================================
# Output Formatting Functions
# ============================================================================
# These provide consistent, styled output across all dotfiles functions.
# Use these instead of raw echo statements for a unified look.

# Print a step/action indicator (blue arrow)
# Usage: df_print_step "Installing packages"
df_print_step() {
    echo -e "${DF_BLUE}==>${DF_NC} $1"
}

# Print a success message (green checkmark)
# Usage: df_print_success "Installation complete"
df_print_success() {
    echo -e "${DF_GREEN}✓${DF_NC} $1"
}

# Print an error message (red X)
# Usage: df_print_error "Failed to connect"
df_print_error() {
    echo -e "${DF_RED}✗${DF_NC} $1"
}

# Print a warning message (yellow warning sign)
# Usage: df_print_warning "Config file missing, using defaults"
df_print_warning() {
    echo -e "${DF_YELLOW}⚠${DF_NC} $1"
}

# Print an info message (cyan info icon)
# Usage: df_print_info "Using cached version"
df_print_info() {
    echo -e "${DF_CYAN}ℹ${DF_NC} $1"
}

# Print a section header (cyan, for grouping output)
# Usage: df_print_section "Configuration"
df_print_section() {
    echo -e "${DF_CYAN}$1:${DF_NC}"
}

# Print a bullet point item (green dot)
# Usage: df_print_item "my-alias" "git status"
df_print_item() {
    local name="$1"
    local description="${2:-}"
    if [[ -n "$description" ]]; then
        echo -e "  ${DF_GREEN}●${DF_NC} ${DF_CYAN}$name${DF_NC} - $description"
    else
        echo -e "  ${DF_GREEN}●${DF_NC} ${DF_CYAN}$name${DF_NC}"
    fi
}

# Print indented content (for sub-items)
# Usage: df_print_indent "Additional details here"
df_print_indent() {
    echo "  $1"
}

# Print a function name header (box style) - already defined in colors.zsh
# but ensure it's available
if ! typeset -f df_print_func_name &>/dev/null; then
    df_print_func_name() {
        local name="$1"
        local width=$((${#name} + 4))
        local border=$(printf '─%.0s' $(seq 1 $width))
        echo -e "${DF_CYAN}╭${border}╮${DF_NC}"
        echo -e "${DF_CYAN}│${DF_NC}  $name  ${DF_CYAN}│${DF_NC}"
        echo -e "${DF_CYAN}╰${border}╯${DF_NC}"
    }
fi

# ============================================================================
# Command Dependency Checking
# ============================================================================
# Check if required commands are available before running functions.

# Check if a command exists
# Usage: df_cmd_exists git && echo "git is installed"
df_cmd_exists() {
    command -v "$1" &>/dev/null
}

# Require a command, exit with error if missing
# Usage: df_require_cmd fzf || return 1
# Usage: df_require_cmd compsize "compsize" || return 1
df_require_cmd() {
    local cmd="$1"
    local package="${2:-$1}"  # Default to command name as package name
    
    if ! command -v "$cmd" &>/dev/null; then
        df_print_error "$cmd not installed"
        echo "Install: sudo pacman -S $package"
        return 1
    fi
    return 0
}

# Require multiple commands at once
# Usage: df_require_cmds git fzf tmux || return 1
df_require_cmds() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        df_print_error "Missing required commands: ${missing[*]}"
        echo "Install: sudo pacman -S ${missing[*]}"
        return 1
    fi
    return 0
}

# ============================================================================
# User Confirmation Prompts
# ============================================================================
# Consistent confirmation dialogs for dangerous operations.

# Ask for yes/no confirmation (defaults to no)
# Usage: df_confirm "Delete all files?" || return
df_confirm() {
    local prompt="$1"
    read -q "REPLY?$prompt [y/N]: "
    echo  # Newline after response
    [[ "$REPLY" =~ ^[Yy]$ ]]
}

# Ask for confirmation with a warning prefix
# Usage: df_confirm_warning "This will delete all data" || return
df_confirm_warning() {
    local message="$1"
    df_print_warning "$message"
    df_confirm "Continue?"
}

# ============================================================================
# File and Directory Helpers
# ============================================================================

# Check if running inside a git repository
# Usage: df_in_git_repo && echo "In a git repo"
df_in_git_repo() {
    git rev-parse --git-dir &>/dev/null 2>&1
}

# Get git root directory
# Usage: local root=$(df_git_root)
df_git_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

# Ensure a directory exists, create if missing
# Usage: df_ensure_dir "$HOME/.cache/myapp"
df_ensure_dir() {
    local dir="$1"
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
}

# Ensure a file exists with optional default content
# Usage: df_ensure_file "$HOME/.config/myapp/config" "# Default config"
df_ensure_file() {
    local file="$1"
    local default_content="${2:-}"
    
    if [[ ! -f "$file" ]]; then
        df_ensure_dir "$(dirname "$file")"
        if [[ -n "$default_content" ]]; then
            echo "$default_content" > "$file"
        else
            touch "$file"
        fi
    fi
}

# ============================================================================
# String Helpers
# ============================================================================

# Truncate a string to a maximum length
# Usage: df_truncate "Long string here" 10  # "Long st..."
df_truncate() {
    local str="$1"
    local max="${2:-50}"
    
    if [[ ${#str} -gt $max ]]; then
        echo "${str:0:$((max-3))}..."
    else
        echo "$str"
    fi
}

# Pad a string to a minimum length
# Usage: df_pad "short" 10  # "short     "
df_pad() {
    local str="$1"
    local width="${2:-20}"
    printf "%-${width}s" "$str"
}

# ============================================================================
# FZF Helpers
# ============================================================================

# Standard fzf options for consistent look
df_fzf_opts() {
    echo "--height=50% --layout=reverse --border=rounded"
}

# Run fzf with standard options
# Usage: echo -e "opt1\nopt2" | df_fzf "Select > "
df_fzf() {
    local prompt="${1:-Select > }"
    shift
    fzf $(df_fzf_opts) --prompt="$prompt" "$@"
}

# ============================================================================
# Environment Helpers
# ============================================================================

# Check if inside tmux
# Usage: df_in_tmux && echo "Inside tmux"
df_in_tmux() {
    [[ -n "$TMUX" ]]
}

# Check if root filesystem is btrfs
# Usage: df_is_btrfs && echo "Using btrfs"
df_is_btrfs() {
    [[ "$(df -T / | awk 'NR==2 {print $2}')" == "btrfs" ]]
}
