# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payouts::Create, type: :service do
  subject(:result) { described_class.call(shipment:) }

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier) { carrier_user.carrier }
  let(:payment) { shipment.payments.find_by(state: "escrowed") }
  let(:shipment) do
    create(:shipment, :delivered).tap do |s|
      s.cargo_offer.update!(carrier: carrier)
      s.payments.find_by(state: "escrowed").update_column(:amount_cents, 12_500_00)
    end
  end

  before { payment } # ensure payment exists before calling the service

  describe "happy path" do
    it "creates a paid payout" do
      expect { result }.to change(Payout, :count).by(1)
    end

    it "returns the payout" do
      expect(result).to be_a(Payout)
      expect(result).to be_state_paid
    end

    it "calculates commission at 15%" do
      gross      = 12_500_00
      commission = (gross * BigDecimal("0.15")).ceil
      net        = gross - commission

      expect(result.gross_amount_cents).to eq(gross)
      expect(result.commission_cents).to   eq(commission)
      expect(result.amount_cents).to       eq(net)
    end

    it "references the escrowed payment as FK" do
      expect(result.payment_id).to eq(payment.id)
    end

    it "sets paid_at" do
      expect(result.paid_at).not_to be_nil
    end

    it "stamps settled_at on the shipment so the dashboard moves it to Pagadas" do
      result
      expect(shipment.reload.settled_at).to eq(result.paid_at)
    end

    it "emits a PAYOUT_APPROVED notification" do
      expect(Notifications::Publisher).to receive(:publish).with(
        user_id: carrier_user.id,
        type:    Notifications::Type::PAYOUT_APPROVED,
        payload: hash_including(
          shipment_id:        shipment.id,
          gross_amount_cents: 12_500_00,
          currency:           "ARS"
        )
      )
      result
    end
  end

  describe "guard: no escrowed payment" do
    before { payment.update_columns(state: "failed") }

    it "raises ConflictError(:no_escrowed_payment)" do
      expect { result }.to raise_error(
        Payouts::Create::ConflictError,
        /no_escrowed_payment/
      )
    end

    it "does not create a payout" do
      expect { result rescue nil }.not_to change(Payout, :count)
    end
  end

  describe "guard: already paid" do
    before { create(:payout, shipment: shipment, payment: payment) }

    it "raises ConflictError(:already_paid)" do
      expect { result }.to raise_error(
        Payouts::Create::ConflictError,
        /already_paid/
      )
    end

    it "does not create a duplicate payout" do
      expect { result rescue nil }.not_to change(Payout, :count)
    end
  end

  describe "notification failure resilience" do
    it "does not roll back the payout when notification raises" do
      allow(Notifications::Publisher).to receive(:publish).and_raise(StandardError, "cable down")
      expect { result }.to change(Payout, :count).by(1)
    end
  end
end
