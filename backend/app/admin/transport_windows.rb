ActiveAdmin.register TransportWindow do
  permit_params :vehicle_id, :origin_zone, :destination_zone, :price_per_km,
                :max_km, :active, :available_from, :available_to

  filter :vehicle
  filter :origin_zone
  filter :destination_zone
  filter :active
  filter :available_from
  filter :available_to

  index do
    selectable_column
    id_column
    column :vehicle
    column(:carrier) { |tw| tw.carrier }
    column :origin_zone
    column :destination_zone
    column :price_per_km
    column :max_km
    column :active
    column :available_from
    column :available_to
    actions
  end

  show do
    attributes_table do
      row :id
      row :vehicle
      row :carrier
      row :origin_zone
      row :destination_zone
      row :price_per_km
      row :max_km
      row :active
      row :available_from
      row :available_to
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :vehicle
      f.input :origin_zone
      f.input :destination_zone
      f.input :price_per_km, min: 0
      f.input :max_km
      f.input :active
      f.input :available_from
      f.input :available_to
    end
    f.actions
  end
end
