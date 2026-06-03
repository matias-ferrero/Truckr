# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Dev::Notifications", type: :request do
  let(:user) { create(:user) }
  let(:auth_header) do
    { "Authorization" => "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
  end

  describe "POST /api/dev/notifications/ping" do
    it "returns 204 and broadcasts a ping carrying the optional message" do
      expect {
        post "/api/dev/notifications/ping",
             params: { message: "hello" }, headers: auth_header, as: :json
      }.to have_broadcasted_to(user).from_channel(NotificationsChannel).with { |data|
        expect(data["type"]).to eq("ping")
        expect(data["payload"]["message"]).to eq("hello")
        expect(data["emitted_at"]).to be_present
      }

      expect(response).to have_http_status(:no_content)
    end

    it "broadcasts a null message when the body is empty" do
      expect {
        post "/api/dev/notifications/ping", headers: auth_header, as: :json
      }.to have_broadcasted_to(user).from_channel(NotificationsChannel).with { |data|
        expect(data["payload"]["message"]).to be_nil
      }

      expect(response).to have_http_status(:no_content)
    end

    it "returns 401 without a valid JWT" do
      post "/api/dev/notifications/ping", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "is not routable in production (route constraint, not a before_action)" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

      expect {
        Rails.application.routes.recognize_path("/api/dev/notifications/ping", method: :post)
      }.to raise_error(ActionController::RoutingError)
    end
  end

  describe "POST /api/dev/notifications/broadcast" do
    it "broadcasts an arbitrary whitelisted type with its payload" do
      expect {
        post "/api/dev/notifications/broadcast",
             params: { type: "cargo_offer_accepted", payload: { cargo_offer_id: 7, currency: "ARS" } },
             headers: auth_header, as: :json
      }.to have_broadcasted_to(user).from_channel(NotificationsChannel).with { |data|
        expect(data["type"]).to eq("cargo_offer_accepted")
        expect(data["payload"]).to include("cargo_offer_id" => 7, "currency" => "ARS")
        expect(data["emitted_at"]).to be_present
      }

      expect(response).to have_http_status(:no_content)
    end

    it "returns 422 for a type outside the whitelist" do
      post "/api/dev/notifications/broadcast",
           params: { type: "not_a_real_type" }, headers: auth_header, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 401 without a valid JWT" do
      post "/api/dev/notifications/broadcast", params: { type: "ping" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
