# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleMaps::DistanceService do
  let(:valid_response_body) do
    { "routes" => [ { "distanceMeters" => 712_000 } ] }.to_json
  end

  def stub_http_success(body)
    http_response = instance_double(Net::HTTPOK, body: body)
    allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    allow(Net::HTTP).to receive(:start).and_return(http_response)
  end

  def stub_http_error
    http_response = instance_double(Net::HTTPInternalServerError, body: "error", code: "500")
    allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
    allow(Net::HTTP).to receive(:start).and_return(http_response)
  end

  around do |example|
    old = ENV["GOOGLE_MAPS_API_KEY"]
    ENV["GOOGLE_MAPS_API_KEY"] = "test-key"
    example.run
  ensure
    ENV["GOOGLE_MAPS_API_KEY"] = old
  end

  # Bypass the global rails_helper stub so we can test the real implementation
  # with a stubbed HTTP layer.
  before do
    allow(described_class).to receive(:fetch_km).and_call_original
  end

  describe ".fetch_km" do
    context "when the API returns a valid driving distance" do
      it "returns the distance in km rounded to 2 decimal places" do
        stub_http_success(valid_response_body)
        expect(described_class.fetch_km(-34.6, -58.4, -31.4, -64.2)).to eq(712.0)
      end
    end

    context "when the Routes API returns no routes (no driving route exists)" do
      it "returns nil" do
        stub_http_success({ "routes" => [] }.to_json)
        expect(described_class.fetch_km(-34.6, -58.4, 0.0, 0.0)).to be_nil
      end
    end

    context "when the HTTP response is not a success" do
      it "returns nil" do
        stub_http_error
        expect(described_class.fetch_km(-34.6, -58.4, -31.4, -64.2)).to be_nil
      end
    end

    context "when the HTTP call raises (timeout, connection refused)" do
      it "returns nil" do
        allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)
        expect(described_class.fetch_km(-34.6, -58.4, -31.4, -64.2)).to be_nil
      end
    end

    context "when GOOGLE_MAPS_API_KEY is not set" do
      around do |ex|
        old = ENV["GOOGLE_MAPS_API_KEY"]
        ENV.delete("GOOGLE_MAPS_API_KEY")
        ex.run
      ensure
        ENV["GOOGLE_MAPS_API_KEY"] = old
      end

      it "returns nil without making an HTTP call" do
        expect(Net::HTTP).not_to receive(:start)
        expect(described_class.fetch_km(-34.6, -58.4, -31.4, -64.2)).to be_nil
      end
    end
  end
end
