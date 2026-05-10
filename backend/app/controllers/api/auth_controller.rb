# frozen_string_literal: true

module Api
  # Auth endpoints — register, login, logout, me, csrf.
  #
  # We deliberately ship our own controller instead of subclassing
  # Devise::SessionsController/RegistrationsController: those defaults are
  # too HTML-centric for the JSON contract the FE expects.
  class AuthController < BaseController
    skip_before_action :verify_authenticity_token, only: :csrf
    before_action :authenticate_user!, only: :me

    # GET /api/auth/csrf — bootstraps a session and returns the CSRF token.
    # Skipped from forgery check (chicken-and-egg).
    def csrf
      render json: { csrf_token: form_authenticity_token }
    end

    # POST /api/auth/register
    # body: { email, password, name, role: "carrier"|"shipper"|"both" }
    #
    # `:role` is read directly from params (not strong-permitted) because it's a
    # control flag — never assigned to the User AR record. Strong params on it
    # would only earn a brakeman PermitAttributes false-positive.
    def register
      role = params[:role].to_s
      unless %w[carrier shipper both].include?(role)
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

    # POST /api/auth/login — body: { email, password }
    def login
      user = User.find_for_authentication(email: login_params[:email].to_s.downcase.strip)

      if user&.valid_password?(login_params[:password])
        sign_in(user)
        render json: MeResource.new(user).serialize
      else
        render json: { error: { code: "invalid_credentials", message: "Email o contraseña inválidos" } },
               status: :unauthorized
      end
    end

    # DELETE /api/auth/logout
    def logout
      sign_out(current_user) if current_user
      reset_session
      head :no_content
    end

    # GET /api/auth/me
    def me
      render json: MeResource.new(current_user).serialize
    end

    private

    def register_params
      params.permit(:email, :password, :name)
    end

    def login_params
      params.permit(:email, :password)
    end

    def attach_role!(user, role)
      case role
      when "carrier" then user.create_carrier!
      when "shipper" then user.create_shipper!
      when "both"
        user.create_carrier!
        user.create_shipper!
      end
    end
  end
end
