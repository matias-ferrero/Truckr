# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }
  let(:token) { Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first }

  it "accepts a connection with a valid JWT in the query string" do
    connect params: { token: token }
    expect(connection.current_user).to eq(user)
  end

  it "rejects a connection with no token" do
    expect { connect }.to have_rejected_connection
  end

  it "rejects a connection with a malformed token" do
    expect { connect params: { token: "not-a-jwt" } }.to have_rejected_connection
  end

  it "rejects a connection once the token has been revoked" do
    revoked = token
    user.update_column(:jti, SecureRandom.uuid) # rotate jti → old token is revoked
    expect { connect params: { token: revoked } }.to have_rejected_connection
  end
end
