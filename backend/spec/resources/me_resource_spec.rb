require "rails_helper"

RSpec.describe MeResource do
  it "serializes a user with carrier + shipper" do
    user = create(:user, :with_carrier, :with_shipper, email: "x@example.com")
    json = JSON.parse(MeResource.new(user).serialize)

    expect(json["email"]).to eq("x@example.com")
    expect(json["roles"]).to contain_exactly("carrier", "shipper")
    expect(json["carrier"]).to be_a(Hash)
    expect(json["shipper"]).to be_a(Hash)
  end

  it "returns nil for missing profile rows" do
    user = create(:user, :with_shipper)
    json = JSON.parse(MeResource.new(user).serialize)

    expect(json["carrier"]).to be_nil
    expect(json["roles"]).to eq(["shipper"])
  end
end
