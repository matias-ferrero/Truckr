# frozen_string_literal: true

module Api
  # Custom auth endpoints that don't fit Devise's controller flow cleanly:
  #
  # - `register`: creates a User + attaches a Carrier or Shipper profile in
  #   a single transaction. Devise's RegistrationsController doesn't model
  #   this role-attach side effect, so we keep it hand-rolled. `sign_in` at
  #   the end fires the devise-jwt dispatcher, which injects
  #   `Authorization: Bearer <jwt>` into the response.
  # - `me`: returns the current authenticated user (with carrier/shipper
  #   rows) — read-only convenience for the SPA.
  #
  # Sessions (login/logout) are handled by Api::SessionsController, which
  # inherits from Devise::SessionsController and is wrapped by devise-jwt.
  # See ADR-011.
  class AuthController < BaseController
    # Auth endpoints predate Pundit; no policies apply here.
    skip_after_action :verify_authorized, raise: false
    skip_after_action :verify_policy_scoped, raise: false

    before_action :authenticate_user!, only: :me

    # POST /api/auth/register
    # body: { email, password, name, role: "carrier"|"shipper" }
    #
    # `:role` is read directly from params (not strong-permitted) because it's
    # a control flag — never assigned to the User AR record. Strong params on
    # it would only earn a brakeman PermitAttributes false-positive.
    def register
      role = params[:role].to_s
      unless %w[carrier shipper].include?(role)
        return render json: {
          error: { code: "unprocessable", details: { role: [ "es inválido" ] } }
        }, status: :unprocessable_entity
      end

      user = nil
      ActiveRecord::Base.transaction do
        user = User.create!(
          email: register_params[:email],
          password: register_params[:password],
          full_name: register_params[:name]
        )
        attach_role!(user, role)
      end
      sign_in(user)
      render json: MeResource.new(user).serialize, status: :created
    end

    # GET /api/auth/me
    def me
      render json: MeResource.new(current_user).serialize
    end

    private

    def register_params
      params.permit(:email, :password, :name)
    end

    def attach_role!(user, role)
      case role
      when "carrier" then user.create_carrier!
      when "shipper" then user.create_shipper!
      end
    end
  end
end
