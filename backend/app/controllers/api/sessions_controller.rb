# frozen_string_literal: true

module Api
  # Sessions via Devise + devise-jwt (ADR-011). Authentication, sign_in,
  # sign_out, and JWT dispatch/revocation are all library code — this
  # subclass only adapts the JSON response shape and forces a 401 on
  # anonymous logout. Wire contract follows Devise convention:
  # `POST /api/auth/login` with body `{ "user": { "email", "password" } }`.
  class SessionsController < Devise::SessionsController
    respond_to :json

    # Devise's `verify_signed_out_user` halts destroy when no session-based
    # user exists — and our stateless JWT setup never populates the session,
    # so this filter always halts with 401. The JWT-bearing user is found
    # via `authenticate_user!` instead.
    skip_before_action :verify_signed_out_user, raise: false

    # Anonymous logout (no/invalid JWT) returns 401 via FailureApp instead
    # of Devise's silent 204. `authenticate_user!` is a no-op inside a
    # devise_controller unless `force: true`, so go through warden directly.
    before_action :require_jwt_user!, only: :destroy

    private

    # On create (sign-in success), Devise calls `respond_with(resource)`.
    # Render the same `Me` JSON shape that `/api/auth/me` returns so
    # clients have one schema. devise-jwt's middleware injects the
    # `Authorization: Bearer <jwt>` header on the response after sign_in.
    def respond_with(resource, _opts = {})
      render json: MeResource.new(resource).serialize, status: :ok
    end

    # Lock the API contract to 204 on logout regardless of the request's
    # Accept header. Devise's default branches into a 303 redirect for
    # navigational formats.
    def respond_to_on_destroy(**)
      head :no_content
    end

    def require_jwt_user!
      warden.authenticate!(scope: :user)
    end
  end
end
