# frozen_string_literal: true

require "rails_helper"

RSpec.describe CargoOfferMailer, type: :mailer do
  let(:carrier_user) { create(:user, :with_carrier) }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:vehicle)      { create(:vehicle, carrier: carrier_user.carrier) }
  let(:window) do
    create(:transport_window, vehicle: vehicle,
           available_from: 2.days.from_now, available_to: 10.days.from_now)
  end
  let(:cargo) { create(:cargo, shipper: shipper_user.shipper) }
  let(:cargo_offer) do
    create(:cargo_offer, cargo: cargo, carrier: carrier_user.carrier,
           transport_window: window)
  end

  describe "#notify_carrier" do
    subject(:mail) { described_class.notify_carrier(cargo_offer) }

    it "is addressed to the carrier's email" do
      expect(mail.to).to contain_exactly(carrier_user.email)
    end

    it "has a subject that identifies the platform" do
      expect(mail.subject).to include("Truckr")
    end

    it "references the cargo offer id in the body" do
      expect(mail.body.encoded).to include(cargo_offer.id.to_s)
    end

    it "does not raise when delivered" do
      expect { mail.deliver_now }.not_to raise_error
    end
  end

  describe "#notify_shipper_offer_accepted" do
    subject(:mail) { described_class.notify_shipper_offer_accepted(cargo_offer) }

    it "is addressed to the shipper's email" do
      expect(mail.to).to contain_exactly(shipper_user.email)
    end

    it "includes payment path in the body" do
      expect(mail.body.encoded).to include("/cargos/#{cargo.id}/pay")
    end
  end

  describe "#notify_shipper_offer_rejected" do
    subject(:mail) { described_class.notify_shipper_offer_rejected(cargo_offer) }

    it "is addressed to the shipper's email" do
      expect(mail.to).to contain_exactly(shipper_user.email)
    end

    it "references the rejected cargo offer id" do
      expect(mail.body.encoded).to include(cargo_offer.id.to_s)
    end
  end
end
