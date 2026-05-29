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
    patch "auth/me",      to: "auth#update_me"

    # Sessions inherit from Devise::SessionsController and so must live
    # inside a devise_scope block — Warden + devise-jwt need the scope to
    # resolve `:user` for the dispatcher/revocation middleware.
    devise_scope :user do
      post   "auth/login",  to: "sessions#create"
      delete "auth/logout", to: "sessions#destroy"
    end

    # Shipper publishes a Cargo and manages its lifecycle (US27 / REQ-BE-00032).
    # `matches` returns Haversine-compatible TransportWindows for a Cargo
    # (US52 / REQ-BE-00039 — public marketplace endpoint retired in ADR-014).
    resources :cargos, only: %i[index show create update destroy] do
      get :matches, on: :member
    end

    # A Carrier-directed bid against an existing Cargo (US7 / REQ-FE-00015).
    # The request body carries a `cargo_id` — no inline Cargo creation.
    resources :cargo_offers, only: %i[index create]

    # Authenticated CRUD on the current carrier's fleet (REQ-BE-00009 / REQ-BE-00010).
    # Declared before the public `:carrier_id` resource so `/carriers/me/...` wins
    # over the wildcard.
    scope path: "carriers/me", as: :me do
      resources :vehicles, only: %i[index show create update destroy],
                           module: "carriers/me"
      resources :transport_windows, only: %i[index show create update destroy],
                                    module: "carriers/me"
      resources :shipments, only: %i[index], module: "carriers/me"
    end

    scope path: "carriers/me/cargo-offers", as: :me_cargo_offers, module: "carriers/me" do
      get "/", to: "cargo_offers#index"
      post "/:id/accept", to: "cargo_offers#accept"
      post "/:id/reject", to: "cargo_offers#reject"
    end

    # Authenticated Shipper-side reads (REQ-BE-00035 §3.2).
    scope path: "shippers/me", as: :shipper_me do
      resources :shipments, only: %i[index], module: "shippers/me"
    end

    # Multi-role shipment detail (REQ-BE-00035 §3.3). Authorisation is
    # Pundit-gated and translates a denied policy into 404 (not 403) — see
    # Api::ShipmentsController. Nested under it: the Shipper-only payment
    # checkout (REQ-BE-00033 / US8).
    resources :shipments, only: %i[show] do
      resources :payments, only: %i[create], module: "shipments"
    end

    # Public read endpoints — anyone can browse a carrier's fleet.
    resources :carriers, only: %i[show] do
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
