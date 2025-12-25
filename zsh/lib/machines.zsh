# ============================================================================
# Machine-Specific Configuration Loader
# ============================================================================
# Automatically loads configuration based on hostname, allowing different
# settings per machine while keeping a single dotfiles repository.
#
# Configuration hierarchy (later files override earlier):
#   1. dotfiles.conf (base config)
#   2. machines/default.zsh (shared overrides)
#   3. machines/<hostname>.zsh (machine-specific)
#   4. ~/.zshrc.local (local user overrides)
#
# Usage:
#   Create ~/.dotfiles/machines/<hostname>.zsh for machine-specific settings
#   Use `df_machine_info` to see current machine detection
# ============================================================================

# Prevent double-sourcing
[[ -n "$_DF_MACHINES_LOADED" ]] && return 0
typeset -g _DF_MACHINES_LOADED=1

# ============================================================================
# Machine Detection
# ============================================================================

typeset -g DF_HOSTNAME="${HOST:-${HOSTNAME:-$(hostname -s 2>/dev/null)}}"
typeset -g DF_HOSTNAME_FULL="$(hostname -f 2>/dev/null || echo "$DF_HOSTNAME")"
typeset -g DF_MACHINE_TYPE="unknown"
typeset -g DF_MACHINE_CONFIG=""

# Detect machine type based on hostname patterns or hardware
_df_detect_machine_type() {
    local hostname="$DF_HOSTNAME"
    
    # Check for common naming patterns
    case "$hostname" in
        *laptop*|*book*|*portable*|*mobile*)
            DF_MACHINE_TYPE="laptop"
            ;;
        *server*|*srv*|*node*|*host*)
            DF_MACHINE_TYPE="server"
            ;;
        *desktop*|*workstation*|*ws*|*pc*)
            DF_MACHINE_TYPE="desktop"
            ;;
        *vm*|*virtual*|*container*)
            DF_MACHINE_TYPE="virtual"
            ;;
        *)
            # Try to detect from hardware
            if [[ -d /sys/class/power_supply/BAT0 ]]; then
                DF_MACHINE_TYPE="laptop"
            elif [[ -f /proc/cpuinfo ]] && grep -qi "hypervisor\|vmware\|virtualbox\|kvm\|xen" /proc/cpuinfo 2>/dev/null; then
                DF_MACHINE_TYPE="virtual"
            elif systemd-detect-virt &>/dev/null && [[ "$(systemd-detect-virt)" != "none" ]]; then
                DF_MACHINE_TYPE="virtual"
            else
                DF_MACHINE_TYPE="desktop"
            fi
            ;;
    esac
}

# ============================================================================
# Configuration Loading
# ============================================================================

_df_load_machine_config() {
    local machines_dir="${DOTFILES_DIR:-$HOME/.dotfiles}/machines"
    local loaded=()
    
    # Create machines directory if it doesn't exist
    [[ ! -d "$machines_dir" ]] && mkdir -p "$machines_dir"
    
    # 1. Load default machine config (shared across all machines)
    if [[ -f "$machines_dir/default.zsh" ]]; then
        source "$machines_dir/default.zsh"
        loaded+=("default")
    fi
    
    # 2. Load machine-type specific config
    if [[ -f "$machines_dir/type-${DF_MACHINE_TYPE}.zsh" ]]; then
        source "$machines_dir/type-${DF_MACHINE_TYPE}.zsh"
        loaded+=("type-${DF_MACHINE_TYPE}")
    fi
    
    # 3. Load hostname-specific config (highest priority)
    if [[ -f "$machines_dir/${DF_HOSTNAME}.zsh" ]]; then
        source "$machines_dir/${DF_HOSTNAME}.zsh"
        loaded+=("$DF_HOSTNAME")
        DF_MACHINE_CONFIG="$machines_dir/${DF_HOSTNAME}.zsh"
    fi
    
    # Store what was loaded for debugging
    typeset -g DF_MACHINE_CONFIGS_LOADED="${(j:, :)loaded}"
}

# ============================================================================
# Machine Information Commands
# ============================================================================

# Display machine detection info
df_machine_info() {
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
    
    df_print_func_name "Machine Configuration"
    echo ""
    df_print_section "Detection"
    df_print_indent "Hostname:      $DF_HOSTNAME"
    df_print_indent "Full hostname: $DF_HOSTNAME_FULL"
    df_print_indent "Machine type:  $DF_MACHINE_TYPE"
    echo ""
    df_print_section "Loaded Configs"
    if [[ -n "$DF_MACHINE_CONFIGS_LOADED" ]]; then
        df_print_indent "$DF_MACHINE_CONFIGS_LOADED"
    else
        df_print_indent "(none)"
    fi
    echo ""
    df_print_section "Config File"
    if [[ -n "$DF_MACHINE_CONFIG" ]]; then
        df_print_indent "$DF_MACHINE_CONFIG"
    else
        df_print_indent "No machine-specific config found"
        df_print_info "Create: ${DOTFILES_DIR:-$HOME/.dotfiles}/machines/${DF_HOSTNAME}.zsh"
    fi
}

# Create a new machine config from template
df_machine_create() {
    local hostname="${1:-$DF_HOSTNAME}"
    local machines_dir="${DOTFILES_DIR:-$HOME/.dotfiles}/machines"
    local config_file="$machines_dir/${hostname}.zsh"
    
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
    
    if [[ -f "$config_file" ]]; then
        df_print_warning "Config already exists: $config_file"
        df_confirm "Edit existing config?" && ${EDITOR:-vim} "$config_file"
        return
    fi
    
    df_print_step "Creating machine config: $hostname"
    
    cat > "$config_file" << EOF
# ============================================================================
# Machine Configuration: ${hostname}
# ============================================================================
# This file is automatically loaded when the hostname matches.
# Created: $(date '+%Y-%m-%d %H:%M')
#
# Available variables to override:
#   DF_WIDTH, MOTD_STYLE, ENABLE_MOTD, ZSH_THEME_NAME
#   Any variable from dotfiles.conf
# ============================================================================

# --- Display Settings ---
# DF_WIDTH="80"                    # Wider terminal?
# MOTD_STYLE="mini"                # mini, compact, full, none

# --- Machine-specific paths ---
# export PATH="\$HOME/custom-tools:\$PATH"

# --- Machine-specific aliases ---
# alias proj='cd ~/projects/work'

# --- Machine-specific environment ---
# export JAVA_HOME="/usr/lib/jvm/java-17"

# --- Conditional features ---
# Example: Disable heavy features on slow machines
# ENABLE_SMART_SUGGESTIONS="false"

# --- SSH agent (if needed on this machine) ---
# if [[ -z "\$SSH_AUTH_SOCK" ]]; then
#     eval "\$(ssh-agent -s)" &>/dev/null
#     ssh-add ~/.ssh/id_ed25519 2>/dev/null
# fi

# --- Custom startup commands ---
# echo "Welcome to ${hostname}!"
EOF

    df_print_success "Created: $config_file"
    df_print_info "Edit with: ${EDITOR:-vim} $config_file"
    
    df_confirm "Edit now?" && ${EDITOR:-vim} "$config_file"
}

# List all machine configs
df_machine_list() {
    local machines_dir="${DOTFILES_DIR:-$HOME/.dotfiles}/machines"
    
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
    
    df_print_func_name "Machine Configurations"
    echo ""
    
    if [[ ! -d "$machines_dir" ]] || [[ -z "$(ls -A "$machines_dir" 2>/dev/null)" ]]; then
        df_print_info "No machine configs found"
        df_print_info "Create one: df_machine_create <hostname>"
        return
    fi
    
    for config in "$machines_dir"/*.zsh(N); do
        [[ -f "$config" ]] || continue
        local name=$(basename "$config" .zsh)
        local marker=""
        [[ "$name" == "$DF_HOSTNAME" ]] && marker=" ${DF_GREEN}(current)${DF_NC}"
        [[ "$name" == "default" ]] && marker=" ${DF_CYAN}(shared)${DF_NC}"
        [[ "$name" == type-* ]] && marker=" ${DF_YELLOW}(type)${DF_NC}"
        df_print_indent "● ${name}${marker}"
    done
}

# ============================================================================
# Aliases
# ============================================================================

alias machines='df_machine_list'
alias machine-info='df_machine_info'
alias machine-create='df_machine_create'
alias machine-edit='${EDITOR:-vim} "${DOTFILES_DIR:-$HOME/.dotfiles}/machines/${DF_HOSTNAME}.zsh"'

# ============================================================================
# Initialize
# ============================================================================

_df_detect_machine_type
_df_load_machine_config
