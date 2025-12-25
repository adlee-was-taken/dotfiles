#!/usr/bin/env zsh
# ============================================================================
# Tests for zsh/lib/utils.zsh
# ============================================================================

# Source utils if not already loaded
source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/utils.zsh" 2>/dev/null

# ============================================================================
# Tests
# ============================================================================

describe "df_cmd_exists"

it "should return true for existing command (ls)"
assert_success "df_cmd_exists ls"

it "should return false for non-existent command"
assert_fail "df_cmd_exists this_command_does_not_exist_12345"

it "should work with common tools"
assert_success "df_cmd_exists git"

# ============================================================================

describe "df_print functions"

it "should have df_print_success defined"
assert_success "typeset -f df_print_success"

it "should have df_print_error defined"
assert_success "typeset -f df_print_error"

it "should have df_print_warning defined"
assert_success "typeset -f df_print_warning"

it "should have df_print_step defined"
assert_success "typeset -f df_print_step"

# ============================================================================

describe "df_in_git_repo"

it "should detect git repository in dotfiles dir"
(
    cd "${DOTFILES_DIR:-$HOME/.dotfiles}"
    if [[ -d .git ]]; then
        assert_success "df_in_git_repo"
    else
        skip "Not a git repo"
    fi
)

it "should return false in /tmp"
(
    cd /tmp
    assert_fail "df_in_git_repo"
)

# ============================================================================

describe "df_ensure_dir"

it "should create directory if it doesn't exist"
local test_dir="/tmp/dotfiles_test_$$"
df_ensure_dir "$test_dir"
assert_dir_exists "$test_dir"
rmdir "$test_dir" 2>/dev/null

it "should not fail if directory exists"
df_ensure_dir "/tmp"
assert_success "true"

# ============================================================================

describe "_df_hline"

it "should create a line of specified width"
local line=$(_df_hline "=" 10)
assert_eq "${#line}" "10"

it "should use specified character"
local line=$(_df_hline "-" 5)
assert_eq "$line" "-----"

# ============================================================================

describe "Color variables"

it "should have DF_GREEN defined"
assert_ne "$DF_GREEN" ""

it "should have DF_RED defined"
assert_ne "$DF_RED" ""

it "should have DF_NC (reset) defined"
assert_ne "$DF_NC" ""

it "should have DF_CYAN defined"
assert_ne "$DF_CYAN" ""

# ============================================================================

describe "Configuration variables"

it "should have DOTFILES_DIR defined"
assert_ne "${DOTFILES_DIR:-}" ""

it "should have DF_WIDTH defined with reasonable value"
local width="${DF_WIDTH:-66}"
(( width >= 40 && width <= 120 )) && assert_success "true" || assert_fail "DF_WIDTH out of range"
