# Onboarding Documents

AI-optimized context documents for efficient session bootstrapping. Distilled from `docs/01-` … `docs/05-` so a session can load only what it needs.

## Documents

| File | Purpose | Approx. tokens |
|------|---------|----------------|
| [`00-philosophy-and-architecture.md`](00-philosophy-and-architecture.md) | What Truckr® is, ADRs, stack, domain model, must-know rules. | ~0.9K |
| [`01-patterns-and-implementation.md`](01-patterns-and-implementation.md) | The 10 codebase patterns + API + job conventions. | ~0.8K |
| [`02-coding-guidelines.md`](02-coding-guidelines.md) | Style, naming, commits, file layout, do/don't. | ~0.8K |
| [`03-module-reference.md`](03-module-reference.md) | Full directory tree + "where to find things". | ~1.2K |
| [`04-ai-harness.md`](04-ai-harness.md) | Skills map, issue lifecycle, conventions. | ~0.6K |
| [`05-testing-strategy.md`](05-testing-strategy.md) | Current state (none), conventions for when tests arrive. | ~0.7K |
| [`06-roadmap.md`](06-roadmap.md) | Live vs. planned, priority work, deferred decisions. | ~0.8K |

Total (full load): **~6K tokens**.

## Usage

These docs are designed to be loaded into AI agent context at session start. Pick the smallest set that covers the task.

| Task type | Documents | Approx. tokens |
|-----------|-----------|----------------|
| `exploration` | `00` | ~0.9K |
| `implementation` | `00` + `01` | ~1.7K |
| `code` | `00` + `02` | ~1.7K |
| `module` | `00` + `03` | ~2.1K |
| `ai` / `skill` work | `00` + `04` | ~1.5K |
| `testing` | `00` + `05` | ~1.6K |
| `planning` | `00` + `06` | ~1.7K |
| `full` | All | ~6K |

## When to Update

Onboarding docs are condensations of the tech docs in `docs/01-` … `docs/05-`. If you find yourself updating an onboarding doc, **first update the canonical source** in the corresponding section, then re-distill here. Don't let the two drift.

For execution order across issues, see [`docs/features/DEPENDENCY-GRAPH.md`](../features/DEPENDENCY-GRAPH.md) — that doc is canonical for the dependency edges and parallelization plan.

| Onboarding | Canonical source |
|------------|------------------|
| `00-philosophy-and-architecture.md` | `01-technical-vision/technical-vision.md` + `02-high-level-design/high-level-design.md` |
| `01-patterns-and-implementation.md` | `02-high-level-design/high-level-design.md` (Core Patterns) |
| `02-coding-guidelines.md` | `CLAUDE.md` + repo conventions |
| `03-module-reference.md` | `00-platform-architecture/platform-architecture.md` + repo tree |
| `04-ai-harness.md` | `05-appendices/ai-harness.md` |
| `05-testing-strategy.md` | (no canonical source yet — onboarding is the canonical source until a tech-doc section is added) |
| `06-roadmap.md` | `01-technical-vision/technical-vision.md` (Future Considerations) + `docs/features/ISSUES-INDEX.md` + `docs/features/DEPENDENCY-GRAPH.md` |
