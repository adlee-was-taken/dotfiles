#!/usr/bin/env zsh
# ============================================================================
# Dotfiles Compile - Pre-compile zsh files for faster loading
# ============================================================================
# Compiles .zsh and .zshrc files to .zwc bytecode format
# This can speed up shell startup by 20-50ms
#
# Usage:
#   dotfiles-compile.sh           # Compile all
#   dotfiles-compile.sh --clean   # Remove compiled files
#
# Aliases: dfc-compile
# ============================================================================

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# MOTD-style header
# ============================================================================

_M_WIDTH=66

print_header() {
    local user="${USER:-root}"
    local hostname="${HOST:-$(hostname -s 2>/dev/null)}"
    local script_name="dotfiles-compile"
    local datetime=$(date '+%a %b %d %H:%M')
    
    # Colors
    local _M_RESET=$'\033[0m'
    local _M_BOLD=$'\033[1m'
    local _M_DIM=$'\033[2m'
    local _M_BLUE=$'\033[38;5;39m'
    local _M_GREY=$'\033[38;5;242m'
    
    # Build horizontal line
    local hline=""
    for ((i=0; i<_M_WIDTH; i++)); do hline+="═"; done
    local inner=$((_M_WIDTH - 2))
    
    # Header content
    local h_left="✦ ${user}@${hostname}"
    local h_center="${script_name}"
    local h_right="${datetime}"
    local h_pad=$(((inner - ${#h_left} - ${#h_center} - ${#h_right}) / 2))
    local h_spaces=""
    for ((i=0; i<h_pad; i++)); do h_spaces+=" "; done
    
    echo ""
    echo "${_M_GREY}╒${hline}╕${_M_RESET}"
    echo "${_M_GREY}│${_M_RESET} ${_M_BOLD}${_M_BLUE}${h_left}${_M_RESET}${h_spaces}${_M_DIM}${h_center}${h_spaces}${h_right}${_M_RESET} ${_M_GREY}│${_M_RESET}"
    echo "${_M_GREY}╘${hline}╛${_M_RESET}"
    echo ""
}

compile_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if [[ ! -f "${file}.zwc" ]] || [[ "$file" -nt "${file}.zwc" ]]; then
            zcompile "$file" 2>/dev/null && \
                echo -e "${GREEN}✓${NC} Compiled: ${file##*/}" || \
                echo -e "${YELLOW}⚠${NC} Skipped:  ${file##*/}"
        else
            echo -e "${CYAN}○${NC} Current:  ${file##*/}"
        fi
    fi
}

clean_compiled() {
    echo "Removing compiled files..."
    
    local count=0
    
    # Dotfiles
    for zwc in "$DOTFILES_DIR"/**/*.zwc(N); do
        rm -f "$zwc"
        ((count++))
    done
    
    # Home zsh files
    rm -f ~/.zshrc.zwc ~/.zshenv.zwc ~/.zprofile.zwc 2>/dev/null
    
    # Oh-my-zsh (optional)
    # rm -f ~/.oh-my-zsh/**/*.zwc(N) 2>/dev/null
    
    echo -e "${GREEN}✓${NC} Removed $count compiled files"
}

compile_all() {
    echo -e "${CYAN}Compiling zsh files for faster startup...${NC}"
    echo
    
    # Core files
    echo "Core files:"
    compile_file ~/.zshrc
    compile_file ~/.zshenv
    compile_file ~/.zprofile
    echo
    
    # Dotfiles zsh files
    echo "Dotfiles:"
    compile_file "$DOTFILES_DIR/zsh/.zshrc"
    compile_file "$DOTFILES_DIR/zsh/aliases.zsh"
    
    # Function files
    for file in "$DOTFILES_DIR/zsh/functions"/*.zsh(N); do
        compile_file "$file"
    done
    
    # Theme
    for file in "$DOTFILES_DIR/zsh/themes"/*.zsh-theme(N); do
        compile_file "$file"
    done
    echo
    
    # Oh-my-zsh core (optional, can save ~10ms)
    if [[ -d ~/.oh-my-zsh ]]; then
        echo "Oh-My-Zsh (optional):"
        compile_file ~/.oh-my-zsh/oh-my-zsh.sh
        # compile_file ~/.oh-my-zsh/lib/*.zsh  # Uncomment for more speed
        echo
    fi
    
    echo -e "${GREEN}✓${NC} Compilation complete"
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
    echo
    echo "The compiled files (.zwc) are automatically used by zsh"
    echo "and can speed up shell startup by 20-50ms."
}

# ============================================================================
# Main
# ============================================================================

print_header

case "${1:-}" in
    --clean|-c)
        clean_compiled
        ;;
    --help|-h)
        show_help
        ;;
    *)
        compile_all
        ;;
esac
