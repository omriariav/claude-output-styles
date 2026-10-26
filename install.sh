#!/usr/bin/env bash
# Install Claude Code output styles (tones).
# Requires bash (not sh).
#   ./install.sh [--project] [--link] [--uninstall] [--list] [-h] [names...]
#   curl -fsSL https://raw.githubusercontent.com/omriariav/claude-output-styles/main/install.sh | bash -s -- israeli
set -euo pipefail

# Styles available when running piped (no clone). Keep in sync with output-styles/*.md.
STYLES_REMOTE="ste israeli"
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/omriariav/claude-output-styles/main}"

usage() {
  cat <<'USAGE'
Usage: install.sh [options] [style ...]

Installs Claude Code output styles into ~/.claude/output-styles/
(or $CLAUDE_CONFIG_DIR/output-styles/). With no style names, installs all.

Options:
  --project      Install to ./.claude/output-styles/ instead of user scope
  --link         Symlink instead of copy (clone mode only)
  --uninstall    Remove installed styles (all, or the named ones)
  --list         List available styles with their name and description
  -h, --help     Show this help

Env:
  REPO_RAW       Base URL for downloads when run piped
                 (default: https://raw.githubusercontent.com/omriariav/claude-output-styles/main)
  CLAUDE_CONFIG_DIR  Overrides ~/.claude for user scope

Examples:
  ./install.sh
  ./install.sh israeli --project
  curl -fsSL https://raw.githubusercontent.com/omriariav/claude-output-styles/main/install.sh | bash -s -- israeli
USAGE
}

die() { echo "error: $*" >&2; exit 1; }

# Clone mode: script lives next to an output-styles/ directory.
SRC_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  _d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [ -d "$_d/output-styles" ] && SRC_DIR="$_d/output-styles"
fi

MODE=install
SCOPE=user
LINK=0
NAMES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --project) SCOPE=project ;;
    --link) LINK=1 ;;
    --uninstall) MODE=uninstall ;;
    --list) MODE=list ;;
    -h|--help) usage; exit 0 ;;
    -*) usage >&2; die "unknown option: $1" ;;
    *) NAMES+=("${1%.md}") ;;
  esac
  shift
done

if [ "$MODE" = install ] && [ "$LINK" = 1 ] && [ -z "$SRC_DIR" ]; then
  die "--link needs a local clone (run ./install.sh from the repo, not piped)"
fi

if [ "$SCOPE" = project ]; then
  DEST_DIR="$PWD/.claude/output-styles"
else
  DEST_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/output-styles"
fi

TMP_DIR=""
cleanup() { [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"; return 0; }
trap cleanup EXIT

# Piped mode: create the temp dir here, in the parent shell (fetch runs in a subshell).
[ -n "$SRC_DIR" ] || TMP_DIR="$(mktemp -d)"

available() {
  if [ -n "$SRC_DIR" ]; then
    local f
    for f in "$SRC_DIR"/*.md; do
      [ -f "$f" ] || continue
      basename "$f" .md
    done
  else
    for f in $STYLES_REMOTE; do echo "$f"; done
  fi
}

# Print path of a local copy of style $1 (downloads when piped).
fetch() {
  local n="$1"
  if [ -n "$SRC_DIR" ]; then
    [ -f "$SRC_DIR/$n.md" ] || die "unknown style: $n (try --list)"
    echo "$SRC_DIR/$n.md"
    return
  fi
  local out="$TMP_DIR/$n.md" url="$REPO_RAW/output-styles/$n.md"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out" || die "download failed: $url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$out" "$url" || die "download failed: $url"
  else
    die "need curl or wget"
  fi
  echo "$out"
}

# Read a frontmatter key from file $1.
fm() {
  awk -v k="$2" '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---" { exit }
    NR>1 { i=index($0, ":"); if (i>0 && substr($0,1,i-1)==k) { v=substr($0,i+1); sub(/^[ \t]+/,"",v); sub(/[ \t\r]+$/,"",v); print v; exit } }
  ' "$1"
}

# Print a free backup path for $1: $1.bak, else $1.bak.<YYYYmmddHHMMSS>[.N].
backup_path() {
  local b="$1.bak" ts i=1
  if [ -e "$b" ] || [ -L "$b" ]; then
    ts="$(date +%Y%m%d%H%M%S)"
    b="$1.bak.$ts"
    while [ -e "$b" ] || [ -L "$b" ]; do b="$1.bak.$ts.$i"; i=$((i + 1)); done
  fi
  echo "$b"
}

check_name() {
  case "$1" in
    ""|*[!A-Za-z0-9_-]*) die "invalid style name: $1" ;;
  esac
}

if [ ${#NAMES[@]} -eq 0 ]; then
  while IFS= read -r n; do NAMES+=("$n"); done < <(available)
fi
[ ${#NAMES[@]} -gt 0 ] || die "no styles found"

case "$MODE" in
  list)
    for n in "${NAMES[@]}"; do
      check_name "$n"
      f="$(fetch "$n")"
      printf '%s\n  name: %s\n  description: %s\n' "$n" "$(fm "$f" name)" "$(fm "$f" description)"
    done
    ;;

  uninstall)
    removed=0
    for n in "${NAMES[@]}"; do
      check_name "$n"
      t="$DEST_DIR/$n.md"
      if [ -e "$t" ] || [ -L "$t" ]; then
        ours=0
        if [ -L "$t" ]; then
          [ -n "$SRC_DIR" ] && [ "$(readlink "$t")" = "$SRC_DIR/$n.md" ] && ours=1
        elif [ -f "$t" ]; then
          f="$(fetch "$n")" || f=""
          [ -n "$f" ] && cmp -s "$f" "$t" && ours=1
        fi
        if [ "$ours" = 1 ]; then
          rm -f "$t"
          echo "removed $t"
          removed=$((removed + 1))
        else
          echo "skipped $t: modified or not installed by this script (delete it manually if you want)"
        fi
      else
        echo "not installed: $t"
      fi
    done
    echo "Done. Restart Claude Code. If one was active, run /output-style default."
    ;;

  install)
    mkdir -p "$DEST_DIR"
    installed=()
    for n in "${NAMES[@]}"; do
      check_name "$n"
      f="$(fetch "$n")"
      t="$DEST_DIR/$n.md"
      if [ "$LINK" = 1 ]; then
        if [ -L "$t" ] && [ "$(readlink "$t")" = "$f" ]; then
          echo "up to date: $t"
        else
          if [ -e "$t" ] || [ -L "$t" ]; then
            bak="$(backup_path "$t")"
            echo "replacing existing $t (backup: $bak)"
            mv "$t" "$bak"
          fi
          ln -s "$f" "$t"
          echo "linked $t -> $f"
        fi
      else
        if [ -L "$t" ]; then
          echo "replacing symlink $t"
          rm -f "$t"
        elif [ -f "$t" ]; then
          if cmp -s "$f" "$t"; then
            echo "up to date: $t"
            installed+=("$f")
            continue
          fi
          bak="$(backup_path "$t")"
          echo "replacing differing $t (backup: $bak)"
          cp -f "$t" "$bak"
        fi
        cp -f "$f" "$t"
        echo "installed $t"
      fi
      installed+=("$f")
    done
    echo
    echo "Styles ready:"
    for f in "${installed[@]}"; do
      echo "  - $(fm "$f" name)"
    done
    echo
    echo "Installed. No tone is active. Restart Claude Code, then pick one: /output-style <name> (or /config -> Output style)."
    echo "Switch back anytime with /output-style default."
    ;;
esac
