# Scheduled & Background Jobs

## Current State

- **Queue adapter**: `solid_queue` (DB-backed, ships with Rails 8). Enabled via the gem in `backend/Gemfile`; production DB split defined in `backend/config/database.yml` under the `queue:` entry.
- **Jobs defined**: none. `backend/app/jobs/` contains only `application_job.rb` (the base class).
- **Worker process**: not wired up in CI/CD or Kamal config yet. When needed, run separately from the web process (e.g. `bundle exec rake solid_queue:start` or a dedicated entrypoint in Kamal).

## Conventions (for when jobs arrive)

- Inherit from `ApplicationJob`.
- Name with the `Job` suffix (`TrackingIngestJob`, `InvoiceEmissionJob`).
- Keep jobs idempotent — solid_queue retries on failure.
- Pass record IDs, not AR objects, in `perform` arguments.
- Log with `Rails.logger.tagged("job:job_name")` for grep-ability.

## Planned Jobs

| Job | Trigger | Purpose |
|-----|---------|---------|
| `TrackingIngestJob` | Incoming webhook from GPS provider | Parse payload → append `TrackingEvent`. |
| `InvoiceEmissionJob` | Shipment transitions to `settled` | Call ARCA, persist CAE on `ArcaInvoice`. |
| `NotificationEmailJob` | Key lifecycle events | Transactional email via Action Mailer. |
| `MatchExpiryJob` | Cron | Expire open `TransportWindow` / `CargoOffer` / `Quote` past their validity. |

Cron-style recurring jobs will use solid_queue's built-in recurring task support when introduced.
