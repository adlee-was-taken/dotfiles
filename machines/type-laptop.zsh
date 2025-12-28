# ============================================================================
# Laptop Machine Type Configuration
# ============================================================================
# Loaded on machines detected as laptops (has battery).
# ============================================================================

# --- Power-aware settings ---
# Reduce resource usage on battery

# Shorter MOTD on laptops (faster)
# MOTD_STYLE="mini"

# --- Battery monitoring alias ---
alias battery='cat /sys/class/power_supply/BAT0/capacity 2>/dev/null && echo "%" || echo "No battery"'
alias power='cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown"'

# --- Brightness control (if available) ---
if command -v brightnessctl &>/dev/null; then
    alias bright='brightnessctl set'
    alias brightness='brightnessctl get'
fi

# --- WiFi helpers ---
if command -v nmcli &>/dev/null; then
    alias wifi='nmcli device wifi list'
    alias wifi-connect='nmcli device wifi connect'
fi

# --- Suspend/hibernate helpers ---
alias suspend='systemctl suspend'
alias hibernate='systemctl hibernate'

