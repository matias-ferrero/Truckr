ActiveAdmin.register Route do
  actions :index, :show

  filter :shipment_id
  filter :provider
  filter :calculated_at

  index do
    selectable_column
    id_column
    column :shipment_id
    column :provider
    column :distance_m
    column :duration_s
    column :calculated_at
    actions
  end
end
