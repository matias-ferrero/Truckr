# frozen_string_literal: true

# Pagy pagination defaults. Headers are integrated in core (pagy 43+);
# `:headers_map` exposes `X-Page`, `X-Per-Page`, `X-Total`, `X-Total-Pages`
# so the frontend can paginate without parsing JSON envelopes.
Pagy::OPTIONS[:limit]     = 20
Pagy::OPTIONS[:max_limit] = 100

Pagy::OPTIONS[:headers_map] = {
  page:  "X-Page",
  limit: "X-Per-Page",
  count: "X-Total",
  pages: "X-Total-Pages"
}

Pagy::OPTIONS.freeze
