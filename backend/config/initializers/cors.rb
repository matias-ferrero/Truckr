# frozen_string_literal: true

# Allow the frontend (Vite dev/preview) to call /api/* cross-origin.
# Auth is via Bearer JWT (ADR-011) — `Authorization` must be exposed so
# the SPA can capture the dispatched token from login/register responses.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # FRONTEND_ORIGIN may be a comma-separated list. Defaults cover both
    # `localhost` and `127.0.0.1` since browsers treat them as distinct
    # origins for the same loopback address.
    default_origins = "http://localhost:5173,http://127.0.0.1:5173," \
                      "http://localhost:4173,http://127.0.0.1:4173"
    origins(*ENV.fetch("FRONTEND_ORIGIN", default_origins).split(",").map(&:strip))

    resource "/api/*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[Authorization X-Total X-Page X-Per-Page X-Total-Pages]
  end
end
