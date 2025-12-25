# ============================================================================
# Project-Local Environment Manager
# ============================================================================
# Automatically activates project-specific settings when entering directories.
# Similar to direnv but integrated with dotfiles.
#
# Features:
#   - Auto-load .dotfiles-local or .envrc files
#   - Virtual environment auto-activation
#   - Node version switching (via nvm)
#   - Custom environment variables per project
#   - Security: prompts before loading untrusted files
# ============================================================================

# Prevent double-sourcing
[[ -n "$_DF_PROJECT_ENV_LOADED" ]] && return 0
typeset -g _DF_PROJECT_ENV_LOADED=1

# ============================================================================
# Configuration
# ============================================================================

# Enable/disable auto-loading
typeset -g DF_PROJECT_ENV_ENABLED="${DF_PROJECT_ENV_ENABLED:-true}"

# Files to look for (in order of priority)
typeset -g DF_PROJECT_ENV_FILES="${DF_PROJECT_ENV_FILES:-.dotfiles-local .envrc .env.local}"

# Trusted directories (auto-allow without prompt)
typeset -g DF_PROJECT_ENV_TRUSTED_DIRS="${DF_PROJECT_ENV_TRUSTED_DIRS:-$HOME/projects $HOME/work $HOME/.dotfiles}"

# Store allowed files
typeset -g DF_PROJECT_ENV_ALLOWED_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/allowed-envs"

# Auto-activate Python virtualenvs
typeset -g DF_PROJECT_AUTO_VENV="${DF_PROJECT_AUTO_VENV:-true}"

# Auto-switch Node versions via .nvmrc
typeset -g DF_PROJECT_AUTO_NVM="${DF_PROJECT_AUTO_NVM:-true}"

# ============================================================================
# Internal State
# ============================================================================

typeset -g _df_project_current_env=""
typeset -g _df_project_original_path="$PATH"
typeset -gA _df_project_original_vars=()

# ============================================================================
# Helper Functions
# ============================================================================

# Check if a path is in trusted directories
_df_project_is_trusted() {
    local dir="$1"
    
    for trusted in ${(s: :)DF_PROJECT_ENV_TRUSTED_DIRS}; do
        [[ "$dir" == "$trusted"* ]] && return 0
    done
    
    return 1
}

# Check if file is explicitly allowed
_df_project_is_allowed() {
    local file="$1"
    local file_hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
    
    [[ ! -f "$DF_PROJECT_ENV_ALLOWED_FILE" ]] && return 1
    
    grep -q "^${file}:${file_hash}$" "$DF_PROJECT_ENV_ALLOWED_FILE" 2>/dev/null
}

# Add file to allowed list
_df_project_allow_file() {
    local file="$1"
    local file_hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
    
    mkdir -p "$(dirname "$DF_PROJECT_ENV_ALLOWED_FILE")"
    
    # Remove old entry if exists
    if [[ -f "$DF_PROJECT_ENV_ALLOWED_FILE" ]]; then
        grep -v "^${file}:" "$DF_PROJECT_ENV_ALLOWED_FILE" > "${DF_PROJECT_ENV_ALLOWED_FILE}.tmp" 2>/dev/null || true
        mv "${DF_PROJECT_ENV_ALLOWED_FILE}.tmp" "$DF_PROJECT_ENV_ALLOWED_FILE"
    fi
    
    echo "${file}:${file_hash}" >> "$DF_PROJECT_ENV_ALLOWED_FILE"
}

# Save current environment variable
_df_project_save_var() {
    local var="$1"
    if [[ -z "${_df_project_original_vars[$var]+x}" ]]; then
        _df_project_original_vars[$var]="${(P)var}"
    fi
}

# Restore saved environment variable
_df_project_restore_var() {
    local var="$1"
    if [[ -n "${_df_project_original_vars[$var]+x}" ]]; then
        export "$var"="${_df_project_original_vars[$var]}"
        unset "_df_project_original_vars[$var]"
    fi
}

# ============================================================================
# Environment Loading
# ============================================================================

# Load a project environment file
_df_project_load_env() {
    local env_file="$1"
    
    [[ ! -f "$env_file" ]] && return 1
    
    # Security check
    if ! _df_project_is_trusted "$(dirname "$env_file")" && ! _df_project_is_allowed "$env_file"; then
        echo ""
        echo -e "${DF_YELLOW}⚠${DF_NC} Found project env: $env_file"
        echo -e "${DF_DIM}$(head -5 "$env_file")${DF_NC}"
        echo ""
        
        if read -q "?Allow loading this file? [y/N] "; then
            echo ""
            _df_project_allow_file "$env_file"
        else
            echo ""
            echo "Skipped. To allow later: project-env allow $env_file"
            return 1
        fi
    fi
    
    # Save current PATH
    _df_project_save_var "PATH"
    
    # Source the file
    _df_project_current_env="$env_file"
    source "$env_file"
    
    # Visual indicator
    local project_name=$(basename "$(dirname "$env_file")")
    echo -e "${DF_GREEN}●${DF_NC} Project: ${DF_CYAN}${project_name}${DF_NC}"
}

# Unload current project environment
_df_project_unload_env() {
    [[ -z "$_df_project_current_env" ]] && return
    
    # Restore PATH
    _df_project_restore_var "PATH"
    
    # Deactivate virtualenv if active
    [[ -n "$VIRTUAL_ENV" ]] && deactivate 2>/dev/null
    
    local project_name=$(basename "$(dirname "$_df_project_current_env")")
    echo -e "${DF_DIM}○ Left: ${project_name}${DF_NC}"
    
    _df_project_current_env=""
}

# ============================================================================
# Auto-Detection
# ============================================================================

# Auto-activate Python virtualenv
_df_project_auto_venv() {
    [[ "$DF_PROJECT_AUTO_VENV" != "true" ]] && return
    
    local venv_dirs=("venv" ".venv" "env" ".env")
    
    for dir in "${venv_dirs[@]}"; do
        if [[ -f "$dir/bin/activate" ]]; then
            source "$dir/bin/activate"
            echo -e "${DF_GREEN}●${DF_NC} Virtualenv: ${DF_CYAN}${dir}${DF_NC}"
            return
        fi
    done
}

# Auto-switch Node version via .nvmrc
_df_project_auto_nvm() {
    [[ "$DF_PROJECT_AUTO_NVM" != "true" ]] && return
    [[ ! -f ".nvmrc" ]] && return
    
    # Check if nvm is available
    if command -v nvm &>/dev/null || [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # Load nvm if not loaded
        [[ -z "$(command -v nvm)" && -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        
        local nvmrc_version=$(cat .nvmrc)
        local current_version=$(node --version 2>/dev/null || echo "none")
        
        if [[ "$current_version" != "$nvmrc_version"* ]]; then
            echo -e "${DF_GREEN}●${DF_NC} Node: ${DF_CYAN}${nvmrc_version}${DF_NC}"
            nvm use 2>/dev/null
        fi
    fi
}

# ============================================================================
# Directory Change Hook
# ============================================================================

_df_project_chpwd_hook() {
    [[ "$DF_PROJECT_ENV_ENABLED" != "true" ]] && return
    
    local current_dir="$PWD"
    
    # Check if we left a project directory
    if [[ -n "$_df_project_current_env" ]]; then
        local env_dir=$(dirname "$_df_project_current_env")
        if [[ "$current_dir" != "$env_dir"* ]]; then
            _df_project_unload_env
        fi
    fi
    
    # Look for project env files
    for env_file in ${(s: :)DF_PROJECT_ENV_FILES}; do
        if [[ -f "$current_dir/$env_file" ]]; then
            _df_project_load_env "$current_dir/$env_file"
            break
        fi
    done
    
    # Auto-activate virtualenv
    _df_project_auto_venv
    
    # Auto-switch Node version
    _df_project_auto_nvm
}

# ============================================================================
# User Commands
# ============================================================================

# Main project-env command
project-env() {
    local cmd="${1:-status}"
    shift 2>/dev/null || true
    
    case "$cmd" in
        status|s)
            source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
            
            df_print_func_name "Project Environment Status"
            echo ""
            df_print_section "Configuration"
            df_print_indent "Enabled:       $DF_PROJECT_ENV_ENABLED"
            df_print_indent "Auto venv:     $DF_PROJECT_AUTO_VENV"
            df_print_indent "Auto nvm:      $DF_PROJECT_AUTO_NVM"
            df_print_indent "Env files:     $DF_PROJECT_ENV_FILES"
            
            echo ""
            df_print_section "Current State"
            if [[ -n "$_df_project_current_env" ]]; then
                df_print_indent "Active env:    $_df_project_current_env"
            else
                df_print_indent "Active env:    (none)"
            fi
            
            if [[ -n "$VIRTUAL_ENV" ]]; then
                df_print_indent "Virtualenv:    $VIRTUAL_ENV"
            fi
            
            echo ""
            df_print_section "Trusted Directories"
            for dir in ${(s: :)DF_PROJECT_ENV_TRUSTED_DIRS}; do
                df_print_indent "● $dir"
            done
            ;;
            
        allow|a)
            local file="${1:-$PWD/.dotfiles-local}"
            if [[ -f "$file" ]]; then
                _df_project_allow_file "$file"
                echo "Allowed: $file"
            else
                echo "File not found: $file"
            fi
            ;;
            
        deny|d)
            local file="${1:-$PWD/.dotfiles-local}"
            if [[ -f "$DF_PROJECT_ENV_ALLOWED_FILE" ]]; then
                grep -v "^${file}:" "$DF_PROJECT_ENV_ALLOWED_FILE" > "${DF_PROJECT_ENV_ALLOWED_FILE}.tmp" 2>/dev/null || true
                mv "${DF_PROJECT_ENV_ALLOWED_FILE}.tmp" "$DF_PROJECT_ENV_ALLOWED_FILE"
                echo "Denied: $file"
            fi
            ;;
            
        list|l)
            echo "Allowed environment files:"
            if [[ -f "$DF_PROJECT_ENV_ALLOWED_FILE" ]]; then
                cat "$DF_PROJECT_ENV_ALLOWED_FILE" | cut -d: -f1 | while read -r file; do
                    if [[ -f "$file" ]]; then
                        echo -e "  ${DF_GREEN}✓${DF_NC} $file"
                    else
                        echo -e "  ${DF_RED}✗${DF_NC} $file (missing)"
                    fi
                done
            else
                echo "  (none)"
            fi
            ;;
            
        create|c)
            local file="${1:-.dotfiles-local}"
            if [[ -f "$file" ]]; then
                echo "File already exists: $file"
                return 1
            fi
            
            cat > "$file" << 'EOF'
# ============================================================================
# Project-Local Environment
# ============================================================================
# This file is automatically loaded when entering this directory.
# Add project-specific settings below.
# ============================================================================

# --- Environment Variables ---
# export PROJECT_NAME="myproject"
# export DATABASE_URL="postgresql://localhost/mydb"

# --- Path Additions ---
# export PATH="$PWD/bin:$PATH"

# --- Virtual Environment ---
# [[ -f venv/bin/activate ]] && source venv/bin/activate

# --- Custom Aliases ---
# alias build='./scripts/build.sh'
# alias test='pytest'

# --- Startup Message ---
# echo "Welcome to $(basename $PWD)!"
EOF
            
            echo "Created: $file"
            echo "Edit with: \${EDITOR:-vim} $file"
            ;;
            
        edit|e)
            local file=""
            for env_file in ${(s: :)DF_PROJECT_ENV_FILES}; do
                [[ -f "$env_file" ]] && { file="$env_file"; break; }
            done
            
            if [[ -n "$file" ]]; then
                ${EDITOR:-vim} "$file"
            else
                echo "No project env file found. Create one: project-env create"
            fi
            ;;
            
        reload|r)
            _df_project_chpwd_hook
            ;;
            
        off)
            DF_PROJECT_ENV_ENABLED="false"
            _df_project_unload_env
            echo "Project environments disabled"
            ;;
            
        on)
            DF_PROJECT_ENV_ENABLED="true"
            _df_project_chpwd_hook
            echo "Project environments enabled"
            ;;
            
        help|--help|-h)
            cat << 'EOF'
Project Environment Manager

Usage: project-env <command> [args]

Commands:
  status, s      Show current status
  allow <file>   Trust a project env file
  deny <file>    Remove trust for a file
  list, l        List allowed files
  create [file]  Create a new project env file
  edit, e        Edit current project's env file
  reload, r      Reload current directory's env
  on/off         Enable/disable auto-loading

Files checked (in order): .dotfiles-local, .envrc, .env.local

Examples:
  project-env create           # Create .dotfiles-local
  project-env allow            # Trust current dir's env file
  project-env off              # Disable auto-loading
EOF
            ;;
            
        *)
            echo "Unknown command: $cmd"
            echo "Use 'project-env help' for usage"
            ;;
    esac
}

# ============================================================================
# Aliases
# ============================================================================

alias penv='project-env'
alias penv-create='project-env create'
alias penv-edit='project-env edit'

# ============================================================================
# Initialize Hook
# ============================================================================

if [[ "$DF_PROJECT_ENV_ENABLED" == "true" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook chpwd _df_project_chpwd_hook
    
    # Run on initial shell load
    _df_project_chpwd_hook
fi
