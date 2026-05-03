# External Systems

Integrations the platform uses today, and the ones on the roadmap. Each row notes status so a reader can tell implemented from planned at a glance.

## Runtime Integrations

### GitHub (active)

- **Purpose**: source-of-truth repo, CI host, release artifact store.
- **Interface**:
  - Push to `main` → `release-please` Action opens/updates Release PR.
  - Merge Release PR → tag `vX.Y.Z` + GitHub Release; `softprops/action-gh-release@v2` attaches `artifacts.pdf` and `prompts.pdf`.
- **Config**: `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json`.
- **Secrets**: uses the default `GITHUB_TOKEN`.

### Payment gateway (planned)

- **Candidates**: Mercado Pago (primary — local market fit), Stripe (fallback).
- **Purpose**: charge clientes, hold funds in escrow, release to transportista on delivery.
- **Integration style**: server-initiated charges via REST + webhook callbacks for status updates.
- **Where it will live**: `Api::PaymentsController` + `PaymentSettlementJob` (solid_queue).

### ARCA — Argentine tax authority (planned)

- **Purpose**: emit electronic invoices (Factura A/B/C) on shipment settlement; retrieve CAE (authorisation code).
- **Interface**: SOAP + WSAA token auth. Usually accessed via a wrapper gem (e.g. `afip.rb` or newer `arca.rb`).
- **Trigger**: settled `Shipment` enqueues `InvoiceEmissionJob`.

### Insurance provider (planned)

- **Purpose**: per-shipment quote + bind of cargo insurance.
- **Integration style**: REST; quote on cargo publication, bind on shipment acceptance.

### Maps / GPS provider (planned)

- **Purpose**: geocoding, route planning, optional live vehicle tracking.
- **Candidates**: Google Maps Platform, HERE, or self-hosted OSRM.
- **Trigger**: `CargoOffer` creation geocodes addresses; `Shipment` creation plans the route; in-transit telemetry ingested via webhook → `TrackingEvent`.

## Build-time Integrations

### mise registry (active)

- **Purpose**: version pinning for `gh`, `typst`, `uv`, `prek`, `typstyle`, `just`.
- **Config**: `mise.toml`.
- **Install**: `mise install`.

### npm / JSR via Deno (active)

- **Purpose**: frontend dependencies resolved via `deno.json` `imports` (npm specifiers).
- **Cache**: `frontend/node_modules` is materialised automatically by Deno (`nodeModulesDir: "auto"`).

### Ruby gems (active)

- **Purpose**: backend dependencies.
- **Config**: `backend/Gemfile` + `backend/Gemfile.lock`.

## Developer Integrations

### VS Code + Tinymist (optional)

- **Purpose**: live preview of `.typ` files during doc editing.
- **Setup**: install the Tinymist extension; open any `.typ` file.

### prek (pre-commit) (active)

- **Purpose**: local enforcement of formatting.
- **Hooks configured**: `typstyle` (formats `.typ` files).
- **Install**: `prek install`.

### Claude / Claude Code (active, dev-time only)

- **Purpose**: AI pair-programming for product, code, and design work. **Not** a runtime dependency — no Anthropic API call is made by the deployed app.
- **Interface**: CLAUDE.md + `.agents/skills/` + `frontend/.agents/skills/` are loaded into each Claude session via convention.
- **GitHub Projects sync**: `.gdsi-sdlc/automation/scripts/` push issue state changes to the project board (`project_number: 7`) using `gh`.
- **Reference**: full inventory in `05-appendices/ai-harness.md`.
