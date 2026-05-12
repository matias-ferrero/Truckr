require "swagger_helper"

RSpec.describe "Api::Auth", type: :request do
  path "/api/auth/register" do
    post "Registers a new user with the chosen role" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          email:    { type: :string },
          password: { type: :string },
          name:     { type: :string },
          role:     { type: :string, enum: %w[carrier shipper] }
        },
        required: %w[email password name role]
      }

      response "201", "created (carrier)" do
        let(:payload) do
          { email: "carrier-#{SecureRandom.hex(3)}@example.com", password: "Password1", name: "Test Carrier", role: "carrier" }
        end
        schema "$ref" => "#/components/schemas/Me"

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["roles"]).to eq([ "carrier" ])
          expect(User.exists?(email: payload[:email])).to be true
          # devise-jwt dispatcher injects the Bearer token on register too (ADR-011)
          expect(response.headers["Authorization"]).to match(/\ABearer [\w-]+\.[\w-]+\.[\w-]+\z/)
        end
      end

      response "201", "created (shipper)" do
        let(:payload) do
          { email: "shipper-#{SecureRandom.hex(3)}@example.com", password: "Password1", name: "Test Shipper", role: "shipper" }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["roles"]).to eq([ "shipper" ])
        end
      end

      response "422", "invalid role" do
        let(:payload) do
          { email: "both-#{SecureRandom.hex(3)}@example.com", password: "Password1", name: "Both", role: "both" }
        end

        schema "$ref" => "#/components/schemas/ErrorEnvelope"

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["error"]["code"]).to eq("unprocessable")
          expect(body["error"]["details"]).to have_key("role")
        end
      end

      response "422", "weak password" do
        let(:payload) { { email: "weak@example.com", password: "weak", name: "X", role: "shipper" } }
        schema "$ref" => "#/components/schemas/ErrorEnvelope"

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]["code"]).to eq("unprocessable")
          expect(User.where(email: "weak@example.com")).to be_empty
        end
      end

      response "422", "invalid email" do
        let(:payload) { { email: "not-an-email", password: "Password1", name: "X", role: "shipper" } }

        run_test!
      end

      response "422", "missing role" do
        let(:payload) { { email: "x@example.com", password: "Password1", name: "X" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]["details"]).to have_key("role")
        end
      end

      response "422", "duplicate email" do
        before { create(:user, email: "dup@example.com") }
        let(:payload) { { email: "dup@example.com", password: "Password1", name: "X", role: "shipper" } }

        run_test!
      end
    end
  end

  path "/api/auth/me" do
    get "Returns the current user with carrier/shipper rows" do
      tags "Auth"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "authenticated" do
        let(:user) { create(:user, :with_carrier, :with_shipper, email: "me@example.com", password: "Password1") }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        schema "$ref" => "#/components/schemas/Me"

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["email"]).to eq("me@example.com")
          expect(body["roles"]).to contain_exactly("carrier", "shipper")
          expect(body["carrier"]).to be_a(Hash)
          expect(body["shipper"]).to be_a(Hash)
        end
      end

      response "401", "anonymous" do
        let(:Authorization) { "" }
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        run_test! do |response|
          expect(JSON.parse(response.body)["error"]["code"]).to eq("unauthorized")
        end
      end
    end
  end
end
