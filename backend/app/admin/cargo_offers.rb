ActiveAdmin.register CargoOffer do
  permit_params :shipper_id, :pickup_address, :delivery_address, :pickup_date,
                :cargo_description, :weight_kg, :volume_cm3, :declared_value_cents

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

  form do |f|
    f.inputs do
      f.input :shipper
      f.input :pickup_address
      f.input :delivery_address
      f.input :pickup_date
      f.input :cargo_description
      f.input :weight_kg, min: 0
      f.input :volume_cm3
      f.input :declared_value_cents
    end
    f.actions
  end
end
