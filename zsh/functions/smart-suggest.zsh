# ============================================================================
# Smart Command Suggestions for Zsh
# ============================================================================
# Provides intelligent suggestions when commands fail or could be improved
#
# Features:
#   - Typo correction for common commands
#   - Suggests existing aliases for frequently typed commands
#   - "Did you mean?" for unknown commands
#   - Package installation suggestions for missing commands
# ============================================================================

# Source shared colors (with fallback)
source "${0:A:h}/../lib/colors.zsh" 2>/dev/null || \
source "$HOME/.dotfiles/zsh/lib/colors.zsh" 2>/dev/null || {
    typeset -g DF_CYAN=$'\033[0;36m' DF_YELLOW=$'\033[1;33m'
    typeset -g DF_GREEN=$'\033[0;32m' DF_RED=$'\033[0;31m'
    typeset -g DF_DIM=$'\033[2m' DF_NC=$'\033[0m'
}

# ============================================================================
# Configuration
# ============================================================================

typeset -g SMART_SUGGEST_ENABLED=true
typeset -g SMART_SUGGEST_TYPOS=true
typeset -g SMART_SUGGEST_ALIASES=true
typeset -g SMART_SUGGEST_PACKAGES=true
typeset -g SMART_SUGGEST_HISTORY=true
typeset -g SMART_SUGGEST_TRACK_FILE="$HOME/.cache/smart-suggest-track"

# ============================================================================
# Common Typo Database
# ============================================================================

typeset -gA TYPO_CORRECTIONS=(
    # Git typos
    [gti]="git" [gitt]="git" [got]="git" [gut]="git" [gi]="git"
    [giit]="git" [ggit]="git" [gitst]="git st" [gits]="git s"
    [gitl]="git l" [gitd]="git d" [gitp]="git p"
    [psuh]="push" [psull]="pull" [pul]="pull" [puhs]="push"
    [stauts]="status" [statis]="status" [statuus]="status"
    [comit]="commit" [commti]="commit" [commt]="commit"
    [chekcout]="checkout" [chekout]="checkout" [checkou]="checkout"
    [branhc]="branch" [barnch]="branch" [bracnh]="branch"
    [marge]="merge" [merg]="merge" [stsh]="stash" [stahs]="stash"
    
    # Docker typos
    [dokcer]="docker" [doker]="docker" [docekr]="docker"
    [dcoker]="docker" [dockr]="docker" [docke]="docker"
    [docker-compoes]="docker-compose" [docker-compsoe]="docker-compose"
    [dokcer-compose]="docker-compose"
    
    # Common command typos
    [sl]="ls" [l]="ls" [sls]="ls" [lss]="ls"
    [cta]="cat" [catt]="cat" [caat]="cat"
    [grpe]="grep" [gerp]="grep" [gre]="grep" [grepp]="grep"
    [mkdri]="mkdir" [mkdr]="mkdir" [mdkir]="mkdir" [mdir]="mkdir"
    [rn]="rm" [rmm]="rm" [chmdo]="chmod" [chomd]="chmod"
    [chonw]="chown" [cown]="chown" [tarr]="tar" [tart]="tar"
    [wegt]="wget" [wgte]="wget" [weget]="wget"
    [crul]="curl" [curll]="curl"
    [pytohn]="python" [pyhton]="python" [pythn]="python"
    [pyton]="python" [pthon]="python" [pytho]="python"
    [ndoe]="node" [noed]="node" [noode]="node"
    [npn]="npm" [nmpm]="npm" [nppm]="npm"
    [yran]="yarn" [yaarn]="yarn" [yanr]="yarn"
    [suod]="sudo" [sudi]="sudo" [sduo]="sudo" [sudoo]="sudo"
    [sssh]="ssh" [shh]="ssh" [scpp]="scp" [spcp]="scp"
    [vmi]="vim" [imv]="vim" [viim]="vim"
    [cde]="code" [cdoe]="code" [cod]="code"
    [clera]="clear" [cler]="clear" [claer]="clear"
    [ecoh]="echo" [ehco]="echo" [echoo]="echo"
    [exti]="exit" [ext]="exit" [exitt]="exit" [eixt]="exit"
    [histroy]="history" [hisotry]="history" [hsitory]="history"
    [histrory]="history" [maek]="make" [mkae]="make"
    [amke]="make" [makee]="make" [ccd]="cd" [cdd]="cd"
)

# ============================================================================
# Package Manager Detection
# ============================================================================

_ss_get_package_manager() {
    if command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    elif command -v brew &>/dev/null; then echo "brew"
    else echo ""
    fi
}

typeset -gA COMMAND_PACKAGES=(
    [htop]="htop" [tree]="tree" [jq]="jq"
    [fd]="fd-find:apt fd:pacman fd:brew" [rg]="ripgrep"
    [bat]="bat" [eza]="eza" [exa]="exa" [fzf]="fzf"
    [tldr]="tldr" [ncdu]="ncdu" [duf]="duf" [dust]="dust"
    [procs]="procs" [bottom]="bottom" [btm]="bottom"
    [lazygit]="lazygit" [lazydocker]="lazydocker"
    [neofetch]="neofetch" [fastfetch]="fastfetch"
    [httpie]="httpie" [http]="httpie"
    [delta]="git-delta:apt delta:pacman git-delta:brew"
    [glow]="glow" [navi]="navi"
)

_ss_suggest_package() {
    local cmd="$1"
    local pm=$(_ss_get_package_manager)
    
    [[ -z "$pm" ]] && return 1
    
    local pkg_info="${COMMAND_PACKAGES[$cmd]}"
    [[ -z "$pkg_info" ]] && return 1
    
    local pkg=""
    
    if [[ "$pkg_info" == *":"* ]]; then
        for entry in ${(s: :)pkg_info}; do
            local p="${entry%%:*}"
            local m="${entry##*:}"
            if [[ "$m" == "$pm" ]]; then
                pkg="$p"
                break
            fi
        done
        [[ -z "$pkg" ]] && pkg="${${(s: :)pkg_info}[1]%%:*}"
    else
        pkg="$pkg_info"
    fi
    
    [[ -z "$pkg" ]] && return 1
    
    local install_cmd=""
    case "$pm" in
        apt)     install_cmd="sudo apt install $pkg" ;;
        dnf)     install_cmd="sudo dnf install $pkg" ;;
        pacman)  install_cmd="sudo pacman -S $pkg" ;;
        brew)    install_cmd="brew install $pkg" ;;
    esac
    
    echo "$install_cmd"
}

# ============================================================================
# Alias Tracking
# ============================================================================

_ss_track_command() {
    [[ "$SMART_SUGGEST_ALIASES" != true ]] && return
    
    local cmd="$1"
    [[ ${#cmd} -lt 8 ]] && return
    
    mkdir -p "$(dirname "$SMART_SUGGEST_TRACK_FILE")"
    echo "$cmd" >> "$SMART_SUGGEST_TRACK_FILE"
    
    local count=$(grep -Fc "$cmd" "$SMART_SUGGEST_TRACK_FILE" 2>/dev/null || echo 0)
    
    if [[ $count -ge 10 && $((count % 10)) -eq 0 ]]; then
        _ss_suggest_alias_for "$cmd" "$count"
    fi
}

_ss_suggest_alias_for() {
    local cmd="$1"
    local count="$2"
    
    local existing=$(alias | grep -F "='$cmd'" | head -1 | cut -d= -f1)
    
    if [[ -n "$existing" ]]; then
        echo
        echo -e "${DF_CYAN}💡 Tip:${DF_NC} You've typed '${DF_YELLOW}$cmd${DF_NC}' $count times"
        echo -e "   You already have an alias: ${DF_GREEN}$existing${DF_NC}"
    else
        local suggested=$(echo "$cmd" | awk '{
            for(i=1; i<=NF && i<=3; i++) 
                printf substr($i,1,1)
        }')
        
        echo
        echo -e "${DF_CYAN}💡 Tip:${DF_NC} You've typed '${DF_YELLOW}$cmd${DF_NC}' $count times"
        echo -e "   Consider adding: ${DF_GREEN}alias $suggested='$cmd'${DF_NC}"
    fi
}

# ============================================================================
# Command Not Found Handler
# ============================================================================

command_not_found_handler() {
    local cmd="$1"
    shift
    local args="$@"
    
    [[ "$SMART_SUGGEST_ENABLED" != true ]] && {
        echo "zsh: command not found: $cmd"
        return 127
    }
    
    echo -e "${DF_RED}✗${DF_NC} Command not found: ${DF_YELLOW}$cmd${DF_NC}"
    
    local suggestion_made=false
    
    if [[ "$SMART_SUGGEST_TYPOS" == true ]]; then
        local correction="${TYPO_CORRECTIONS[$cmd]}"
        if [[ -n "$correction" ]]; then
            echo -e "${DF_CYAN}→${DF_NC} Did you mean: ${DF_GREEN}$correction${DF_NC}?"
            echo -e "  ${DF_DIM}Run: $correction $args${DF_NC}"
            suggestion_made=true
        fi
    fi
    
    if [[ "$suggestion_made" != true ]]; then
        local similar=$(compgen -c 2>/dev/null | grep -i "^${cmd:0:3}" | head -3 | tr '\n' ', ' | sed 's/,$//')
        if [[ -n "$similar" ]]; then
            echo -e "${DF_CYAN}→${DF_NC} Similar commands: ${DF_GREEN}$similar${DF_NC}"
            suggestion_made=true
        fi
    fi
    
    if [[ "$SMART_SUGGEST_PACKAGES" == true ]]; then
        local install_cmd=$(_ss_suggest_package "$cmd")
        if [[ -n "$install_cmd" ]]; then
            echo -e "${DF_CYAN}→${DF_NC} To install: ${DF_GREEN}$install_cmd${DF_NC}"
            suggestion_made=true
        fi
    fi
    
    return 127
}

# ============================================================================
# Hooks
# ============================================================================

_ss_preexec_hook() {
    local cmd="$1"
    local first_word="${cmd%% *}"
    _ss_track_command "$cmd"
}

_ss_precmd_hook() {
    local exit_code=$?
    [[ $exit_code -eq 0 ]] && return
    
    local last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
    [[ -z "$last_cmd" ]] && return
    
    local first_word="${last_cmd%% *}"
    
    if [[ "$first_word" == "git" && $exit_code -ne 0 ]]; then
        local git_subcmd=$(echo "$last_cmd" | awk '{print $2}')
        local correction="${TYPO_CORRECTIONS[$git_subcmd]}"
        
        if [[ -n "$correction" ]]; then
            echo -e "${DF_CYAN}→${DF_NC} Did you mean: ${DF_GREEN}git $correction${DF_NC}?"
        fi
    fi
}

# ============================================================================
# Quick Fix Function
# ============================================================================

fuck() {
    local last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
    local first_word="${last_cmd%% *}"
    
    local correction="${TYPO_CORRECTIONS[$first_word]}"
    
    if [[ -n "$correction" ]]; then
        local fixed_cmd="${last_cmd/$first_word/$correction}"
        echo -e "${DF_GREEN}Running:${DF_NC} $fixed_cmd"
        eval "$fixed_cmd"
    else
        echo "No automatic fix available"
        echo "Last command: $last_cmd"
    fi
}

# ============================================================================
# Setup Hooks
# ============================================================================

_ss_setup() {
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _ss_preexec_hook
    add-zsh-hook precmd _ss_precmd_hook
}

[[ "$SMART_SUGGEST_ENABLED" == true ]] && _ss_setup
