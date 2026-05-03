# AI Harness

How AI assistants are wired into the Truckr® development workflow. This appendix is the reference for **what skills exist, where they live, and when to use which**. The decision behind it is recorded as **ADR-006** in `01-technical-vision/technical-vision.md`.

## Layout

```
fiuba-gestion-tp/
├── CLAUDE.md                       # Project-wide conventions (always loaded)
├── .agents/
│   └── skills/                     # Repo-wide product/planning skills
│       ├── job-stories/SKILL.md
│       ├── task-planning/SKILL.md
│       └── user-stories/SKILL.md
├── .gdsi-sdlc/                     # File-backed Kanban + automation harness
│   ├── config.json                 # GitHub Projects sync config
│   ├── issues/
│   │   ├── Backlog/                # Not yet planned
│   │   ├── Ready/                  # Planned, ready for work
│   │   ├── InProgress/             # Active
│   │   ├── InReview/               # PR open
│   │   └── Done/                   # Merged
│   └── automation/
│       ├── config/
│       ├── scripts/                # Sync + queue processors
│       └── queue/{sync,completed,failures}/
├── frontend/
│   ├── .impeccable.md              # Frontend design north-star
│   ├── .agents/skills/             # Design / UX skills (15+)
│   └── .claude/skills/             # Symlinks → ../.agents/skills/* for Claude Code
└── backend/                        # No backend-specific skills yet (see roadmap)
```

## Skills Inventory

### Repo-level — product & planning (`.agents/skills/`)

| Skill | Purpose |
|-------|---------|
| `user-stories` | Generate / refine user stories in the `Como X quiero Y para Z` format with numbered acceptance criteria. |
| `job-stories` | Generate / refine job stories (`When …, I want to …, so I can …`) for situational framing. |
| `task-planning` | Decompose a backlog item or epic into ordered, testable tasks. |

These are language- and stack-agnostic. They are the canonical entry point when working from `docs/artifacts/usm.typ`, `wbs.typ`, `personas.typ` or any item in `.gdsi-sdlc/issues/Backlog/`.

### Frontend-level — design & UX craft (`frontend/.agents/skills/`)

The frontend is held to a high design standard (see `frontend/.impeccable.md`). The skill set is grouped by intent:

| Group | Skills | Purpose |
|-------|--------|---------|
| **Vision & critique** | `impeccable`, `critique`, `audit`, `clarify` | Set or evaluate a UI against the design north-star and heuristics (cognitive load, personas, scoring). |
| **Composition** | `layout`, `shape`, `typeset`, `colorize` | Spatial design, geometry, typography, palette work. |
| **Polish & motion** | `polish`, `animate`, `overdrive`, `quieter` | Refinement, motion design, intensifying or restraining a UI. |
| **Adaptation** | `adapt`, `optimize`, `distill` | Responsive design, perf, content reduction. |

Each skill is a `SKILL.md` file; some carry `reference/` material (e.g. `impeccable/reference/typography.md`, `critique/reference/heuristics-scoring.md`) and `scripts/` (e.g. `impeccable/scripts/cleanup-deprecated.mjs`). The same skills are exposed to Claude Code via symlinks in `frontend/.claude/skills/`.

### Backend-level — none yet

No backend skill folder exists today. Likely first additions when implementation accelerates: `rails-controller`, `rails-model`, `rspec-test`, `solid-queue-job`, `migration`. These should land under `backend/.agents/skills/` with matching `backend/.claude/skills/` symlinks.

## Issue Lifecycle

The `.gdsi-sdlc/` harness models a Kanban board as folders. Each issue is a markdown file named `<TAG>-<slug>.issue.md` where `TAG` follows the project convention `<PREFIX>-<SCOPE>-<NNNNN>`:

- **Prefixes**: `REQ` (feature), `FIX` (bug), `DOC`, `TST`, `REF` (refactor), `INF` (infra), `REL` (release).
- **Scopes**: `DOC`, `BE` (backend), `FE` (frontend), `INFRA`, `GEN` (cross-cutting).

Movement between folders mirrors status changes (`Backlog → Ready → InProgress → InReview → Done`). The `automation/queue/` directory carries pending sync events to GitHub Projects (`project_number: 7` per `.gdsi-sdlc/config.json`).

`docs/features/ISSUES-INDEX.md` is the human-readable index of currently active issues.

## Conventions for AI-Assisted Work

These come from `CLAUDE.md` and are repeated here for quick reference:

- All written content (artifacts, user stories, prompts) is in **Spanish (es-AR)**.
- Code, identifiers, commit messages, issue titles in **English**.
- Conventional Commits drive `release-please`; commits drift from this convention will be silently dropped from the release.
- typstyle auto-formats `.typ` on commit — let it.
- Documentation-only changes typically take a single `*-DOC-*` issue rather than per-component splits.

## Where to Find Things

| Need to… | Look in… |
|----------|----------|
| Add a product / planning skill | `.agents/skills/<name>/SKILL.md` |
| Add a frontend design skill | `frontend/.agents/skills/<name>/SKILL.md` + symlink under `frontend/.claude/skills/` |
| Document a project-wide convention | `CLAUDE.md` |
| Tweak the frontend design north-star | `frontend/.impeccable.md` |
| Create a new issue | `.gdsi-sdlc/issues/Backlog/<TAG>-<slug>.issue.md` |
| Move an issue forward | Move the file to the next status folder |
| Reconfigure GitHub Projects sync | `.gdsi-sdlc/config.json` |

## Document Information

| Attribute | Value |
|-----------|-------|
| Version | 1.0 |
| Generated | 2026-05-03 |
| Scope | AI tooling, skills, and SDLC harness |
