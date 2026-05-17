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
  # - `update_me`: patches the modifiable subset of the current user's
  #   personal data (name, email, phone). Email changes reset
  #   `verified_at` until US22 (email re-verification) lands.
  #
  # Sessions (login/logout) are handled by Api::SessionsController, which
  # inherits from Devise::SessionsController and is wrapped by devise-jwt.
  # See ADR-011.
  class AuthController < BaseController
    # Auth endpoints predate Pundit; no policies apply here.
    skip_after_action :verify_authorized, raise: false
    skip_after_action :verify_policy_scoped, raise: false

    before_action :authenticate_user!, only: %i[me update_me]

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

    # PATCH /api/auth/me
    # body: { name?, email?, phone? }
    #
    # Modifiable subset of the User AR record. Role-bearing relations
    # (carrier/shipper) and credentials (password, jti) are out of scope —
    # password rotation lives behind a dedicated endpoint when US22 lands,
    # and the carrier vehicle data is owned by REQ-BE-00009. Changing the
    # email invalidates `verified_at`: the new address has not been proven
    # to belong to the user, so the verified state must reset until the
    # re-verification flow (US22) is wired.
    def update_me
      changing_email = update_me_params.key?(:email) &&
        update_me_params[:email].to_s.strip.downcase != current_user.email

      current_user.assign_attributes(update_me_params)
      current_user.verified_at = nil if changing_email

      if current_user.save
        render json: MeResource.new(current_user).serialize
      else
        render json: { error: { code: "unprocessable", details: current_user.errors.as_json } },
               status: :unprocessable_entity
      end
    end

    private

    def update_me_params
      # `name` is the wire alias for the AR column `full_name` — mirrors
      # the register endpoint so the frontend doesn't have to remember two
      # different field names for the same concept.
      raw = params.permit(:name, :email, :phone)
      raw[:full_name] = raw.delete(:name) if raw.key?(:name)
      raw
    end

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
