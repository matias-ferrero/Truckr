# frozen_string_literal: true

# Alba serializer config — backed by Oj for fast JSON. Inflector active_support
# so `transport_window` <-> `TransportWindow` casing is automatic when Alba
# resolves attribute names.
require "alba"
require "oj"

# Optimize Oj for Rails — handles ActiveSupport::TimeWithZone, BigDecimal,
# and other Rails idioms that strict mode rejects.
Oj.default_options = { mode: :rails }

Alba.backend = :oj_rails
Alba.inflector = :active_support
