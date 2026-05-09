ActiveAdmin.register Shipper do
  actions :index, :show
  config.batch_actions = false

  filter :user_email, as: :string, label: "User email"
  filter :company_name
  filter :tax_id

  index do
    selectable_column
    id_column
    column :user
    column :company_name
    column :tax_id
    column :billing_address
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :company_name
      row :tax_id
      row :billing_address
      row :created_at
      row :updated_at
    end
  end
end
