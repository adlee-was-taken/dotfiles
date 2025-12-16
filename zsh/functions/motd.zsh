#!/usr/bin/env zsh
# ============================================================================
# Dynamic MOTD (zsh) — PARSE-SAFE GRID LAYOUT
# ============================================================================

# ---------------------------- Configuration ---------------------------------

MOTD_ENABLED="${MOTD_ENABLED:-true}"
MOTD_MAX_WIDTH=80
MOTD_LABEL_WIDTH=12
MOTD_ONCE_VAR="__MOTD_SHOWN"

# ---------------------------- Colors -----------------------------------------

autoload -Uz colors && colors

C_RESET="%f%k"
C_DIM="%F{242}"
C_HEAD="%B%F{39}"
C_LABEL="%F{51}"
C_OK="%F{82}"

# ---------------------------- Utilities --------------------------------------

_strip_colors() {
  local s="$1"
  s="${s//\%\{/%}"
  s="${s//\%\}/%}"
  print -r -- "${(S%%)s}"
}

_term_width() {
  print ${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
}

_box_width() {
  local w=$(_term_width)
  (( w > MOTD_MAX_WIDTH )) && w=$MOTD_MAX_WIDTH
  print $w
}

_hr_top() {
  local w=$(_box_width)
  print -P -- "${C_DIM}┌${(l:$((w-2))::─:)}┐${C_RESET}"
}

_hr_bottom() {
  local w=$(_box_width)
  print -P -- "${C_DIM}└${(l:$((w-2))::─:)}┘${C_RESET}"
}

_header() {
  local text="$1"
  local w=$(_box_width)
  local inner=$(( w - 2 ))

  # Strip color + force ASCII dash to avoid Unicode width issues
  local raw="$(_strip_colors "$text" | sed 's/—/-/')"
  (( ${#raw} > inner )) && raw="${raw[1,inner]}"

  local pad=$(( (inner - ${#raw}) / 2 ))
  local rpad=$(( inner - ${#raw} - pad ))

  print -P -- \
    "${C_DIM}│${C_RESET}${(l:$pad:: :)}${text}${(l:$rpad:: :)}${C_DIM}│${C_RESET}"
}

_message() {
  local msg="$1"
  local w=$(_box_width)
  local inner=$(( w - 2 ))

  local raw="$(_strip_colors "$msg")"
  (( ${#raw} > inner )) && msg="${msg[1,inner]}"

  local fill=$(( inner - ${#raw} ))

  print -P -- \
    "${C_DIM}│${C_RESET}${msg}${(l:$fill:: :)}${C_DIM}│${C_RESET}"
}

_blank() {
  local w=$(_box_width)
  print -P -- "${C_DIM}│${C_RESET}$(printf '%*s' $((w-2)) '')${C_DIM}│${C_RESET}"
}

_row() {
  local label="$1"
  local value="$2"

  local w=$(_box_width)
  local value_width=$(( w - 4 - MOTD_LABEL_WIDTH ))

  # Truncate value safely
  local raw="$(_strip_colors "$value")"
  if (( ${#raw} > value_width )); then
    value="${value[1,value_width]}"
  fi

  # Recalculate after truncation
  raw="$(_strip_colors "$value")"
  local pad_len=$(( value_width - ${#raw} ))
  (( pad_len < 0 )) && pad_len=0

  printf -v lpad "%-*s" "$MOTD_LABEL_WIDTH" "$label"
  printf -v vpad "%*s" "$pad_len" ""

  print -P -- \
    "${C_DIM}│${C_RESET} ${C_LABEL}${lpad}${C_RESET} ${value}${vpad}${C_DIM}│${C_RESET}"
}


# ---------------------------- Info Providers ---------------------------------

_get_os()     { uname -sr }
_get_uptime() { uptime | sed 's/.*up *//' | cut -d',' -f1 }
_get_load()   { uptime | awk -F'load average:' '{print $2}' | xargs }
_get_mem()    { free -h | awk '/Mem:/ {print $3 "/" $2}' }
_get_disk() {
  df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}'
}

# ---------------------------- MOTD -------------------------------------------

show_motd() {
  [[ -o interactive ]] || return
  [[ "$MOTD_ENABLED" != true ]] && return
  [[ -n ${(P)MOTD_ONCE_VAR} ]] && return
  typeset -g ${MOTD_ONCE_VAR}=1

  _hr_top
  _header "${C_HEAD} $(hostname) ${C_RESET}- ${C_DIM}$(_get_os)${C_RESET}"
  _blank
  _row "Uptime" "$(_get_uptime)"
  _row "Load"   "$(_get_load)"
  _row "Memory" "$(_get_mem)"
  _row "Disk"   "$(_get_disk)"
  _blank
  _message "${C_OK}System up to date${C_RESET}"
  _hr_bottom
  print
}

show_motd

