ActiveAdmin.register CargoOffer do
  permit_params :cargo_id, :carrier_id, :transport_window_id, :amount_cents,
                :currency, :status, :expires_at

  filter :cargo
  filter :carrier
  filter :status, as: :select, collection: CargoOffer::STATES
  filter :expires_at

  index do
    selectable_column
    id_column
    column :cargo
    column :carrier
    column :transport_window
    column :amount_cents
    column :currency
    column :status
    column :expires_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :cargo
      row :carrier
      row :transport_window
      row :amount_cents
      row :currency
      row :status
      row :expires_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :cargo
      f.input :carrier
      f.input :transport_window
      f.input :amount_cents
      f.input :currency
      f.input :status, as: :select, collection: CargoOffer::STATES
      f.input :expires_at
    end
    f.actions
  end
end
