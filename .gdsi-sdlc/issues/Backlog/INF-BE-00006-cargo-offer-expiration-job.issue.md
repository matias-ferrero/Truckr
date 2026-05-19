---
tag: INF-BE-00006
title: CargoOfferExpirationJob — auto-expira `pending` a las 48 h y flipea Window
  a `open` (mismo tx)
priority: P2
status: backlog
created: '2026-05-19'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/196
author: Claude Code
github_issue: 196
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtNI9M
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-19T16:06:12.103834+00:00Z
labels:
- INF
- BE
- marketplace
- job
- solid-queue
---

## Summary

Job recurrente de Solid Queue que, cada cierto intervalo corto, identifica `CargoOffer`s en estado `pending` cuya `expires_at` ya pasó (48 h desde su creación) y las marca como `expired`, **flippeando en la misma transacción de DB el `TransportWindow` asociado de `pending_offer → open`** para que otros Shippers vean la Window reaparecer inmediatamente. Cierra el loop de la decisión bloqueada del 2026-05-19 sobre auto-flip de Windows.

## Problem Statement

El dominio renombrado del 2026-05-19 introduce dos lifecycles acoplados:

- `CargoOffer.status: pending` tiene TTL de 48 h. Si el Carrier no acepta ni rechaza, expira automáticamente.
- `TransportWindow.status: pending_offer` (Window-lock-on-Offer del MVP) tiene que volver a `open` cuando la Offer expira, **sin intervención manual del Carrier**, para que el Window quede otra vez visible al resto de los Shippers.

Sin este job, las Windows quedan en `pending_offer` indefinidamente cuando un Carrier nunca responde una Offer, bloqueando el inventario para otros Shippers. Es una garantía de **vida** del sistema de matching.

`domain-model.md` § 8 (jobs) ya referencia este job conceptualmente; esta issue lo aterriza en código.

## Expected Behavior

### Job

- Clase: `CargoOfferExpirationJob < ApplicationJob`.
- Queue: `default` (o `low` si el setup tiene split — alinear con `INF-BE-00005`).
- Lookup: `CargoOffer.where(status: :pending).where("expires_at <= ?", Time.current)`.
- Para cada offer:
  - Misma DB transaction:
    1. `offer.update!(status: :expired)`.
    2. `offer.transport_window.update!(status: :open)` solo si la Window estaba en `pending_offer` y la offer expirada es la que la tenía bloqueada. Si la Window ya cambió (race con otro accept/reject), no-op + log warning.
  - Hook opcional: emitir evento `cargo_offer.expired` (a definir con `INF-BE-00005` o el event-bus que termine usándose; out-of-scope estricto si todavía no existe).
- Idempotente: si una offer ya está `expired`, skip (no double-flip de Window).

### Scheduling

- Solid Queue `recurring` config: cada 5 minutos en prod, cada 1 minuto en dev/test (configurable via ENV `CARGO_OFFER_EXPIRATION_INTERVAL_MIN`).
- Documentado en `config/recurring.yml` (o el archivo que esté usando Solid Queue tras `INF-BE-00005`).
- Una sola instancia corriendo a la vez (Solid Queue locks por job class — confirmar setup).

### `expires_at` column

- `CargoOffer.expires_at` (datetime, NOT NULL) set on create a `created_at + 48.hours`.
- Indexar `(status, expires_at)` para que el scan del job sea cheap (B-tree compatible con SQLite per CLAUDE.md DB policy).
- Esta columna se agrega via migración en esta issue si `REF-BE-00002` no la trajo; coordinar con el plan.

### Configuración de TTL

- Constant: `CargoOffer::EXPIRATION_WINDOW = 48.hours` en el modelo. NO usar un ENV var para esto — es una decisión de producto fija (decisión bloqueada 2026-05-19).
- Si en el futuro se quiere acortar para tests, override en `spec_helper` con `stub_const`.

## Current Behavior

`CargoOffer` post-`REF-BE-00002` no tiene `expires_at` y no hay job recurrente que lo procese. Una Offer `pending` queda `pending` para siempre.

## Reproduction Steps

Post-`REF-BE-00002`:

1. Crear una `Cargo` + una `TransportWindow` matching.
2. Shipper autorea una `CargoOffer` contra la Window → Window queda en `pending_offer`.
3. Esperar 48 h sin Carrier action.
4. Observar que la Offer sigue `pending` y la Window sigue `pending_offer` indefinidamente → BUG / vida del sistema.

## Impact

**Quién**: indirecto pero crítico — Shippers (no ven Windows que deberían estar disponibles) y Carriers (no se les libera capacidad cuando perdieron una oportunidad).

**Cómo**: garantiza vida del matching. Sin este job, el sistema se vuelve un graveyard de Windows bloqueadas con cada Carrier inactivo. Es el complemento simétrico de los siguientes paths:

- Carrier acepta → Window `pending_offer → reserved` (parte de `REQ-BE-00024`).
- Carrier rechaza → Window `pending_offer → open` (parte de `REQ-BE-00024`).
- **48 h sin acción → Window `pending_offer → open` (esta issue).**

**Riesgos**:

- Race condition: si el job corre exactamente cuando un Carrier presiona accept/reject, podría doble-flippear la Window. Mitigación: el job usa `with_lock` sobre la offer y compara `transport_window.status` antes de update — si no es `pending_offer`, skip.
- Performance: con N offers `pending` y el job corriendo cada 5 min, esperamos N pequeño (MVP). Si crece, optimizar con scope batched.
- Solid Queue recurring deduplication: confirmar que el setup default de Rails 8 + Solid Queue no dispare múltiples instancias del mismo job en paralelo. Si lo hace, lock global vía advisory lock o table flag.

## Technical Notes

### Migración

```ruby
# db/migrate/<timestamp>_add_expires_at_to_cargo_offers.rb
add_column :cargo_offers, :expires_at, :datetime
add_index :cargo_offers, [:status, :expires_at]
# Backfill para registros existentes (si los hay): created_at + 48.hours
CargoOffer.where(expires_at: nil).find_each do |offer|
  offer.update_column(:expires_at, offer.created_at + 48.hours)
end
change_column_null :cargo_offers, :expires_at, false
```

Coordinar con `REF-BE-00002`: si la migración del rename ya incluye `expires_at`, esta issue solo trae el job (no la columna).

### Modelo

```ruby
# app/models/cargo_offer.rb
EXPIRATION_WINDOW = 48.hours

before_validation :set_expires_at, on: :create

private

def set_expires_at
  self.expires_at ||= Time.current + EXPIRATION_WINDOW
end
```

### Job

```ruby
# app/jobs/cargo_offer_expiration_job.rb
class CargoOfferExpirationJob < ApplicationJob
  queue_as :default

  def perform
    CargoOffer.where(status: :pending)
              .where("expires_at <= ?", Time.current)
              .find_each do |offer|
      ActiveRecord::Base.transaction do
        offer.lock!
        next unless offer.status == "pending"

        offer.update!(status: :expired)

        window = offer.transport_window
        if window.status == "pending_offer"
          window.update!(status: :open)
        else
          Rails.logger.warn(
            "[CargoOfferExpirationJob] Window #{window.id} not in pending_offer (#{window.status}); skipping flip"
          )
        end
      end
    end
  end
end
```

### Recurring config (Solid Queue)

```yaml
# config/recurring.yml
production:
  cargo_offer_expiration:
    class: CargoOfferExpirationJob
    schedule: every 5 minutes
development:
  cargo_offer_expiration:
    class: CargoOfferExpirationJob
    schedule: every 1 minute
```

(Confirmar formato real contra Solid Queue docs cuando se implemente.)

### Specs

- Job spec (`spec/jobs/cargo_offer_expiration_job_spec.rb`):
  - Offers `pending` con `expires_at` pasado → marcadas `expired` + Window `open`.
  - Offers `pending` con `expires_at` futuro → no-op.
  - Offers ya `expired` → no-op (idempotencia).
  - Window que ya cambió (`reserved` o `closed`) → offer `expired` pero Window no se toca; warning log.
  - Transacción rollback: si el Window update falla, la offer queda `pending` (no half-state).
- Model spec: `set_expires_at` callback corre on create.
- Travel time con `ActiveSupport::Testing::TimeHelpers#travel_to`.

### Observabilidad

- Job loggea conteo de offers procesadas por run (`INFO`).
- Métrica: tag-eable cuando aterrice un setup de métricas. Out-of-scope estricto para esta issue.

### Sequencing

Depende de:

1. **`REF-BE-00002`** — el modelo `CargoOffer` debe existir con la semántica nueva (bid).
2. **`INF-BE-00005`** — Solid Queue scaffolded.

No bloquea US27 (`REQ-BE-00032`) — esa issue puede mergear sin el job, solo es marginalmente broken en el TTL. Pero idealmente aterriza dentro del mismo sprint para cerrar el loop.

## Origin

Identificado durante la sesión de grilling del 2026-05-19 que bloqueó la decisión de Window auto-flip en expiración + mismo-tx. `domain-model.md` § 8 referencia el job pero no había issue creada — esta cierra el gap.

## Related

- Issue gemela conceptual: `REQ-BE-00024` (US12 — acceptance/rejection del Carrier; también flippea Window pero por path manual).
- Bloquea en: `REF-BE-00002` (modelo `CargoOffer` post-rename), `INF-BE-00005` (Solid Queue).
- Beneficia: `REQ-BE-00032` (US27), `REQ-FE-00015` (US7), `REQ-FE-00017` (US10), `REQ-BE-00024` (US12) — todos asumen que la Window se libera "sola" tras 48 h.
- Docs: `docs/02-high-level-design/domain-model.md` § 8 (job conventions).
- Docs: `docs/05-appendices/glossary.md` — `Oferta de carga`, `TransportWindow`.

## Acceptance Criteria

- [ ] `REF-BE-00002` mergeada (`CargoOffer` con semántica de bid existe).
- [ ] `INF-BE-00005` mergeada (Solid Queue scaffolded).
- [ ] Columna `cargo_offers.expires_at` (NOT NULL, indexada con `(status, expires_at)`) presente. Migración nueva (no editar las del 2026-05-09) si `REF-BE-00002` no la trajo.
- [ ] `CargoOffer::EXPIRATION_WINDOW = 48.hours` constant + callback `before_validation :set_expires_at, on: :create`.
- [ ] `CargoOfferExpirationJob` implementado, con tx que cubre offer `expired` + Window `open` juntos.
- [ ] Job es idempotente para offers ya `expired`.
- [ ] Job NO toca la Window si está en estado distinto de `pending_offer` (race-safe); loggea warning.
- [ ] Recurring config registra el job cada 5 min en prod (1 min en dev). Confirmar single-instance (Solid Queue lock).
- [ ] Specs cubren: happy path, future expires_at no-op, ya-expired no-op, Window in non-pending_offer state, transaction rollback en falla.
- [ ] `just backend-test` verde; cobertura mantiene o supera baseline.
- [ ] Brakeman + bundler-audit + rubocop verdes.
- [ ] PR title: `feat(marketplace): cargo offer expiration job (48h auto-expire + window flip)`. Body referencia `INF-BE-00006` y `Closes #N`.
