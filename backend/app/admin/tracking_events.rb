ActiveAdmin.register TrackingEvent do
  actions :index, :show

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
end
