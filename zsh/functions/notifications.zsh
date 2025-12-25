# ============================================================================
# Long-Running Command Notifications
# ============================================================================
# Sends notifications when long-running commands complete.
# Integrates with the existing timer in the adlee theme.
#
# Features:
#   - Desktop notifications (notify-send/libnotify)
#   - Terminal bell fallback
#   - Sound notification (optional)
#   - Configurable thresholds
#   - Smart filtering (no notifications for editors, etc.)
# ============================================================================

# Prevent double-sourcing
[[ -n "$_DF_NOTIFY_LOADED" ]] && return 0
typeset -g _DF_NOTIFY_LOADED=1

# ============================================================================
# Configuration
# ============================================================================

# Minimum duration (seconds) before notification is sent
typeset -g DF_NOTIFY_THRESHOLD="${DF_NOTIFY_THRESHOLD:-60}"

# Enable/disable notifications
typeset -g DF_NOTIFY_ENABLED="${DF_NOTIFY_ENABLED:-true}"

# Notification methods (space-separated): desktop bell sound
typeset -g DF_NOTIFY_METHODS="${DF_NOTIFY_METHODS:-desktop bell}"

# Sound file for audio notification (optional)
typeset -g DF_NOTIFY_SOUND="${DF_NOTIFY_SOUND:-/usr/share/sounds/freedesktop/stereo/complete.oga}"

# Commands to ignore (editors, pagers, interactive tools)
typeset -g DF_NOTIFY_IGNORE_CMDS="${DF_NOTIFY_IGNORE_CMDS:-vim nvim nano vi less more man htop top btop watch ssh tmux}"

# Only notify on failure (exit code != 0)
typeset -g DF_NOTIFY_ONLY_FAILURES="${DF_NOTIFY_ONLY_FAILURES:-false}"

# ============================================================================
# Internal State
# ============================================================================

typeset -g _df_notify_cmd=""
typeset -g _df_notify_start=0

# ============================================================================
# Notification Functions
# ============================================================================

# Check if command should be ignored
_df_notify_should_ignore() {
    local cmd="$1"
    local first_word="${cmd%% *}"
    
    # Check against ignore list
    for ignore in ${(s: :)DF_NOTIFY_IGNORE_CMDS}; do
        [[ "$first_word" == "$ignore" ]] && return 0
    done
    
    # Ignore backgrounded commands
    [[ "$cmd" == *'&'* ]] && return 0
    
    # Ignore commands run with nohup
    [[ "$cmd" == nohup* ]] && return 0
    
    return 1
}

# Send desktop notification
_df_notify_desktop() {
    local title="$1"
    local body="$2"
    local urgency="${3:-normal}"
    local icon="${4:-terminal}"
    
    if command -v notify-send &>/dev/null; then
        notify-send --urgency="$urgency" --icon="$icon" --app-name="Terminal" "$title" "$body" 2>/dev/null
        return 0
    fi
    
    # macOS fallback
    if command -v osascript &>/dev/null; then
        osascript -e "display notification \"$body\" with title \"$title\"" 2>/dev/null
        return 0
    fi
    
    return 1
}

# Send terminal bell
_df_notify_bell() {
    printf '\a'
}

# Play sound notification
_df_notify_sound() {
    local sound_file="$1"
    
    if [[ -f "$sound_file" ]]; then
        if command -v paplay &>/dev/null; then
            paplay "$sound_file" &>/dev/null &
        elif command -v aplay &>/dev/null; then
            aplay -q "$sound_file" &>/dev/null &
        elif command -v afplay &>/dev/null; then
            afplay "$sound_file" &>/dev/null &
        fi
    fi
}

# Format duration for display
_df_notify_format_duration() {
    local secs=$1
    
    if (( secs >= 3600 )); then
        printf "%dh %dm %ds" $((secs/3600)) $((secs%3600/60)) $((secs%60))
    elif (( secs >= 60 )); then
        printf "%dm %ds" $((secs/60)) $((secs%60))
    else
        printf "%ds" $secs
    fi
}

# Main notification function
_df_notify_send() {
    local cmd="$1"
    local exit_code="$2"
    local duration="$3"
    
    # Skip if disabled
    [[ "$DF_NOTIFY_ENABLED" != "true" ]] && return
    
    # Skip if below threshold
    (( duration < DF_NOTIFY_THRESHOLD )) && return
    
    # Skip ignored commands
    _df_notify_should_ignore "$cmd" && return
    
    # Skip if only failures and this succeeded
    [[ "$DF_NOTIFY_ONLY_FAILURES" == "true" && $exit_code -eq 0 ]] && return
    
    # Build notification content
    local title icon urgency
    local duration_str=$(_df_notify_format_duration "$duration")
    local cmd_short="${cmd:0:50}"
    [[ ${#cmd} -gt 50 ]] && cmd_short="${cmd_short}..."
    
    if (( exit_code == 0 )); then
        title="✓ Command Complete"
        icon="dialog-information"
        urgency="normal"
    else
        title="✗ Command Failed (exit $exit_code)"
        icon="dialog-error"
        urgency="critical"
    fi
    
    local body="$cmd_short\nDuration: $duration_str"
    
    # Send notifications based on configured methods
    for method in ${(s: :)DF_NOTIFY_METHODS}; do
        case "$method" in
            desktop)
                _df_notify_desktop "$title" "$body" "$urgency" "$icon"
                ;;
            bell)
                _df_notify_bell
                ;;
            sound)
                [[ -n "$DF_NOTIFY_SOUND" ]] && _df_notify_sound "$DF_NOTIFY_SOUND"
                ;;
        esac
    done
}

# ============================================================================
# Hook Functions
# ============================================================================

# Called before command execution
_df_notify_preexec() {
    _df_notify_cmd="$1"
    _df_notify_start=$SECONDS
}

# Called after command completion
_df_notify_precmd() {
    local exit_code=$?
    
    # Skip if no command was tracked
    [[ -z "$_df_notify_cmd" ]] && return
    [[ $_df_notify_start -eq 0 ]] && return
    
    local duration=$((SECONDS - _df_notify_start))
    
    # Send notification
    _df_notify_send "$_df_notify_cmd" "$exit_code" "$duration"
    
    # Reset state
    _df_notify_cmd=""
    _df_notify_start=0
}

# ============================================================================
# User Commands
# ============================================================================

# Toggle notifications
df_notify_toggle() {
    if [[ "$DF_NOTIFY_ENABLED" == "true" ]]; then
        DF_NOTIFY_ENABLED="false"
        echo "Notifications: OFF"
    else
        DF_NOTIFY_ENABLED="true"
        echo "Notifications: ON"
    fi
}

# Set notification threshold
df_notify_threshold() {
    if [[ -z "$1" ]]; then
        echo "Current threshold: ${DF_NOTIFY_THRESHOLD}s"
        echo "Usage: df_notify_threshold <seconds>"
    else
        DF_NOTIFY_THRESHOLD="$1"
        echo "Threshold set to: ${DF_NOTIFY_THRESHOLD}s"
    fi
}

# Test notification
df_notify_test() {
    echo "Sending test notification..."
    _df_notify_desktop "Test Notification" "This is a test notification from dotfiles" "normal" "terminal"
    _df_notify_bell
    echo "Done. Did you see/hear it?"
}

# Show notification status
df_notify_status() {
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null
    
    df_print_func_name "Notification Status"
    echo ""
    df_print_section "Configuration"
    df_print_indent "Enabled:    $DF_NOTIFY_ENABLED"
    df_print_indent "Threshold:  ${DF_NOTIFY_THRESHOLD}s"
    df_print_indent "Methods:    $DF_NOTIFY_METHODS"
    df_print_indent "Only fail:  $DF_NOTIFY_ONLY_FAILURES"
    
    echo ""
    df_print_section "Capabilities"
    
    if command -v notify-send &>/dev/null; then
        df_print_indent "Desktop: ✓ (notify-send)"
    elif command -v osascript &>/dev/null; then
        df_print_indent "Desktop: ✓ (osascript/macOS)"
    else
        df_print_indent "Desktop: ✗ (install libnotify)"
    fi
    
    df_print_indent "Bell:    ✓ (always available)"
    
    if [[ -n "$DF_NOTIFY_SOUND" && -f "$DF_NOTIFY_SOUND" ]]; then
        df_print_indent "Sound:   ✓ ($DF_NOTIFY_SOUND)"
    else
        df_print_indent "Sound:   ✗ (no sound file configured)"
    fi
    
    echo ""
    df_print_section "Ignored Commands"
    df_print_indent "$DF_NOTIFY_IGNORE_CMDS"
}

# ============================================================================
# Aliases
# ============================================================================

alias notify-toggle='df_notify_toggle'
alias notify-test='df_notify_test'
alias notify-status='df_notify_status'

# ============================================================================
# Initialize Hooks
# ============================================================================

# Only set up hooks if not already done (avoid duplicates)
if [[ -z "$_DF_NOTIFY_HOOKS_SET" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _df_notify_preexec
    add-zsh-hook precmd _df_notify_precmd
    typeset -g _DF_NOTIFY_HOOKS_SET=1
fi
