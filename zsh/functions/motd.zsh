#!/usr/bin/env zsh
# ============================================================================
# MOTD — Width-Safe, Color-Safe, Reload-Safe
# ============================================================================

# ---------------------------- Guards -----------------------------------------

[[ -o interactive ]] || return
[[ -n $__MOTD_SHOWN ]] && return
typeset -g __MOTD_SHOWN=1

# ---------------------------- Configuration ----------------------------------

BOX_WIDTH=78        # total width INCLUDING borders
INNER_WIDTH=$(( BOX_WIDTH - 2 ))
LABEL_WIDTH=12

# ---------------------------- Colors -----------------------------------------

autoload -Uz colors && colors

C_DIM="%F{242}"
C_HEAD="%B%F{39}"
C_LABEL="%F{51}"
C_OK="%F{82}"
C_RESET="%f%b"

# ---------------------------- Low-level helpers ------------------------------

repeat_char() {
  local ch="$1" n="$2"
  printf '%*s' "$n" '' | tr ' ' "$ch"
}

pad_right() {
  local s="$1" w="$2"
  printf '%-*s' "$w" "$s"
}

center_text() {
  local s="$1" w="$2"
  local len=${#s}
  (( len >= w )) && { print "${s[1,w]}"; return }
  local pad=$(( (w - len) / 2 ))
  printf '%*s%s%*s' "$pad" '' "$s" "$(( w - len - pad ))" ''
}

# ---------------------------- Box primitives ---------------------------------

box_top() {
  print "${C_DIM}┌$(repeat_char '─' $INNER_WIDTH)┐${C_RESET}"
}

box_bottom() {
  print "${C_DIM}└$(repeat_char '─' $INNER_WIDTH)┘${C_RESET}"
}

box_blank() {
  print "${C_DIM}│$(repeat_char ' ' $INNER_WIDTH)│${C_RESET}"
}

box_line() {
  local content="$1"
  content="$(pad_right "$content" "$INNER_WIDTH")"
  print "${C_DIM}│${C_RESET}${content}${C_DIM}│${C_RESET}"
}

# ---------------------------- Content builders -------------------------------

header_line() {
  local text="$1"
  box_line "$(center_text "$text" "$INNER_WIDTH")"
}

row_line() {
  local label="$1" value="$2"
  local left="$(pad_right "$label" "$LABEL_WIDTH")"
  box_line " ${left} ${value}"
}

# ---------------------------- Info providers ---------------------------------

get_os()     { uname -sr }
get_uptime() { uptime | sed 's/.*up *//' | cut -d',' -f1 }
get_load()   { uptime | awk -F'load average:' '{print $2}' | xargs }
get_mem()    { free -h | awk '/Mem:/ {print $3 "/" $2}' }
get_disk()   { df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}' }

# ---------------------------- Render -----------------------------------------

box_top
header_line "${C_HEAD}$(hostname)${C_RESET} - ${C_DIM}$(get_os)${C_RESET}"
box_blank
row_line "${C_LABEL}Uptime${C_RESET}"  "$(get_uptime)"
row_line "${C_LABEL}Load${C_RESET}"    "$(get_load)"
row_line "${C_LABEL}Memory${C_RESET}"  "$(get_mem)"
row_line "${C_LABEL}Disk${C_RESET}"    "$(get_disk)"
box_blank
box_line " ${C_OK}System up to date${C_RESET}"
box_bottom
print

