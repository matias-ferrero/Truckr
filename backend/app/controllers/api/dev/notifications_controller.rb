# frozen_string_literal: true

module Api
  module Dev
    # Development-only endpoint to confirm the notifications framework roundtrip
    # end to end (INF-FE-00005 / ADR-013). The route is gated by a route
    # constraint in config/routes.rb (`Rails.env.development? || .test?`), so it
    # literally does not exist in production — a 404 happens at the routing
    # layer, never reaching this controller.
    #
    # `/api/dev/*` is the canonical home for future debug endpoints (force-expire
    # offers, replay jobs, …) — a single grep target for "what dev routes exist".
    class NotificationsController < Api::BaseController
      before_action :authenticate_user!

      # No Pundit resource to authorize on this debug endpoint — it only
      # broadcasts to the already-authenticated current_user. Opt out of
      # BaseController's `verify_authorized` invariant.
      skip_after_action :verify_authorized

      # POST /api/dev/notifications/ping
      # Broadcasts a `:ping` to the current user. Optional body: `{ message }`.
      # 204 on success, 401 without a valid JWT.
      def ping
        Notifications::Publisher.publish(
          user_id: current_user.id,
          type: Notifications::Type::PING,
          payload: {
            message: params[:message].presence,
            at: Time.current.iso8601
          }
        )

        head :no_content
      end

      # POST /api/dev/notifications/broadcast
      # Broadcasts an arbitrary whitelisted type to the current user. Body:
      # `{ type: "cargo_offer_accepted", payload: { ... } }`. Lets e2e specs and
      # manual QA drive real notification types (REQ-FE-00030 and later
      # consumers) without orchestrating the full multi-role domain flow.
      # 204 on success, 422 for a type outside the whitelist.
      def broadcast
        # Read the arbitrary payload straight from the parsed request body (plain
        # Hash, string keys) — not through strong params. The payload is only
        # broadcast to the current user, never mass-assigned to a model, so there
        # is no `permit!`/`to_unsafe_h` mass-assignment sink for Brakeman to flag.
        raw_payload = request.request_parameters["payload"]
        payload = raw_payload.is_a?(Hash) ? raw_payload : {}

        Notifications::Publisher.publish(
          user_id: current_user.id,
          type: params.require(:type).to_sym,
          payload: payload
        )

        head :no_content
      rescue Notifications::UnknownTypeError
        head :unprocessable_entity
      end
    end
  end
end
