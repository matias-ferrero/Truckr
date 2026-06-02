FactoryBot.define do
  factory :review do
    association :shipment, factory: %i[shipment delivered]
    rating { 5 }
    body   { "Excelente experiencia, todo en tiempo y forma." }
    # US30 owns the carrier→shipper direction; default to it.
    # Enum keys (`:carrier_authored` / `:shipper_authored`) — NOT the DB values
    # ("carrier" / "shipper"), which Rails' enum= rejects with ArgumentError.
    authored_by { :carrier_authored }

    # Derive the carrier/shipper from the shipment's cargo_offer so the row is
    # internally consistent with the trade it reviews.
    shipper { shipment.cargo_offer.cargo.shipper }
    carrier { shipment.cargo_offer.carrier }

    trait :carrier_authored do
      authored_by { :carrier_authored }
    end

    trait :shipper_authored do
      authored_by { :shipper_authored }
    end
  end
end
