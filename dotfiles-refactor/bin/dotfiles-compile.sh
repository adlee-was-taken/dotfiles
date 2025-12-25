#!/usr/bin/env zsh
# ============================================================================
# Dotfiles Compile - Pre-compile zsh files for faster loading
# ============================================================================

set -e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_CYAN=$'\033[0;36m'
    DF_NC=$'\033[0m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
}

# ============================================================================
# Functions
# ============================================================================

compile_file() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        if [[ ! -f "${file}.zwc" ]] || [[ "$file" -nt "${file}.zwc" ]]; then
            if zcompile "$file" 2>/dev/null; then
                echo -e "${DF_GREEN}✓${DF_NC} Compiled: ${file##*/}"
            else
                echo -e "${DF_YELLOW}⚠${DF_NC} Skipped:  ${file##*/}"
            fi
        else
            echo -e "${DF_CYAN}○${DF_NC} Current:  ${file##*/}"
        fi
    fi
}

clean_compiled() {
    echo "Removing compiled files..."
    
    local count=0
    
    # Remove .zwc files in dotfiles directory
    for zwc in "$DOTFILES_HOME"/**/*.zwc(N); do
        rm -f "$zwc"
        ((count++))
    done
    
    # Remove home directory compiled files
    rm -f ~/.zshrc.zwc ~/.zshenv.zwc ~/.zprofile.zwc 2>/dev/null
    
    echo -e "${DF_GREEN}✓${DF_NC} Removed $count compiled files"
}

compile_all() {
    echo -e "${DF_CYAN}Compiling zsh files for faster startup...${DF_NC}"
    echo ""
    
    echo "Core files:"
    compile_file ~/.zshrc
    compile_file ~/.zshenv
    compile_file ~/.zprofile
    echo ""
    
    echo "Dotfiles:"
    compile_file "$DOTFILES_HOME/zsh/.zshrc"
    compile_file "$DOTFILES_HOME/zsh/aliases.zsh"
    
    # Lib files
    for file in "$DOTFILES_HOME/zsh/lib"/*.zsh(N); do
        compile_file "$file"
    done
    
    # Function files
    for file in "$DOTFILES_HOME/zsh/functions"/*.zsh(N); do
        compile_file "$file"
    done
    
    # Theme files
    for file in "$DOTFILES_HOME/zsh/themes"/*.zsh-theme(N); do
        compile_file "$file"
    done
    echo ""
    
    # Oh-My-Zsh (optional)
    if [[ -d ~/.oh-my-zsh ]]; then
        echo "Oh-My-Zsh (optional):"
        compile_file ~/.oh-my-zsh/oh-my-zsh.sh
        echo ""
    fi
    
    echo -e "${DF_GREEN}✓${DF_NC} Compilation complete"
    echo ""
    echo "To measure startup time:"
    echo "  time zsh -i -c exit"
    echo "  hyperfine 'zsh -i -c exit'  # More accurate"
}

show_help() {
    echo "Usage: dotfiles-compile.sh [OPTIONS]"
    echo ""
    echo "Compile zsh files to bytecode for faster shell startup."
    echo ""
    echo "Options:"
    echo "  (none)    Compile all zsh files"
    echo "  --clean   Remove all compiled (.zwc) files"
    echo "  --help    Show this help"
}

# ============================================================================
# Main
# ============================================================================

df_print_header "dotfiles-compile"

case "${1:-}" in
    --clean|-c) clean_compiled ;;
    --help|-h) show_help ;;
    *) compile_all ;;
esac
