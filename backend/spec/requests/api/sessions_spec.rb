require "swagger_helper"

RSpec.describe "Api::Sessions", type: :request do
  # The bearer token format JWT uses: three base64url segments separated by dots.
  JWT_PATTERN = /\ABearer [\w-]+\.[\w-]+\.[\w-]+\z/

  before do
    # rack-attack reads from Rails.cache; the test env defaults to :null_store
    # which silently drops counters. Swap to a memory store and reset it
    # between examples so throttling is observable.
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end

  path "/api/auth/login" do
    post "Authenticates with email + password and returns a JWT" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      # Wire shape follows Devise convention (`params[:user]`): nested
      # `{ user: { email, password } }`. devise-jwt's middleware sets the
      # Authorization header on the response after a successful sign_in.
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: { email: { type: :string }, password: { type: :string } },
            required: %w[email password]
          }
        },
        required: %w[user]
      }

      response "200", "ok (returns Bearer token in Authorization header)" do
        let!(:user) { create(:user, :with_shipper, email: "login@example.com", password: "Password1") }
        let(:payload) { { user: { email: "login@example.com", password: "Password1" } } }
        schema "$ref" => "#/components/schemas/Me"

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["email"]).to eq("login@example.com")
          expect(body["roles"]).to eq([ "shipper" ])
          expect(response.headers["Authorization"]).to match(JWT_PATTERN)
        end
      end

      response "401", "invalid password" do
        let!(:user) { create(:user, email: "login@example.com", password: "Password1") }
        let(:payload) { { user: { email: "login@example.com", password: "WrongOne1" } } }
        schema "$ref" => "#/components/schemas/ErrorEnvelope"

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]["code"]).to eq("invalid_credentials")
          expect(response.headers["Authorization"]).to be_nil
        end
      end

      response "401", "email not found (no user enumeration)" do
        let(:payload) { { user: { email: "ghost@example.com", password: "Password1" } } }
        schema "$ref" => "#/components/schemas/ErrorEnvelope"

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]["code"]).to eq("invalid_credentials")
        end
      end
    end
  end

  path "/api/auth/logout" do
    delete "Revokes the JWT (rotates the user's JTI)" do
      tags "Auth"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: false

      response "204", "no content (JWT revoked)" do
        let(:user) { create(:user, password: "Password1") }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

        run_test! do
          expect(response.body).to be_blank
        end
      end

      response "401", "missing Authorization header" do
        let(:Authorization) { "" }
        schema "$ref" => "#/components/schemas/ErrorEnvelope"

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]["code"]).to eq("unauthorized")
        end
      end
    end
  end

  describe "revocation behaviour" do
    it "invalidates the JWT on logout (subsequent /me returns 401)" do
      user = create(:user, :with_shipper, password: "Password1")
      token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
      headers = { "Authorization" => "Bearer #{token}" }

      get "/api/auth/me", headers: headers
      expect(response).to have_http_status(:ok)

      delete "/api/auth/logout", headers: headers
      expect(response).to have_http_status(:no_content)

      get "/api/auth/me", headers: headers
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("unauthorized")
    end
  end

  describe "rate limiting" do
    let!(:user) { create(:user, email: "rl@example.com", password: "Password1") }

    it "returns 429 after 5 failed login attempts from the same IP" do
      6.times do
        post "/api/auth/login",
             params: { user: { email: "rl@example.com", password: "Wrong1234" } },
             as: :json
      end
      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("rate_limited")
    end
  end
end
