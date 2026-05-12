# frozen_string_literal: true

module Api
  # Devise's default FailureApp issues HTML redirects on auth failure, which
  # is wrong for a JSON API. This subclass emits the unified error envelope
  # used across the rest of the API (`{ error: { code, message } }`) with a
  # 401 status code — for invalid login credentials, missing/expired/revoked
  # JWTs, and anonymous access to protected endpoints. ADR-011.
  class DeviseFailureApp < Devise::FailureApp
    def respond
      # Other Devise scopes (e.g. ActiveAdmin's :admin_user) still want the
      # default HTML redirect-to-sign-in behaviour. Only the :user scope —
      # our JSON API — gets the envelope.
      return super unless scope == :user

      self.status = 401
      self.content_type = "application/json"
      code = login_failure? ? "invalid_credentials" : "unauthorized"
      self.response_body = {
        error: {
          code: code,
          message: I18n.t("errors.#{code}")
        }
      }.to_json
    end

    private

    # Distinguishes "bad credentials at login" from "no/invalid JWT on a
    # protected endpoint" by reading Warden's failure reason:
    # - :invalid / :not_found_in_database → wrong password / unknown email
    # - :unauthenticated → missing or invalid JWT
    def login_failure?
      %i[invalid not_found_in_database].include?(warden_message)
    end
  end
end
