# Platform Architecture — Truckr® Monorepo

## Overview

Truckr® lives in a single Git repository with **three independently buildable components**. Each component has its own language toolchain, its own README, and its own build commands. They share versioning (SemVer via `release-please`) and a top-level `justfile` / `mise.toml` for developer experience.

```
fiuba-gestion-tp/
├── backend/     # Rails 8 API (Ruby 3.4)
├── frontend/    # React 18 + Vite SPA (TypeScript / Deno)
├── docs/        # Typst academic report + Python build scripts
├── justfile     # Top-level doc tasks (artifacts, chats, lint)
├── mise.toml    # Tool pins (gh, typst, uv, prek, typstyle, just)
└── .github/workflows/  # release-please workflow
```

## Why a monorepo

| Concern | Why monorepo works for this project |
|---------|-------------------------------------|
| Single academic deliverable | The GDSI report references code, diagrams, and user stories in one place. |
| Small team | Contributors switch between backend, frontend, and docs inside the same session. |
| Shared release cadence | One SemVer tag per milestone; release PDFs attach to the same GitHub release. |
| Tool pinning | `mise.toml` guarantees every contributor has the same Typst / Just / uv versions. |

If the product graduates past the academic deliverable, each component can be extracted into its own repository without rewriting its internals — the boundaries are already clean.

## Component Matrix

| Component | Language | Framework | Build tool | Test tool | Runtime |
|-----------|----------|-----------|------------|-----------|---------|
| backend | Ruby 3.4 | Rails 8.1 (API-only) | `bundle`, `bin/rails` | RSpec (`bundle exec rspec`, smoke spec only) | Puma + Thruster |
| frontend | TypeScript 5.3 | React 18 + Vite 5 | `deno task build` | Vitest (unit/component) + Playwright (E2E); smoke specs only | Static bundle |
| docs | Typst + Python | — | `just build` | `just lint` | Typst compiler |

## Inter-component Contracts

- **frontend → backend**: HTTP/JSON, `VITE_API_BASE_URL` env var, default `http://localhost:3000`. Schema validated at the boundary by hand-written TS type guards (`isLandingData`). No codegen today.
- **docs ↔ code**: one-way. Docs reference product decisions; code does not depend on docs at runtime. Typst PDFs are built from `.typ` sources in CI.
- **release pipeline**: `release-please` watches `main`, derives bumps from Conventional Commits, opens a Release PR. Merging the Release PR tags a version and triggers `typst compile` in GitHub Actions to attach the PDFs.

## Platform Diagram

See `diagrams/platform-overview.puml`.

## Document Information

| Attribute | Value |
|-----------|-------|
| Version | 1.0 |
| Generated | 2026-04-17 |
