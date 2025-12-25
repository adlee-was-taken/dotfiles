#!/usr/bin/env zsh
# ============================================================================
# Dotfiles Compile - Pre-compile zsh files for faster loading
# ============================================================================

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Source shared colors and utils (provides DF_WIDTH)
source "$DOTFILES_DIR/zsh/lib/utils.zsh" 2>/dev/null || \
source "$DOTFILES_DIR/zsh/lib/colors.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_CYAN=$'\033[0;36m'
    DF_NC=$'\033[0m' DF_GREY=$'\033[38;5;242m' DF_LIGHT_BLUE=$'\033[38;5;39m'
    DF_BOLD=$'\033[1m' DF_DIM=$'\033[2m'
}

# Use DF_WIDTH from utils.zsh or default to 66
typeset -g WIDTH="${DF_WIDTH:-66}"

# ============================================================================
# MOTD-style header
# ============================================================================

print_header() {
    if declare -f df_print_header &>/dev/null; then
        df_print_header "dotfiles-compile "
    else
        local user="${USER:-root}"
        local hostname="${HOST:-$(hostname -s 2>/dev/null)}"
        local datetime=$(date '+%a %b %d %H:%M')
        local hline=""
        for ((i=0; i<WIDTH; i++)); do hline+="═"; done

        echo ""
        echo "${DF_GREY}╒${hline}╕${DF_NC}"
        echo "${DF_GREY}│${DF_NC} ${DF_BOLD}${DF_LIGHT_BLUE}✦ ${user}@${hostname}${DF_NC}      ${DF_DIM}dotfiles-compile${DF_NC}      ${datetime} ${DF_GREY}│${DF_NC}"
        echo "${DF_GREY}╘${hline}╛${DF_NC}"
        echo ""
    fi
}

compile_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if [[ ! -f "${file}.zwc" ]] || [[ "$file" -nt "${file}.zwc" ]]; then
            zcompile "$file" 2>/dev/null && \
                echo -e "${DF_GREEN}✓${DF_NC} Compiled: ${file##*/}" || \
                echo -e "${DF_YELLOW}⚠${DF_NC} Skipped:  ${file##*/}"
        else
            echo -e "${DF_CYAN}○${DF_NC} Current:  ${file##*/}"
        fi
    fi
}

clean_compiled() {
    echo "Removing compiled files..."

    local count=0

    for zwc in "$DOTFILES_DIR"/**/*.zwc(N); do
        rm -f "$zwc"
        ((count++))
    done

    rm -f ~/.zshrc.zwc ~/.zshenv.zwc ~/.zprofile.zwc 2>/dev/null

    echo -e "${DF_GREEN}✓${DF_NC} Removed $count compiled files"
}

compile_all() {
    echo -e "${DF_CYAN}Compiling zsh files for faster startup...${DF_NC}"
    echo

    echo "Core files:"
    compile_file ~/.zshrc
    compile_file ~/.zshenv
    compile_file ~/.zprofile
    echo

    echo "Dotfiles:"
    compile_file "$DOTFILES_DIR/zsh/.zshrc"
    compile_file "$DOTFILES_DIR/zsh/aliases.zsh"

    for file in "$DOTFILES_DIR/zsh/lib"/*.zsh(N); do
        compile_file "$file"
    done

    for file in "$DOTFILES_DIR/zsh/functions"/*.zsh(N); do
        compile_file "$file"
    done

    for file in "$DOTFILES_DIR/zsh/themes"/*.zsh-theme(N); do
        compile_file "$file"
    done
    echo

    if [[ -d ~/.oh-my-zsh ]]; then
        echo "Oh-My-Zsh (optional):"
        compile_file ~/.oh-my-zsh/oh-my-zsh.sh
        echo
    fi

    echo -e "${DF_GREEN}✓${DF_NC} Compilation complete"
    echo
    echo "To measure startup time:"
    echo "  time zsh -i -c exit"
    echo "  hyperfine 'zsh -i -c exit'  # More accurate"
}

show_help() {
    echo "Usage: dotfiles-compile.sh [OPTIONS]"
    echo
    echo "Compile zsh files to bytecode for faster shell startup."
    echo
    echo "Options:"
    echo "  (none)    Compile all zsh files"
    echo "  --clean   Remove all compiled (.zwc) files"
    echo "  --help    Show this help"
}

# ============================================================================
# Main
# ============================================================================

print_header

case "${1:-}" in
    --clean|-c) clean_compiled ;;
    --help|-h) show_help ;;
    *) compile_all ;;
esac
