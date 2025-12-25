#!/usr/bin/env bash
# ============================================================================
# Dotfiles Version Checker
# ============================================================================

# ============================================================================
# Source Configuration
# ============================================================================

_df_source_config() {
    local locations=(
        "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/utils.zsh"
        "$HOME/.dotfiles/zsh/lib/utils.zsh"
    )
    for loc in "${locations[@]}"; do
        [[ -f "$loc" ]] && { source "$loc"; return 0; }
    done
    
    # Fallback defaults
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_CYAN=$'\033[0;36m'
    DF_NC=$'\033[0m' DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_LIGHT_GREEN=$'\033[38;5;82m'
    DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
    DOTFILES_VERSION="${DOTFILES_VERSION:-unknown}"
    DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
    DF_WIDTH="${DF_WIDTH:-66}"
}

_df_source_config

# ============================================================================
# Parse Arguments
# ============================================================================

CHECK_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --check|-c) CHECK_ONLY=true ;;
        --help|-h) echo "Usage: dotfiles-version.sh [--check]"; exit 0 ;;
    esac
done

# ============================================================================
# Header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-version"
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width="${DF_WIDTH:-66}"
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}    ${DF_LIGHT_GREEN}dotfiles-version${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

# ============================================================================
# Version Info
# ============================================================================

get_local_commit() {
    [[ -d "${DOTFILES_DIR}/.git" ]] && { cd "$DOTFILES_DIR"; git rev-parse --short HEAD 2>/dev/null || echo "unknown"; } || echo "not a git repo"
}

get_local_date() {
    [[ -d "${DOTFILES_DIR}/.git" ]] && { cd "$DOTFILES_DIR"; git log -1 --format="%ci" 2>/dev/null | cut -d' ' -f1 || echo "unknown"; } || echo "unknown"
}

# ============================================================================
# Main
# ============================================================================

main() {
    local local_commit=$(get_local_commit)
    local local_date=$(get_local_date)

    if [[ "$CHECK_ONLY" == true ]]; then
        echo "Version: $DOTFILES_VERSION ($local_commit)"
        exit 0
    fi

    print_header

    echo -e "${DF_CYAN}Local:${DF_NC}"
    echo -e "  Version:  ${DF_GREEN}${DOTFILES_VERSION}${DF_NC}"
    echo -e "  Commit:   ${local_commit}"
    echo -e "  Date:     ${local_date}"
    echo -e "  Path:     ${DOTFILES_DIR}"
    echo -e "  Branch:   ${DOTFILES_BRANCH}"
    echo -e "  Width:    ${DF_WIDTH}"
    echo
}

main "$@"
