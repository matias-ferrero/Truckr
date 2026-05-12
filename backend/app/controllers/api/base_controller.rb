# frozen_string_literal: true

module Api
  # Base controller for the JSON API.
  #
  # ApplicationController stays untouched (it must inherit from
  # ActionController::Base for ActiveAdmin to work). The API hangs off this
  # leaner ActionController::API stack — augmented with Devise helpers (for
  # current_user resolution via Warden), Pundit, Pagy, and a uniform error
  # envelope. CSRF / cookies are deliberately absent: ADR-011 routes auth
  # through stateless JWTs and there is no session vector to protect.
  class BaseController < ActionController::API
    include Devise::Controllers::Helpers
    include Pundit::Authorization
    include Pagy::Method

    rescue_from Pundit::NotAuthorizedError, with: :forbidden
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
    rescue_from ActionController::ParameterMissing, with: :unprocessable_param

    after_action :pagy_response_headers

    # current_user comes from Devise::Controllers::Helpers and is populated
    # by Warden's :jwt_authenticatable strategy when the request carries a
    # valid `Authorization: Bearer <jwt>` header.
    def current_carrier = current_user&.carrier
    def current_shipper = current_user&.shipper

    def authenticate_user!
      return if current_user

      render json: { error: { code: "unauthorized", message: I18n.t("errors.unauthorized") } },
             status: :unauthorized
    end

    def require_carrier!
      return if current_carrier

      render json: { error: { code: "forbidden", message: I18n.t("errors.carrier_role_required") } },
             status: :forbidden
    end

    private

    def pagy_response_headers
      response.headers.merge!(@pagy.headers_hash) if @pagy
    end

    def forbidden(_e)
      render json: { error: { code: "forbidden", message: I18n.t("errors.forbidden") } },
             status: :forbidden
    end

    def not_found(_e)
      render json: { error: { code: "not_found", message: I18n.t("errors.not_found") } },
             status: :not_found
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
