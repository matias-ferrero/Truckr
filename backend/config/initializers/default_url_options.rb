# frozen_string_literal: true

# Rails.application.routes.url_helpers needs a host to generate absolute URLs
# when called outside a request context (e.g. ActiveStorage URLs in serializers).
# config.action_controller.default_url_options only applies inside controllers;
# this sets the fallback that url_helpers reads from models and resources.
Rails.application.config.after_initialize do
  host = ENV.fetch("APP_HOST", "localhost")
  port = ENV.fetch("PORT", "3000").to_i
  Rails.application.routes.default_url_options = { host: host, port: port }
end
