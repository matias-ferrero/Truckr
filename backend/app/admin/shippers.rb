ActiveAdmin.register Shipper do
  permit_params :user_id, :company_name, :tax_id, :billing_address

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

  form do |f|
    f.inputs do
      f.input :user
      f.input :company_name
      f.input :tax_id
      f.input :billing_address
    end
    f.actions
  end
end
