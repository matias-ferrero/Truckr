ActiveAdmin.register TrackingEvent do
  permit_params :shipment_id, :kind, :from_status, :to_status, :lat, :lng, :recorded_at

  filter :shipment_id
  filter :kind, as: :select, collection: TrackingEvent::KINDS
  filter :recorded_at

  index do
    selectable_column
    id_column
    column :shipment_id
    column :kind
    column :from_status
    column :to_status
    column :recorded_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :shipment
      f.input :kind, as: :select, collection: TrackingEvent::KINDS
      f.input :from_status
      f.input :to_status
      f.input :lat
      f.input :lng
      f.input :recorded_at
    end
    f.actions
  end
end
