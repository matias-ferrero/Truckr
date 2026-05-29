ActiveAdmin.register Vehicle do
  # volume_cm3 is derived from length/width/height in a before_save callback,
  # so it is intentionally not a permitted/editable param.
  permit_params :carrier_id, :plate, :make, :model, :year, :vehicle_type, :max_load_kg,
                :length_cm, :width_cm, :height_cm, :gps_enabled, :description

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

  form do |f|
    f.inputs do
      f.input :carrier
      f.input :plate
      f.input :make
      f.input :model
      f.input :year
      f.input :vehicle_type, as: :select, collection: Vehicle::VEHICLE_TYPES
      f.input :max_load_kg, min: 0
      f.input :length_cm
      f.input :width_cm
      f.input :height_cm
      f.input :gps_enabled
      f.input :description
    end
    f.actions
  end

  controller do
    # Show all vehicles in Admin (including soft-deleted) so admins can
    # inspect or restore via console. ADR-009 convention: use `with_discarded`.
    def scoped_collection
      Vehicle.with_discarded
    end
  end
end
