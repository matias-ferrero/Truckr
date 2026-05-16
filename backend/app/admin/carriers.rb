ActiveAdmin.register Carrier do
  permit_params :user_id, :legal_name, :tax_id, :base_city, :province, :description,
                :rating_avg, :reviews_count, :completed_shipments

  filter :user_email, as: :string, label: "User email"
  filter :legal_name
  filter :tax_id
  filter :base_city
  filter :province

  index do
    selectable_column
    id_column
    column :user
    column :legal_name
    column :tax_id
    column :base_city
    column :province
    column :rating_avg
    column :completed_shipments
    actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :legal_name
      row :tax_id
      row :base_city
      row :province
      row :rating_avg
      row :completed_shipments
      row :created_at
      row :updated_at
    end

    panel "Vehicles" do
      table_for carrier.vehicles do
        column :id
        column :plate
        column :capacity_kg
        column :vehicle_type
        column :gps_enabled
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :user
      f.input :legal_name
      f.input :tax_id
      f.input :base_city
      f.input :province
      f.input :description
      f.input :rating_avg
      f.input :reviews_count
      f.input :completed_shipments
    end
    f.actions
  end
end
