require "rails_helper"

RSpec.describe "Admin panel", type: :request do
  it "redirects unauthenticated requests to the admin login" do
    get "/admin"

    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("/admin/login")
  end

  context "with a valid AdminUser" do
    let!(:admin) do
      AdminUser.create!(
        email: "test-admin@example.com",
        password: "password",
        password_confirmation: "password"
      )
    end

    it "lets the admin sign in and reach the dashboard" do
      post "/admin/login", params: {
        admin_user: { email: admin.email, password: "password" }
      }

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dashboard")
    end

    it "renders the AdminUsers index without Ransack allowlist errors" do
      post "/admin/login", params: {
        admin_user: { email: admin.email, password: "password" }
      }

      get "/admin/admin_users"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(admin.email)
    end
  end
end
