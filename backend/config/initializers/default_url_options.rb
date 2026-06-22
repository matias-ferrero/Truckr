# frozen_string_literal: true

# Rails.application.routes.url_helpers needs a host to generate absolute URLs
# when called outside a request context (e.g. ActiveStorage URLs in serializers).
# config.action_controller.default_url_options only applies inside controllers;
# this sets the fallback that url_helpers reads from models and resources.
Rails.application.config.after_initialize do
  host = ENV.fetch("APP_HOST", "localhost")
  # Scheme follows force_ssl (true in production.rb, false in dev/test) so we
  # don't carry a separate protocol env var. Behind kamal-proxy the request is
  # plain HTTP but assume_ssl/force_ssl present it as HTTPS.
  protocol = Rails.application.config.force_ssl ? "https" : "http"

  options = { host: host, protocol: protocol }

  # Local dev runs Rails directly on :3000; deployed envs sit behind the proxy
  # on the scheme's standard port (443), which must be omitted to keep URLs
  # canonical (https://host, never https://host:443). APP_PORT overrides when a
  # non-standard port is genuinely needed.
  port = ENV.fetch("APP_PORT", host == "localhost" ? "3000" : nil)
  standard_port = protocol == "https" ? "443" : "80"
  options[:port] = port.to_i if port.present? && port.to_s != standard_port

  Rails.application.routes.default_url_options = options
end
