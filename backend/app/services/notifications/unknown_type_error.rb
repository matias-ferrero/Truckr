# frozen_string_literal: true

module Notifications
  # Raised by Notifications::Publisher when asked to emit a type that is not in
  # the Notifications::Type whitelist.
  class UnknownTypeError < StandardError; end
end
