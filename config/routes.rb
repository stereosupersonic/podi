Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Custom authentication routes
  get "login", to: "users/sessions#new", as: :login
  post "login", to: "users/sessions#create"
  delete "logout", to: "users/sessions#destroy", as: :logout

  # Alias for compatibility with existing views
  get "users/sign_out", to: "users/sessions#destroy", as: :destroy_user_session

  namespace :admin do
    resources :statistics, only: %w[index]
    resources :episodes, only: %w[index show edit update new create]
    resources :events, only: %w[index show]
    resource :setting, only: %w[edit update]
    resource :info, only: %w[show] do
      post :trigger_exception
    end
  end

  resources :episodes, only: %i[show index], param: :slug

  root to: "welcome#index"

  get "about", to: "welcome#about", as: :about
  get "imprint", to: "welcome#imprint", as: :imprint
  get "privacy", to: "welcome#privacy", as: :privacy
  get "ready", to: "welcome#ready", as: :ready

  get "/sitemap.xml.gz", to: redirect("https://wartenberger-podcast.s3.amazonaws.com/sitemap.xml.gz")
  # episode shortcut /006 or /2
  get ":id", to: "welcome#epsiode", constraints: { id: /\d+/ }

  get "up", to: "welcome#ready"
end
