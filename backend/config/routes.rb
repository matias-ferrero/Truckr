Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # Devise mount for the domain User. Sessions go through Api::SessionsController
  # (Devise::SessionsController subclass) wrapped by devise-jwt; register stays
  # custom because of the role-attach side effect. The skip keeps Devise's
  # default HTML routes off the surface — the `devise_for :users` declaration
  # is still required so that `sign_in`/`sign_out` can resolve a scope and so
  # that the devise-jwt middleware sees the `:user` Warden scope.
  devise_for :users, skip: :all

  namespace :api do
    post "auth/register", to: "auth#register"
    get  "auth/me",       to: "auth#me"

    # Sessions inherit from Devise::SessionsController and so must live
    # inside a devise_scope block — Warden + devise-jwt need the scope to
    # resolve `:user` for the dispatcher/revocation middleware.
    devise_scope :user do
      post   "auth/login",  to: "sessions#create"
      delete "auth/logout", to: "sessions#destroy"
    end

    # Authenticated CRUD on the current carrier's fleet (REQ-BE-00009 / REQ-BE-00010).
    # Declared before the public `:carrier_id` resource so `/carriers/me/...` wins
    # over the wildcard.
    scope path: "carriers/me", as: :me do
      resources :vehicles, only: %i[index show create update destroy],
                           module: "carriers/me"
    end

    # Public read endpoints — anyone can browse a carrier's fleet.
    resources :carriers, only: [] do
      resources :vehicles, only: %i[index show], controller: "carriers/vehicles"
    end
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
