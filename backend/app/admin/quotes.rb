ActiveAdmin.register Quote do
  permit_params :cargo_offer_id, :carrier_id, :transport_window_id, :amount_cents,
                :currency, :status, :expires_at

  filter :cargo_offer
  filter :carrier
  filter :status, as: :select, collection: Quote::STATES
  filter :expires_at

  index do
    selectable_column
    id_column
    column :cargo_offer
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
      row :cargo_offer
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
      f.input :cargo_offer
      f.input :carrier
      f.input :transport_window
      f.input :amount_cents
      f.input :currency
      f.input :status, as: :select, collection: Quote::STATES
      f.input :expires_at
    end
    f.actions
  end
end
