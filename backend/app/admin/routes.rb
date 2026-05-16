ActiveAdmin.register Route do
  permit_params :shipment_id, :provider, :distance_m, :duration_s, :polyline, :calculated_at

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

  form do |f|
    f.inputs do
      f.input :shipment
      f.input :provider
      f.input :distance_m
      f.input :duration_s
      f.input :polyline
      f.input :calculated_at
    end
    f.actions
  end
end
