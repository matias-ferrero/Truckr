# frozen_string_literal: true

# Rate-limit login attempts: 5 per 15 minutes per IP. Backed by Rails.cache —
# in production this is Solid Cache; in dev it's the in-memory cache (must be
# enabled with `bin/rails dev:cache`); in test we override the cache store
# locally so the throttle is observable.
class Rack::Attack
  throttle("login/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/api/auth/login" && req.post?
  end

  self.throttled_responder = lambda do |_env|
    [
      429,
      { "content-type" => "application/json" },
      [{ error: { code: "rate_limited", message: "Demasiados intentos. Intentá en 15 minutos." } }.to_json]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack
