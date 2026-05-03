# AI Harness (Onboarding)

A condensed AI-agent-facing pointer to the harness. The full inventory is in `docs/05-appendices/ai-harness.md`; the architectural rationale is **ADR-006** in `docs/01-technical-vision/`.

## Layout

```
fiuba-gestion-tp/
├── CLAUDE.md                    # Project conventions (always loaded)
├── .agents/skills/              # Repo-wide product/planning skills
│   ├── user-stories/SKILL.md
│   ├── job-stories/SKILL.md
│   └── task-planning/SKILL.md
├── frontend/
│   ├── .impeccable.md           # Design north-star
│   ├── .agents/skills/          # 15 design skills
│   └── .claude/skills/          # Symlinks → ../.agents/skills/* for Claude Code
├── backend/                     # No backend skills yet (planned)
└── .gdsi-sdlc/                  # File-backed Kanban
```

## Skill Map (when to invoke what)

| Goal | Skill |
|------|-------|
| Convert a feature idea into user stories | `.agents/skills/user-stories` |
| Frame a feature in JTBD terms | `.agents/skills/job-stories` |
| Decompose an epic into ordered tasks | `.agents/skills/task-planning` |
| Build or refactor any UI surface | `frontend/.agents/skills/impeccable` |
| Audit/critique a screen against heuristics | `frontend/.agents/skills/critique`, `audit` |
| Tighten a screen that's "almost there" | `frontend/.agents/skills/polish`, `clarify` |
| Add motion / animation | `frontend/.agents/skills/animate` |
| Layout / spatial fixes | `frontend/.agents/skills/layout`, `shape` |
| Typography pass | `frontend/.agents/skills/typeset` |
| Color / palette pass | `frontend/.agents/skills/colorize` |
| Make UI quieter / more restrained | `frontend/.agents/skills/quieter` |
| Push UI further / more expressive | `frontend/.agents/skills/overdrive` |
| Responsive adaptation | `frontend/.agents/skills/adapt` |
| Trim copy / surface | `frontend/.agents/skills/distill` |
| Performance / size optimisation | `frontend/.agents/skills/optimize` |

## Issue Lifecycle

Each issue is a markdown file at `.gdsi-sdlc/issues/<status>/<TAG>-<slug>.issue.md` where `TAG` = `<PREFIX>-<SCOPE>-<NNNNN>`:

- **Prefixes**: `REQ` (feature), `FIX` (bug), `DOC`, `TST`, `REF` (refactor), `INF` (infra), `REL` (release).
- **Scopes**: `DOC`, `BE` (backend), `FE` (frontend), `INFRA`, `GEN` (cross-cutting).

Move the file to advance status:

```
Backlog → Ready → InProgress → InReview → Done
```

`automation/queue/sync/` holds pending GitHub Projects sync events (`project_number: 7`, see `.gdsi-sdlc/config.json`). `automation/queue/{completed,failures}/` are the post-processing buckets.

`docs/features/ISSUES-INDEX.md` is the human-readable index — keep it up to date when status changes.

## Conventions Recap (from `CLAUDE.md`)

- Spanish (es-AR) for product content; English for code/identifiers/commits.
- Conventional Commits or release-please drops the change.
- Documentation-only changes typically take a single `*-DOC-*` issue.
- typstyle auto-formats `.typ` on commit — let it.

## Adding a New Skill

1. Choose the right scope:
   - Repo-wide product/planning → `.agents/skills/<name>/`
   - Frontend craft → `frontend/.agents/skills/<name>/` **and** symlink to `frontend/.claude/skills/<name>`.
   - Backend (when needed) → `backend/.agents/skills/<name>/` (folder doesn't exist yet — create it).
2. Create `SKILL.md` with: purpose, when-to-invoke triggers, inputs, outputs, examples.
3. Optional: `reference/*.md` for deep references the skill consumes; `scripts/*` for executable helpers.
4. Commit with `chore(skills): add <name> skill` (or `feat(skills): …` if it materially changes workflow).

## Don't

- Don't paste skill prompts into chat history as a substitute for a skill folder.
- Don't bypass the issue Kanban by tracking work in chat or in commit messages.
- Don't invent new TAG prefixes/scopes — extend `.gdsi-sdlc/config.json` first.
- Don't widen CORS / disable CSP / commit secrets to make AI tooling "easier".
