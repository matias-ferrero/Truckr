# API Overview

The backend exposes a single JSON endpoint today. This appendix documents the current shape and records the conventions every future endpoint is expected to follow.

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

## Endpoints

### `GET /api/landing_pages`

Returns the content of the public landing page. The response is built in-process from a hardcoded hash — there is no database row backing it today.

**Request**

```
GET /api/landing_pages
Accept: application/json
```

**Response 200**

```json
{
  "hero": {
    "title": "Truckr®",
    "subtitle": "Conectando transportistas independientes con clientes",
    "description": "La plataforma de servicios de transporte que une oferta y demanda",
    "cta_primary": "Comenzar",
    "cta_secondary": "Más información"
  },
  "features": [
    { "id": 1, "title": "Para Transportistas", "description": "...", "icon": "truck" },
    { "id": 2, "title": "Para Clientes",       "description": "...", "icon": "package" },
    { "id": 3, "title": "Seguro y Confiable",  "description": "...", "icon": "shield" }
  ],
  "color_palette": {
    "primary":   "#bee4fa",
    "secondary": "#f1e3aa",
    "tertiary":  "#b4b4b4",
    "error":     "#ff9999",
    "neutral":   "#ffffff"
  },
  "stats": [
    { "label": "Transportistas Activos", "value": "500+" },
    { "label": "Clientes Satisfechos",   "value": "1000+" },
    { "label": "Envíos Completados",     "value": "5000+" }
  ]
}
```

**Known constraint**: `features[*].icon` is validated by the frontend to one of `"truck" | "package" | "shield"`; unknown values render a fallback glyph. Keep this enum in sync when extending.

### `GET /up`

Rails health check — returns `200` when the app boots cleanly. Reserved for load-balancer probes; do not add business logic.

## Planned Endpoints

Drawn from the product backlog (`docs/artifacts/backlog-us.typ`). Names are indicative; the real shape will be finalised when each story is implemented.

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/sessions` | Sign in, issue token / session. |
| DELETE | `/api/sessions` | Sign out. |
| POST | `/api/users` | Register a new transportista or cliente. |
| GET | `/api/users/me` | Current user profile. |
| GET, POST | `/api/transport_windows` | List/create transportista availability. |
| GET, PATCH, DELETE | `/api/transport_windows/:id` | Show/update/cancel. |
| GET, POST | `/api/cargo_offers` | List/create cliente cargo. |
| GET, POST | `/api/quotes` | List/send quotes. |
| POST | `/api/quotes/:id/accept` | Cliente accepts a quote → creates a Shipment. |
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
