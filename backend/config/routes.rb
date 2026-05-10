Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # Devise mount for the domain User. We ship our own controllers (Api::AuthController),
  # so the default Devise routes are skipped — but the `devise_for :users` declaration
  # is still required so that `sign_in`/`sign_out` can resolve a scope.
  devise_for :users, skip: :all

  namespace :api do
    get    "auth/csrf",     to: "auth#csrf"
    post   "auth/register", to: "auth#register"
    post   "auth/login",    to: "auth#login"
    delete "auth/logout",   to: "auth#logout"
    get    "auth/me",       to: "auth#me"
  end

  # OpenAPI / Swagger UI (dev/test only — production gets it via separate deploy).
  if Rails.env.development? || Rails.env.test?
    mount Rswag::Ui::Engine  => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
