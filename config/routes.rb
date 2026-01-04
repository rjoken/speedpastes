Rails.application.routes.draw do
  root "home#index"

  get "/signup", to: "registrations#new"
  post "/signup", to: "registrations#create"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  get "/u/:username", to: "profiles#show", as: :profile

  resource :settings, only: [ :show, :update ] do
    post :data_export
    delete :account
  end

  resources :pastes, except: [ :index, :show ]

  # MUST BE LAST: shortcode paste URL like /uUyG6pZ
  get "/:shortcode", to: "pastes#show", constraints: { shortcode: /[A-Za-z0-9_-]{6,12}/ }, as: :short_paste
end
