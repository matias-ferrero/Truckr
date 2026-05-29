# frozen_string_literal: true

require "rails_helper"

# AC8 (REQ-BE-00039 / ADR-014): the public marketplace endpoint
# `GET /api/transport_windows` is retired. Browsing happens exclusively
# through `GET /api/cargos/:id/matches`.
RSpec.describe "Api::TransportWindows", type: :request do
  describe "GET /api/transport_windows (retired)" do
    it "is not routable — the public marketplace endpoint was removed by REQ-BE-00039" do
      get "/api/transport_windows", params: { date_from: "2026-05-12", date_to: "2026-05-14" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
