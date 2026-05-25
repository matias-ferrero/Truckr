require "rails_helper"

RSpec.describe Payment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shipment) }
  end

  describe "validations" do
    subject { build(:payment) }

    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:state) }

    it "requires amount_cents to be a positive integer" do
      expect(build(:payment, amount_cents: 0)).not_to be_valid
      expect(build(:payment, amount_cents: -1)).not_to be_valid
      expect(build(:payment, amount_cents: 1)).to be_valid
    end

    it "rejects unknown state assignments via the enum" do
      expect { described_class.new(state: "pending") }.to raise_error(ArgumentError)
    end

    it "rejects unknown provider assignments via the enum" do
      expect { described_class.new(provider: "paypal") }.to raise_error(ArgumentError)
    end

    it "accepts both terminal states" do
      expect(build(:payment, :escrowed)).to be_valid
      expect(build(:payment, :failed)).to be_valid
    end
  end

  describe "enums" do
    it "exposes the STATES whitelist verbatim" do
      expect(described_class::STATES).to eq(%w[escrowed failed])
    end

    it "exposes the PROVIDERS whitelist verbatim" do
      expect(described_class::PROVIDERS).to eq(%w[fake mercadopago stripe other])
    end

    it "exposes prefixed state predicates" do
      expect(build(:payment, :escrowed)).to be_state_escrowed
      expect(build(:payment, :failed)).to be_state_failed
    end

    it "exposes prefixed provider predicates" do
      expect(build(:payment, provider: "fake")).to be_provider_fake
    end
  end

  describe "factories" do
    it "builds an escrowed row" do
      p = create(:payment, :escrowed)
      expect(p.state).to eq("escrowed")
      expect(p.escrowed_at).to be_present
      expect(p.failed_at).to be_nil
    end

    it "builds a failed row" do
      p = create(:payment, :failed)
      expect(p.state).to eq("failed")
      expect(p.failed_at).to be_present
      expect(p.escrowed_at).to be_nil
      expect(p.failure_reason).to be_present
    end
  end

  describe "immutability after create" do
    let!(:payment) { create(:payment, :escrowed) }

    Payment::IMMUTABLE_FIELDS.each do |field|
      it "raises ActiveRecord::ReadOnlyRecord on #{field} mutation" do
        new_value =
          case field
          when "shipment_id"  then create(:shipment, :accepted).id
          when "amount_cents" then payment.amount_cents + 1
          when "currency"     then "USD"
          when "provider"     then "mercadopago"
          when "state"        then "failed"
          when "escrowed_at"  then 1.minute.from_now
          when "failed_at"    then 1.minute.from_now
          end

        payment.public_send("#{field}=", new_value)
        expect { payment.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    it "allows mutating non-locked fields (e.g. failure_reason)" do
      failed = create(:payment, :failed, failure_reason: "card_declined")
      expect { failed.update!(failure_reason: "card_expired") }.not_to raise_error
      expect(failed.reload.failure_reason).to eq("card_expired")
    end

    it "allows mutating provider_reference after create" do
      expect { payment.update!(provider_reference: "fake-late-bind") }.not_to raise_error
      expect(payment.reload.provider_reference).to eq("fake-late-bind")
    end
  end
end
