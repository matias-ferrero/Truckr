ActiveAdmin.register Vehicle do
  actions :index, :show
  config.batch_actions = false

  filter :carrier_legal_name, as: :string, label: "Carrier legal name"
  filter :plate
  filter :vehicle_type, as: :select, collection: Vehicle::VEHICLE_TYPES
  filter :gps_enabled

  index do
    selectable_column
    id_column
    column :carrier
    column :plate
    column :capacity_kg
    column :vehicle_type
    column :gps_enabled
    actions
  end

  show do
    attributes_table do
      row :id
      row :carrier
      row :plate
      row :capacity_kg
      row :vehicle_type
      row :gps_enabled
      row :created_at
      row :updated_at
    end
  end
end
