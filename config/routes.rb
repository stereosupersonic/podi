require "sidekiq/web"

Sidekiq::Web.app_url = "/" # back link from sidekiq to the application

Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users

  devise_scope :user do
    get "login", to: "devise/sessions#new"
  end

  namespace :admin do
    resources :episodes, only: %w[index edit update new create]
    resources :events, only: %w[index show]
    resource :setting, only: %w[edit update]
  end

  resources :episodes, only: %i[show index], param: :slug

  root to: "welcome#index"

  get "about", to: "welcome#about", as: :about
  get "imprint", to: "welcome#imprint", as: :imprint
  get "privacy", to: "welcome#privacy", as: :privacy

  get "/sitemap.xml.gz", to: redirect("https://wartenberger-podcast.s3.amazonaws.com/sitemap.xml.gz")
  # episode shortcut /006 or /2
  get ":id", to: "welcome#epsiode", constraints: {id: /\d+/}
end
