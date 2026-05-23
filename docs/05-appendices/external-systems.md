# External Systems

Integrations the platform uses today, and the ones on the roadmap. Each row notes status so a reader can tell implemented from planned at a glance.

## Runtime Integrations

### AWS (active — staging)

- **Purpose**: hosts the deployed staging environment.
- **Services used**:
  - **EC2 + EIP** — single `t3.micro` instance running Docker; EIP keeps the sslip.io hostname stable for Let's Encrypt cert renewals.
  - **ECR** — `truckr-backend` image registry; Kamal pushes from operator laptop, EC2 pulls via Kamal-injected `docker login`.
  - **S3 + CloudFront** — frontend bundle hosted in a private S3 bucket fronted by CloudFront with Origin Access Control.
  - **SSM Parameter Store** — source-of-truth for `RAILS_MASTER_KEY` (under `/truckr/staging/*`); fetched at deploy time by `backend/.kamal/secrets`.
  - **DLM (Data Lifecycle Manager)** — daily EBS snapshots of the SQLite volume; 7-day retention.
  - **IAM** — least-privilege EC2 role (`AmazonSSMManagedInstanceCore` only); GitHub OIDC role for future CI deploys (INF-INFRA-00004).
  - **S3 + DynamoDB (state backend)** — `truckr-tfstate-${account_id}` bucket + lock table for Terraform remote state.
- **Provisioning**: `infra/envs/staging/` (Terraform). First-bootstrap in [`infra/README.md`](../../infra/README.md); day-2 ops in [`deployment-runbook.md`](deployment-runbook.md).
- **TLS**: kamal-proxy + Let's Encrypt on `<eip>.sslip.io` (auto-renew).

### GitHub (active)

- **Purpose**: source-of-truth repo, CI host, release artifact store.
- **Interface**:
  - Push to `main` → `release-please` Action opens/updates Release PR.
  - Merge Release PR → tag `vX.Y.Z` + GitHub Release; `softprops/action-gh-release@v2` attaches `artifacts.pdf` and `prompts.pdf`.
- **Config**: `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json`.
- **Secrets**: uses the default `GITHUB_TOKEN`.

### Payment gateway

- **MVP**: `Payments::FakeGateway` (in-tree, deterministic, always-on including in production). It IS the payment gateway for the MVP — see ADR-012.
- **Post-MVP candidates**: Mercado Pago (primary — local market fit), Stripe (fallback). When introduced, they implement the same `Payments::Gateway` Ruby interface — no domain-model change.
- **Purpose**: charge expedidores at the moment they accept the Carrier's offer; unlock the Carrier's contact info and the Shipment's pickup readiness once payment succeeds.
- **Integration style (MVP)**: in-process `confirm!` on the fake gateway. Return-URL flow (`GET /api/payments/:id/return?outcome=...`) — no webhooks.
- **Integration style (post-MVP)**: server-initiated charges via REST + signed webhook callbacks.
- **Where it lives**: `Api::Shipments::PaymentsController` + `Api::PaymentsController` (return / abandon actions); `app/services/payments/` for the gateway interface and adapters.
- **Escrow semantics (MVP)**: `Payment.status = escrowed` is terminal. There is no settlement job; no `released` transition. A real-gateway integration would re-introduce both.

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
