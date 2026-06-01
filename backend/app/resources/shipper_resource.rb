# frozen_string_literal: true

# Alba serializer for Shipper. Identity fields plus the headline review
# numbers shown on the public profile (US54 / REQ-BE-00045 — AC4):
#   - rating_avg:    average of carrier-authored ratings, rounded to 1 dp, or
#                    nil when the shipper has no reviews yet.
#   - reviews_count: how many carrier-authored reviews the shipper has.
#
# Both are computed on the fly from the reviews table (unlike Carrier, which
# persists denormalised columns) so the profile always reflects current data.
# Carrier→Shipper is the only direction that exists today; scoping by
# `carrier_authored` keeps the numbers correct once Shipper→Carrier (US20)
# starts writing the other direction into the same table.
class ShipperResource
  include Alba::Resource

  attributes :id, :company_name, :tax_id, :billing_address

  attribute :rating_avg do |shipper|
    avg = Review.carrier_authored.where(shipper_id: shipper.id).average(:rating)
    avg&.round(1)&.to_s
  end

  attribute :reviews_count do |shipper|
    Review.carrier_authored.where(shipper_id: shipper.id).count
  end
end
