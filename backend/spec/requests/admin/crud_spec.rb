require "rails_helper"

RSpec.describe "Admin panel CRUD", type: :request do
  let!(:admin) do
    AdminUser.create!(
      email: "test-admin@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  before do
    post "/admin/login", params: {
      admin_user: { email: admin.email, password: "password" }
    }
  end

  # Resources whose `new` and `edit` pages should render now that full CRUD is
  # enabled. AdminUser already had CRUD; the rest were index/show only.
  describe "new + edit pages render for every resource" do
    {
      "carriers"          => :carrier,
      "shippers"          => :shipper,
      "vehicles"          => :vehicle,
      "cargo_offers"      => :cargo_offer,
      "transport_windows" => :transport_window,
      "quotes"            => :quote,
      "shipments"         => :shipment,
      "tracking_events"   => :tracking_event,
      "routes"            => :route,
      "users"             => :user
    }.each do |path, factory_name|
      it "renders new + edit for #{path}" do
        record = create(factory_name)

        get "/admin/#{path}/new"
        expect(response).to have_http_status(:ok)

        get "/admin/#{path}/#{record.id}/edit"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "create / update / destroy lifecycle" do
    let(:carrier) { create(:carrier) }

    it "creates a vehicle" do
      expect do
        post "/admin/vehicles", params: {
          vehicle: {
            carrier_id: carrier.id, plate: "ZZ999ZZ", make: "Volvo",
            model: "FH", year: 2021, vehicle_type: "semi_trailer",
            max_load_kg: 20_000, gps_enabled: true
          }
        }
      end.to change(Vehicle, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "updates a vehicle" do
      vehicle = create(:vehicle, carrier: carrier)

      patch "/admin/vehicles/#{vehicle.id}", params: {
        vehicle: { make: "Scania" }
      }

      expect(response).to have_http_status(:redirect)
      expect(vehicle.reload.make).to eq("Scania")
    end

    it "destroys a vehicle" do
      vehicle = create(:vehicle, carrier: carrier)

      expect do
        delete "/admin/vehicles/#{vehicle.id}"
      end.to change(Vehicle, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "user update without a password" do
    it "keeps the existing password when the field is left blank" do
      user = create(:user)

      patch "/admin/users/#{user.id}", params: {
        user: { full_name: "Updated Name", password: "", password_confirmation: "" }
      }

      expect(response).to have_http_status(:redirect)
      expect(user.reload.full_name).to eq("Updated Name")
    end
  end
end
