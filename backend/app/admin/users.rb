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
    column :impersonate do |user|
      link_to "Impersonate",
              impersonate_admin_user_path(user),
              class: "member_link",
              target: "_blank",
              rel: "noopener"
    end
    actions
  end

  action_item :impersonate, only: :show do
    link_to "Impersonate",
            impersonate_admin_user_path(user),
            target: "_blank",
            rel: "noopener"
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

  # Mints an impersonation JWT and redirects to the SPA's /impersonate route
  # with the token in the URL fragment. Fragments are not sent to servers, so
  # the raw JWT never appears in any request log between admin and SPA.
  member_action :impersonate, method: :get do
    user = User.find(params[:id])
    token = ImpersonationTokenService.new(user, current_admin_user).call
    Rails.logger.warn(
      "[IMPERSONATION] admin=#{current_admin_user.email} " \
      "impersonated user_id=#{user.id} email=#{user.email}"
    )

    frontend_url = ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173")
                      .split(",").map(&:strip).first
    redirect_to "#{frontend_url}/impersonate#token=#{token}",
                allow_other_host: true
  end
end
