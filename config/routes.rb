require "sidekiq/web"

Rails.application.routes.draw do
  constraints ->(request) { User.find_by(id: request.session[:user_id])&.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # Custom authentication routes
  get "login", to: "users/sessions#new", as: :login
  post "login", to: "users/sessions#create"
  delete "logout", to: "users/sessions#destroy", as: :logout

  namespace :admin do
    resources :statistics, only: %w[index]
    resources :episodes, only: %w[index show edit update new create]
    resources :events, only: %w[index show]
    resource :setting, only: %w[edit update]
    resource :info, only: %w[show] do
      post :trigger_exception
    end
  end

  get "episodes/search", to: "episodes#search", as: :search_episodes
  resources :episodes, only: %i[show index], param: :slug

  root to: "welcome#index"
  get "up" => "rails/health#show", :as => :rails_health_check
  get "about", to: "welcome#about", as: :about
  get "imprint", to: "welcome#imprint", as: :imprint
  get "privacy", to: "welcome#privacy", as: :privacy
  get "ready", to: redirect("/up")

  get "sitemap.xml" => "sitemaps#show", as: :sitemap, defaults: { format: :xml }
  # episode shortcut /006 or /2
  get ":id", to: "welcome#epsiode", constraints: { id: /\d+/ }
end
