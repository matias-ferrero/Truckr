#import "@preview/cmarker:0.1.8"

= Implement Haversine algorithm in matching

_2026-05-26 01:42 UTC — rama `chore/just-review-worktree` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc844-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  We're working on .claude/worktrees/gmaps-fulfilment

  The matching algorithm that's used in the frontend is not using Haversine yet, implement it
  ```,
  h1-level: 4,
  label-prefix: "cc845-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now update the spec assertion to also check origin_lat/lng are present:
  ```,
  h1-level: 4,
  label-prefix: "cc846-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now update the type, the content (i18n), and the components.
  ```,
  h1-level: 4,
  label-prefix: "cc847-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now update MatchCard to accept the cargo pickup point and render distance:
  ```,
  h1-level: 4,
  label-prefix: "cc848-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now wire pickup coords from CargoMatches into MatchCard:
  ```,
  h1-level: 4,
  label-prefix: "cc849-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Add a test for MatchCard distance rendering. CABA cargo pickup vs La Plata origin ~56km:
  ```,
  h1-level: 4,
  label-prefix: "cc850-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Run the frontend tests to verify:
  ```,
  h1-level: 4,
  label-prefix: "cc851-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All 298 frontend tests pass.
  ```,
  h1-level: 4,
  label-prefix: "cc852-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now run the backend spec for the cargos endpoint to verify the resource change:
  ```,
  h1-level: 4,
  label-prefix: "cc853-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All 22 cargos specs pass.

  Summary of changes (worktree `.claude/worktrees/gmaps-fulfilment`, branch `gmaps-fulfilment`):

  **Backend**
  - `backend/app/resources/cargo_match_resource.rb` — expose `origin_lat`, `origin_lng`; replace the "deferred to GMaps" note with rationale for client-side Haversine.
  - `backend/spec/requests/api/cargos_spec.rb` — assert the new lat/lng keys are present in the matches payload.

  **Frontend**
  - `frontend/src/lib/geo.ts` (new) — `haversineKm({lat,lng}, {lat,lng})`, mirrors `Truckr::Geo`.
  - `frontend/src/lib/geo.test.ts` (new) — 4 cases: identity, symmetry, CABA↔La Plata, CABA↔Salta.
  - `frontend/src/types/Cargo.ts` — `CargoMatch` gains `origin_lat: string`, `origin_lng: string`; comment updated.
  - `frontend/src/features/cargo/cargosContent.ts` — adds `match.distanceKm(km)` Spanish label.
  - `frontend/src/features/cargo/MatchCard.tsx` — accepts optional `pickup` prop, computes Haversine vs `match.origin_*`, renders distance line.
  - `frontend/src/features/cargo/CargoMatches.tsx` — passes the cargo's `pickup_lat`/`pickup_lng` to each `MatchCard`.
  - `MatchCard.test.tsx`, `CargoMatches.test.tsx`, `CreateOfferPage.test.tsx` fixtures gain `origin_lat`/`origin_lng`; two new MatchCard tests cover rendered distance + hidden-when-no-pickup.

  **Verified**
  - `deno task test:run` — 298/298 passing.
  - `bundle exec rspec spec/requests/api/cargos_spec.rb` — 22/22 passing.
  ```,
  h1-level: 4,
  label-prefix: "cc854-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  22:51:18 web.1  | Started GET "/api/cargos/3/matches?page=1" for 127.0.0.1 at 2026-05-25 22:51:18 -0300
  22:51:18 web.1  | Processing by Api::CargosController#matches as JSON
  22:51:18 web.1  |   Parameters: {"page" => "1", "id" => "3"}
  22:51:18 web.1  |   User Load (0.1ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 2 LIMIT 1 /*action='matches',application='Trukr',controller='cargos'*/
  22:51:18 web.1  |   ↳ app/controllers/api/base_controller.rb:41:in 'Api::BaseController#authenticate_user!'
  22:51:18 web.1  |   Shipper Load (0.1ms)  SELECT "shippers".* FROM "shippers" WHERE "shippers"."user_id" = 2 LIMIT 1 /*action='matches',application='Trukr',controller='cargos'*/
  22:51:18 web.1  |   ↳ app/controllers/api/base_controller.rb:38:in 'Api::BaseController#current_shipper'
  22:51:18 web.1  |   Cargo Load (0.2ms)  SELECT "cargos".* FROM "cargos" WHERE "cargos"."id" = 3 LIMIT 1 /*action='matches',application='Trukr',controller='cargos'*/
  22:51:18 web.1  |   ↳ app/controllers/api/cargos_controller.rb:76:in 'Api::CargosController#set_cargo'
  22:51:18 web.1  |   TransportWindow Load (0.2ms)  SELECT DISTINCT "transport_windows"."id", "transport_windows"."origin_lat", "transport_windows"."origin_lng", "transport_windows"."pickup_radius_km" FROM "transport_windows" INNER JOIN "vehicles" ON "vehicles"."id" = "transport_windows"."vehicle_id" WHERE "transport_windows"."active" = TRUE AND "transport_windows"."id" NOT IN (SELECT "cargo_offers"."transport_window_id" FROM "cargo_offers" WHERE "cargo_offers"."status" IN ('pending', 'accepted')) AND ("transport_windows"."origin_province_normalized" LIKE '%ciudad autonoma de buenos aires%' AND "transport_windows"."destination_province_normalized" LIKE '%buenos aires%' AND "transport_windows"."available_from" <= '2026-06-05 23:59:00' AND "transport_windows"."available_to" >= '2026-06-02 00:00:00' OR ("transport_windows"."origin_province_normalized" LIKE '%ciudad autonoma de buenos aires%' AND "transport_windows"."available_from" <= '2026-06-05 23:59:00' AND "transport_windows"."available_to" >= '2026-06-02 00:00:00') AND "transport_windows"."destination_province_normalized" IS NULL) AND (vehicles.max_load_kg >= 123.0) /*action='matches',application='Trukr',controller='cargos'*/
  ```,
  h1-level: 4,
  label-prefix: "cc855-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  That log just shows the matches endpoint running its pickup-radius pre-select (the `within_pickup_radius_of` scope at `transport_window.rb:62-71`) — that's existing behavior, unchanged by this work. The new `origin_lat`/`origin_lng` keys ship with each item in the JSON response, and the FE now reads them through `MatchCard` to compute Haversine vs `cargo.pickup_lat`/`pickup_lng`.

  If you want to confirm the response shape end-to-end without booting Playwright, hit it once with the JWT:

  ```sh
  curl -s -H "Authorization: Bearer $JWT" http://localhost:3000/api/cargos/3/matches?page=1 | jq '.[0] | {id, origin_lat, origin_lng}'
  ```

  You should see `origin_lat` / `origin_lng` populated. Anything else you want me to check or adjust?
  ````,
  h1-level: 4,
  label-prefix: "cc856-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  commit this
  ```,
  h1-level: 4,
  label-prefix: "cc857-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Committed as `9767715` on `feature/gmaps-fulfilment`, hooks clean.
  ```,
  h1-level: 4,
  label-prefix: "cc858-",
)
