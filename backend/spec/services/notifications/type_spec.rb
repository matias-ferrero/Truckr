# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::Type do
  it "registers the cargo-offer resolution types in the closed whitelist (REQ-FE-00030)" do
    expect(described_class::ALL).to include(:cargo_offer_accepted, :cargo_offer_rejected)
  end

  it "recognises the new types via registered?" do
    expect(described_class.registered?(:cargo_offer_accepted)).to be(true)
    expect(described_class.registered?(:cargo_offer_rejected)).to be(true)
  end

  it "still rejects an unregistered type" do
    expect(described_class.registered?(:not_a_real_type)).to be(false)
  end
end
