# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create(:user) }

  before { stub_connection current_user: user }

  it "subscribes the authenticated user to their personal stream" do
    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user)
  end

  it "delivers a publisher broadcast to the subscribed user" do
    subscribe

    expect {
      Notifications::Publisher.publish(
        user_id: user.id, type: :ping, payload: { message: "hi" }
      )
    }.to have_broadcasted_to(user).from_channel(NotificationsChannel)
  end
end
