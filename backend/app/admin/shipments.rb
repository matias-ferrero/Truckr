ActiveAdmin.register Shipment do
  permit_params :cargo_offer_id, :status, :accepted_at, :picked_up_at, :delivered_at,
                :discarded_at
  config.sort_order = "created_at_desc"

  filter :status, as: :select, collection: Shipment::STATUSES
  filter :created_at

  index do
    selectable_column
    id_column
    column :cargo_offer_id
    column :status
    column :accepted_at
    column :picked_up_at
    column :delivered_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :cargo_offer_id
      row :status
      row :accepted_at
      row :picked_up_at
      row :delivered_at
      row :discarded_at
      row :created_at
      row :updated_at
    end

    panel "Tracking log (most recent 100)" do
      table_for shipment.tracking_events.recent(100) do
        column :recorded_at
        column :kind
        column :from_status
        column :to_status
        column :lat
        column :lng
        column(:metadata) { |e| e.metadata.to_json if e.metadata }
      end
    end

    panel "Route" do
      if shipment.route
        attributes_table_for shipment.route do
          row :provider
          row :distance_m
          row :duration_s
          row :calculated_at
          row(:polyline) { |r| r.polyline.to_s.truncate(120) }
        end
      else
        para "No route calculated yet."
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :cargo_offer
      f.input :status, as: :select, collection: Shipment::STATUSES
      f.input :accepted_at
      f.input :picked_up_at
      f.input :delivered_at
      f.input :discarded_at
    end
    f.actions
  end
end
