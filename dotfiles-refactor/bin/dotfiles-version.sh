#!/usr/bin/env bash
# ============================================================================
# Dotfiles Version Checker
# ============================================================================

# ============================================================================
# Parse Arguments First
# ============================================================================

CHECK_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --check|-c) CHECK_ONLY=true ;;
        --help|-h)
            echo "Usage: dotfiles-version.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --check, -c    Output version only (for scripts)"
            echo "  --help         Show this help"
            exit 0
            ;;
    esac
done

# ============================================================================
# Source Bootstrap
# ============================================================================

source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_CYAN=$'\033[0;36m' DF_NC=$'\033[0m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    DOTFILES_VERSION="${DOTFILES_VERSION:-unknown}"
    DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
    DF_WIDTH="${DF_WIDTH:-66}"
    df_print_header() { echo "=== $1 ==="; }
}

# ============================================================================
# Version Info Functions
# ============================================================================

get_local_commit() {
    if [[ -d "${DOTFILES_HOME}/.git" ]]; then
        cd "$DOTFILES_HOME"
        git rev-parse --short HEAD 2>/dev/null || echo "unknown"
    else
        echo "not a git repo"
    fi
}

get_local_date() {
    if [[ -d "${DOTFILES_HOME}/.git" ]]; then
        cd "$DOTFILES_HOME"
        git log -1 --format="%ci" 2>/dev/null | cut -d' ' -f1 || echo "unknown"
    else
        echo "unknown"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    local local_commit=$(get_local_commit)
    local local_date=$(get_local_date)

    # Short output for scripts
    if [[ "$CHECK_ONLY" == true ]]; then
        echo "Version: ${DOTFILES_VERSION} (${local_commit})"
        exit 0
    fi

    # Full output
    df_print_header "dotfiles-version"

    echo -e "${DF_CYAN}Local:${DF_NC}"
    echo -e "  Version:  ${DF_GREEN}${DOTFILES_VERSION}${DF_NC}"
    echo -e "  Commit:   ${local_commit}"
    echo -e "  Date:     ${local_date}"
    echo -e "  Path:     ${DOTFILES_HOME}"
    echo -e "  Branch:   ${DOTFILES_BRANCH}"
    echo -e "  Width:    ${DF_WIDTH}"
    echo ""
}

main "$@"
