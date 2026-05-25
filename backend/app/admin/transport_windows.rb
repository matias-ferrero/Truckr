ActiveAdmin.register TransportWindow do
  permit_params :vehicle_id, :origin_province, :origin_locality,
                :destination_province, :destination_locality,
                :price_per_km, :max_km, :active, :available_from, :available_to

  filter :vehicle
  filter :origin_province
  filter :destination_province
  filter :active
  filter :available_from
  filter :available_to

  index do
    selectable_column
    id_column
    column :vehicle
    column(:carrier) { |tw| tw.carrier }
    column :origin_province
    column :origin_locality
    column :destination_province
    column :destination_locality
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
      row :origin_province
      row :origin_locality
      row :destination_province
      row :destination_locality
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
      f.input :origin_province
      f.input :origin_locality
      f.input :destination_province
      f.input :destination_locality
      f.input :price_per_km, min: 0
      f.input :max_km
      f.input :active
      f.input :available_from
      f.input :available_to
    end
    f.actions
  end
end
