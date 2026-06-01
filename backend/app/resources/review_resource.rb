# frozen_string_literal: true

# Alba resource for a Review. Shared by the creation endpoints (US20 / US30)
# and the listing endpoints (US26 / US54). `authored_by` is exposed as its
# string enum value ("shipper" | "carrier") so consumers can tell the two
# review directions apart.
class ReviewResource
  include Alba::Resource

  attributes :id, :rating, :body, :created_at

  attribute :authored_by do |review|
    Review::AUTHORS.fetch(review.authored_by.to_sym, review.authored_by)
  end
end
