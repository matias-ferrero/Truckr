ActiveAdmin.register Shipment do
  actions :index, :show
  config.sort_order = "created_at_desc"

  filter :status, as: :select, collection: Shipment::STATUSES
  filter :created_at

  index do
    selectable_column
    id_column
    column :quote_id
    column :status
    column :picked_up_at
    column :delivered_at
    column :settled_at
    column :cancelled_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :quote_id
      row :status
      row :picked_up_at
      row :delivered_at
      row :settled_at
      row :cancelled_at
      row :cancellation_reason
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
end
