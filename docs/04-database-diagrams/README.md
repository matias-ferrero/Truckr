# Database Diagrams

**Status**: the backend currently has **no migrations and no domain tables**. `backend/db/` contains only a placeholder `seeds.rb`; there is no `schema.rb` or `structure.sql` yet. The landing-page response is built from a hardcoded Ruby hash.

The ERDs in this folder therefore describe the **planned** data model, derived from the product artifacts under `docs/artifacts/` (product vision, personas, USM, backlog). Treat them as a design target; they will be refined once the first migrations land.

## Files

| File | Domain | Status |
|------|--------|--------|
| `erd-identity.puml` | Users, transportistas, clientes, vehicles | Planned |
| `erd-marketplace.puml` | Transport windows, cargo offers, quotes | Planned |
| `erd-fulfilment.puml` | Shipments, tracking events, routes | Planned |
| `erd-commerce.puml` | Payments, insurance, ARCA invoicing | Planned |

## Conventions

- Primary keys: `id : bigint` (Rails default).
- Foreign keys: `{entity}_id : bigint` with a `<<FK>>` marker.
- Timestamps (`created_at`, `updated_at`) are assumed on every table and omitted for readability.
- Required fields are prefixed with `*`.
- Enum columns use Rails `enum` — values shown in the notes below each diagram.

## Rendering

```sh
# Render a single diagram
java -jar plantuml.jar docs/04-database-diagrams/erd-identity.puml

# Render all
java -jar plantuml.jar docs/04-database-diagrams/*.puml
```
