# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::Carriers::Me::CargoOffers", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:pickup_start) { 3.days.from_now }
  let(:pickup_end)   { 5.days.from_now }

  before { sign_in carrier_user }

  describe "GET /api/carriers/me/cargo-offers" do
    it "returns only pending offers for the authenticated carrier by default" do
      vehicle = create(:vehicle, carrier: carrier)
      window = create(:transport_window, vehicle: vehicle, status: "pending_offer",
                      available_from: 2.days.from_now, available_to: 10.days.from_now)
      cargo = create(:cargo, shipper: shipper_user.shipper,
                     pickup_window_start: pickup_start, pickup_window_end: pickup_end)
      mine = create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window, status: "pending")
      second_vehicle = create(:vehicle, carrier: carrier)
      _accepted = create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier,
                         transport_window: create(:transport_window, vehicle: second_vehicle, status: "reserved",
                                                  available_from: 2.days.from_now,
                                                  available_to: 10.days.from_now))

      other_carrier = create(:carrier)
      other_vehicle = create(:vehicle, carrier: other_carrier)
      other_window = create(:transport_window, vehicle: other_vehicle, status: "pending_offer",
               available_from: 2.days.from_now, available_to: 10.days.from_now)
      _foreign = create(:cargo_offer, cargo: cargo, carrier: other_carrier, transport_window: other_window)

      get "/api/carriers/me/cargo-offers"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |o| o["id"] }).to contain_exactly(mine.id)
      expect(body.first).to include("price_amount_cents", "shipper", "cargo", "transport_window")
    end

    it "filters by status" do
      vehicle = create(:vehicle, carrier: carrier)
      cargo = create(:cargo, shipper: shipper_user.shipper,
                     pickup_window_start: pickup_start, pickup_window_end: pickup_end)
      pending = create(:cargo_offer, cargo: cargo, carrier: carrier,
                       transport_window: create(:transport_window, vehicle: vehicle, status: "pending_offer",
                                                available_from: 2.days.from_now,
                                                available_to: 10.days.from_now), status: "pending")
      second_vehicle = create(:vehicle, carrier: carrier)
      accepted = create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier,
                        transport_window: create(:transport_window, vehicle: second_vehicle, status: "reserved",
                                                 available_from: 2.days.from_now,
                                                 available_to: 10.days.from_now))

      get "/api/carriers/me/cargo-offers", params: { status: "accepted" }

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |o| o["id"] }
      expect(ids).to contain_exactly(accepted.id)
      expect(ids).not_to include(pending.id)
    end

    it "exposes the shipper's identity and review headline numbers (carrier-dashboard-v2)" do
      vehicle = create(:vehicle, carrier: carrier)
      window = create(:transport_window, vehicle: vehicle, status: "pending_offer",
                      available_from: 2.days.from_now, available_to: 10.days.from_now)
      cargo = create(:cargo, shipper: shipper_user.shipper,
                     pickup_window_start: pickup_start, pickup_window_end: pickup_end)
      create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window, status: "pending")
      # Two carrier-authored reviews about this shipper → avg 4.5, count 2.
      create(:review, :carrier_authored, rating: 4,
             shipment: create(:shipment, :delivered,
                              cargo_offer: create(:cargo_offer, :accepted,
                                                  cargo: create(:cargo, shipper: shipper_user.shipper,
                                                                pickup_window_start: pickup_start,
                                                                pickup_window_end: pickup_end))))
      create(:review, :carrier_authored, rating: 5,
             shipment: create(:shipment, :delivered,
                              cargo_offer: create(:cargo_offer, :accepted,
                                                  cargo: create(:cargo, shipper: shipper_user.shipper,
                                                                pickup_window_start: pickup_start,
                                                                pickup_window_end: pickup_end))))

      get "/api/carriers/me/cargo-offers"

      shipper = JSON.parse(response.body).first.fetch("shipper")
      expect(shipper).to include(
        "id"            => shipper_user.shipper.id,
        "name"          => shipper_user.full_name,
        "rating_avg"    => "4.5",
        "reviews_count" => 2
      )
    end

    it "nulls rating_avg for an unrated shipper" do
      vehicle = create(:vehicle, carrier: carrier)
      window = create(:transport_window, vehicle: vehicle, status: "pending_offer",
                      available_from: 2.days.from_now, available_to: 10.days.from_now)
      cargo = create(:cargo, shipper: shipper_user.shipper,
                     pickup_window_start: pickup_start, pickup_window_end: pickup_end)
      create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window, status: "pending")

      get "/api/carriers/me/cargo-offers"

      shipper = JSON.parse(response.body).first.fetch("shipper")
      expect(shipper["rating_avg"]).to be_nil
      expect(shipper["reviews_count"]).to eq(0)
    end

    it "rejects unauthenticated requests" do
      sign_out carrier_user

      get "/api/carriers/me/cargo-offers"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/carriers/me/cargo-offers/:id/accept" do
    let(:cargo) do
      create(:cargo, shipper: shipper_user.shipper, status: "open",
             pickup_window_start: pickup_start, pickup_window_end: pickup_end)
    end

    it "accepts winner and cascades sibling rejects atomically" do
      winner_window = create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "pending_offer",
              available_from: 2.days.from_now, available_to: 10.days.from_now)
      winner = create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: winner_window,
                      status: "pending", expires_at: 2.days.from_now)

      other_carrier = create(:carrier)
      sibling_window = create(:transport_window, vehicle: create(:vehicle, carrier: other_carrier), status: "pending_offer",
               available_from: 2.days.from_now, available_to: 10.days.from_now)
      sibling = create(:cargo_offer, cargo: cargo, carrier: other_carrier, transport_window: sibling_window,
                       status: "pending", expires_at: 2.days.from_now)

      post "/api/carriers/me/cargo-offers/#{winner.id}/accept"

      expect(response).to have_http_status(:ok)
      expect(winner.reload.status).to eq("accepted")
      expect(winner.accepted_at).to be_present
      expect(winner_window.reload.status).to eq("reserved")

      expect(sibling.reload.status).to eq("rejected")
      expect(sibling.rejected_at).to be_present
      expect(sibling_window.reload.status).to eq("open")

      expect(cargo.reload.status).to eq("accepted")
      expect(Shipment.find_by(cargo_offer_id: winner.id)).to be_present
    end

    it "returns 409 when already accepted" do
      winner_window = create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "reserved",
              available_from: 2.days.from_now, available_to: 10.days.from_now)
      winner = create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier, transport_window: winner_window)

      post "/api/carriers/me/cargo-offers/#{winner.id}/accept"

      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body).dig("error", "code")).to eq("conflict")
    end

    it "returns 409 when pending offer is expired" do
      winner_window = create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "pending_offer",
              available_from: 2.days.from_now, available_to: 10.days.from_now)
      winner = create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: winner_window,
                      status: "pending", expires_at: 1.minute.ago)

      post "/api/carriers/me/cargo-offers/#{winner.id}/accept"

      expect(response).to have_http_status(:conflict)
    end

    it "returns 403 for non-owner carrier" do
      owner = create(:carrier)
      winner_window = create(:transport_window, vehicle: create(:vehicle, carrier: owner), status: "pending_offer",
              available_from: 2.days.from_now, available_to: 10.days.from_now)
      winner = create(:cargo_offer, cargo: cargo, carrier: owner, transport_window: winner_window,
                      status: "pending", expires_at: 2.days.from_now)

      post "/api/carriers/me/cargo-offers/#{winner.id}/accept"

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 409 when parent cargo is not open" do
      cargo.update!(status: "cancelled")
      winner_window = create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "pending_offer",
              available_from: 2.days.from_now, available_to: 10.days.from_now)
      winner = create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: winner_window,
                      status: "pending", expires_at: 2.days.from_now)

      post "/api/carriers/me/cargo-offers/#{winner.id}/accept"

      expect(response).to have_http_status(:conflict)
    end
  end

  describe "POST /api/carriers/me/cargo-offers/:id/reject" do
    let(:cargo) do
      create(:cargo, shipper: shipper_user.shipper, status: "open",
             pickup_window_start: pickup_start, pickup_window_end: pickup_end)
    end

    it "marks the offer as rejected and re-opens its transport window" do
      window = create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "pending_offer",
           available_from: 2.days.from_now, available_to: 10.days.from_now)
      offer = create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window,
                     status: "pending", expires_at: 2.days.from_now)

      post "/api/carriers/me/cargo-offers/#{offer.id}/reject"

      expect(response).to have_http_status(:ok)
      expect(offer.reload.status).to eq("rejected")
      expect(offer.rejected_at).to be_present
      expect(window.reload.status).to eq("open")
    end

    it "returns 409 when already rejected" do
      window = create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "open",
           available_from: 2.days.from_now, available_to: 10.days.from_now)
      offer = create(:cargo_offer, :rejected, cargo: cargo, carrier: carrier, transport_window: window)

      post "/api/carriers/me/cargo-offers/#{offer.id}/reject"

      expect(response).to have_http_status(:conflict)
    end

    it "publishes a realtime cargo_offer_rejected to the offer's shipper (REQ-FE-00030)" do
      allow(Notifications::Publisher).to receive(:publish)
      window = create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "pending_offer",
           available_from: 2.days.from_now, available_to: 10.days.from_now)
      offer = create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window,
                     status: "pending", expires_at: 2.days.from_now)

      post "/api/carriers/me/cargo-offers/#{offer.id}/reject"

      expect(response).to have_http_status(:ok)
      expect(Notifications::Publisher).to have_received(:publish).with(
        user_id: shipper_user.shipper.user_id,
        type: :cargo_offer_rejected,
        payload: hash_including(
          cargo_offer_id: offer.id,
          cargo_id: cargo.id,
          amount_cents: offer.amount_cents,
          currency: offer.currency
        )
      )
    end

    it "emits the broadcast after the transaction commits, not inside it (SQLite single-writer)" do
      # Regression for the Solid Cable self-lock: with transactional fixtures the
      # example holds exactly one transaction; emitting the broadcast inside the
      # reject's own transaction would show a second (savepoint) level. The :test
      # ActionCable adapter hides the real SQLite3::BusyException, so we assert
      # transaction depth at publish time instead.
      observed = []
      allow(Notifications::Publisher).to receive(:publish) do
        observed << ActiveRecord::Base.connection.open_transactions
      end
      window = create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "pending_offer",
           available_from: 2.days.from_now, available_to: 10.days.from_now)
      offer = create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window,
                     status: "pending", expires_at: 2.days.from_now)

      post "/api/carriers/me/cargo-offers/#{offer.id}/reject"

      expect(response).to have_http_status(:ok)
      expect(observed).not_to be_empty
      expect(observed).to all(eq(1))
    end
  end
end
