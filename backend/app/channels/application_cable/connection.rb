# frozen_string_literal: true

module ApplicationCable
  # Authenticates the WebSocket on `#connect` by reading the JWT from the query
  # string (`wss://…/cable?token=<jwt>`). Browsers can't set custom headers on
  # `new WebSocket(url)`, and ADR-011 auth is stateless JWT (no Devise cookie
  # session), so the token can't ride the `Authorization` header the way the
  # REST API does — it travels as `?token=<jwt>` and is filtered from logs via
  # `config.filter_parameters << :token`.
  #
  # `Warden::JWTAuth::UserDecoder` is the same decoder the REST `Bearer`
  # strategy uses: it verifies the signature + expiration, checks the scope, and
  # runs the configured revocation strategy (the User model's JTIMatcher). Every
  # failure mode — missing, malformed, expired, wrong-scope, nil-user, revoked —
  # subclasses `JWT::DecodeError`, so a single rescue rejects them all.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      reject_unauthorized_connection if token.blank?

      Warden::JWTAuth::UserDecoder.new.call(token, :user, nil)
    rescue JWT::DecodeError
      reject_unauthorized_connection
    end
  end
end
