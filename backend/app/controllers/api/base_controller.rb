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

    # Pundit's verify_* invariants are wired as after_actions with `only:` /
    # `except:` references to `:index`. Rails 7.1 raises when a callback names
    # an action the controller doesn't define (e.g. AuthController has no
    # `index`), so opt out of that check here — Pundit handles the "did you
    # call authorize?" assertion itself.
    self.raise_on_missing_callback_actions = false

    rescue_from Pundit::NotAuthorizedError, with: :forbidden
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed,
                ActiveRecord::RecordNotSaved, with: :unprocessable
    rescue_from ActionController::ParameterMissing, with: :unprocessable_param
    rescue_from Date::Error, with: :unprocessable_param

    after_action :pagy_response_headers
    after_action :verify_authorized, except: :index
    after_action :verify_policy_scoped, only: :index

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

    def require_shipper!
      return if current_shipper

      render json: { error: { code: "forbidden", message: I18n.t("errors.shipper_role_required") } },
             status: :forbidden
    end

    private

    def pagy_response_headers
      response.headers.merge!(@pagy.headers_hash) if @pagy
    end

    def render_error(code:, status:, details: nil, message: nil)
      payload = { code: code }
      payload[:message] = message if message
      payload[:details] = details if details
      render json: { error: payload }, status: status
    end

    def render_collection(resource_class, scope)
      @pagy, page_records = pagy(scope)
      render json: resource_class.new(page_records).serialize
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
      details = if e.respond_to?(:param)
        { e.param => [ "is required" ] }
      else
        { base: [ e.message ] }
      end
      render json: { error: { code: "unprocessable", details: details } },
             status: :unprocessable_entity
    end
  end
end
