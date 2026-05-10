require "swagger_helper"

RSpec.describe "Api::Auth", type: :request do
  before do
    # rack-attack reads from Rails.cache; the test env defaults to :null_store
    # which silently drops counters. Swap to a memory store and reset it
    # between examples so throttling is observable.
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end

  path "/api/auth/csrf" do
    get "Returns the CSRF token and bootstraps a session cookie" do
      tags "Auth"
      produces "application/json"

      response "200", "ok" do
        schema type: :object,
               properties: { csrf_token: { type: :string } },
               required: %w[csrf_token]

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to have_key("csrf_token")
          expect(body["csrf_token"]).to be_a(String).and be_present
        end
      end
    end
  end

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
          role:     { type: :string, enum: %w[carrier shipper both] }
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
          expect(body["roles"]).to eq(["carrier"])
          expect(User.exists?(email: payload[:email])).to be true
        end
      end

      response "201", "created (shipper)" do
        let(:payload) do
          { email: "shipper-#{SecureRandom.hex(3)}@example.com", password: "Password1", name: "Test Shipper", role: "shipper" }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["roles"]).to eq(["shipper"])
        end
      end

      response "201", "created (both)" do
        let(:payload) do
          { email: "both-#{SecureRandom.hex(3)}@example.com", password: "Password1", name: "Both", role: "both" }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["roles"]).to contain_exactly("carrier", "shipper")
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

  path "/api/auth/login" do
    post "Logs in with email + password" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: { email: { type: :string }, password: { type: :string } },
        required: %w[email password]
      }

      response "200", "ok" do
        let!(:user) { create(:user, :with_shipper, email: "login@example.com", password: "Password1") }
        let(:payload) { { email: "login@example.com", password: "Password1" } }
        schema "$ref" => "#/components/schemas/Me"

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["email"]).to eq("login@example.com")
          expect(body["roles"]).to eq(["shipper"])
        end
      end

      response "401", "invalid credentials" do
        let!(:user) { create(:user, email: "login@example.com", password: "Password1") }
        let(:payload) { { email: "login@example.com", password: "WrongOne1" } }
        schema "$ref" => "#/components/schemas/ErrorEnvelope"

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]["code"]).to eq("invalid_credentials")
        end
      end
    end
  end

  path "/api/auth/logout" do
    delete "Signs the current user out" do
      tags "Auth"
      produces "application/json"

      response "204", "no content" do
        before do
          create(:user, email: "out@example.com", password: "Password1")
          post "/api/auth/login", params: { email: "out@example.com", password: "Password1" }, as: :json
        end

        run_test!
      end
    end
  end

  path "/api/auth/me" do
    get "Returns the current user with carrier/shipper rows" do
      tags "Auth"
      produces "application/json"

      response "200", "authenticated" do
        before do
          create(:user, :with_carrier, :with_shipper, email: "me@example.com", password: "Password1")
          post "/api/auth/login", params: { email: "me@example.com", password: "Password1" }, as: :json
        end
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
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        run_test! do |response|
          expect(JSON.parse(response.body)["error"]["code"]).to eq("unauthorized")
        end
      end
    end
  end

  describe "rate limiting" do
    let!(:user) { create(:user, email: "rl@example.com", password: "Password1") }

    it "returns 429 after 5 failed login attempts from the same IP" do
      6.times do
        post "/api/auth/login",
             params: { email: "rl@example.com", password: "Wrong1234" },
             as: :json
      end
      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("rate_limited")
    end
  end
end
