# ============================================================================
# Default Machine Configuration
# ============================================================================
# This file is loaded on ALL machines before hostname-specific configs.
# Use it for settings that should be shared across all your machines.
#
# Load order:
#   1. dotfiles.conf (base config)
#   2. machines/default.zsh (this file)
#   3. machines/type-<type>.zsh (laptop, desktop, server, virtual)
#   4. machines/<hostname>.zsh (machine-specific)
#   5. ~/.zshrc.local (local overrides, not synced)
# ============================================================================

# ============================================================================
# Shared Settings
# ============================================================================

# Uncomment and modify settings you want on all machines

# --- Display ---
# DF_WIDTH="74"

# --- Features ---
# ENABLE_SMART_SUGGESTIONS="true"
# ENABLE_COMMAND_PALETTE="true"

# --- Notification Settings ---
# DF_NOTIFY_ENABLED="true"
# DF_NOTIFY_THRESHOLD="60"

# --- Project Environment ---
# DF_PROJECT_ENV_ENABLED="true"
# DF_PROJECT_AUTO_VENV="true"

# ============================================================================
# Shared Aliases
# ============================================================================

# Add aliases that should exist on all machines
# alias mycompany='cd ~/work/mycompany'

# ============================================================================
# Shared Environment
# ============================================================================

# Environment variables for all machines
# export EDITOR="nvim"
# export BROWSER="firefox"

# ============================================================================
# Shared Functions
# ============================================================================

# Functions available on all machines
# myfunction() {
#     echo "This works everywhere"
# }
