#!/usr/bin/env bash
# ============================================================================
# Dotfiles Version Checker
# ============================================================================

# Load Configuration
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

# Source shared colors
source "$DOTFILES_DIR/zsh/lib/colors.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_CYAN=$'\033[0;36m'
    DF_NC=$'\033[0m' DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m' DF_LIGHT_GREEN=$'\033[38;5;82m'
}

# Source utils.zsh
source "$DOTFILES_HOME/zsh/lib/utils.zsh" 2>/dev/null

CHECK_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --check|-c) CHECK_ONLY=true ;;
        --help|-h)
            echo "Usage: dotfiles-version.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --check    Only check for updates (exit 1 if behind)"
            echo "  --help     Show this help message"
            exit 0
            ;;
    esac
done

# ============================================================================
# MOTD-style header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-version "
    else
        local user="${USER:-root}"
        local hostname="${HOSTNAME:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local width=66
        local hline="" && for ((i=0; i<width; i++)); do hline+="═"; done

        echo ""
        echo -e "${DF_GREY}╒${hline}╕${DF_NC}"
        echo -e "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}      ${DF_LIGHT_GREEN}dotfiles-version${DF_NC}       ${datetime} ${DF_GREY}│${DF_NC}"
        echo -e "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

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

    print_header

    echo -e "${DF_CYAN}Local:${DF_NC}"
    echo -e "  Version:  ${DF_GREEN}${local_version}${DF_NC}"
    echo -e "  Commit:   ${local_commit}"
    echo -e "  Date:     ${local_date}"
    echo -e "  Path:     ${DOTFILES_DIR}"
    echo

    echo -e "${DF_CYAN}Remote:${DF_NC}"
    echo -e "  Version:  ${remote_version}"
    echo -e "  Commit:   ${remote_commit}"
    echo -e "  Branch:   ${DOTFILES_BRANCH}"
    echo

    echo -e "${DF_CYAN}Status:${DF_NC}"

    case "$version_status" in
        current)
            echo -e "  Version:  ${DF_GREEN}✓ Up to date${DF_NC}"
            ;;
        behind)
            echo -e "  Version:  ${DF_YELLOW}⚠ New version available: ${remote_version}${DF_NC}"
            ;;
        ahead)
            echo -e "  Version:  ${DF_CYAN}ℹ Local is ahead of remote${DF_NC}"
            ;;
        *)
            echo -e "  Version:  ${DF_YELLOW}? Cannot determine${DF_NC}"
            ;;
    esac

    if [[ "$commits_behind" -gt 0 ]]; then
        echo -e "  Commits:  ${DF_YELLOW}⚠ ${commits_behind} commit(s) behind${DF_NC}"
        echo
        echo -e "${DF_YELLOW}To update:${DF_NC}"
        echo "  dfu                          # Alias"
        echo "  dotfiles-update.sh           # Full command"
    elif [[ "$commits_behind" == "0" ]]; then
        echo -e "  Commits:  ${DF_GREEN}✓ Up to date${DF_NC}"
    fi

    echo
}

main "$@"
