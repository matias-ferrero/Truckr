# frozen_string_literal: true

# Test helpers for JWT-authenticated request specs (ADR-011). Mints a token
# for an existing User via Warden::JWTAuth and exposes a header-builder for
# Authorization: Bearer transport.
module JwtHelpers
  def jwt_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end
end

RSpec.configure do |config|
  config.include JwtHelpers, type: :request
end
