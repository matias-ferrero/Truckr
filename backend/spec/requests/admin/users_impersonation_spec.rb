require "rails_helper"

RSpec.describe "Admin user impersonation", type: :request do
  let!(:admin) do
    AdminUser.create!(
      email: "test-admin@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end
  let!(:user) { create(:user) }

  def sign_in_admin!
    post "/admin/login", params: {
      admin_user: { email: admin.email, password: "password" }
    }
  end

  it "redirects unauthenticated impersonation attempts to the admin login" do
    get "/admin/users/#{user.id}/impersonate"
    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("/admin/login")
  end

  context "with an authenticated admin" do
    before { sign_in_admin! }

    it "redirects to the SPA /impersonate route with the JWT in the URL fragment" do
      get "/admin/users/#{user.id}/impersonate"

      expect(response).to have_http_status(:redirect)
      uri = URI.parse(response.location)
      expect(uri.path).to eq("/impersonate")

      # URI#fragment is "token=<jwt>" — parse it like a query string.
      params = URI.decode_www_form(uri.fragment.to_s).to_h
      token = params.fetch("token")
      expect(token).to be_present

      decoded, = JWT.decode(token, Warden::JWTAuth.config.secret, true, algorithm: "HS256")
      expect(decoded["sub"]).to eq(user.id.to_s)
      expect(decoded["impersonated_by"]).to eq(admin.email)
    end

    it "renders an Impersonate link on the AA users index" do
      get "/admin/users"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("/admin/users/#{user.id}/impersonate")
    end
  end
end
