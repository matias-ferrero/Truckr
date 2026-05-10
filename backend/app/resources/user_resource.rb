# frozen_string_literal: true

class UserResource
  include Alba::Resource
  attributes :id, :email, :full_name, :phone, :verified_at, :created_at
end
