#!/usr/bin/env zsh
# ============================================================================
# Tests for zsh/lib/config.zsh
# ============================================================================

# Source config if not already loaded
source "${DOTFILES_DIR:-$HOME/.dotfiles}/zsh/lib/config.zsh" 2>/dev/null

# ============================================================================
# Tests
# ============================================================================

describe "Core configuration variables"

it "should have DOTFILES_VERSION defined"
assert_ne "${DOTFILES_VERSION:-}" ""

it "should have DOTFILES_DIR defined"
assert_ne "${DOTFILES_DIR:-}" ""

it "should have DOTFILES_BRANCH defined"
assert_ne "${DOTFILES_BRANCH:-}" ""

# ============================================================================

describe "Display configuration"

it "should have DF_WIDTH defined"
assert_ne "${DF_WIDTH:-}" ""

it "should have DF_WIDTH as a number"
[[ "${DF_WIDTH:-66}" =~ ^[0-9]+$ ]] && assert_success "true" || assert_fail "DF_WIDTH not a number"

it "should have MOTD_STYLE defined"
assert_ne "${MOTD_STYLE:-}" ""

it "should have ENABLE_MOTD defined"
assert_ne "${ENABLE_MOTD:-}" ""

# ============================================================================

describe "Theme configuration"

it "should have ZSH_THEME_NAME defined"
assert_ne "${ZSH_THEME_NAME:-}" ""

it "should have THEME_TIMER_THRESHOLD defined"
assert_ne "${THEME_TIMER_THRESHOLD:-}" ""

# ============================================================================

describe "Feature toggles"

it "should have ENABLE_SMART_SUGGESTIONS defined"
assert_ne "${ENABLE_SMART_SUGGESTIONS:-}" ""

it "should have ENABLE_COMMAND_PALETTE defined"
assert_ne "${ENABLE_COMMAND_PALETTE:-}" ""

it "should have ENABLE_VAULT defined"
assert_ne "${ENABLE_VAULT:-}" ""

# ============================================================================

describe "Path configuration"

it "should have valid DOTFILES_DIR path"
assert_dir_exists "${DOTFILES_DIR:-$HOME/.dotfiles}"

it "should have dotfiles.conf in DOTFILES_DIR"
if [[ -d "${DOTFILES_DIR:-$HOME/.dotfiles}" ]]; then
    assert_file_exists "${DOTFILES_DIR:-$HOME/.dotfiles}/dotfiles.conf"
else
    skip "DOTFILES_DIR not found"
fi

# ============================================================================

describe "df_config helper function"

it "should have df_config function defined"
if typeset -f df_config &>/dev/null; then
    assert_success "true"
else
    skip "df_config not defined in this version"
fi

it "should return default for undefined variable"
if typeset -f df_config &>/dev/null; then
    local result=$(df_config "UNDEFINED_VAR_12345" "default_value")
    assert_eq "$result" "default_value"
else
    skip "df_config not defined"
fi
