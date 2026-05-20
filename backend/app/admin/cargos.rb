ActiveAdmin.register Cargo do
  permit_params :shipper_id, :status, :pickup_address, :delivery_address,
                :pickup_zone, :delivery_zone, :pickup_window_start, :pickup_window_end,
                :cargo_description, :weight_kg, :volume_cm3, :declared_value_cents,
                :cancellation_reason

  filter :shipper
  filter :status, as: :select, collection: Cargo::STATUSES
  filter :pickup_window_start
  filter :weight_kg

  index do
    selectable_column
    id_column
    column :shipper
    column :status
    column :pickup_zone
    column :delivery_zone
    column :pickup_window_start
    column :pickup_window_end
    column :weight_kg
    column :volume_cm3
    column :declared_value_cents
    actions
  end

  show do
    attributes_table do
      row :id
      row :shipper
      row :status
      row :pickup_address
      row :delivery_address
      row :pickup_zone
      row :delivery_zone
      row :pickup_window_start
      row :pickup_window_end
      row :cargo_description
      row :weight_kg
      row :volume_cm3
      row :declared_value_cents
      row :cancelled_at
      row :cancellation_reason
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :shipper
      f.input :status, as: :select, collection: Cargo::STATUSES
      f.input :pickup_address
      f.input :delivery_address
      f.input :pickup_zone
      f.input :delivery_zone
      f.input :pickup_window_start
      f.input :pickup_window_end
      f.input :cargo_description
      f.input :weight_kg, min: 0
      f.input :volume_cm3
      f.input :declared_value_cents
      f.input :cancellation_reason
    end
    f.actions
  end
end
