# API Overview

The backend exposes **no domain JSON endpoints yet** — only the Rails health check and the ActiveAdmin admin UI. The landing page is a static React module (`frontend/src/landingContent.ts`) and never hits the API. This appendix records the conventions every future endpoint is expected to follow.

## Base URL

- **Development**: `http://localhost:3000`
- **Production**: TBD (depends on deploy target; Kamal config not yet committed).
- **Frontend env var**: `VITE_API_BASE_URL` — falls back to `http://localhost:3000` if unset.

## Conventions

- All endpoints live under the `/api/` namespace. `/up` is reserved for the Rails health check; do not add business endpoints there.
- Content type: `application/json; charset=utf-8` on requests and responses.
- JSON key style: **snake_case**, matching Ruby conventions. The frontend reads snake_case keys directly — there is no camelCase serializer.
- Errors: no shared envelope yet. **Recommended** shape when introduced:
  ```json
  { "error": { "code": "validation_failed", "message": "Human-readable", "details": { "field": ["too_short"] } } }
  ```
- Versioning: none yet. When the first breaking change ships, move to `/api/v1/...`.
- Auth: none yet. All endpoints are public.

## Live Routes

### `GET /up`

Rails health check — returns `200` when the app boots cleanly. Reserved for load-balancer probes; do not add business logic.

### `/admin/*`

ActiveAdmin admin UI (Devise-protected). Not part of the public API surface; intended for internal/back-office use.

## Landing Page (frontend-only)

The public landing page is a static React module: `frontend/src/App.tsx` reads from `frontend/src/landingContent.ts` (hero copy, features, stats, brand `color_palette`). There is no `GET /api/landing_pages` endpoint and none is planned — content edits go directly into `landingContent.ts`.

## Planned Endpoints

Drawn from the product backlog (`docs/artifacts/backlog-us.typ`). Names are indicative; the real shape will be finalised when each story is implemented.

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/sessions` | Sign in, issue token / session. |
| DELETE | `/api/sessions` | Sign out. |
| POST | `/api/users` | Register a new transportista or expedidor. |
| GET | `/api/users/me` | Current user profile. |
| GET, POST | `/api/transport_windows` | List/create transportista availability. |
| GET, PATCH, DELETE | `/api/transport_windows/:id` | Show/update/cancel. |
| GET, POST | `/api/cargos` | List/create Shipper Cargo publications (US27). |
| POST | `/api/cargos/:id/offers` | Shipper authors a CargoOffer against a TransportWindow (US7). |
| GET | `/api/carriers/me/cargo-offers` | Carrier inbox — CargoOffers received. |
| POST | `/api/carriers/me/cargo-offers/:id/accept` | Carrier accepts a CargoOffer → creates a Shipment; cascades sibling-reject and flips the TransportWindow (REQ-BE-00024). |
| GET, POST | `/api/shipments` | List/show active shipments. |
| POST | `/api/shipments/:id/tracking_events` | Append tracking event (transportista or provider webhook). |
| POST | `/api/payments` | Initiate charge on quote acceptance. |
| POST | `/api/payments/webhook` | Gateway webhook (status updates). |

## CORS

Configured in `backend/config/initializers/cors.rb`. Currently allows the following origins for any verb/header:

- `localhost`
- `127.0.0.1`
- `localhost:3000`
- `localhost:5173` (Vite dev server)

**Before any production deploy**, narrow this to the real production frontend origin(s) and constrain methods to what the endpoints need.
