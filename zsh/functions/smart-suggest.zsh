# ============================================================================
# Smart Command Suggestions for Zsh
# ============================================================================

source "${0:A:h}/../lib/utils.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/utils.zsh" 2>/dev/null

typeset -g SMART_SUGGEST_ENABLED=true
typeset -g SMART_SUGGEST_TRACK_FILE="$HOME/.cache/smart-suggest-track"

typeset -gA TYPO_CORRECTIONS=(
    [gti]="git" [gitt]="git" [got]="git" [gi]="git"
    [gitst]="git st" [gits]="git s" [gitp]="git p"
    [psuh]="push" [psull]="pull" [pul]="pull"
    [stauts]="status" [comit]="commit" [commti]="commit"
    [chekcout]="checkout" [branhc]="branch" [marge]="merge"
    [dokcer]="docker" [doker]="docker" [dcoker]="docker"
    [sl]="ls" [sls]="ls" [cta]="cat" [grpe]="grep" [gerp]="grep"
    [mkdri]="mkdir" [chmdo]="chmod" [suod]="sudo" [sduo]="sudo"
    [pytohn]="python" [pyhton]="python" [ndoe]="node"
    [vmi]="vim" [cde]="code" [clera]="clear" [exti]="exit"
)

typeset -gA COMMAND_PACKAGES=(
    [htop]="htop" [tree]="tree" [jq]="jq" [fd]="fd" [rg]="ripgrep"
    [bat]="bat" [eza]="eza" [fzf]="fzf" [tldr]="tldr" [ncdu]="ncdu"
    [lazygit]="lazygit" [neofetch]="neofetch" [delta]="git-delta"
)

_ss_track() {
    local cmd="$1"
    [[ ${#cmd} -lt 8 ]] && return
    df_ensure_dir "$(dirname "$SMART_SUGGEST_TRACK_FILE")"
    echo "$cmd" >> "$SMART_SUGGEST_TRACK_FILE"
    local count=$(grep -Fc "$cmd" "$SMART_SUGGEST_TRACK_FILE" 2>/dev/null || echo 0)
    if (( count >= 10 && count % 10 == 0 )); then
        local existing=$(alias | grep -F "='$cmd'" | head -1 | cut -d= -f1)
        [[ -n "$existing" ]] && df_print_info "You have alias: $existing" || \
            df_print_info "Consider: alias xyz='$cmd'"
    fi
}

command_not_found_handler() {
    local cmd="$1"; shift
    [[ "$SMART_SUGGEST_ENABLED" != true ]] && { echo "zsh: command not found: $cmd"; return 127; }
    
    df_print_error "Command not found: $cmd"
    
    local correction="${TYPO_CORRECTIONS[$cmd]}"
    [[ -n "$correction" ]] && { df_print_info "Did you mean: $correction?"; df_print_indent "Run: $correction $@"; }
    
    local pkg="${COMMAND_PACKAGES[$cmd]}"
    [[ -n "$pkg" ]] && df_print_info "Install: sudo pacman -S $pkg"
    
    return 127
}

fuck() {
    local last=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
    local first="${last%% *}"
    local fix="${TYPO_CORRECTIONS[$first]}"
    [[ -n "$fix" ]] && { df_print_step "Running: ${last/$first/$fix}"; eval "${last/$first/$fix}"; } || df_print_warning "No fix for: $last"
}

_ss_preexec() { _ss_track "$1"; }
_ss_precmd() {
    local exit=$?; (( exit == 0 )) && return
    local last=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
    [[ "${last%% *}" == "git" ]] && {
        local sub=$(echo "$last" | awk '{print $2}')
        local fix="${TYPO_CORRECTIONS[$sub]}"
        [[ -n "$fix" ]] && df_print_info "Did you mean: git $fix?"
    }
}

_ss_setup() {
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _ss_preexec
    add-zsh-hook precmd _ss_precmd
}

[[ "$SMART_SUGGEST_ENABLED" == true ]] && _ss_setup
