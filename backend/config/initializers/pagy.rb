# frozen_string_literal: true

# Pagy pagination defaults. Headers extra exposes `Link`, `X-Page`,
# `X-Per-Page`, `X-Total` so the frontend can paginate without parsing JSON
# envelopes.
require "pagy/extras/headers"

Pagy::DEFAULT[:limit]     = 20
Pagy::DEFAULT[:max_items] = 100

# Expose pagination as RFC-8288 Link plus the friendlier X- aliases
# the frontend already expects (`X-Page`, `X-Per-Page`, `X-Total`).
Pagy::DEFAULT[:headers] = {
  page:  "X-Page",
  limit: "X-Per-Page",
  count: "X-Total",
  pages: "X-Total-Pages"
}
