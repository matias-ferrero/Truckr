ActiveAdmin.register User do
  actions :index, :show
  config.batch_actions = false

  filter :email
  filter :full_name
  filter :verified_at
  filter :created_at

  index do
    selectable_column
    id_column
    column :email
    column :full_name
    column :phone
    column :verified_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :full_name
      row :phone
      row :verified_at
      row :created_at
      row :updated_at
      row :carrier
      row :shipper
    end
  end
end
