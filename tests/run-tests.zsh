#!/usr/bin/env zsh
# ============================================================================
# Dotfiles Test Framework
# ============================================================================
# Simple unit testing for shell functions and scripts.
#
# Usage:
#   ./tests/run-tests.zsh              # Run all tests
#   ./tests/run-tests.zsh test_utils   # Run specific test file
# ============================================================================

set -e

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
TESTS_DIR="$SCRIPT_DIR"

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

# ============================================================================
# Test Framework Functions
# ============================================================================

# Start a test group
describe() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
}

# Run a single test
it() {
    CURRENT_TEST="$1"
    ((TESTS_RUN++))
}

# Assert equality
assert_eq() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$actual" == "$expected" ]]; then
        echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $CURRENT_TEST"
        echo -e "    ${RED}Expected:${NC} $expected"
        echo -e "    ${RED}Actual:${NC}   $actual"
        ((TESTS_FAILED++))
    fi
}

# Assert not equal
assert_ne() {
    local actual="$1"
    local not_expected="$2"
    
    if [[ "$actual" != "$not_expected" ]]; then
        echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $CURRENT_TEST"
        echo -e "    ${RED}Should not equal:${NC} $not_expected"
        ((TESTS_FAILED++))
    fi
}

# Assert command succeeds
assert_success() {
    local cmd="$1"
    
    if eval "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $CURRENT_TEST"
        echo -e "    ${RED}Command failed:${NC} $cmd"
        ((TESTS_FAILED++))
    fi
}

# Assert command fails
assert_fail() {
    local cmd="$1"
    
    if ! eval "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $CURRENT_TEST"
        echo -e "    ${RED}Expected failure but succeeded:${NC} $cmd"
        ((TESTS_FAILED++))
    fi
}

# Assert string contains
assert_contains() {
    local haystack="$1"
    local needle="$2"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $CURRENT_TEST"
        echo -e "    ${RED}String should contain:${NC} $needle"
        ((TESTS_FAILED++))
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $CURRENT_TEST"
        echo -e "    ${RED}File not found:${NC} $file"
        ((TESTS_FAILED++))
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    
    if [[ -d "$dir" ]]; then
        echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $CURRENT_TEST"
        echo -e "    ${RED}Directory not found:${NC} $dir"
        ((TESTS_FAILED++))
    fi
}

# Assert command exists
assert_cmd_exists() {
    local cmd="$1"
    
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $CURRENT_TEST"
        echo -e "    ${RED}Command not found:${NC} $cmd"
        ((TESTS_FAILED++))
    fi
}

# Skip a test
skip() {
    local reason="${1:-No reason given}"
    echo -e "  ${YELLOW}○${NC} $CURRENT_TEST (SKIPPED: $reason)"
}

# ============================================================================
# Test Runner
# ============================================================================

run_test_file() {
    local test_file="$1"
    source "$test_file"
}

print_summary() {
    echo ""
    echo "─────────────────────────────────────────"
    echo -e "Tests:  ${CYAN}$TESTS_RUN${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo "─────────────────────────────────────────"
    
    if (( TESTS_FAILED > 0 )); then
        echo -e "${RED}FAILED${NC}"
        return 1
    else
        echo -e "${GREEN}PASSED${NC}"
        return 0
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo "╔═══════════════════════════════════════╗"
    echo "║      Dotfiles Test Suite              ║"
    echo "╚═══════════════════════════════════════╝"
    
    # Source the libraries we're testing
    source "$DOTFILES_DIR/zsh/lib/bootstrap.zsh" 2>/dev/null || true
    
    local specific_test="$1"
    
    if [[ -n "$specific_test" ]]; then
        # Run specific test file
        if [[ -f "$TESTS_DIR/${specific_test}.zsh" ]]; then
            run_test_file "$TESTS_DIR/${specific_test}.zsh"
        elif [[ -f "$TESTS_DIR/test_${specific_test}.zsh" ]]; then
            run_test_file "$TESTS_DIR/test_${specific_test}.zsh"
        else
            echo "Test file not found: $specific_test"
            exit 1
        fi
    else
        # Run all test files
        for test_file in "$TESTS_DIR"/test_*.zsh(N); do
            [[ -f "$test_file" ]] || continue
            echo ""
            echo -e "${YELLOW}Running: $(basename "$test_file")${NC}"
            run_test_file "$test_file"
        done
    fi
    
    print_summary
}

# Export functions for test files
export -f describe it assert_eq assert_ne assert_success assert_fail
export -f assert_contains assert_file_exists assert_dir_exists assert_cmd_exists skip

main "$@"
