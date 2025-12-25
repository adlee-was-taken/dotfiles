#!/usr/bin/env bash
# ============================================================================
# Dotfiles Startup Profiler
# ============================================================================
# Measures and analyzes shell startup time to identify slow components.
#
# Usage:
#   dotfiles-profile.sh              # Quick profile
#   dotfiles-profile.sh --detailed   # Detailed zprof output
#   dotfiles-profile.sh --benchmark  # Multiple runs with hyperfine
#   dotfiles-profile.sh --compare    # Compare with minimal shell
# ============================================================================

# Don't exit on error
set +e

# Source bootstrap
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/lib/bootstrap.zsh" 2>/dev/null || {
    DF_GREEN=$'\033[0;32m' DF_YELLOW=$'\033[1;33m' DF_RED=$'\033[0;31m'
    DF_CYAN=$'\033[0;36m' DF_BLUE=$'\033[0;34m' DF_NC=$'\033[0m'
    DF_DIM=$'\033[2m'
    df_print_header() { echo "=== $1 ==="; }
    df_print_success() { echo -e "${DF_GREEN}✓${DF_NC} $1"; }
    df_print_warning() { echo -e "${DF_YELLOW}⚠${DF_NC} $1"; }
    df_print_error() { echo -e "${DF_RED}✗${DF_NC} $1"; }
    df_print_info() { echo -e "${DF_CYAN}ℹ${DF_NC} $1"; }
    df_print_step() { echo -e "${DF_BLUE}==>${DF_NC} $1"; }
    df_print_section() { echo -e "${DF_CYAN}$1:${DF_NC}"; }
    df_print_indent() { echo "  $1"; }
}

# ============================================================================
# Configuration
# ============================================================================

PROFILE_RUNS=5
SLOW_THRESHOLD_MS=200
VERY_SLOW_THRESHOLD_MS=500

# ============================================================================
# Time Measurement Helper
# ============================================================================

# Get time in milliseconds (portable)
get_time_ms() {
    # Try GNU date with nanoseconds
    if date +%s%3N 2>/dev/null | grep -qE '^[0-9]+$'; then
        date +%s%3N
    # Try perl (very portable)
    elif command -v perl &>/dev/null; then
        perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1000'
    # Try python
    elif command -v python3 &>/dev/null; then
        python3 -c 'import time; print(int(time.time() * 1000))'
    elif command -v python &>/dev/null; then
        python -c 'import time; print(int(time.time() * 1000))'
    # Fallback to seconds (less precise)
    else
        echo "$(($(date +%s) * 1000))"
    fi
}

# Time a command and return milliseconds
time_command() {
    local start end
    start=$(get_time_ms)
    eval "$@" 2>/dev/null
    end=$(get_time_ms)
    echo $((end - start))
}

# ============================================================================
# Profiling Functions
# ============================================================================

# Quick timing measurement
quick_profile() {
    df_print_section "Quick Startup Timing"
    echo ""
    
    local times=()
    local i duration
    
    for i in $(seq 1 $PROFILE_RUNS); do
        duration=$(time_command "zsh -i -c 'exit'")
        times+=("$duration")
        printf "  Run %d: ${DF_CYAN}%dms${DF_NC}\n" "$i" "$duration"
    done
    
    # Calculate average
    local sum=0
    local t
    for t in "${times[@]}"; do
        sum=$((sum + t))
    done
    local avg=$((sum / PROFILE_RUNS))
    
    echo ""
    df_print_section "Results"
    
    if (( avg < SLOW_THRESHOLD_MS )); then
        echo -e "  Average: ${DF_GREEN}${avg}ms${DF_NC} (excellent)"
    elif (( avg < VERY_SLOW_THRESHOLD_MS )); then
        echo -e "  Average: ${DF_YELLOW}${avg}ms${DF_NC} (acceptable)"
    else
        echo -e "  Average: ${DF_RED}${avg}ms${DF_NC} (slow - optimization recommended)"
    fi
}

# Detailed zprof analysis
detailed_profile() {
    df_print_section "Detailed Function Profiling (zprof)"
    echo ""
    
    # Create temporary profile script
    local tmp_script=$(mktemp)
    cat > "$tmp_script" << 'PROFILE_SCRIPT'
zmodload zsh/zprof
source ~/.zshrc
zprof
PROFILE_SCRIPT
    
    # Run zsh with the profiling script
    zsh -c "source $tmp_script" 2>/dev/null | head -50
    
    rm -f "$tmp_script"
    
    echo ""
    df_print_info "Top functions shown. These are the slowest during startup."
}

# Benchmark with hyperfine
benchmark_profile() {
    if ! command -v hyperfine &>/dev/null; then
        df_print_warning "hyperfine not installed"
        df_print_info "Install: sudo pacman -S hyperfine"
        df_print_info "Falling back to quick profile..."
        echo ""
        quick_profile
        return
    fi
    
    df_print_section "Benchmark (hyperfine)"
    echo ""
    
    hyperfine --warmup 3 --min-runs 10 \
        'zsh -i -c exit' \
        2>&1
    
    echo ""
    df_print_success "Benchmark complete"
}

# Compare with minimal shell
compare_profile() {
    df_print_section "Comparison: Full vs Minimal Shell"
    echo ""
    
    df_print_step "Full shell (with dotfiles):"
    local full_time
    full_time=$(time_command "zsh -i -c 'exit'")
    echo -e "  ${DF_CYAN}${full_time}ms${DF_NC}"
    
    df_print_step "Minimal shell (no rc files):"
    local min_time
    min_time=$(time_command "zsh --no-rcs -i -c 'exit'")
    echo -e "  ${DF_CYAN}${min_time}ms${DF_NC}"
    
    local overhead=$((full_time - min_time))
    local overhead_pct=0
    if (( min_time > 0 )); then
        overhead_pct=$((overhead * 100 / min_time))
    fi
    
    echo ""
    df_print_section "Analysis"
    df_print_indent "Shell baseline:    ${min_time}ms"
    df_print_indent "Dotfiles overhead: ${overhead}ms (+${overhead_pct}%)"
    
    if (( overhead > VERY_SLOW_THRESHOLD_MS )); then
        echo ""
        df_print_warning "High overhead detected. Consider:"
        df_print_indent "• Lazy-loading heavy plugins (nvm, kubectl, etc.)"
        df_print_indent "• Compiling zsh files: dfcompile"
        df_print_indent "• Reducing oh-my-zsh plugins"
        df_print_indent "• Using zsh-defer for non-critical loads"
    fi
}

# Show optimization tips
show_tips() {
    df_print_section "Optimization Tips"
    echo ""
    
    cat << 'EOF'
  1. COMPILE ZSH FILES
     Run: dfcompile
     Compiles .zsh files to .zwc bytecode for faster parsing.

  2. LAZY-LOAD HEAVY TOOLS
     nvm, pyenv, rbenv, kubectl - only load when first used.
     Example in .zshrc:
       kubectl() {
         unfunction kubectl
         source <(command kubectl completion zsh)
         kubectl "$@"
       }

  3. REDUCE OH-MY-ZSH PLUGINS
     Each plugin adds startup time. Only enable what you use.
     Heavy plugins: nvm, kubectl, docker-compose, thefuck

  4. USE ZSH-DEFER
     Defer non-critical loading until after first prompt:
       zsh-defer source ~/.dotfiles/zsh/functions/heavy-stuff.zsh

  5. PROFILE REGULARLY
     Run this script after changes to track impact.

  6. CHECK FOR SLOW COMPLETIONS
     Completion initialization can be slow:
       autoload -Uz compinit
       if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
         compinit
       else
         compinit -C  # Skip security check (faster)
       fi

  7. AVOID SUBSHELLS IN PROMPT
     $(command) in PS1/PROMPT runs every prompt.
     Cache values or use precmd hook instead.

EOF
}

# ============================================================================
# Help
# ============================================================================

show_help() {
    cat << 'EOF'
Dotfiles Startup Profiler

Usage: dotfiles-profile.sh [OPTIONS]

Options:
  (none)        Quick profile (5 runs, average time)
  --detailed    Detailed zprof function-level profiling
  --benchmark   Benchmark with hyperfine (if installed)
  --compare     Compare full shell vs minimal shell
  --tips        Show optimization tips
  --all         Run all profiling methods
  --help        Show this help

Thresholds:
  < 200ms       Excellent (green)
  200-500ms     Acceptable (yellow)
  > 500ms       Slow (red) - optimization recommended

Examples:
  dotfiles-profile.sh              # Quick timing
  dotfiles-profile.sh --detailed   # See which functions are slow
  dotfiles-profile.sh --compare    # See dotfiles overhead
  dotfiles-profile.sh --all        # Full analysis

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    df_print_header "dotfiles-profile"
    
    case "${1:-quick}" in
        --detailed|-d)
            detailed_profile
            ;;
        --benchmark|-b)
            benchmark_profile
            ;;
        --compare|-c)
            compare_profile
            ;;
        --tips|-t)
            show_tips
            ;;
        --all|-a)
            quick_profile
            echo ""
            compare_profile
            echo ""
            detailed_profile
            echo ""
            show_tips
            ;;
        --help|-h)
            show_help
            ;;
        --quick|-q|*)
            quick_profile
            echo ""
            df_print_info "For more analysis: $0 --all"
            ;;
    esac
}

main "$@"
