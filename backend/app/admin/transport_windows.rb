ActiveAdmin.register TransportWindow do
  permit_params :vehicle_id,
                :origin_address, :origin_locality, :origin_admin_area, :origin_lat, :origin_lng,
                :destination_address, :destination_locality, :destination_admin_area,
                :destination_lat, :destination_lng,
                :pickup_radius_km, :dropoff_radius_km,
                :price_per_km, :max_km, :active, :available_from, :available_to

  filter :vehicle
  filter :origin_locality
  filter :origin_admin_area
  filter :destination_locality
  filter :destination_admin_area
  filter :pickup_radius_km
  filter :dropoff_radius_km
  filter :active
  filter :available_from
  filter :available_to

  index do
    selectable_column
    id_column
    column :vehicle
    column(:carrier) { |tw| tw.carrier }
    column(:origin) { |tw| "#{tw.origin_locality}, #{tw.origin_admin_area}" }
    column(:destination) { |tw| tw.destination_locality.present? ? "#{tw.destination_locality}, #{tw.destination_admin_area}" : "—" }
    column :pickup_radius_km
    column :dropoff_radius_km
    column :price_per_km
    column :max_km
    column :active
    column :available_from
    column :available_to
    actions
  end

  show do
    attributes_table do
      row :id
      row :vehicle
      row :carrier
      row :origin_address
      row :origin_locality
      row :origin_admin_area
      row :origin_lat
      row :origin_lng
      row :pickup_radius_km
      row :destination_address
      row :destination_locality
      row :destination_admin_area
      row :destination_lat
      row :destination_lng
      row :dropoff_radius_km
      row :price_per_km
      row :max_km
      row :active
      row :available_from
      row :available_to
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :vehicle
      f.input :origin_address
      f.input :origin_locality
      f.input :origin_admin_area
      f.input :origin_lat
      f.input :origin_lng
      f.input :pickup_radius_km
      f.input :destination_address
      f.input :destination_locality
      f.input :destination_admin_area
      f.input :destination_lat
      f.input :destination_lng
      f.input :dropoff_radius_km
      f.input :price_per_km, min: 0
      f.input :max_km
      f.input :active
      f.input :available_from
      f.input :available_to
    end
    f.actions
  end
end
