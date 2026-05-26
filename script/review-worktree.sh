#!/usr/bin/env bash
# Boot a worktree under .claude/worktrees/<name> into a 3-pane kitty layout
# for manual UI/behavior review. See docs/features/REF/review-worktree.plan.md.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
WORKTREES_DIR="$REPO_ROOT/.claude/worktrees"

die() { echo "review-worktree: $*" >&2; exit 1; }

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

require_cmd git
require_cmd kitty
require_cmd mise
require_cmd deno
require_cmd bundle
require_cmd mktemp

[[ -d "$WORKTREES_DIR" ]] || die "no .claude/worktrees/ in $REPO_ROOT"

# ── Resolve target worktree ────────────────────────────────────────────────
NAME="${1:-}"
if [[ -z "$NAME" ]]; then
    if command -v fzf >/dev/null 2>&1; then
        NAME="$(ls -1 "$WORKTREES_DIR" | fzf --prompt='worktree> ' --height=40% --reverse)"
        [[ -n "$NAME" ]] || die "no worktree selected"
    else
        echo "Available worktrees (install fzf for picker):" >&2
        ls -1 "$WORKTREES_DIR" >&2
        die "pass a worktree name as argument"
    fi
fi

WT="$WORKTREES_DIR/$NAME"
[[ -d "$WT" ]] || die "worktree not found: $WT"
[[ -d "$WT/backend" ]] || die "no backend/ in worktree $NAME"
[[ -d "$WT/frontend" ]] || die "no frontend/ in worktree $NAME"

# ── Anchor banner ──────────────────────────────────────────────────────────
BRANCH="$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
echo
echo "Reviewing $BRANCH  →  http://localhost:5173"
echo

# ── Trust worktree's mise config (idempotent) ──────────────────────────────
echo "▸ mise trust"
mise trust "$WT" >/dev/null

# ── Copy .env* from main repo into the worktree (gitignored, won't follow) ─
echo "▸ copy .env* from main repo"
shopt -s nullglob
for dir in "" backend frontend; do
    src_dir="$REPO_ROOT${dir:+/$dir}"
    dst_dir="$WT${dir:+/$dir}"
    [[ -d "$dst_dir" ]] || continue
    for env_file in "$src_dir"/.env*; do
        [[ -f "$env_file" ]] || continue
        cp -n "$env_file" "$dst_dir/"
    done
done
shopt -u nullglob

# ── Deps (always, idempotent) ──────────────────────────────────────────────
echo "▸ bundle install (backend)"
(cd "$WT/backend" && bundle install)

echo "▸ deno install (frontend)"
(cd "$WT/frontend" && deno install)

# ── DB prep ────────────────────────────────────────────────────────────────
DB_FILE="$WT/backend/storage/development.sqlite3"
if [[ -f "$DB_FILE" ]]; then
    echo "▸ db:migrate (existing DB)"
    (cd "$WT/backend" && bin/rails db:migrate)
else
    echo "▸ db:prepare + db:seed (fresh DB)"
    (cd "$WT/backend" && bin/rails db:prepare && bin/rails db:seed)
fi

# ── Spawn kitty session ────────────────────────────────────────────────────
SESSION="$(mktemp -t review-worktree.XXXXXX.conf)"
SHELL_BIN="${SHELL:-/bin/bash}"

cat >"$SESSION" <<EOF
new_tab review:$NAME

launch --cwd=$WT/backend --title=backend bin/dev
launch --location=vsplit --cwd=$WT/frontend --title=frontend deno task dev -- --open
launch --location=hsplit --cwd=$WT --title=shell $SHELL_BIN
EOF

kitty --detach --session "$SESSION" --title "review:$NAME"

# Session file is consumed at spawn; safe to clean up shortly. Leave it for
# debugging — /tmp gets reaped on boot.

echo "▸ kitty window spawned. Close the window to tear down all servers."
