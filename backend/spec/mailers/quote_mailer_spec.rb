# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteMailer, type: :mailer do
  let(:carrier_user) { create(:user, :with_carrier) }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:vehicle)      { create(:vehicle, carrier: carrier_user.carrier) }
  let(:window) do
    create(:transport_window, vehicle: vehicle,
           available_from: 2.days.from_now, available_to: 10.days.from_now)
  end
  let(:cargo_offer) { create(:cargo_offer, shipper: shipper_user.shipper) }
  let(:quote) do
    create(:quote, cargo_offer: cargo_offer, carrier: carrier_user.carrier,
           transport_window: window)
  end

  describe "#notify_carrier" do
    subject(:mail) { described_class.notify_carrier(quote) }

    it "is addressed to the carrier's email" do
      expect(mail.to).to contain_exactly(carrier_user.email)
    end

    it "has a subject that identifies the platform" do
      expect(mail.subject).to include("Truckr")
    end

    it "references the quote id in the body" do
      expect(mail.body.encoded).to include(quote.id.to_s)
    end

    it "does not raise when delivered" do
      expect { mail.deliver_now }.not_to raise_error
    end
  end
end
