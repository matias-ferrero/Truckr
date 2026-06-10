#!/usr/bin/env bash
# Boot a worktree under .claude/worktrees/<name> — or the root clone via the
# special name `main` — into a 3-pane kitty layout for manual UI/behavior
# review. See docs/features/REF/review-worktree.plan.md.

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
require_cmd ss

# Pick a free TCP port in [lo, hi]. `ss -Hltn` lists every socket in LISTEN
# state; we extract the trailing :port from each local address and reject any
# random candidate that's already bound. Random candidates (not lowest-free)
# so two reviews booted back-to-back are unlikely to race for the same port
# before either server binds it. `excluded` lets the caller reserve a port it
# just picked but hasn't bound yet (the backend port while choosing frontend).
pick_free_port() {
    local lo="$1" hi="$2" excluded="${3:-}" port
    local busy
    busy="$(ss -Hltn 2>/dev/null | awk '{print $4}' | sed -E 's/.*:([0-9]+)$/\1/')"
    for _ in $(seq 1 100); do
        port=$(( (RANDOM % (hi - lo + 1)) + lo ))
        [[ "$port" == "$excluded" ]] && continue
        if ! grep -qx "$port" <<<"$busy"; then
            echo "$port"
            return 0
        fi
    done
    die "no free port found in $lo-$hi after 100 tries"
}

# Worktrees dir is optional: `just review main` targets the root clone and
# doesn't need it. Empty it out rather than dying so `main` always works.
[[ -d "$WORKTREES_DIR" ]] || WORKTREES_DIR=""

# ── Resolve target: `main` = root clone, otherwise a worktree ──────────────
NAME="${1:-}"
if [[ -z "$NAME" ]]; then
    if command -v fzf >/dev/null 2>&1; then
        NAME="$( { echo main; [[ -n "$WORKTREES_DIR" ]] && ls -1 "$WORKTREES_DIR"; } \
            | fzf --prompt='target> ' --height=40% --reverse)"
        [[ -n "$NAME" ]] || die "no target selected"
    else
        echo "Available targets (install fzf for picker):" >&2
        echo "main" >&2
        [[ -n "$WORKTREES_DIR" ]] && ls -1 "$WORKTREES_DIR" >&2
        die "pass a target name as argument"
    fi
fi

if [[ "$NAME" == "main" ]]; then
    WT="$REPO_ROOT"
else
    [[ -n "$WORKTREES_DIR" ]] || die "no .claude/worktrees/ in $REPO_ROOT"
    WT="$WORKTREES_DIR/$NAME"
    [[ -d "$WT" ]] || die "worktree not found: $WT"
fi
[[ -d "$WT/backend" ]] || die "no backend/ in $NAME"
[[ -d "$WT/frontend" ]] || die "no frontend/ in $NAME"

# ── Pick two random free ports so reviews run in parallel ──────────────────
# Each review session binds its own backend (Rails) and frontend (Vite) port,
# so several worktrees can run side by side without colliding on :3000/:5173.
# The chosen ports are threaded through three places:
#   • FE_PORT  → Vite's --port, and the backend's FRONTEND_ORIGIN allowlist so
#                CORS (config/initializers/cors.rb) and ActiveAdmin's
#                impersonation redirect (app/admin/users.rb) target this SPA.
#   • BE_PORT  → foreman/Puma via PORT, and the SPA's VITE_API_BASE_URL so the
#                frontend calls this backend instead of the default :3000.
# Action Cable's dev origin allowlist already accepts any localhost:<port>
# (config/environments/development.rb), so no extra wiring is needed there.
BE_PORT="$(pick_free_port 3001 3999)"
FE_PORT="$(pick_free_port 5174 5999)"
FRONTEND_ORIGIN="http://localhost:$FE_PORT,http://127.0.0.1:$FE_PORT"
BACKEND_URL="http://localhost:$BE_PORT"

# ── Anchor banner ──────────────────────────────────────────────────────────
BRANCH="$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
echo
echo "Reviewing $BRANCH"
echo "  frontend →  http://localhost:$FE_PORT"
echo "  backend  →  $BACKEND_URL"
echo

# ── Trust worktree's mise config (idempotent) ──────────────────────────────
echo "▸ mise trust"
mise trust "$WT" >/dev/null

# ── Copy .env* from main repo into the worktree (gitignored, won't follow) ─
# Skipped when reviewing the root clone — source and destination are the same.
if [[ "$WT" != "$REPO_ROOT" ]]; then
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
else
    echo "▸ root clone — .env* already in place"
fi

# ── Deps (always, idempotent) ──────────────────────────────────────────────
echo "▸ bundle install (backend)"
(cd "$WT/backend" && bundle install)

echo "▸ deno install (frontend)"
(cd "$WT/frontend" && deno install)

# foreman runs the backend Procfile but isn't in the Gemfile (it's a dev-only
# tool the repo installs ad hoc). Mirror backend/bin/dev and install on demand.
if ! gem list foreman -i --silent >/dev/null 2>&1; then
    echo "▸ installing foreman"
    gem install foreman
fi

# ── DB prep ────────────────────────────────────────────────────────────────
DB_FILE="$WT/backend/storage/development.sqlite3"
if [[ -f "$DB_FILE" ]]; then
    echo "▸ db:migrate (existing DB)"
    (cd "$WT/backend" && bin/rails db:migrate)
else
    echo "▸ db:prepare + db:seed (fresh DB)"
    (cd "$WT/backend" && bin/rails db:prepare && bin/rails db:seed)
fi

# ── Generate a backend Procfile with the chosen port baked in ──────────────
# We can't reuse the worktree's bin/dev / Procfile.dev: a worktree may be on
# any branch, and older branches hardcode `-p 3000`, ignoring our PORT env. By
# generating our own Procfile (port literal-expanded by bash here) and running
# foreman directly, the bind port is enforced no matter the branch. `foreman
# -p $BE_PORT` also exports PORT=$BE_PORT to the web process so ActiveStorage's
# signed-URL port matches the Puma bind port (see backend/bin/dev for why).
# `-d $WT/backend` (on the launch below) is required: foreman defaults its
# working dir to the Procfile's location (/tmp here), which would otherwise
# break the relative `bin/rails`.
BE_PROCFILE="$(mktemp -t review-worktree.XXXXXX.procfile)"
cat >"$BE_PROCFILE" <<EOF
web: bin/rails server -p $BE_PORT -b 127.0.0.1
css: bin/rails dartsass:watch
EOF

# ── Spawn kitty session ────────────────────────────────────────────────────
SESSION="$(mktemp -t review-worktree.XXXXXX.conf)"
SHELL_BIN="${SHELL:-/bin/bash}"

# Per-pane env + args carry the chosen ports into each server:
#   • backend pane: foreman runs our generated Procfile (Puma → BE_PORT);
#     FRONTEND_ORIGIN scopes CORS + the impersonation redirect to this SPA.
#   • frontend pane: VITE_API_BASE_URL points the SPA at this session's backend;
#     `deno task dev` forwards trailing args to Vite WITHOUT a `--` separator
#     (a literal `--` reaches Vite and makes it ignore --port, drifting back to
#     5173). --port binds Vite to FE_PORT; --strictPort fails loudly instead of
#     silently drifting to another port (which would break the wiring above).
cat >"$SESSION" <<EOF
new_tab review:$NAME

launch --cwd=$WT/backend --env PORT=$BE_PORT --env FRONTEND_ORIGIN=$FRONTEND_ORIGIN --title=backend foreman start -f $BE_PROCFILE -d $WT/backend -p $BE_PORT
launch --location=vsplit --cwd=$WT/frontend --env VITE_API_BASE_URL=$BACKEND_URL --title=frontend deno task dev --port $FE_PORT --strictPort --open
launch --location=hsplit --cwd=$WT --title=shell $SHELL_BIN
EOF

kitty --detach --session "$SESSION" --title "review:$NAME"

# Session file is consumed at spawn; safe to clean up shortly. Leave it for
# debugging — /tmp gets reaped on boot.

echo "▸ kitty window spawned. Close the window to tear down all servers."
