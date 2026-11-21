#!/usr/bin/env bash
# Tompachilo skill installer: pick skills, pick coding agents, install.
#
#   curl -fsSL https://raw.githubusercontent.com/urviljoshi/skills/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --to claude,codex --skills all --yes
#   ./install.sh            (from a clone: installs from the local files)
#
# Needs: bash 3.2+, and curl or wget + tar when it is not run from a clone.
# Skills and custom agents are discovered from skills/*/SKILL.md and agents/*.md,
# so new ones appear in the menu without changes to this script.

set -o pipefail

REPO="${SKILLS_REPO:-urviljoshi/skills}"
REF="${SKILLS_REF:-main}"

# ----------------------------------------------------------------- colours --
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  R=$'\e[0m' B=$'\e[1m' D=$'\e[2m'
  CYAN=$'\e[38;5;51m' PINK=$'\e[38;5;213m' GREEN=$'\e[38;5;114m'
  YELLOW=$'\e[38;5;221m' RED=$'\e[38;5;203m' GREY=$'\e[38;5;245m'
  GRADIENT=(51 45 39 63 99 135 171)
else
  R='' B='' D='' CYAN='' PINK='' GREEN='' YELLOW='' RED='' GREY=''
  GRADIENT=()
fi

say()  { printf '%s\n' "$*"; }
ok()   { printf '  %s✔%s %s\n' "$GREEN" "$R" "$*"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$R" "$*"; }
die()  { printf '  %s✘ %s%s\n' "$RED" "$*" "$R" >&2; exit 1; }
tilde() { case $1 in "$HOME"*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }

banner() {
  local art=(
    ''
    '   ████████╗ ██████╗ ███╗   ███╗██████╗  █████╗  ██████╗██╗  ██╗██╗██╗      ██████╗'
    '   ╚══██╔══╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██╔════╝██║  ██║██║██║     ██╔═══██╗'
    '      ██║   ██║   ██║██╔████╔██║██████╔╝███████║██║     ███████║██║██║     ██║   ██║'
    '      ██║   ██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██║██║     ██╔══██║██║██║     ██║   ██║'
    '      ██║   ╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║╚██████╗██║  ██║██║███████╗╚██████╔╝'
    '      ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝'
  )
  local i=0 line c
  for line in "${art[@]}"; do
    c=''
    [ ${#GRADIENT[@]} -gt 0 ] && c=$'\e[38;5;'"${GRADIENT[$i]}m"
    printf '%s%s%s\n' "$c" "$line" "$R"
    i=$((i + 1))
  done
  printf '   %s✦ skill installer ✦%s  %sskills for Claude Code, Codex & Copilot%s\n\n' \
    "$PINK$B" "$R" "$GREY" "$R"
}

# ------------------------------------------------------------------ args ----
usage() {
  cat <<EOF
Usage: install.sh [options]

With no options the installer asks everything in interactive menus.

  --to LIST       Coding agents: claude, codex, copilot, or all (comma separated)
  --skills LIST   Skill names, or all
  --agents LIST   Custom agents (Claude Code and Copilot only), all, or none
  --global        Install for your user, in every project (default)
  --project       Install into the current directory only
  --list          Show the available skills and agents, then exit
  --ref REF       Git branch or tag to install from (default: main)
  -y, --yes       Do not ask; use defaults for anything not given
  -h, --help      Show this help

Environment: SKILLS_REPO (default urviljoshi/skills), SKILLS_REF, NO_COLOR.
EOF
}

OPT_TO='' OPT_SKILLS='' OPT_AGENTS='' OPT_SCOPE='' OPT_YES=0 OPT_LIST=0
need() { [ -n "${2:-}" ] || die "$1 needs a value"; }
while [ $# -gt 0 ]; do
  case $1 in
    --to)        need "$1" "${2:-}"; OPT_TO=$2; shift ;;
    --to=*)      OPT_TO=${1#*=} ;;
    --skills|--skill) need "$1" "${2:-}"; OPT_SKILLS=$2; shift ;;
    --skills=*|--skill=*) OPT_SKILLS=${1#*=} ;;
    --agents)    need "$1" "${2:-}"; OPT_AGENTS=$2; shift ;;
    --agents=*)  OPT_AGENTS=${1#*=} ;;
    --global)    OPT_SCOPE=global ;;
    --project)   OPT_SCOPE=project ;;
    --list)      OPT_LIST=1 ;;
    --ref)       need "$1" "${2:-}"; REF=$2; shift ;;
    --ref=*)     REF=${1#*=} ;;
    -y|--yes)    OPT_YES=1 ;;
    -h|--help)   usage; exit 0 ;;
    *)           die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

INTERACTIVE=0
if [ "$OPT_YES" = 0 ] && [ "$OPT_LIST" = 0 ] && { : </dev/tty; } 2>/dev/null; then
  INTERACTIVE=1
fi

# ---------------------------------------------------------------- source ----
TMP=''
cleanup() {
  [ "$INTERACTIVE" = 1 ] && printf '\e[?25h'
  [ -n "$TMP" ] && rm -rf "$TMP"
}
trap cleanup EXIT
trap 'printf "\n"; exit 130' INT

SRC=''
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  [ -d "$here/skills" ] && SRC=$here
fi

[ "$OPT_LIST" = 0 ] && banner

if [ -z "$SRC" ]; then
  TMP=$(mktemp -d 2>/dev/null || mktemp -d -t skills)
  url="https://github.com/$REPO/archive/$REF.tar.gz"
  printf '  %s↓%s fetching %s%s%s (%s) ' "$CYAN" "$R" "$B" "$REPO" "$R" "$REF"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" | tar -xz -C "$TMP" --strip-components=1
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$url" | tar -xz -C "$TMP" --strip-components=1
  else
    printf '\n'; die "curl or wget is required"
  fi
  [ $? -eq 0 ] && [ -d "$TMP/skills" ] || { printf '\n'; die "could not download $url"; }
  printf '%s✔%s\n\n' "$GREEN" "$R"
  SRC=$TMP
fi

# ------------------------------------------------------------- discovery ----
# Print one frontmatter value (single-line values only).
fm_get() {
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    index($0, key ":") == 1 {
      sub(/^[^:]*:[ \t]*/, ""); gsub(/^["\047]|["\047]$/, ""); print; exit
    }' "$1"
}

SKILLS=() SKILL_DESCS=()
for f in "$SRC"/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  SKILLS+=("$(basename "$(dirname "$f")")")
  SKILL_DESCS+=("$(fm_get "$f" description)")
done
[ ${#SKILLS[@]} -gt 0 ] || die "no skills found in $SRC/skills"

AGENTS=() AGENT_DESCS=()
for f in "$SRC"/agents/*.md; do
  [ -f "$f" ] || continue
  AGENTS+=("$(basename "$f" .md)")
  AGENT_DESCS+=("$(fm_get "$f" description)")
done

if [ "$OPT_LIST" = 1 ]; then
  say "Skills:"
  for i in "${!SKILLS[@]}"; do printf '  %-20s %s\n' "${SKILLS[$i]}" "${SKILL_DESCS[$i]:0:90}"; done
  say "Custom agents (Claude Code, Copilot):"
  for i in "${!AGENTS[@]}"; do printf '  %-20s %s\n' "${AGENTS[$i]}" "${AGENT_DESCS[$i]:0:90}"; done
  exit 0
fi

# --------------------------------------------------------------- targets ----
T_IDS=(claude codex copilot)
T_NAMES=("Claude Code" "Codex" "GitHub Copilot")

detected() {
  case $1 in
    claude)  command -v claude  >/dev/null 2>&1 || [ -d "$HOME/.claude" ] ;;
    codex)   command -v codex   >/dev/null 2>&1 || [ -d "$HOME/.codex" ] || [ -d "$HOME/.agents" ] ;;
    copilot) command -v copilot >/dev/null 2>&1 || [ -d "$HOME/.copilot" ] ;;
  esac
}

# skills_dir TARGET SCOPE / agents_dir TARGET SCOPE ('' = not supported)
skills_dir() {
  case "$1:$2" in
    claude:global)   echo "$HOME/.claude/skills" ;;
    claude:project)  echo "$PWD/.claude/skills" ;;
    codex:global)    echo "$HOME/.agents/skills" ;;
    codex:project)   echo "$PWD/.agents/skills" ;;
    copilot:global)  echo "$HOME/.copilot/skills" ;;
    copilot:project) echo "$PWD/.github/skills" ;;
  esac
}
agents_dir() {
  case "$1:$2" in
    claude:global)   echo "$HOME/.claude/agents" ;;
    claude:project)  echo "$PWD/.claude/agents" ;;
    copilot:global)  echo "$HOME/.copilot/agents" ;;
    copilot:project) echo "$PWD/.github/agents" ;;
  esac
}

# ------------------------------------------------------------------ menu ----
# Inputs: M_LABELS, M_DESCS, M_SEL (0/1 per item). Output: M_SEL.
# menu MODE(multi|single) TITLE MIN_SELECTED
KEY=''
read_key() {
  local k='' k2=''
  IFS= read -rsn1 k </dev/tty || { KEY=quit; return; }
  case $k in
    $'\e') IFS= read -rsn2 k2 </dev/tty
           case $k2 in '[A'|'OA') KEY=up ;; '[B'|'OB') KEY=down ;; *) KEY=other ;; esac ;;
    ''|$'\n'|$'\r') KEY=enter ;;
    ' ')   KEY=space ;;
    k|K)   KEY=up ;;
    j|J)   KEY=down ;;
    a|A)   KEY=all ;;
    q|Q)   KEY=quit ;;
    *)     KEY=other ;;
  esac
}

menu() {
  local mode=$1 title=$2 min=${3:-0}
  local n=${#M_LABELS[@]} cur=0 drawn=0 i w=0 cols msg='' hint
  local box arrow label desc count all
  cols=$(tput cols 2>/dev/null || echo 80)
  [ "$cols" -gt 110 ] && cols=110
  for i in "${!M_LABELS[@]}"; do [ ${#M_LABELS[$i]} -gt $w ] && w=${#M_LABELS[$i]}; done
  if [ "$mode" = single ]; then
    for i in "${!M_SEL[@]}"; do [ "${M_SEL[$i]}" = 1 ] && cur=$i; done
    hint='↑/↓ move · enter select'
  else
    hint='↑/↓ move · space toggle · a all · enter confirm'
  fi

  printf '\e[?25l'
  while :; do
    [ $drawn -gt 0 ] && printf '\e[%dA' "$drawn"
    printf '\e[J'
    printf '  %s?%s %s%s%s  %s%s%s\n' "$PINK$B" "$R" "$B" "$title" "$R" "$GREY" "$hint" "$R"
    drawn=1
    for ((i = 0; i < n; i++)); do
      if [ $i = $cur ]; then arrow="$CYAN❯$R"; else arrow=' '; fi
      if [ "$mode" = single ]; then
        if [ $i = $cur ]; then box="$CYAN●$R"; else box="$GREY○$R"; fi
      elif [ "${M_SEL[$i]}" = 1 ]; then box="$GREEN◉$R"
      else box="$GREY◯$R"; fi
      label=$(printf "%-${w}s" "${M_LABELS[$i]}")
      [ $i = $cur ] && label="$CYAN$B$label$R"
      desc=${M_DESCS[$i]}
      local room=$((cols - w - 12))
      [ $room -lt 10 ] && room=10
      [ ${#desc} -gt $room ] && desc="${desc:0:$((room - 1))}…"
      printf '  %s %s %s  %s%s%s\n' "$arrow" "$box" "$label" "$GREY" "$desc" "$R"
      drawn=$((drawn + 1))
    done
    if [ -n "$msg" ]; then printf '  %s%s%s\n' "$YELLOW" "$msg" "$R"; drawn=$((drawn + 1)); fi

    read_key
    msg=''
    case $KEY in
      up)    cur=$(( (cur - 1 + n) % n )) ;;
      down)  cur=$(( (cur + 1) % n )) ;;
      space) [ "$mode" = multi ] && M_SEL[$cur]=$((1 - M_SEL[cur])) ;;
      all)
        if [ "$mode" = multi ]; then
          all=1; for i in "${!M_SEL[@]}"; do [ "${M_SEL[$i]}" = 0 ] && all=0; done
          for i in "${!M_SEL[@]}"; do M_SEL[$i]=$((1 - all)); done
        fi ;;
      enter)
        if [ "$mode" = single ]; then
          for i in "${!M_SEL[@]}"; do M_SEL[$i]=0; done; M_SEL[$cur]=1; break
        fi
        count=0; for i in "${!M_SEL[@]}"; do [ "${M_SEL[$i]}" = 1 ] && count=$((count + 1)); done
        [ $count -ge "$min" ] && break
        msg="Select at least $min (space to toggle)." ;;
      quit)  printf '\e[%dA\e[J\e[?25h' "$drawn"; say "  ${GREY}Cancelled.${R}"; exit 130 ;;
    esac
  done

  # Collapse the menu into one summary line.
  local picked=''
  for i in "${!M_SEL[@]}"; do
    [ "${M_SEL[$i]}" = 1 ] && picked="${picked:+$picked, }${M_LABELS[$i]}"
  done
  printf '\e[%dA\e[J\e[?25h' "$drawn"
  printf '  %s✔%s %s%s%s %s%s%s\n' "$GREEN" "$R" "$B" "$title" "$R" "$CYAN" "${picked:-none}" "$R"
}

# Turn "a,b" or "all" into 0/1 flags over a list. pick_csv CSV NAME... -> PICKED
pick_csv() {
  local csv=",$1," i; shift
  PICKED=()
  for i in "$@"; do
    case $csv in *,all,*|*",$i,"*) PICKED+=(1) ;; *) PICKED+=(0) ;; esac
  done
}
check_names() { # check_names KIND CSV NAME...
  local kind=$1 csv=$2 x n ok; shift 2
  local IFS=,
  for x in $csv; do
    [ "$x" = all ] || [ "$x" = none ] && continue
    ok=0; for n in "$@"; do [ "$x" = "$n" ] && ok=1; done
    [ $ok = 1 ] || die "unknown $kind: $x"
  done
}

# ------------------------------------------------------------- questions ----
# 1. skills
if [ -n "$OPT_SKILLS" ]; then
  check_names "skill" "$OPT_SKILLS" "${SKILLS[@]}"
  pick_csv "$OPT_SKILLS" "${SKILLS[@]}"; S_SEL=("${PICKED[@]}")
else
  S_SEL=(); for s in "${SKILLS[@]}"; do S_SEL+=(1); done
  if [ "$INTERACTIVE" = 1 ]; then
    M_LABELS=("${SKILLS[@]}") M_DESCS=("${SKILL_DESCS[@]}") M_SEL=("${S_SEL[@]}")
    menu multi "Which skills?" 1
    S_SEL=("${M_SEL[@]}")
  fi
fi

# 2. coding agents
if [ -n "$OPT_TO" ]; then
  check_names "agent" "$OPT_TO" "${T_IDS[@]}"
  pick_csv "$OPT_TO" "${T_IDS[@]}"; T_SEL=("${PICKED[@]}")
else
  T_SEL=()
  for t in "${T_IDS[@]}"; do if detected "$t"; then T_SEL+=(1); else T_SEL+=(0); fi; done
  if [ "$INTERACTIVE" = 1 ]; then
    M_LABELS=("${T_NAMES[@]}") M_DESCS=() M_SEL=("${T_SEL[@]}")
    for i in "${!T_IDS[@]}"; do
      d=$(tilde "$(skills_dir "${T_IDS[$i]}" global)")
      detected "${T_IDS[$i]}" && d="detected · $d"
      M_DESCS+=("$d")
    done
    menu multi "Install for which coding agents?" 1
    T_SEL=("${M_SEL[@]}")
  else
    case " ${T_SEL[*]} " in *" 1 "*) ;; *) die "no coding agent detected; pass --to claude,codex,copilot" ;; esac
  fi
fi

# 3. scope
SCOPE=${OPT_SCOPE:-global}
if [ -z "$OPT_SCOPE" ] && [ "$INTERACTIVE" = 1 ]; then
  M_LABELS=("Global" "This project") M_SEL=(1 0)
  M_DESCS=("for you, in every project (~/…)" "only in $(tilde "$PWD")")
  menu single "Where should they go?"
  [ "${M_SEL[1]}" = 1 ] && SCOPE=project
fi

# 4. custom agents (only for targets that support them)
A_SEL=(); for a in "${AGENTS[@]}"; do A_SEL+=(1); done
WANTS_AGENTS=0
for i in "${!T_IDS[@]}"; do
  [ "${T_SEL[$i]}" = 1 ] && [ -n "$(agents_dir "${T_IDS[$i]}" "$SCOPE")" ] && WANTS_AGENTS=1
done
if [ ${#AGENTS[@]} -eq 0 ] || [ "$WANTS_AGENTS" = 0 ]; then
  A_SEL=(); for a in "${AGENTS[@]}"; do A_SEL+=(0); done
elif [ -n "$OPT_AGENTS" ]; then
  check_names "custom agent" "$OPT_AGENTS" "${AGENTS[@]}"
  pick_csv "$OPT_AGENTS" "${AGENTS[@]}"; A_SEL=("${PICKED[@]}")
elif [ "$INTERACTIVE" = 1 ]; then
  M_LABELS=("${AGENTS[@]}") M_DESCS=("${AGENT_DESCS[@]}") M_SEL=("${A_SEL[@]}")
  menu multi "Also install custom agents? (Claude Code, Copilot)" 0
  A_SEL=("${M_SEL[@]}")
fi

# --------------------------------------------------------------- confirm ----
n_skills=0; for x in "${S_SEL[@]}"; do [ "$x" = 1 ] && n_skills=$((n_skills + 1)); done
n_agents=0; for x in "${A_SEL[@]}"; do [ "$x" = 1 ] && n_agents=$((n_agents + 1)); done

if [ "$INTERACTIVE" = 1 ]; then
  printf '\n  %s?%s Install %s%d skill(s)%s and %s%d agent(s)%s? %s[Y/n]%s ' \
    "$PINK$B" "$R" "$B" "$n_skills" "$R" "$B" "$n_agents" "$R" "$GREY" "$R"
  IFS= read -r answer </dev/tty
  case $answer in n*|N*) say "  ${GREY}Cancelled.${R}"; exit 0 ;; esac
fi

# --------------------------------------------------------------- install ----
# Copy an agent file; for Copilot, name it NAME.agent.md and drop the
# Claude-specific `tools:` line (tool names differ between agents).
install_agent() { # install_agent TARGET SRC DEST_DIR NAME
  if [ "$1" = copilot ]; then
    awk '{ sub(/\r$/, "") } /^---$/ { fm++ } !(fm == 1 && /^tools:/)' "$2" > "$3/$4.agent.md"
    echo "$3/$4.agent.md"
  else
    cp "$2" "$3/$4.md"
    echo "$3/$4.md"
  fi
}

say ''
for ti in "${!T_IDS[@]}"; do
  [ "${T_SEL[$ti]}" = 1 ] || continue
  t=${T_IDS[$ti]}
  sdir=$(skills_dir "$t" "$SCOPE")
  printf '  %s%s%s %s→ %s%s\n' "$B$CYAN" "${T_NAMES[$ti]}" "$R" "$GREY" "$(tilde "$sdir")" "$R"
  mkdir -p "$sdir" || die "cannot create $sdir"
  for si in "${!SKILLS[@]}"; do
    [ "${S_SEL[$si]}" = 1 ] || continue
    s=${SKILLS[$si]} note=''
    [ -e "$sdir/$s" ] && note=" ${GREY}(updated)${R}"
    rm -rf "${sdir:?}/$s" && cp -R "$SRC/skills/$s" "$sdir/$s" || die "failed to copy $s"
    find "$sdir/$s" -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null
    ok "$s$note"
  done
  adir=$(agents_dir "$t" "$SCOPE")
  if [ -n "$adir" ] && [ "$n_agents" -gt 0 ]; then
    mkdir -p "$adir" || die "cannot create $adir"
    for ai in "${!AGENTS[@]}"; do
      [ "${A_SEL[$ai]}" = 1 ] || continue
      dest=$(install_agent "$t" "$SRC/agents/${AGENTS[$ai]}.md" "$adir" "${AGENTS[$ai]}") || die "failed to copy ${AGENTS[$ai]}"
      ok "${AGENTS[$ai]} ${GREY}agent → $(tilde "$dest")${R}"
    done
  fi
  say ''
done

printf '  %s✦ Done.%s Restart your coding agent so it loads the new skills.\n' "$PINK$B" "$R"
say ''
