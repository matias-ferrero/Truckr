# frozen_string_literal: true

# Subscribes the authenticated user to their personal notification stream
# (INF-FE-00005 / ADR-013). `stream_for current_user` derives the stream name
# from the User's GlobalID, scoped to this channel class
# (`notifications:<gid>`) — so it won't collide with future per-user channels
# (PresenceChannel, LiveChatChannel, …). Anonymous subscriptions never reach
# here: `ApplicationCable::Connection#connect` rejects them first.
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
