require "rails_helper"

RSpec.describe ImpersonationTokenService do
  let(:user) { create(:user) }
  let(:admin) do
    AdminUser.create!(
      email: "admin@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  it "encodes a JWT signed with the warden-jwt secret carrying the user's jti" do
    token = described_class.new(user, admin).call

    decoded, = JWT.decode(token, Warden::JWTAuth.config.secret, true, algorithm: "HS256")

    expect(decoded["sub"]).to eq(user.id.to_s)
    expect(decoded["jti"]).to eq(user.jti)
    expect(decoded["scp"]).to eq("user")
    expect(decoded["impersonated_by"]).to eq(admin.email)
    expect(decoded["exp"]).to be > Time.now.to_i
  end

  it "expires within the configured TTL" do
    token = described_class.new(user, admin).call
    decoded, = JWT.decode(token, Warden::JWTAuth.config.secret, true, algorithm: "HS256")

    # Allow a little slack for clock drift between encode and assertion.
    expect(decoded["exp"] - decoded["iat"]).to eq(described_class::EXPIRATION.to_i)
  end
end
