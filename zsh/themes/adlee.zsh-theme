#!/usr/bin/env zsh
# ============================================================================
# ADLee's zsh Theme for oh-my-zsh
# ============================================================================

# ============================================================================
# OPTIONS
# ============================================================================

setopt PROMPT_SUBST
setopt PROMPT_CR
setopt PROMPT_SP
setopt TYPESET_SILENT
export PROMPT_EOL_MARK=''
export KEYTIMEOUT=1

# Force color loading (critical for tmux)
autoload -U colors && colors

# ============================================================================
# CONFIGURATION
# ============================================================================

# Colors
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

# Thresholds
typeset -g PATH_TRUNCATE_LENGTH=32
typeset -g TIMER_THRESHOLD=10

# ============================================================================
# GIT PROMPT
# ============================================================================

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg_bold[green]%}⎇ "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color$FG[239]%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# ============================================================================
# COMMAND TIMER
# ============================================================================

_adlee_format_elapsed_time() {
    local elapsed=$1
    local timestamp="%D{%Y-%m-%d %I:%M:%S}"
    
    if (( elapsed >= 3600 )); then
        local hours=$((elapsed / 3600))
        local remainder=$((elapsed % 3600))
        local minutes=$((remainder / 60))
        local seconds=$((remainder % 60))
        print -P "${COLOR_RED}•••[ completed in: %b%B${COLOR_RED}${hours}h${minutes}m${seconds}s%b${COLOR_RED} at: %b%B${COLOR_RED}${timestamp}%b${COLOR_RED} ]•••%b"
    elif (( elapsed >= 60 )); then
        local minutes=$((elapsed / 60))
        local seconds=$((elapsed % 60))
        print -P "${COLOR_ORANGE}••[ completed in: %b%B${COLOR_LIGHT_ORANGE}${minutes}m${seconds}s%b${COLOR_ORANGE} at: %b%B${COLOR_LIGHT_ORANGE}${timestamp}%b${COLOR_ORANGE} ]••%b"
    else
        print -P "${COLOR_LIGHT_GREEN}•[ completed in: %b%B${COLOR_BRIGHT_GREEN}${elapsed}s%b${COLOR_BRIGHT_GREEN} at: %b%B${COLOR_LIGHT_GREEN}${timestamp}%b${COLOR_LIGHT_GREEN} ]•%b"
    fi
}

# ============================================================================
# PROMPT
# ============================================================================

_adlee_build_prompt() {
    # %(#.TRUE.FALSE) - red for root, blue for users
    PROMPT='%{$FG[239]%}┌[%{$FG[118]%}%n@%m%{$reset_color$FG[239]%}]─[%{$FG[179]%}%~%{$reset_color$FG[239]%}$(git_prompt_info)%{$FG[239]%}]
%{$FG[239]%}└%{$FX[bold]%}%(#.%{$FG[196]%}.%{$FG[069]%})%#%{$reset_color%} '
}

# ============================================================================
# HOOKS
# ============================================================================

adlee_preexec() {
    cmd_start_time=$SECONDS
    echo -ne "\e[0m"
}

adlee_precmd() {
    if [[ -n $cmd_start_time ]]; then
        local elapsed=$((SECONDS - cmd_start_time))
        (( elapsed > TIMER_THRESHOLD )) && _adlee_format_elapsed_time $elapsed
        unset cmd_start_time
    fi
    zle_highlight=( default:fg=white )
    _adlee_build_prompt
}

TRAPALRM() {
    _adlee_build_prompt
    [[ "$WIDGET" != "expand-or-complete" ]] && zle reset-prompt
}

# ============================================================================
# UTILITIES
# ============================================================================

histsearch() {
    fc -lim "$@" 1
}

# ============================================================================
# INITIALIZATION
# ============================================================================

autoload -Uz add-zsh-hook
add-zsh-hook preexec adlee_preexec
add-zsh-hook precmd adlee_precmd

# Configure ZLE
zle -N zle-line-init
zle -N zle-keymap-select

# Initial prompt build (critical for tmux)
_adlee_build_prompt

