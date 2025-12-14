#!/usr/bin/env zsh
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# % ~/.oh-my-zsh/themes/adlee.zsh-theme
# === ADLee's zsh (oh-my-zsh) Theme ===
# =====================================

# ============================================================================
# CONFIGURATION & CONSTANTS
# ============================================================================

setopt PROMPT_SUBST
# Ensure proper line handling in tmux
setopt PROMPT_CR
setopt PROMPT_SP
setopt TYPESET_SILENT 
export PROMPT_EOL_MARK=''

# Prevent multiple initialization on reload
if [[ -z "$_ADLEE_THEME_LOADED" || "$TERM" = 'tmux-256color' ]] ; then
    export _ADLEE_THEME_LOADED=1
    
    export KEYTIMEOUT=1
    
    # Color definitions
    typeset -g COLOR_GREY='%{$FG[239]%}'
    typeset -g COLOR_YELLOW='%{$FG[179]%}'
    typeset -g COLOR_BLUE='%{$FG[069]%}'
    typeset -g COLOR_GREEN='%{$FG[118]%}'
    typeset -g COLOR_RED='%{$FG[196]%}'
    typeset -g COLOR_ORANGE='%{$FG[220]%}'
    typeset -g COLOR_LIGHT_ORANGE='%{$FG[228]%}'
    typeset -g COLOR_LIGHT_GREEN='%{$FG[002]%}'
    typeset -g COLOR_BRIGHT_GREEN='%{$FG[010]%}'
    typeset -g COLOR_RESET='%{$reset_color%}'
    typeset -g COLOR_BOLD='%{$FX[bold]%}'
    
    # Prompt characters
    typeset -g PROMPT_CHAR_USER="${COLOR_GREY}└${COLOR_BOLD}${COLOR_BLUE}%#${COLOR_RESET} "
    typeset -g PROMPT_CHAR_ROOT="${COLOR_GREY}└${COLOR_BOLD}${COLOR_RED}%#${COLOR_RESET} "
    
    # Path truncation threshold
    typeset -g PATH_TRUNCATE_LENGTH=32
    
    # Timer threshold (seconds)
    typeset -g TIMER_THRESHOLD=10
fi

# ============================================================================
# GIT PROMPT CONFIGURATION
# ============================================================================

ZSH_THEME_GIT_PROMPT_PREFIX="]─[%{$fg_bold[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color$FG[239]%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get shortened path (last two directories if path is too long)
_adlee_get_short_path() {
    local full_path="$(pwd | sed -e 's/\/Users\/alee/~/g')"
    local path_len=$(echo -n "$full_path" | wc -m | tr -d ' ')
    
    if [ "$path_len" -gt "$PATH_TRUNCATE_LENGTH" ]; then
        local short_path=$(pwd | awk -F '/' '{print $(NF - 1)"/"$NF}')
        echo "${COLOR_YELLOW}⋯${COLOR_RESET}${COLOR_GREY}${COLOR_YELLOW}/${short_path}${COLOR_RESET}${COLOR_GREY}"
    else
        echo "${COLOR_YELLOW}%~${COLOR_RESET}${COLOR_GREY}"
    fi
}

# Get appropriate prompt character based on user
_adlee_get_prompt_char() {
    if [[ $UID == 0 || $EUID == 0 ]]; then
        echo "$PROMPT_CHAR_ROOT"
    else
        echo "$PROMPT_CHAR_USER"
    fi
}

# Format user@host section
_adlee_format_user_host() {
    echo "${COLOR_GREEN}%n@%m${COLOR_RESET}${COLOR_GREY}"
}

# Format current directory with git info
_adlee_format_directory() {
    local short_path="$(_adlee_get_short_path)"
    local git_info='$(git_prompt_info)'"${COLOR_GREY}"
    echo "${short_path}${git_info}"
}

# ============================================================================
# COMMAND TIMER FUNCTIONS
# ============================================================================

# Format elapsed time based on duration
_adlee_format_elapsed_time() {
    local elapsed=$1
    local timestamp="%D{%Y-%m-%d %I:%M:%S}"
    
    if [[ $elapsed -ge 3600 ]]; then
        # Hours
        local hours=$((elapsed / 3600))
        local remainder=$((elapsed % 3600))
        local minutes=$((remainder / 60))
        local seconds=$((remainder % 60))
        print -P "${COLOR_RED}•─[ completed in: %b%B${COLOR_RED}${hours}h${minutes}m${seconds}s%b${COLOR_RED} at: %b%B${COLOR_RED}${timestamp}%b${COLOR_RED} ]─•%b"
    elif [[ $elapsed -ge 60 ]]; then
        # Minutes
        local minutes=$((elapsed / 60))
        local seconds=$((elapsed % 60))
        print -P "${COLOR_ORANGE}•─[ completed in: %b%B${COLOR_LIGHT_ORANGE}${minutes}m${seconds}s%b${COLOR_ORANGE} at: %b%B${COLOR_LIGHT_ORANGE}${timestamp}%b${COLOR_ORANGE} ]─•%b"
    else
        # Seconds only
        print -P "${COLOR_LIGHT_GREEN}•─[ completed in: %b%B${COLOR_BRIGHT_GREEN}${elapsed}s%b${COLOR_BRIGHT_GREEN} at: %b%B${COLOR_LIGHT_GREEN}${timestamp}%b${COLOR_LIGHT_GREEN} ]─•%b"
    fi
}

# ============================================================================
# PROMPT BUILDING
# ============================================================================

_adlee_build_prompt() {
    local user_host="$(_adlee_format_user_host)"
    local directory="$(_adlee_format_directory)"
    
    # Build top line: ┌[user@host]─[directory]
    local top_line="${COLOR_GREY}┌[${user_host}]─[${directory}]"
    
    print -P "${top_line}"
    
    # Set bottom line prompt character
    PROMPT="$(_adlee_get_prompt_char)"
}

# ============================================================================
# ZSH HOOKS
# ============================================================================

adlee_preexec() {
    cmd_start_time=$SECONDS
    echo -ne "\e[0m"
}

adlee_precmd() {
    # Handle command timer
    if [[ -n $cmd_start_time ]]; then
        local elapsed=$((SECONDS - cmd_start_time))
        if [[ $elapsed -gt $TIMER_THRESHOLD ]]; then
            _adlee_format_elapsed_time $elapsed
        fi
        unset cmd_start_time
    fi
    
    # Configure ZLE highlighting
    zle_highlight=( default:fg=white )
    
    # Rebuild prompt
    _adlee_build_prompt
}

TRAPALRM() {
    _adlee_build_prompt
    if [[ "$WIDGET" != "expand-or-complete" ]]; then
        zle reset-prompt
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Search command history
histsearch() {
    fc -lim "$@" 1
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Load required functions
autoload -Uz add-zsh-hook

# Register hooks
add-zsh-hook preexec adlee_preexec
add-zsh-hook precmd adlee_precmd

# Configure ZLE
zle -N zle-line-init
zle -N zle-keymap-select

# Define zshrc reload function and widget
reload-zshrc() {
    echo -n "Re-sourcing \`~/.zshrc.\` ... "
    source ~/.zshrc
    echo "Completed."
    _adlee_build_prompt
    zle reset-prompt
}
zle -N reload-zshrc  # Register as a widget
bindkey "^X@s^[^R" reload-zshrc  # Bind to Ctrl+Super+Alt+R

 # Function.
grab-fastfetch() {
    echo "fastfetch"
    fastfetch
    _adlee_build_prompt
    zle reset-prompt
}
zle -N grab-fastfetch  # Register as a widget
bindkey "^X@s^[^F" grab-fastfetch  # Bind to Ctrl+Super+Alt+F


# ============================================================================
# DEPLOYMENT NOTES
# ============================================================================
# For system-wide deployment, use one of these approaches:
#
# OPTION 1: Symlink (Recommended)
#   Master location: /usr/local/share/zsh/themes/adlee.zsh-theme
#   User symlinks:
#     ln -sf /usr/local/share/zsh/themes/adlee.zsh-theme ~/.oh-my-zsh/themes/adlee.zsh-theme
#     sudo ln -sf /usr/local/share/zsh/themes/adlee.zsh-theme /root/.oh-my-zsh/themes/adlee.zsh-theme
#
# OPTION 2: Source from shared location
#   In each user's ~/.zshrc (before oh-my-zsh initialization):
#     source /usr/local/share/zsh/themes/adlee.zsh-theme
#
# OPTION 3: Custom oh-my-zsh location
#   Set in ~/.zshrc:
#     export ZSH_CUSTOM="/usr/local/share/oh-my-zsh-custom"
#   Then place theme in: /usr/local/share/oh-my-zsh-custom/themes/adlee.zsh-theme
