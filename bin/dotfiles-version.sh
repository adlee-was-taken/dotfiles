#!/usr/bin/env bash
# ============================================================================
# Dotfiles Version Checker
# ============================================================================
# Shows current and remote version info
#
# Usage:
#   dotfiles-version.sh           # Show version info
#   dotfiles-version.sh --check   # Check for updates (exit 1 if behind)
# ============================================================================

# ============================================================================
# Load Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_CONF="${SCRIPT_DIR}/../dotfiles.conf"
[[ -f "$DOTFILES_CONF" ]] || DOTFILES_CONF="${SCRIPT_DIR}/dotfiles.conf"
[[ -f "$DOTFILES_CONF" ]] || DOTFILES_CONF="$HOME/.dotfiles/dotfiles.conf"

if [[ -f "$DOTFILES_CONF" ]]; then
    source "$DOTFILES_CONF"
else
    DOTFILES_DIR="$HOME/.dotfiles"
    DOTFILES_VERSION="unknown"
    DOTFILES_BRANCH="main"
    DOTFILES_RAW_URL="https://raw.githubusercontent.com/adlee-was-taken/dotfiles/main"
fi

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# Options
# ============================================================================

CHECK_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --check|-c)
            CHECK_ONLY=true
            ;;
        --help|-h)
            echo "Usage: dotfiles-version.sh [OPTIONS]"
            echo
            echo "Options:"
            echo "  --check    Only check for updates (exit 1 if behind)"
            echo "  --help     Show this help message"
            echo
            echo "Aliases:"
            echo "  dfv, dfversion   Show version info"
            echo
            exit 0
            ;;
    esac
done

# ============================================================================
# Functions
# ============================================================================

get_local_version() {
    echo "${DOTFILES_VERSION:-unknown}"
}

get_local_commit() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        cd "$DOTFILES_DIR"
        git rev-parse --short HEAD 2>/dev/null || echo "unknown"
        cd - > /dev/null
    else
        echo "not a git repo"
    fi
}

get_local_date() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        cd "$DOTFILES_DIR"
        git log -1 --format="%ci" 2>/dev/null | cut -d' ' -f1 || echo "unknown"
        cd - > /dev/null
    else
        echo "unknown"
    fi
}

get_remote_version() {
    # Try to get version from remote dotfiles.conf
    local remote_conf=$(curl -fsSL "${DOTFILES_RAW_URL}/dotfiles.conf" 2>/dev/null)
    if [[ -n "$remote_conf" ]]; then
        echo "$remote_conf" | grep -oP 'DOTFILES_VERSION="\K[^"]+' || echo "unknown"
    else
        echo "unavailable"
    fi
}

get_remote_commit() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        cd "$DOTFILES_DIR"
        git fetch origin --quiet 2>/dev/null || true
        git rev-parse --short "origin/${DOTFILES_BRANCH}" 2>/dev/null || echo "unavailable"
        cd - > /dev/null
    else
        echo "not a git repo"
    fi
}

get_commits_behind() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        cd "$DOTFILES_DIR"
        git fetch origin --quiet 2>/dev/null || true
        local behind=$(git rev-list HEAD.."origin/${DOTFILES_BRANCH}" --count 2>/dev/null)
        echo "${behind:-0}"
        cd - > /dev/null
    else
        echo "0"
    fi
}

compare_versions() {
    local local_v="$1"
    local remote_v="$2"

    if [[ "$local_v" == "unknown" || "$remote_v" == "unknown" || "$remote_v" == "unavailable" ]]; then
        echo "unknown"
        return
    fi

    if [[ "$local_v" == "$remote_v" ]]; then
        echo "current"
    else
        # Simple semver comparison
        local local_parts=(${local_v//./ })
        local remote_parts=(${remote_v//./ })

        for i in 0 1 2; do
            local l=${local_parts[$i]:-0}
            local r=${remote_parts[$i]:-0}
            if (( l < r )); then
                echo "behind"
                return
            elif (( l > r )); then
                echo "ahead"
                return
            fi
        done
        echo "current"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    local local_version=$(get_local_version)
    local local_commit=$(get_local_commit)
    local local_date=$(get_local_date)
    local remote_version=$(get_remote_version)
    local remote_commit=$(get_remote_commit)
    local commits_behind=$(get_commits_behind)
    local version_status=$(compare_versions "$local_version" "$remote_version")

    if [[ "$CHECK_ONLY" == true ]]; then
        if [[ "$commits_behind" -gt 0 ]]; then
            echo "Updates available: $commits_behind commit(s) behind"
            exit 1
        else
            echo "Up to date"
            exit 0
        fi
    fi

    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Dotfiles Version Info                                     ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${CYAN}Local:${NC}"
    echo -e "  Version:  ${GREEN}${local_version}${NC}"
    echo -e "  Commit:   ${local_commit}"
    echo -e "  Date:     ${local_date}"
    echo -e "  Path:     ${DOTFILES_DIR}"
    echo

    echo -e "${CYAN}Remote:${NC}"
    echo -e "  Version:  ${remote_version}"
    echo -e "  Commit:   ${remote_commit}"
    echo -e "  Branch:   ${DOTFILES_BRANCH}"
    echo

    echo -e "${CYAN}Status:${NC}"

    case "$version_status" in
        current)
            echo -e "  Version:  ${GREEN}✓ Up to date${NC}"
            ;;
        behind)
            echo -e "  Version:  ${YELLOW}⚠ New version available: ${remote_version}${NC}"
            ;;
        ahead)
            echo -e "  Version:  ${CYAN}ℹ Local is ahead of remote${NC}"
            ;;
        *)
            echo -e "  Version:  ${YELLOW}? Cannot determine${NC}"
            ;;
    esac

    if [[ "$commits_behind" -gt 0 ]]; then
        echo -e "  Commits:  ${YELLOW}⚠ ${commits_behind} commit(s) behind${NC}"
        echo
        echo -e "${YELLOW}To update:${NC}"
        echo "  dfu                          # Alias"
        echo "  dotfiles-update.sh           # Full command"
    elif [[ "$commits_behind" == "0" ]]; then
        echo -e "  Commits:  ${GREEN}✓ Up to date${NC}"
    fi

    echo
}

main "$@"
