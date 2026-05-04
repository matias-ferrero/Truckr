# Glossary

**Source of truth.** This file is the authoritative term registry for the Truckr® project. Whenever a term is introduced, renamed, or deprecated:

1. Update this file FIRST.
2. Propagate to product artifacts (`docs/artifacts/*.typ`), tech docs, code identifiers, and UI copy.
3. Drift between this file and any other doc counts as a defect — fix on sight.

Spanish ↔ English terms used across the Truckr® codebase, product artifacts and this documentation set.

## Domain Terms

The `English model / table` column lists the canonical Rails identifier for each term that is (or will be) persisted. Identifiers are **always English** — Spanish stays in product artifacts, issue titles, UI copy and narrative prose. See `docs/02-high-level-design/domain-model.md` for the persona ↔ model mapping derived from this table.

| Term (es-AR) | English model / table | Definition |
|--------------|-----------------------|------------|
| **Transportista** | `Carrier` / `carriers` | Independent truck owner / driver who publishes availability and fulfils cargo. Persona in `docs/artifacts/personas.typ`. |
| **Expedidor** | `Shipper` / `shippers` | Party who needs to ship cargo — covers SMB clients and producers (agricultural / industrial) shipping their own goods. Persona in `docs/artifacts/personas.typ`. Replaces the older terms "Cliente" and "Productor" (deprecated 2026-05-03). |
| **Usuario (cuenta de auth)** | `User` / `users` | Base account record (email, password digest, common profile fields). A single `User` may have a `Carrier` profile, a `Shipper` profile, or both — role state is derived from the relation rows via `User.carriers` / `User.shippers` scopes and `user.carrier?` / `user.shipper?` predicates (no denormalised flags; see ADR-008). |
| **Camión / Vehículo** | `Vehicle` / `vehicles` | Truck registered by a Transportista. Plate, capacity, type, GPS-capable flag. |
| **Ventana de transporte** | `TransportWindow` / `transport_windows` | Block of availability published by a Transportista (origin, destination, time range, vehicle). |
| **Carga (oferta)** | `CargoOffer` / `cargo_offers` | "Cargo offer / load" — goods published by an Expedidor for transport. |
| **Cotización** | `Quote` / `quotes` | Price offer from a Transportista against a specific `CargoOffer`. The frontend's "Solicitar cotización" form captures a request locally but does not yet POST to the API. |
| **Envío** | `Shipment` / `shipments` | Active or completed transport contract between a Transportista and an Expedidor. State machine: `draft → quoted → accepted → in_transit → delivered → settled` (+ `cancelled`). Soft-deleted (audit). |
| **Evento de tracking** | `TrackingEvent` / `tracking_events` | Append-only log entry for a Shipment: position, status change. |
| **Ruta** | `Route` / `routes` | Planned polyline + waypoints for a Shipment. |
| **Pago / Escrow** | `Payment` / `payments` | Held funds released on delivery. Soft-deleted (audit). |
| **Seguro** | `InsurancePolicy` / `insurance_policies` | Insurance policy brokered per Shipment, optional. |
| **Factura ARCA** | `ArcaInvoice` / `arca_invoices` | Fiscal document emitted against a settled Shipment. Soft-deleted (audit). |
| **Pasarela de pagos** | — (external) | Third-party payment gateway with escrow capability. Not a model — integration target. |
| **Tracking** | — (concept) | Live position and status updates for an in-transit shipment. The model is `TrackingEvent`. |

### Deprecated synonyms (kept for traceability — do not introduce in new content)

| Term | Status | Notes |
|------|--------|-------|
| **Cliente** | deprecated 2026-05-03 — folded into `Expedidor` | The word "cliente" remains valid in two narrow contexts: (a) **cliente fiscal** when referring to the ARCA invoice counter-party (`ArcaInvoice` references the `Shipper` as the fiscal customer); (b) **clientes externos** as a generic word for "external customers" of the platform (rare; prefer "usuarios" or "expedidores" when possible). Any other use is a defect. |
| **Productor** | deprecated 2026-05-03 — folded into `Expedidor` | Was a sub-persona of Cliente (agricultural / industrial producer). Modelled as `Shipper` with no specialised subtype in Phase 0/1. |

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
