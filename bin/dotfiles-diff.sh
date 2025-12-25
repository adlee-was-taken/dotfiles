#!/usr/bin/env bash
# ============================================================================
# Dotfiles Diff & Audit Tool
# ============================================================================
# Compare configurations, audit for issues, and track changes.
#
# Usage:
#   dotfiles-diff.sh                    # Show uncommitted changes
#   dotfiles-diff.sh --symlinks         # Verify symlink integrity
#   dotfiles-diff.sh --secrets          # Audit for exposed secrets
#   dotfiles-diff.sh --permissions      # Check file permissions
#   dotfiles-diff.sh --audit            # Full security audit
# ============================================================================

set -e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_CYAN=$'\033[0;36m' DF_BLUE=$'\033[0;34m' DF_NC=$'\033[0m'
    DF_DIM=$'\033[2m'
    DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1" >&2; }
    df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
    df_print_step() { echo -e "${DF_BLUE}==>${DF_NC} $1"; }
    df_print_section() { echo -e "${DF_CYAN}$1:${DF_NC}"; }
    df_print_indent() { echo "  $1"; }
}

DOTFILES_DIR="${DOTFILES_HOME:-$HOME/.dotfiles}"

# ============================================================================
# Diff Functions
# ============================================================================

# Show git diff for uncommitted changes
show_git_diff() {
    df_print_section "Uncommitted Changes"
    
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        df_print_warning "Not a git repository"
        return 1
    fi
    
    cd "$DOTFILES_DIR"
    
    local changes=$(git status --porcelain 2>/dev/null)
    
    if [[ -z "$changes" ]]; then
        df_print_success "No uncommitted changes"
        return 0
    fi
    
    echo ""
    echo "$changes" | while read -r status file; do
        case "$status" in
            M*|" M") echo -e "  ${DF_YELLOW}modified:${DF_NC}  $file" ;;
            A*|"A ") echo -e "  ${DF_GREEN}added:${DF_NC}     $file" ;;
            D*|" D") echo -e "  ${DF_RED}deleted:${DF_NC}   $file" ;;
            R*)      echo -e "  ${DF_BLUE}renamed:${DF_NC}   $file" ;;
            \?\?)    echo -e "  ${DF_DIM}untracked:${DF_NC} $file" ;;
            *)       echo -e "  ${status}: $file" ;;
        esac
    done
    
    echo ""
    df_print_step "View full diff: git -C $DOTFILES_DIR diff"
}

# Show what's different between repo and installed files
show_installed_diff() {
    df_print_section "Installed File Differences"
    echo ""
    
    local files_to_check=(
        "$HOME/.zshrc:$DOTFILES_DIR/zsh/.zshrc"
        "$HOME/.gitconfig:$DOTFILES_DIR/git/.gitconfig"
        "$HOME/.vimrc:$DOTFILES_DIR/vim/.vimrc"
        "$HOME/.tmux.conf:$DOTFILES_DIR/tmux/.tmux.conf"
    )
    
    local has_diff=false
    
    for pair in "${files_to_check[@]}"; do
        local installed="${pair%%:*}"
        local source="${pair#*:}"
        local name=$(basename "$installed")
        
        if [[ ! -e "$installed" ]]; then
            echo -e "  ${DF_YELLOW}⚠${DF_NC} $name: not installed"
            continue
        fi
        
        if [[ -L "$installed" ]]; then
            local target=$(readlink -f "$installed")
            if [[ "$target" == "$source" ]] || [[ "$target" == "$(readlink -f "$source")" ]]; then
                echo -e "  ${DF_GREEN}✓${DF_NC} $name: symlink OK"
            else
                echo -e "  ${DF_YELLOW}⚠${DF_NC} $name: symlink points elsewhere → $target"
                has_diff=true
            fi
        else
            # Regular file - check if different
            if diff -q "$installed" "$source" &>/dev/null; then
                echo -e "  ${DF_GREEN}✓${DF_NC} $name: content matches (regular file)"
            else
                echo -e "  ${DF_RED}✗${DF_NC} $name: differs from source"
                has_diff=true
            fi
        fi
    done
    
    if [[ "$has_diff" == true ]]; then
        echo ""
        df_print_warning "Some files differ. Run installer to sync: ./install.sh"
    fi
}

# ============================================================================
# Symlink Verification
# ============================================================================

check_symlinks() {
    df_print_section "Symlink Integrity Check"
    echo ""
    
    local symlinks=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
    )
    
    local broken=0
    local missing=0
    local ok=0
    
    for link in "${symlinks[@]}"; do
        local name=$(basename "$link")
        
        if [[ ! -e "$link" && ! -L "$link" ]]; then
            echo -e "  ${DF_DIM}○${DF_NC} $name: not installed"
            ((missing++))
        elif [[ -L "$link" ]]; then
            if [[ -e "$link" ]]; then
                echo -e "  ${DF_GREEN}✓${DF_NC} $name → $(readlink "$link")"
                ((ok++))
            else
                echo -e "  ${DF_RED}✗${DF_NC} $name: BROKEN → $(readlink "$link")"
                ((broken++))
            fi
        else
            echo -e "  ${DF_YELLOW}⚠${DF_NC} $name: regular file (not symlink)"
        fi
    done
    
    # Check bin scripts
    echo ""
    df_print_section "Bin Script Symlinks"
    
    if [[ -d "$HOME/.local/bin" ]]; then
        for script in "$HOME/.local/bin"/dotfiles-*.sh; do
            [[ -e "$script" ]] || continue
            local name=$(basename "$script")
            
            if [[ -L "$script" ]]; then
                if [[ -e "$script" ]]; then
                    echo -e "  ${DF_GREEN}✓${DF_NC} $name"
                    ((ok++))
                else
                    echo -e "  ${DF_RED}✗${DF_NC} $name: BROKEN"
                    ((broken++))
                fi
            fi
        done
    fi
    
    echo ""
    df_print_section "Summary"
    df_print_indent "OK: $ok | Missing: $missing | Broken: $broken"
    
    if (( broken > 0 )); then
        echo ""
        df_print_error "Found $broken broken symlinks!"
        df_print_indent "Fix with: dffix"
    fi
}

# ============================================================================
# Security Audit
# ============================================================================

audit_secrets() {
    df_print_section "Secret Detection Audit"
    echo ""
    
    cd "$DOTFILES_DIR"
    
    local issues=0
    
    # Patterns that might indicate secrets
    local patterns=(
        'api[_-]?key\s*[:=]'
        'secret[_-]?key\s*[:=]'
        'password\s*[:=]'
        'token\s*[:=]'
        'private[_-]?key'
        'BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY'
        'aws_access_key_id'
        'aws_secret_access_key'
    )
    
    df_print_step "Scanning tracked files..."
    
    for pattern in "${patterns[@]}"; do
        local matches=$(git grep -l -i -E "$pattern" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            echo ""
            df_print_warning "Pattern '$pattern' found in:"
            echo "$matches" | while read -r file; do
                df_print_indent "  $file"
                ((issues++))
            done
        fi
    done
    
    if (( issues == 0 )); then
        df_print_success "No obvious secrets found in tracked files"
    else
        echo ""
        df_print_error "Found potential secrets in $issues location(s)"
        df_print_indent "Review these files and use the vault for sensitive data"
    fi
    
    # Check git history (limited)
    echo ""
    df_print_step "Scanning recent git history (last 50 commits)..."
    
    local history_issues=$(git log -50 --all -p 2>/dev/null | grep -c -i -E 'password|secret|api.?key|token' || echo 0)
    
    if (( history_issues > 0 )); then
        df_print_warning "Found $history_issues potential matches in git history"
        df_print_indent "Consider: git filter-branch or BFG Repo Cleaner"
    else
        df_print_success "No obvious secrets in recent history"
    fi
}

audit_permissions() {
    df_print_section "File Permission Audit"
    echo ""
    
    cd "$DOTFILES_DIR"
    
    local issues=0
    
    # Check for world-writable files
    df_print_step "Checking for world-writable files..."
    local world_writable=$(find . -type f -perm -o+w 2>/dev/null | grep -v ".git" || true)
    
    if [[ -n "$world_writable" ]]; then
        df_print_warning "World-writable files found:"
        echo "$world_writable" | while read -r file; do
            df_print_indent "$file"
            ((issues++))
        done
    else
        df_print_success "No world-writable files"
    fi
    
    # Check bin scripts are executable
    echo ""
    df_print_step "Checking bin script permissions..."
    
    for script in "$DOTFILES_DIR/bin"/*.sh; do
        [[ -f "$script" ]] || continue
        local name=$(basename "$script")
        
        if [[ -x "$script" ]]; then
            echo -e "  ${DF_GREEN}✓${DF_NC} $name"
        else
            echo -e "  ${DF_RED}✗${DF_NC} $name: not executable"
            ((issues++))
        fi
    done
    
    # Check sensitive directories
    echo ""
    df_print_step "Checking sensitive directories..."
    
    if [[ -d "$DOTFILES_DIR/vault" ]]; then
        local vault_perms=$(stat -c %a "$DOTFILES_DIR/vault" 2>/dev/null || stat -f %Lp "$DOTFILES_DIR/vault" 2>/dev/null)
        if [[ "$vault_perms" == "700" ]]; then
            df_print_success "vault/ directory: 700 (secure)"
        else
            df_print_warning "vault/ directory: $vault_perms (should be 700)"
            ((issues++))
        fi
    fi
    
    echo ""
    if (( issues == 0 )); then
        df_print_success "All permission checks passed"
    else
        df_print_warning "Found $issues permission issues"
    fi
}

full_audit() {
    df_print_step "Running full security audit..."
    echo ""
    
    audit_secrets
    echo ""
    audit_permissions
    echo ""
    check_symlinks
}

# ============================================================================
# Machine Comparison
# ============================================================================

compare_machines() {
    df_print_section "Machine Configuration Comparison"
    echo ""
    
    local machines_dir="$DOTFILES_DIR/machines"
    
    if [[ ! -d "$machines_dir" ]] || [[ -z "$(ls -A "$machines_dir" 2>/dev/null)" ]]; then
        df_print_info "No machine configs to compare"
        df_print_indent "Create with: df_machine_create"
        return
    fi
    
    local configs=("$machines_dir"/*.zsh(N))
    
    if (( ${#configs[@]} < 2 )); then
        df_print_info "Need at least 2 machine configs to compare"
        return
    fi
    
    df_print_step "Available configs:"
    for config in "${configs[@]}"; do
        df_print_indent "$(basename "$config" .zsh)"
    done
    
    echo ""
    read -p "Compare which two? (e.g., 'laptop server'): " config1 config2
    
    if [[ -f "$machines_dir/$config1.zsh" && -f "$machines_dir/$config2.zsh" ]]; then
        echo ""
        diff -u --color=always "$machines_dir/$config1.zsh" "$machines_dir/$config2.zsh" || true
    else
        df_print_error "Config not found"
    fi
}

# ============================================================================
# Help
# ============================================================================

show_help() {
    cat << 'EOF'
Dotfiles Diff & Audit Tool

Usage: dotfiles-diff.sh [OPTIONS]

Options:
  (none)           Show uncommitted git changes
  --installed      Compare installed files with source
  --symlinks       Verify symlink integrity
  --secrets        Scan for exposed secrets
  --permissions    Check file permissions
  --audit          Full security audit (secrets + permissions + symlinks)
  --machines       Compare machine configurations
  --help           Show this help

Examples:
  dotfiles-diff.sh                  # Quick git status
  dotfiles-diff.sh --symlinks       # Verify all symlinks are valid
  dotfiles-diff.sh --audit          # Full security audit
  dotfiles-diff.sh --machines       # Compare laptop vs server configs

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    df_print_header "dotfiles-diff"
    
    case "${1:-}" in
        --installed|-i)
            show_installed_diff
            ;;
        --symlinks|-s)
            check_symlinks
            ;;
        --secrets)
            audit_secrets
            ;;
        --permissions|-p)
            audit_permissions
            ;;
        --audit|-a)
            full_audit
            ;;
        --machines|-m)
            compare_machines
            ;;
        --help|-h)
            show_help
            ;;
        *)
            show_git_diff
            echo ""
            show_installed_diff
            ;;
    esac
}

main "$@"
