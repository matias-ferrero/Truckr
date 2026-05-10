# frozen_string_literal: true

# Allow the frontend (Vite dev server) to call /api/* with credentials so
# that cookie-based session auth + CSRF tokens flow correctly cross-origin.
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
             credentials: true,
             expose: %w[X-CSRF-Token]
  end
end
