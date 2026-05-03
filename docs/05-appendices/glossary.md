# Glossary

Spanish ↔ English terms used across the Truckr® codebase, product artifacts and this documentation set.

## Domain Terms

| Term | Language | Definition |
|------|----------|------------|
| **Transportista** | es | Independent truck owner/driver who publishes availability and fulfils cargo. |
| **Cliente** | es | Any shipper — used generically in API copy. |
| **Productor** | es | Specific kind of cliente: a producer (often agricultural or industrial) shipping their own goods. Used as a persona in `docs/artifacts/personas.typ`. |
| **Ventana de transporte** | es | "Transport window" — a block of availability published by a transportista (origin, destination, time range, vehicle). Maps to the planned `TransportWindow` model. |
| **Carga** | es | "Cargo / load" — goods to be transported; maps to `CargoOffer`. |
| **Envío** | es | "Shipment" — an active or completed transport contract between a transportista and a cliente. |
| **Cotización** | es | "Quote" — a price offer from a transportista for a specific cargo offer. The frontend's "Solicitar cotización" form captures a request but does not yet POST to the API. |
| **Pasarela de pagos** | es | Payment gateway with escrow capability. |
| **Tracking** | en/es | Live position and status updates for an in-transit shipment. |
| **Seguro** | es | Insurance policy brokered per shipment. |

## AI Harness Terms

| Term | Definition |
|------|------------|
| **Skill** | A versioned, reviewable folder under `.agents/skills/<name>/` (or `frontend/.agents/skills/<name>/`) containing a `SKILL.md` and optional `reference/`, `scripts/`. The canonical AI-agent entry point for a class of work. |
| **CLAUDE.md** | Repo-root file that ships project-wide conventions to AI assistants. Always loaded by Claude Code. |
| **`.agents/`** | Vendor-neutral skill location; mirrored into `.claude/skills/` via symlinks for Claude Code discovery. |
| **`.gdsi-sdlc/`** | File-backed Kanban + automation harness driving the issue lifecycle. |
| **Issue TAG** | `<PREFIX>-<SCOPE>-<NNNNN>` identifier (e.g. `INF-GEN-00002`). Prefixes: REQ, FIX, DOC, TST, REF, INF, REL. Scopes: DOC, BE, FE, INFRA, GEN. |
| **`impeccable`** | The frontend design north-star skill; companion to `frontend/.impeccable.md`. |

## Acronyms

| Acronym | Expansion | Context |
|---------|-----------|---------|
| **GDSI** | Gestión del Desarrollo de Sistemas Informáticos | Capstone subject at FIUBA for which this project is the deliverable. |
| **FIUBA** | Facultad de Ingeniería, Universidad de Buenos Aires | Host institution. |
| **ARCA** | Agencia de Recaudación y Control Aduanero | Argentine federal tax authority (successor to AFIP); fiscal-invoicing integration target. |
| **USM** | User Story Map | Product artifact under `docs/artifacts/usm.typ`. |
| **WBS** | Work Breakdown Structure | Product artifact under `docs/artifacts/wbs.typ`. |
| **MVP** | Minimum Viable Product | Scope marker used throughout the USM and backlog. |
| **CTA** | Call To Action | UI term used in the landing-page payload (`cta_primary`, `cta_secondary`). |
| **CORS** | Cross-Origin Resource Sharing | HTTP security mechanism configured in `backend/config/initializers/cors.rb`. |
| **SPA** | Single-Page Application | The React frontend. |
| **ADR** | Architecture Decision Record | Format used in `01-technical-vision/technical-vision.md`. |
| **CUIT** | Clave Única de Identificación Tributaria | Argentine company tax ID. |
| **DNI** | Documento Nacional de Identidad | Argentine national ID. |

## Tool Names

| Tool | Purpose |
|------|---------|
| **mise** | Version manager — pins Ruby, Typst, Deno, just, uv, prek, typstyle. |
| **just** | Command runner (see `justfile`). |
| **uv** | Python package / project manager used by `docs/scripts/*.py`. |
| **prek** | Pre-commit hook runner. |
| **typstyle** | Formatter for `.typ` files. |
| **Typst** | Markup-based typesetting system (LaTeX alternative). |
| **Thruster** | HTTP asset-caching/compression front-end for Puma. |
| **Kamal** | Docker-based deployment tool from 37signals. |
| **release-please** | Google-maintained tool that automates CHANGELOG + SemVer tags from Conventional Commits. |
| **Solid Queue / Cache / Cable** | Rails 8 database-backed replacements for Redis-backed job queue, cache and Action Cable pub/sub. |
