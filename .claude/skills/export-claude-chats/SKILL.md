---
name: export-claude-chats
description: Copy a teammate's local Claude Code chat transcripts for the Truckr (fiuba-gestion-tp) repo into docs/prompts/raw/claude/ and generate the Typst (.typ) prompt-record files. Use when a contributor wants to export, archive, or contribute their Claude Code chat history / prompts for this repo, or mentions syncing .jsonl transcripts, "my Claude chats", or the prompts deliverable.
---

# Export Claude Code chats → Typst

Each teammate runs this on their own machine to contribute their Claude Code
prompt history for this repo to the `docs/prompts/` deliverable. Only the
redacted, derived `.typ` files are committed — the raw `.jsonl` transcripts stay
local (they are gitignored).

## Quick start

From a clone of this repo, on the machine where you used Claude Code:

```sh
just sync-claude-chats     # copy your local .jsonl into docs/prompts/raw/claude/
just build-claude-chats    # convert to .typ and compile the PDF
```

Then commit the generated `.typ` files (see step 4). That's the whole flow.

## How it works

Claude Code stores each session as a JSON-Lines transcript under
`~/.claude/projects/<cwd-with-slashes-as-dashes>/<session-id>.jsonl`. This repo
shows up as one project dir for the main checkout plus one per git worktree.

1. **Sync** — `scripts/sync-claude-chats.sh` finds every `~/.claude/projects/`
   dir containing `fiuba-gestion-tp`, then copies the top-level `*.jsonl` into
   `docs/prompts/raw/claude/`, mapping origin so the aggregator groups them:
   - main checkout → `claude/main/`
   - worktree `<name>` → `claude/worktree-<name>/`

   It lists the matched project dirs and asks before copying; it is idempotent
   — re-run any time to pick up new sessions. Pass `-y` (or run non-interactively)
   to skip the prompt. Honors `CLAUDE_CONFIG_DIR` (defaults to `~/.claude`).

2. **Convert** — `just build-claude-chats` runs
   `docs/scripts/claude_jsonl2typ.py` over the copied `.jsonl`, writing a
   `<id>.typ` next to each and a grouped `main.typ` aggregator, then compiles a
   PDF. (`just convert-claude-chats` does the conversion without the PDF.)

3. **Redaction (automatic)** — before rendering, the converter strips internal
   thinking, tool calls, and `<system-reminder>` noise, then scrubs PII
   (emails, secrets/tokens, URL credentials, home-dir usernames, public IPs,
   phones) and applies the `c9y → gdsi` course-rebrand. Pass `--no-redact` to
   the script directly only if you have a reason to keep raw text (not
   recommended for committed files).

4. **Commit** — only the `.typ` are tracked; `*.jsonl` and the PDF are
   gitignored. Stage and commit:

   ```sh
   git add docs/prompts/raw/claude/'**/*.typ' docs/prompts/raw/claude/main.typ
   git commit -m "docs(prompts): add <name>'s Claude Code transcripts (Typst)"
   ```

   `typstyle` runs on commit via the pre-commit hook — let it reformat, re-stage
   if needed, and commit again.

## Verify before pushing

- `just build-claude-chats` compiled the aggregator PDF cleanly.
- A quick residual scan returns nothing committed-sensitive, e.g.:
  ```sh
  grep -rIl -e '@gmail' -e 'sk-ant-' -e 'ghp_' -e '/home/' docs/prompts/raw/claude/*.typ docs/prompts/raw/claude/**/*.typ
  ```
  (Expect no output. If a pattern slips through, extend `_redact_pii` in the
  converter rather than hand-editing the `.typ`.)

## Notes

- PR title must start with a conventional type (`docs:`/`chore:`), no `[TAG]`
  bracket prefix — squash-merge feeds release-please. Reference the TAG in the
  body. Pass `--assignee @me` when opening the PR.
- Retention: Claude Code prunes transcripts after `cleanupPeriodDays` (default
  30). Sessions older than that are already gone and cannot be exported.
