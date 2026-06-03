# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::Publisher, type: :channel do
  let(:user) { create(:user) }

  describe ".publish" do
    it "broadcasts a registered type to the user's stream" do
      expect {
        described_class.publish(user_id: user.id, type: :ping, payload: { message: "hi" })
      }.to have_broadcasted_to(user).from_channel(NotificationsChannel)
    end

    it "raises UnknownTypeError for a type outside the whitelist" do
      expect {
        described_class.publish(user_id: user.id, type: :not_registered, payload: {})
      }.to raise_error(Notifications::UnknownTypeError)
    end

    it "raises ArgumentError when the payload is not a Hash" do
      expect {
        described_class.publish(user_id: user.id, type: :ping, payload: "nope")
      }.to raise_error(ArgumentError)
    end

    it "injects an ISO-8601 emitted_at server-side and coerces the payload via as_json" do
      expect {
        described_class.publish(
          user_id: user.id,
          type: :ping,
          payload: { sent_at: Time.utc(2026, 1, 2, 3, 4, 5), nested: { ok: true } }
        )
      }.to have_broadcasted_to(user).from_channel(NotificationsChannel).with { |data|
        expect(data["type"]).to eq("ping")
        expect(data["emitted_at"]).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
        # as_json stringified the symbol keys and serialized the Time.
        expect(data["payload"]).to include("sent_at", "nested")
        expect(data["payload"]["nested"]).to eq("ok" => true)
      }
    end
  end
end
