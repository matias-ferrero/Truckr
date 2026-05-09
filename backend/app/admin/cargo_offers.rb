ActiveAdmin.register CargoOffer do
  actions :index, :show

  filter :shipper
  filter :pickup_date
  filter :weight_kg

  index do
    selectable_column
    id_column
    column :shipper
    column :pickup_address
    column :delivery_address
    column :pickup_date
    column :weight_kg
    column :volume_cm3
    column :declared_value_cents
    actions
  end

  show do
    attributes_table do
      row :id
      row :shipper
      row :pickup_address
      row :delivery_address
      row :pickup_date
      row :cargo_description
      row :weight_kg
      row :volume_cm3
      row :declared_value_cents
      row :created_at
      row :updated_at
    end
  end
end
