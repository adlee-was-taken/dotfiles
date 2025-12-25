# ============================================================================
# Server Machine Type Configuration
# ============================================================================
# Loaded on machines detected as servers.
# ============================================================================

# --- Minimal MOTD (servers don't need fancy displays) ---
MOTD_STYLE="mini"

# --- Disable notifications (no desktop on servers) ---
DF_NOTIFY_ENABLED="false"

# --- Server monitoring aliases ---
alias ports='ss -tulpn'
alias listening='ss -tulpn | grep LISTEN'
alias connections='ss -tan | grep ESTAB | wc -l'

# --- Log watching ---
alias syslog='sudo tail -f /var/log/syslog 2>/dev/null || sudo journalctl -f'
alias authlog='sudo tail -f /var/log/auth.log 2>/dev/null || sudo journalctl -f -u sshd'

# --- Docker shortcuts (servers often run containers) ---
if command -v docker &>/dev/null; then
    alias dstats='docker stats --no-stream'
    alias dclean='docker system prune -af'
    alias dlogs='docker logs -f'
fi

# --- Quick system checks ---
alias diskspace='df -h | grep -v tmpfs | grep -v loop'
alias meminfo='free -h'
alias cpuinfo='lscpu | grep -E "Model name|Socket|Core|Thread"'

# --- Security ---
alias failed-logins='sudo journalctl -u sshd | grep -i "failed\|invalid"'
alias active-users='who'
