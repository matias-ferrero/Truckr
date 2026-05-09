ActiveAdmin.register TransportWindow do
  actions :index, :show

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
end
