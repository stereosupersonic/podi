Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  devise_for :users

  devise_scope :user do
    get "login", to: "devise/sessions#new"
  end

  get "/404" => "errors#not_found"
  get "/500" => "errors#internal_error"
  get "/502" => "errors#internal_error"
  get "/422" => "errors#unprocessable_entity"
  get "/503" => "errors#internal_error"

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
end
