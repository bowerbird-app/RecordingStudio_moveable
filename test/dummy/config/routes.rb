Rails.application.routes.draw do
  mount RecordingStudioApi::Engine, at: "/recording_studio_api"
  devise_for :users

  # RecordingStudio engine is data/API-focused and has no browser root route.
  # Keep legacy links working by redirecting the base path to the app home.
  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioAccessible::Engine, at: "/recording_studio_accessible"
  mount RecordingStudioMoveable::Engine, at: "/recording_studio_moveable", as: :recording_studio_moveable

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  patch "workspace_selection", to: "workspace_selections#update", as: :workspace_selection

  get "data", to: "data#index", as: :data

  get "docs/access", to: "moveable_docs#access", as: :access_docs
  get "docs/setup", to: "moveable_docs#setup", as: :setup_docs
  get "docs/methods", to: "moveable_docs#methods", as: :methods_docs
  get "docs/redirects", to: "moveable_docs#redirects", as: :redirects_docs
  get "docs/api", to: "moveable_docs#api", as: :api_docs

  resources :events, only: :index
  resources :recording_studio_folders, only: :show
  resources :recording_studio_pages, only: :show
end
