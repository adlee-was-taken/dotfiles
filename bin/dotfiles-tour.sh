#!/usr/bin/env bash
# ============================================================================
# Dotfiles First-Run Experience & Tour
# ============================================================================
# Provides a guided introduction for new users and after updates.
#
# Usage:
#   dotfiles-tour.sh             # Interactive tour
#   dotfiles-tour.sh --quick     # Quick feature overview
#   dotfiles-tour.sh --changelog # Show recent changes
# ============================================================================

set -e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_CYAN=$'\033[0;36m' DF_BLUE=$'\033[0;34m' DF_MAGENTA=$'\033[0;35m'
    DF_NC=$'\033[0m' DF_DIM=$'\033[2m' DF_BOLD=$'\033[1m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    DOTFILES_VERSION="${DOTFILES_VERSION:-1.0.0}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_section() { echo -e "${DF_CYAN}$1:${DF_NC}"; }
    df_print_indent() { echo "  $1"; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_info() { echo -e "${DF_CYAN}ℹ${DF_NC} $1"; }
}

DOTFILES_DIR="${DOTFILES_HOME:-$HOME/.dotfiles}"
FIRST_RUN_FILE="$DOTFILES_DIR/.initialized"
LAST_VERSION_FILE="$DOTFILES_DIR/.last-version"

# ============================================================================
# Welcome Screen
# ============================================================================

show_welcome() {
    clear
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║     █████╗ ██████╗ ██╗     ███████╗███████╗                   ║
    ║    ██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝                   ║
    ║    ███████║██║  ██║██║     █████╗  █████╗                     ║
    ║    ██╔══██║██║  ██║██║     ██╔══╝  ██╔══╝                     ║
    ║    ██║  ██║██████╔╝███████╗███████╗███████╗                   ║
    ║    ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝                   ║
    ║                                                               ║
    ║              D O T F I L E S                                  ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo ""
    echo -e "    ${DF_DIM}Version: ${DOTFILES_VERSION}${DF_NC}"
    echo ""
    echo -e "    Welcome to ADLee's Dotfiles!"
    echo -e "    ${DF_DIM}A productive development environment for Arch/CachyOS${DF_NC}"
    echo ""
}

# ============================================================================
# Tour Pages
# ============================================================================

tour_navigation() {
    clear
    df_print_header "Navigation & Shortcuts"
    echo ""
    
    df_print_section "Directory Navigation"
    echo ""
    echo -e "  ${DF_CYAN}..${DF_NC}           Go up one directory"
    echo -e "  ${DF_CYAN}...${DF_NC}          Go up two directories"
    echo -e "  ${DF_CYAN}~${DF_NC}            Go to home"
    echo -e "  ${DF_CYAN}c.${DF_NC}           Go to dotfiles directory"
    echo ""
    
    df_print_section "Bookmarks"
    echo ""
    echo -e "  ${DF_CYAN}bookmark add work ~/projects/work${DF_NC}"
    echo -e "  ${DF_CYAN}j work${DF_NC}       Jump to bookmark"
    echo -e "  ${DF_CYAN}bm list${DF_NC}      List all bookmarks"
    echo ""
    
    df_print_section "Command Palette (Ctrl+Space)"
    echo ""
    echo -e "  Fuzzy search through:"
    echo -e "  • Aliases and functions"
    echo -e "  • Command history"
    echo -e "  • Bookmarks"
    echo -e "  • Quick actions"
}

tour_dotfiles_management() {
    clear
    df_print_header "Dotfiles Management"
    echo ""
    
    df_print_section "Quick Commands"
    echo ""
    echo -e "  ${DF_GREEN}dfd${DF_NC}          Health check (doctor)"
    echo -e "  ${DF_GREEN}dffix${DF_NC}        Auto-fix issues"
    echo -e "  ${DF_GREEN}dfu${DF_NC}          Update dotfiles"
    echo -e "  ${DF_GREEN}dfs${DF_NC}          Sync status"
    echo -e "  ${DF_GREEN}dfpush${DF_NC}       Push changes"
    echo -e "  ${DF_GREEN}dfpull${DF_NC}       Pull changes"
    echo ""
    
    df_print_section "Quick Edit"
    echo ""
    echo -e "  ${DF_CYAN}v.zshrc${DF_NC}      Edit ~/.zshrc"
    echo -e "  ${DF_CYAN}v.conf${DF_NC}       Edit dotfiles.conf"
    echo -e "  ${DF_CYAN}v.alias${DF_NC}      Edit aliases"
    echo -e "  ${DF_CYAN}reload${DF_NC}       Reload shell config"
    echo ""
    
    df_print_section "Machine-Specific Config"
    echo ""
    echo -e "  ${DF_CYAN}machine-info${DF_NC}    Show current machine detection"
    echo -e "  ${DF_CYAN}machine-create${DF_NC}  Create config for this machine"
}

tour_git_helpers() {
    clear
    df_print_header "Git & Development"
    echo ""
    
    df_print_section "Git Shortcuts"
    echo ""
    echo -e "  ${DF_GREEN}g${DF_NC}   = git"
    echo -e "  ${DF_GREEN}gs${DF_NC}  = git status"
    echo -e "  ${DF_GREEN}ga${DF_NC}  = git add"
    echo -e "  ${DF_GREEN}gc${DF_NC}  = git commit"
    echo -e "  ${DF_GREEN}gp${DF_NC}  = git push"
    echo -e "  ${DF_GREEN}gl${DF_NC}  = git pull"
    echo -e "  ${DF_GREEN}gd${DF_NC}  = git diff"
    echo -e "  ${DF_GREEN}glog${DF_NC} = pretty log graph"
    echo ""
    
    df_print_section "Project Templates"
    echo ""
    echo -e "  ${DF_CYAN}py-new myproject${DF_NC}      Basic Python"
    echo -e "  ${DF_CYAN}py-flask myapp${DF_NC}        Flask web app"
    echo -e "  ${DF_CYAN}py-fastapi myapi${DF_NC}      FastAPI REST"
    echo -e "  ${DF_CYAN}py-cli mytool${DF_NC}         CLI with Click"
    echo -e "  ${DF_CYAN}py-data analysis${DF_NC}      Data science"
    echo ""
    
    df_print_section "Project Environments"
    echo ""
    echo -e "  Auto-loads ${DF_CYAN}.dotfiles-local${DF_NC} when entering directories"
    echo -e "  Auto-activates Python virtualenvs"
    echo -e "  Auto-switches Node versions via .nvmrc"
}

tour_tmux_workspaces() {
    clear
    df_print_header "Tmux Workspaces"
    echo ""
    
    df_print_section "Quick Commands"
    echo ""
    echo -e "  ${DF_GREEN}tw myproject${DF_NC}      Create/attach workspace"
    echo -e "  ${DF_GREEN}tw myproject dev${DF_NC}  Create with 'dev' template"
    echo -e "  ${DF_GREEN}twl${DF_NC}               List workspaces"
    echo -e "  ${DF_GREEN}twf${DF_NC}               Fuzzy search workspaces"
    echo -e "  ${DF_GREEN}tws mytemplate${DF_NC}    Save current layout"
    echo ""
    
    df_print_section "Built-in Templates"
    echo ""
    echo -e "  ${DF_CYAN}dev${DF_NC}       Editor + terminal + logs"
    echo -e "  ${DF_CYAN}ops${DF_NC}       4-pane monitoring grid"
    echo -e "  ${DF_CYAN}review${DF_NC}    Side-by-side comparison"
    echo -e "  ${DF_CYAN}debug${DF_NC}     Main (70%) + helper (30%)"
    echo -e "  ${DF_CYAN}ssh-multi${DF_NC} 4 panes for servers"
    echo ""
    
    df_print_section "Tmuxinator (if installed)"
    echo ""
    echo -e "  ${DF_CYAN}txi myproject${DF_NC}      Start tmuxinator project"
    echo -e "  ${DF_CYAN}txi-new myproj dev${DF_NC} Create from template"
}

tour_system_tools() {
    clear
    df_print_header "System Administration"
    echo ""
    
    df_print_section "Systemd Helpers"
    echo ""
    echo -e "  ${DF_GREEN}sc${DF_NC}         sudo systemctl"
    echo -e "  ${DF_GREEN}scr${DF_NC} svc    Restart + status"
    echo -e "  ${DF_GREEN}sce${DF_NC} svc    Enable + start"
    echo -e "  ${DF_GREEN}scd${DF_NC} svc    Disable + stop"
    echo -e "  ${DF_GREEN}sclog${DF_NC} svc  Follow logs"
    echo -e "  ${DF_GREEN}scf${DF_NC}        Interactive (fzf)"
    echo -e "  ${DF_GREEN}sc-failed${DF_NC}  Show failed services"
    echo ""
    
    df_print_section "Btrfs & Snapshots (if using btrfs)"
    echo ""
    echo -e "  ${DF_CYAN}btrfs-health${DF_NC}    Quick filesystem check"
    echo -e "  ${DF_CYAN}snap 'desc'${DF_NC}     Create snapshot"
    echo -e "  ${DF_CYAN}snapls${DF_NC}          List snapshots"
    echo -e "  ${DF_CYAN}sys-update${DF_NC}      Update with pre/post snapshot"
    echo ""
    
    df_print_section "SSH Manager"
    echo ""
    echo -e "  ${DF_CYAN}ssh-save myserver user@host${DF_NC}"
    echo -e "  ${DF_CYAN}sshc myserver${DF_NC}   Connect (auto-tmux)"
    echo -e "  ${DF_CYAN}sshf${DF_NC}            Fuzzy search servers"
}

tour_productivity() {
    clear
    df_print_header "Productivity Features"
    echo ""
    
    df_print_section "Smart Suggestions"
    echo ""
    echo -e "  Auto-corrects common typos: ${DF_DIM}gti → git${DF_NC}"
    echo -e "  Suggests packages for missing commands"
    echo -e "  Use ${DF_CYAN}fuck${DF_NC} to re-run corrected command"
    echo ""
    
    df_print_section "Long-Running Command Notifications"
    echo ""
    echo -e "  Desktop notifications when commands take > 60s"
    echo -e "  ${DF_CYAN}notify-toggle${DF_NC}     Enable/disable"
    echo -e "  ${DF_CYAN}notify-status${DF_NC}     Check configuration"
    echo ""
    
    df_print_section "Password Manager (LastPass)"
    echo ""
    echo -e "  ${DF_CYAN}pw search${DF_NC}        Search and copy password"
    echo -e "  ${DF_CYAN}pwf${DF_NC}              Fuzzy search (fzf)"
    echo -e "  ${DF_CYAN}pw gen 24${DF_NC}        Generate 24-char password"
    echo ""
    
    df_print_section "Secrets Vault"
    echo ""
    echo -e "  ${DF_CYAN}vault init${DF_NC}       Initialize encrypted vault"
    echo -e "  ${DF_CYAN}vault set KEY${DF_NC}    Store a secret"
    echo -e "  ${DF_CYAN}vault get KEY${DF_NC}    Retrieve a secret"
}

tour_complete() {
    clear
    df_print_header "Tour Complete!"
    echo ""
    
    df_print_success "You're ready to go!"
    echo ""
    
    df_print_section "Quick Reference"
    echo ""
    echo -e "  ${DF_CYAN}dfd${DF_NC}              Run health check"
    echo -e "  ${DF_CYAN}Ctrl+Space${DF_NC}       Command palette"
    echo -e "  ${DF_CYAN}dotfiles-cli help${DF_NC} Full command list"
    echo ""
    
    df_print_section "Documentation"
    echo ""
    echo -e "  ${DF_CYAN}~/.dotfiles/README.md${DF_NC}"
    echo -e "  ${DF_CYAN}~/.dotfiles/docs/REFERENCE.md${DF_NC}"
    echo ""
    
    df_print_section "Getting Help"
    echo ""
    echo -e "  Most commands support ${DF_CYAN}--help${DF_NC}"
    echo -e "  Check ${DF_CYAN}~/.dotfiles/INSTALL.md${DF_NC} for troubleshooting"
    echo ""
    
    # Mark first run complete
    touch "$FIRST_RUN_FILE"
    echo "$DOTFILES_VERSION" > "$LAST_VERSION_FILE"
}

# ============================================================================
# Interactive Tour
# ============================================================================

run_interactive_tour() {
    local pages=(
        "show_welcome:Welcome"
        "tour_navigation:Navigation & Shortcuts"
        "tour_dotfiles_management:Dotfiles Management"
        "tour_git_helpers:Git & Development"
        "tour_tmux_workspaces:Tmux Workspaces"
        "tour_system_tools:System Administration"
        "tour_productivity:Productivity Features"
        "tour_complete:Complete"
    )
    
    local current=0
    local total=${#pages[@]}
    
    while true; do
        local page_info="${pages[$current]}"
        local func="${page_info%%:*}"
        local title="${page_info#*:}"
        
        # Show current page
        $func
        
        # Navigation footer
        echo ""
        echo -e "${DF_DIM}─────────────────────────────────────────────────────────────${DF_NC}"
        echo -e "  Page $((current + 1)) of $total: ${DF_CYAN}$title${DF_NC}"
        echo ""
        
        if (( current == total - 1 )); then
            echo -e "  Press ${DF_GREEN}Enter${DF_NC} to finish, ${DF_CYAN}p${DF_NC} for previous, ${DF_RED}q${DF_NC} to quit"
        else
            echo -e "  Press ${DF_GREEN}Enter${DF_NC} for next, ${DF_CYAN}p${DF_NC} for previous, ${DF_RED}q${DF_NC} to quit"
        fi
        
        read -rsn1 key
        
        case "$key" in
            q|Q)
                echo ""
                echo "Tour cancelled. Run 'dotfiles-tour.sh' anytime to continue."
                exit 0
                ;;
            p|P)
                (( current > 0 )) && ((current--))
                ;;
            *)
                if (( current == total - 1 )); then
                    echo ""
                    echo -e "${DF_GREEN}Enjoy your new shell!${DF_NC}"
                    exit 0
                fi
                ((current++))
                ;;
        esac
    done
}

# ============================================================================
# Quick Overview
# ============================================================================

show_quick_overview() {
    df_print_header "Quick Feature Overview"
    echo ""
    
    cat << 'EOF'
╭──────────────────────────────────────────────────────────────╮
│  NAVIGATION                                                  │
│    Ctrl+Space  Command palette    j <bookmark>  Jump         │
│    ..          Up directory       c.            Dotfiles dir │
├──────────────────────────────────────────────────────────────┤
│  DOTFILES                                                    │
│    dfd         Health check       dfu           Update       │
│    dfpush      Push changes       reload        Reload shell │
├──────────────────────────────────────────────────────────────┤
│  GIT                                                         │
│    gs          Status             glog          Pretty log   │
│    ga/gc/gp    Add/commit/push    gd            Diff         │
├──────────────────────────────────────────────────────────────┤
│  TMUX                                                        │
│    tw <name>   Create workspace   twl           List         │
│    twf         Fuzzy search       tws           Save layout  │
├──────────────────────────────────────────────────────────────┤
│  SYSTEM                                                      │
│    sc          systemctl          scf           Interactive  │
│    scr <svc>   Restart service    sc-failed     Show failed  │
├──────────────────────────────────────────────────────────────┤
│  PYTHON                                                      │
│    py-new      Basic project      py-flask      Flask app    │
│    py-fastapi  REST API           venv          Activate env │
╰──────────────────────────────────────────────────────────────╯
EOF
    
    echo ""
    df_print_info "Run 'dotfiles-tour.sh' for full interactive tour"
}

# ============================================================================
# Changelog
# ============================================================================

show_changelog() {
    df_print_header "Recent Changes"
    echo ""
    
    cd "$DOTFILES_DIR"
    
    local last_version=""
    [[ -f "$LAST_VERSION_FILE" ]] && last_version=$(cat "$LAST_VERSION_FILE")
    
    if [[ -n "$last_version" && "$last_version" != "$DOTFILES_VERSION" ]]; then
        echo -e "Updated from ${DF_YELLOW}$last_version${DF_NC} to ${DF_GREEN}$DOTFILES_VERSION${DF_NC}"
        echo ""
    fi
    
    df_print_section "Recent Commits"
    echo ""
    
    if [[ -d .git ]]; then
        git log --oneline -15 2>/dev/null | while read -r line; do
            echo -e "  ${DF_DIM}•${DF_NC} $line"
        done
    else
        echo "  (git history not available)"
    fi
    
    echo ""
    
    # Update version tracking
    echo "$DOTFILES_VERSION" > "$LAST_VERSION_FILE"
}

# ============================================================================
# First Run Check
# ============================================================================

check_first_run() {
    if [[ ! -f "$FIRST_RUN_FILE" ]]; then
        echo ""
        echo -e "${DF_CYAN}Welcome!${DF_NC} This appears to be your first time using these dotfiles."
        echo -e "Run ${DF_GREEN}dotfiles-tour.sh${DF_NC} for a quick introduction."
        echo ""
    fi
}

# ============================================================================
# Help
# ============================================================================

show_help() {
    cat << 'EOF'
Dotfiles Tour & First-Run Experience

Usage: dotfiles-tour.sh [OPTIONS]

Options:
  (none)        Interactive tour
  --quick, -q   Quick feature overview
  --changelog   Show recent changes
  --check       Check if first run (for .zshrc)
  --help        Show this help

The tour introduces all major features of the dotfiles system.
Run it anytime to refresh your memory!

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    case "${1:-}" in
        --quick|-q)
            df_print_header "dotfiles-tour"
            show_quick_overview
            ;;
        --changelog|-c)
            df_print_header "dotfiles-tour"
            show_changelog
            ;;
        --check)
            check_first_run
            ;;
        --help|-h)
            show_help
            ;;
        *)
            run_interactive_tour
            ;;
    esac
}

main "$@"
