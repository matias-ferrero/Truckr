#!/usr/bin/env bash
# Copy THIS machine's Claude Code transcripts for the Truckr repo into
# docs/prompts/raw/claude/, mirroring the main-checkout / per-worktree layout
# that docs/scripts/claude_jsonl2typ.py expects (origin = first subdir).
#
# Idempotent: re-run any time to refresh. Copies only top-level *.jsonl
# (subagent sidechains are skipped — the converter ignores them anyway).
#
# Lists the matched project dirs and asks for confirmation before copying.
# Pass -y/--yes to skip the prompt; it is also auto-skipped when stdin is not
# a terminal (e.g. CI). Honors CLAUDE_CONFIG_DIR; defaults to ~/.claude.
set -euo pipefail

ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    -y | --yes) ASSUME_YES=1 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

REPO_SLUG="fiuba-gestion-tp"
PROJECTS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"

# Repo root (where docs/ lives) from git; fall back to cwd.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DEST_ROOT="$REPO_ROOT/docs/prompts/raw/claude"

if [[ ! -d "$PROJECTS_DIR" ]]; then
  echo "No Claude projects dir at $PROJECTS_DIR — nothing to copy." >&2
  exit 1
fi

# ── Pass 1: build the copy plan ──────────────────────────────────────────────
# Parallel arrays: source dir, destination origin, transcript count.
shopt -s nullglob
srcs=() origins_arr=() counts=()
planned=0
for proj in "$PROJECTS_DIR"/*"$REPO_SLUG"*; do
  [[ -d "$proj" ]] || continue
  base="$(basename "$proj")"

  # Map the project dir name -> destination origin subdir.
  # Claude Code names project dirs after the cwd with '/' replaced by '-':
  #   .../-home-<user>-.../fiuba-gestion-tp        -> main
  #   ...fiuba-gestion-tp--claude-worktrees-<name> -> worktree-<name>
  case "$base" in
    *--claude-worktrees-*) origin="worktree-${base##*--claude-worktrees-}" ;;
    *"$REPO_SLUG") origin="main" ;;
    *) continue ;;
  esac

  files=("$proj"/*.jsonl)
  [[ ${#files[@]} -gt 0 ]] || continue

  srcs+=("$proj")
  origins_arr+=("$origin")
  counts+=("${#files[@]}")
  planned=$((planned + ${#files[@]}))
done

if [[ ${#srcs[@]} -eq 0 ]]; then
  echo "No transcripts found for '$REPO_SLUG' under $PROJECTS_DIR." >&2
  echo "Have you used Claude Code in a clone of this repo on this machine?" >&2
  exit 1
fi

# ── Confirm ──────────────────────────────────────────────────────────────────
echo "Found $planned transcript(s) across ${#srcs[@]} project dir(s):"
for i in "${!srcs[@]}"; do
  printf '  %-3s %s -> %s/\n' "${counts[$i]}" "$(basename "${srcs[$i]}")" "${origins_arr[$i]}"
done
echo "Destination: $DEST_ROOT"
echo

if [[ "$ASSUME_YES" -ne 1 && -t 0 ]]; then
  read -r -p "Copy these transcripts? [y/N] " reply
  case "$reply" in
    [yY] | [yY][eE][sS]) ;;
    *) echo "Aborted — nothing copied."; exit 0 ;;
  esac
fi

# ── Pass 2: copy ─────────────────────────────────────────────────────────────
copied=0
for i in "${!srcs[@]}"; do
  dest="$DEST_ROOT/${origins_arr[$i]}"
  mkdir -p "$dest"
  cp -f "${srcs[$i]}"/*.jsonl "$dest"/
  copied=$((copied + counts[i]))
done

echo
echo "Copied $copied transcript(s) into:"
echo "  $DEST_ROOT"
echo "Next: run 'just build-claude-chats' to generate the .typ files (+ PDF)."
