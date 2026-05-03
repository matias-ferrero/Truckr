require "rails_helper"

RSpec.describe "RSpec pipeline smoke", type: :request do
  it "loads the Rails environment" do
    expect(defined?(Rails)).to eq("constant")
    expect(Rails.env).to eq("test")
  end

  it "responds 200 on /up" do
    get "/up"
    expect(response).to have_http_status(:ok)
  end
end
