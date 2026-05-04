# Database Diagrams

**Status**: the backend currently has **no domain migrations and no domain tables** — only ActiveAdmin/Devise tables exist. `backend/db/` holds the ActiveAdmin schema plus a placeholder `seeds.rb`. The landing page is purely a static frontend page (`frontend/src/landingContent.ts`); no backend record is involved.

The ERDs in this folder describe the **drafted** data model (v1), produced under [REQ-BE-00005](../features/REQ/REQ-BE-00005/REQ-BE-00005-disenar-modelo-de-dominio-inicial.plan.md). They are aligned with ADR-007 to ADR-010 in [`docs/01-technical-vision/technical-vision.md`](../01-technical-vision/technical-vision.md) and the detailed entity spec in [`docs/02-high-level-design/domain-model.md`](../02-high-level-design/domain-model.md). Identity is at "ready-to-migrate" depth; the other contexts are conceptual and will be refined as their migrations land.

## Files

| File | Domain | Status |
|------|--------|--------|
| `erd-overview.puml` | Cross-context relationships across all four bounded contexts | Draft v1 |
| `erd-identity.puml` | `users`, `carriers`, `shippers`, `vehicles` | Draft v1 (ready-to-migrate) |
| `erd-marketplace.puml` | `transport_windows`, `cargo_offers`, `quotes` | Draft v1 (conceptual) |
| `erd-fulfilment.puml` | `shipments`, `tracking_events`, `routes` | Draft v1 (conceptual) |
| `erd-commerce.puml` | `payments`, `insurance_policies`, `arca_invoices` | Draft v1 (conceptual) |

## Conventions

- Identifiers (entities, attributes) are **English**. Persona ↔ model mapping (`Transportista` ↔ `Carrier`, `Expedidor` ↔ `Shipper`) lives in [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md).
- Primary keys: `id : bigint` (Rails default; ADR-007).
- Foreign keys: `{entity}_id : bigint` with a `<<FK>>` marker.
- Timestamps (`created_at`, `updated_at`) are explicit.
- Required fields are prefixed with `*`.
- Enum-like columns are typed as `string` to keep the SQLite Phase-0/1 schema portable (ADR-002); allowed values listed in brackets.
- Soft-delete (`deleted_at`) appears only on `shipments`, `payments`, `arca_invoices` (ADR-009).
- Latitude / longitude are `decimal(9,6)` columns (ADR-010); no spatial index until Phase 2.

## Rendering

```sh
# Render a single diagram
java -jar plantuml.jar docs/04-database-diagrams/erd-identity.puml

# Render all
java -jar plantuml.jar docs/04-database-diagrams/*.puml

# Syntax check only (no image output)
plantuml -checkonly docs/04-database-diagrams/*.puml
```
