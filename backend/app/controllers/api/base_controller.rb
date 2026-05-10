# frozen_string_literal: true

module Api
  # Base controller for the JSON API.
  #
  # ApplicationController stays untouched (it must inherit from
  # ActionController::Base for ActiveAdmin to work). The API hangs off this
  # leaner ActionController::API stack — augmented with the bits we need:
  # cookies, CSRF, Devise helpers, Pundit, Pagy, and a uniform error envelope.
  class BaseController < ActionController::API
    include ActionController::Cookies
    include ActionController::RequestForgeryProtection
    include Devise::Controllers::Helpers
    include Pundit::Authorization
    include Pagy::Method

    # ActionController::API doesn't pick up the test-env
    # `config.action_controller.allow_forgery_protection = false` (that flag
    # only flips on ActionController::Base). Explicitly mirror it here so
    # request specs can POST without juggling tokens.
    self.allow_forgery_protection = false if Rails.env.test?

    protect_from_forgery with: :exception

    rescue_from Pundit::NotAuthorizedError, with: :forbidden
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
    rescue_from ActionController::ParameterMissing, with: :unprocessable_param

    after_action :pagy_response_headers

    # current_user comes from Devise::Controllers::Helpers.
    def current_carrier = current_user&.carrier
    def current_shipper = current_user&.shipper

    def authenticate_user!
      return if current_user

      render json: { error: { code: "unauthorized", message: "Autenticación requerida" } },
             status: :unauthorized
    end

    def require_carrier!
      return if current_carrier

      render json: { error: { code: "forbidden", message: "Carrier role required" } },
             status: :forbidden
    end

    private

    def pagy_response_headers
      response.headers.merge!(@pagy.headers_hash) if @pagy
    end

    def forbidden(_e)
      render json: { error: { code: "forbidden", message: "Acceso denegado" } }, status: :forbidden
    end

    def not_found(_e)
      render json: { error: { code: "not_found", message: "Recurso no encontrado" } }, status: :not_found
    end

    def unprocessable(e)
      render json: { error: { code: "unprocessable", details: e.record.errors.as_json } },
             status: :unprocessable_entity
    end

    def unprocessable_param(e)
      render json: { error: { code: "unprocessable", details: { e.param => [ "is required" ] } } },
             status: :unprocessable_entity
    end
  end
end
