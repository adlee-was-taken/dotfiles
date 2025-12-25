# ============================================================================
# FZF-Powered Utilities
# ============================================================================
# Additional fuzzy finders for various system exploration tasks.
#
# Features:
#   - envf: Environment variable browser
#   - pathf: PATH explorer
#   - procf: Process manager
#   - aliasf: Alias browser
#   - funcf: Function browser
#   - histf: Enhanced history search
# ============================================================================

# Prevent double-sourcing
[[ -n "$_DF_FZF_EXTRAS_LOADED" ]] && return 0
typeset -g _DF_FZF_EXTRAS_LOADED=1

# Source utils
source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null || {
    # Fallback definitions
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_CYAN=$'\033[0;36m' DF_BLUE=$'\033[0;34m' DF_NC=$'\033[0m'
    df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
    df_print_info() { echo -e "${DF_CYAN}ℹ${DF_NC} $1"; }
    df_print_step() { echo -e "${DF_BLUE}==>${DF_NC} $1"; }
    df_print_section() { echo -e "${DF_CYAN}$1:${DF_NC}"; }
}

# ============================================================================
# Check FZF
# ============================================================================

_fzf_check() {
    if ! command -v fzf &>/dev/null; then
        df_print_error "fzf not installed"
        df_print_info "Install: sudo pacman -S fzf"
        return 1
    fi
    return 0
}

# Common fzf options
_fzf_common_opts() {
    echo "--height=60% --layout=reverse --border=rounded --info=inline"
}

# ============================================================================
# Environment Variable Browser
# ============================================================================

envf() {
    _fzf_check || return 1
    
    local selected=$(env | sort | fzf $(_fzf_common_opts) \
        --prompt="Env > " \
        --preview='echo {} | cut -d= -f1 | xargs -I{} bash -c "echo -e \"Variable: {}\n\nValue:\n\"; printenv {}"' \
        --preview-window=right:50%:wrap \
        --header="Enter: copy value | Ctrl-E: edit | Ctrl-U: unset")
    
    [[ -z "$selected" ]] && return
    
    local var_name="${selected%%=*}"
    local var_value="${selected#*=}"
    
    echo ""
    echo -e "${DF_CYAN}$var_name${DF_NC}=$var_value"
    echo ""
    
    # Copy to clipboard if available
    if command -v wl-copy &>/dev/null; then
        echo -n "$var_value" | wl-copy
        df_print_success "Value copied to clipboard"
    elif command -v xclip &>/dev/null; then
        echo -n "$var_value" | xclip -selection clipboard
        df_print_success "Value copied to clipboard"
    fi
}

# Set/edit environment variable interactively
env-set() {
    local var_name="$1"
    
    if [[ -z "$var_name" ]]; then
        _fzf_check || return 1
        var_name=$(env | cut -d= -f1 | sort | fzf $(_fzf_common_opts) \
            --prompt="Select var to edit > " \
            --header="Select existing variable or type new name")
        [[ -z "$var_name" ]] && return
    fi
    
    local current_value="${(P)var_name}"
    
    echo "Variable: $var_name"
    echo "Current:  ${current_value:-(not set)}"
    echo ""
    read -r "new_value?New value: "
    
    if [[ -n "$new_value" ]]; then
        export "$var_name"="$new_value"
        df_print_success "Set $var_name=$new_value"
    fi
}

# ============================================================================
# PATH Explorer
# ============================================================================

pathf() {
    _fzf_check || return 1
    
    local selected=$(echo "$PATH" | tr ':' '\n' | nl -ba | \
        fzf $(_fzf_common_opts) \
        --prompt="PATH > " \
        --preview='dir=$(echo {} | awk "{print \$2}"); 
                   if [[ -d "$dir" ]]; then 
                       echo "Directory: $dir"
                       echo ""
                       echo "Executables:"
                       ls -1 "$dir" 2>/dev/null | head -30
                       count=$(ls -1 "$dir" 2>/dev/null | wc -l)
                       [[ $count -gt 30 ]] && echo "... and $((count-30)) more"
                   else
                       echo "Directory not found: $dir"
                   fi' \
        --preview-window=right:50% \
        --header="PATH entries (in order)")
    
    [[ -z "$selected" ]] && return
    
    local dir=$(echo "$selected" | awk '{print $2}')
    
    echo ""
    df_print_section "Directory: $dir"
    
    if [[ -d "$dir" ]]; then
        ls -la "$dir" | head -20
    else
        df_print_warning "Directory does not exist"
    fi
}

# Add to PATH interactively
path-add() {
    local dir="${1:-$PWD}"
    
    if [[ ! -d "$dir" ]]; then
        df_print_error "Not a directory: $dir"
        return 1
    fi
    
    dir=$(realpath "$dir")
    
    if [[ ":$PATH:" == *":$dir:"* ]]; then
        df_print_warning "Already in PATH: $dir"
        return 0
    fi
    
    echo "Add to PATH: $dir"
    echo ""
    echo "1) Prepend (higher priority)"
    echo "2) Append (lower priority)"
    echo "3) Cancel"
    echo ""
    
    read -k1 "choice?Choice [1]: "
    echo ""
    
    case "${choice:-1}" in
        1)
            export PATH="$dir:$PATH"
            df_print_success "Prepended to PATH"
            ;;
        2)
            export PATH="$PATH:$dir"
            df_print_success "Appended to PATH"
            ;;
        *)
            echo "Cancelled"
            ;;
    esac
}

# ============================================================================
# Process Manager
# ============================================================================

procf() {
    _fzf_check || return 1
    
    # Preview without sudo - only show info accessible to current user
    local selected=$(ps aux --sort=-%mem | \
        fzf $(_fzf_common_opts) \
        --prompt="Process > " \
        --header-lines=1 \
        --preview='pid=$(echo {} | awk "{print \$2}"); 
                   echo "=== Process Details ==="
                   ps -p $pid -o pid,ppid,user,%cpu,%mem,stat,start,time,args 2>/dev/null || echo "Process may have exited"
                   echo ""
                   echo "=== Command Line ==="
                   cat /proc/$pid/cmdline 2>/dev/null | tr "\0" " " || echo "(not accessible)"
                   echo ""
                   echo "=== Working Directory ==="
                   readlink /proc/$pid/cwd 2>/dev/null || echo "(not accessible)"
                   echo ""
                   echo "=== File Descriptors (owned by you) ==="
                   ls -l /proc/$pid/fd 2>/dev/null | head -10 || echo "(not accessible)"' \
        --preview-window=right:50%:wrap \
        --header="Process list | Enter: actions | (sorted by memory)")
    
    [[ -z "$selected" ]] && return
    
    local pid=$(echo "$selected" | awk '{print $2}')
    local user=$(echo "$selected" | awk '{print $1}')
    local cmd=$(echo "$selected" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
    
    echo ""
    df_print_section "Selected Process"
    echo "  PID:  $pid"
    echo "  User: $user"
    echo "  CMD:  ${cmd:0:60}"
    echo ""
    echo "Actions:"
    echo "  1) Show full details"
    echo "  2) Send SIGTERM (graceful stop)"
    echo "  3) Send SIGKILL (force kill)"
    echo "  4) Send SIGHUP (reload config)"
    echo "  5) Open files (requires sudo)"
    echo "  6) Cancel"
    echo ""
    
    read -k1 "action?Action [1]: "
    echo ""
    
    case "${action:-1}" in
        1)
            echo ""
            ps -p "$pid" -f
            echo ""
            echo "Command line:"
            cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' '
            echo ""
            ;;
        2)
            df_print_step "Sending SIGTERM to $pid..."
            if kill -TERM "$pid" 2>/dev/null; then
                df_print_success "Signal sent"
            else
                df_print_warning "Failed - trying with sudo..."
                sudo kill -TERM "$pid" && df_print_success "Signal sent" || df_print_error "Failed"
            fi
            ;;
        3)
            df_print_step "Sending SIGKILL to $pid..."
            if kill -KILL "$pid" 2>/dev/null; then
                df_print_success "Signal sent"
            else
                df_print_warning "Failed - trying with sudo..."
                sudo kill -KILL "$pid" && df_print_success "Signal sent" || df_print_error "Failed"
            fi
            ;;
        4)
            df_print_step "Sending SIGHUP to $pid..."
            if kill -HUP "$pid" 2>/dev/null; then
                df_print_success "Signal sent"
            else
                df_print_warning "Failed - trying with sudo..."
                sudo kill -HUP "$pid" && df_print_success "Signal sent" || df_print_error "Failed"
            fi
            ;;
        5)
            echo ""
            df_print_step "Open files for PID $pid:"
            sudo lsof -p "$pid" 2>/dev/null | head -30 || df_print_error "Failed to get open files"
            ;;
        *)
            echo "Cancelled"
            ;;
    esac
}

# Quick kill by name
killf() {
    _fzf_check || return 1
    
    local selected=$(ps aux | grep -v "grep" | \
        fzf $(_fzf_common_opts) \
        --prompt="Kill > " \
        --header-lines=1 \
        --multi \
        --preview='pid=$(echo {} | awk "{print \$2}"); 
                   ps -p $pid -o pid,ppid,user,%cpu,%mem,stat,args 2>/dev/null' \
        --header="Select process(es) to kill (Tab to select multiple)")
    
    [[ -z "$selected" ]] && return
    
    echo "$selected" | while read -r line; do
        local pid=$(echo "$line" | awk '{print $2}')
        local cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
        
        df_print_step "Killing PID $pid (${cmd:0:40})"
        if kill "$pid" 2>/dev/null; then
            df_print_success "Killed"
        else
            df_print_warning "Trying with sudo..."
            sudo kill "$pid" && df_print_success "Killed" || df_print_error "Failed"
        fi
    done
}

# ============================================================================
# Alias Browser
# ============================================================================

aliasf() {
    _fzf_check || return 1
    
    local selected=$(alias | sed "s/^alias //" | sort | \
        fzf $(_fzf_common_opts) \
        --prompt="Alias > " \
        --preview='name=$(echo {} | cut -d= -f1); 
                   cmd=$(echo {} | cut -d= -f2- | sed "s/^'\''//;s/'\''$//");
                   echo "Alias: $name"
                   echo ""
                   echo "Expands to:"
                   echo "$cmd"
                   echo ""
                   echo "Type: $(type $name 2>/dev/null || echo "alias")"' \
        --preview-window=right:50%:wrap \
        --header="Enter: insert alias | Ctrl-E: edit definition")
    
    [[ -z "$selected" ]] && return
    
    local alias_name="${selected%%=*}"
    print -z "$alias_name "
}

# ============================================================================
# Function Browser
# ============================================================================

funcf() {
    _fzf_check || return 1
    
    local selected=$(print -l ${(ok)functions} | grep -v "^_" | sort | \
        fzf $(_fzf_common_opts) \
        --prompt="Function > " \
        --preview='whence -f {}' \
        --preview-window=right:60%:wrap \
        --header="Shell functions | Enter: insert | Ctrl-V: view source")
    
    [[ -z "$selected" ]] && return
    
    print -z "$selected "
}

# ============================================================================
# Enhanced History Search
# ============================================================================

histf() {
    _fzf_check || return 1
    
    local selected=$(fc -ln 1 | tac | awk '!seen[$0]++' | \
        fzf $(_fzf_common_opts) \
        --prompt="History > " \
        --no-sort \
        --header="Command history (newest first) | Enter: execute | Ctrl-E: edit")
    
    [[ -z "$selected" ]] && return
    
    print -z "$selected"
}

# ============================================================================
# File Finder (enhanced)
# ============================================================================

ff() {
    _fzf_check || return 1
    
    local search_dir="${1:-.}"
    local query="${2:-}"
    
    local cmd="find $search_dir -type f 2>/dev/null"
    
    # Use fd if available (faster)
    if command -v fd &>/dev/null; then
        cmd="fd --type f . $search_dir"
    fi
    
    local selected=$(eval "$cmd" | \
        fzf $(_fzf_common_opts) \
        --query="$query" \
        --prompt="File > " \
        --preview='
            file={}
            if file "$file" | grep -q "text"; then
                bat --style=numbers --color=always "$file" 2>/dev/null || cat "$file"
            else
                file "$file"
                echo ""
                ls -lh "$file"
            fi' \
        --preview-window=right:60% \
        --header="Files | Enter: open | Ctrl-E: edit | Ctrl-Y: copy path")
    
    [[ -z "$selected" ]] && return
    
    echo "$selected"
}

# Open file with appropriate application
ffo() {
    local file=$(ff "$@")
    [[ -z "$file" ]] && return
    
    if [[ -f "$file" ]]; then
        if file "$file" | grep -q "text"; then
            ${EDITOR:-vim} "$file"
        else
            xdg-open "$file" 2>/dev/null || open "$file" 2>/dev/null
        fi
    fi
}

# ============================================================================
# Directory Finder
# ============================================================================

fdir() {
    _fzf_check || return 1
    
    local search_dir="${1:-.}"
    
    local cmd="find $search_dir -type d 2>/dev/null"
    
    if command -v fd &>/dev/null; then
        cmd="fd --type d . $search_dir"
    fi
    
    local selected=$(eval "$cmd" | \
        fzf $(_fzf_common_opts) \
        --prompt="Directory > " \
        --preview='ls -la {} | head -30' \
        --preview-window=right:50% \
        --header="Directories | Enter: cd")
    
    [[ -z "$selected" ]] && return
    
    cd "$selected"
}

# ============================================================================
# Git Helpers
# ============================================================================

# Git branch switcher
gbf() {
    _fzf_check || return 1
    
    if ! git rev-parse --git-dir &>/dev/null; then
        df_print_error "Not a git repository"
        return 1
    fi
    
    local selected=$(git branch -a --color=always | grep -v '/HEAD\s' | \
        fzf $(_fzf_common_opts) \
        --ansi \
        --prompt="Branch > " \
        --preview='git log --oneline --graph --color=always $(echo {} | sed "s/.* //" | sed "s#remotes/##") -- | head -20' \
        --header="Git branches | Enter: checkout")
    
    [[ -z "$selected" ]] && return
    
    local branch=$(echo "$selected" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
    git checkout "$branch"
}

# Git commit browser
glogf() {
    _fzf_check || return 1
    
    if ! git rev-parse --git-dir &>/dev/null; then
        df_print_error "Not a git repository"
        return 1
    fi
    
    local selected=$(git log --oneline --color=always | \
        fzf $(_fzf_common_opts) \
        --ansi \
        --prompt="Commit > " \
        --preview='git show --color=always $(echo {} | cut -d" " -f1)' \
        --preview-window=right:60% \
        --header="Git commits | Enter: show | Ctrl-D: diff")
    
    [[ -z "$selected" ]] && return
    
    local commit=$(echo "$selected" | cut -d" " -f1)
    git show "$commit"
}

# ============================================================================
# Help
# ============================================================================

fzf-help() {
    cat << 'EOF'
FZF Utilities

  Environment:
    envf             Browse environment variables
    env-set [VAR]    Set/edit environment variable

  Path:
    pathf            Explore PATH directories
    path-add [DIR]   Add directory to PATH

  Process:
    procf            Browse and manage processes
    killf            Fuzzy kill processes

  Shell:
    aliasf           Browse aliases
    funcf            Browse functions
    histf            Search command history

  Files:
    ff [DIR]         Find files
    ffo [DIR]        Find and open file
    fdir [DIR]       Find and cd to directory

  Git:
    gbf              Branch switcher
    glogf            Commit browser

EOF
}

# ============================================================================
# Aliases
# ============================================================================

alias envbrowse='envf'
alias pathbrowse='pathf'
alias proc='procf'
