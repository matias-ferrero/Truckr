ActiveAdmin.register Quote do
  actions :index, :show

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
end
