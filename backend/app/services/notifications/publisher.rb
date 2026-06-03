# frozen_string_literal: true

module Notifications
  # The single entry point for emitting in-app notifications (INF-FE-00005 /
  # ADR-013). Every feature emits through here — nobody calls
  # `ActionCable.server.broadcast` directly — so the transport stays
  # swappable behind a stable signature:
  #
  #   Notifications::Publisher.publish(user_id:, type:, payload:)
  #
  # Contract:
  #   - user_id (Integer): the single recipient. No multi-user fan-out.
  #   - type (Symbol): must be registered in Notifications::Type, else
  #     Notifications::UnknownTypeError.
  #   - payload (Hash): JSON-serializable; coerced via `as_json` before
  #     broadcasting. ArgumentError if not a Hash.
  #
  # The broadcast message is `{ type:, payload:, emitted_at: }` where
  # `emitted_at` is an ISO-8601 server timestamp injected here (the server is
  # the clock authority — callers never set it).
  #
  # Delivery is best-effort live: if the recipient has no open WebSocket the
  # broadcast is lost. Nothing is persisted (no `notifications` table, no
  # server-side id, no offline queue) — see ADR-013.
  #
  # Emission is synchronous: we resolve `User.find(user_id)` and call
  # `NotificationsChannel.broadcast_to(user, message)` (idiomatic Rails — scoped
  # to the User's GlobalID within the channel namespace). Moving this onto a job
  # is a one-class change when the first hot-path caller appears; the external
  # signature stays `publish(user_id:, ...)` regardless.
  class Publisher
    def self.publish(user_id:, type:, payload:)
      unless Notifications::Type.registered?(type)
        raise Notifications::UnknownTypeError, "Unknown notification type: #{type.inspect}"
      end

      raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)

      user = User.find(user_id)
      message = {
        type: type.to_s,
        payload: payload.as_json,
        emitted_at: Time.current.iso8601
      }

      NotificationsChannel.broadcast_to(user, message)
    end
  end
end
