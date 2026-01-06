Rails.application.routes.draw do
  root "home#index"

  get "/signup", to: "registrations#new"
  post "/signup", to: "registrations#create"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  get "/u/:id_or_username", to: "profiles#show", as: :profile

  resource :settings, only: [ :show, :update ] do
    post :data_export
    delete :account

    delete :avatar
    post :import_pastebin
  end

  resource :settings, only: [ :show ] do
    patch :password
    patch :email
    patch :username
  end

  get "/account_change/:token", to: "account_changes#show", as: :account_change

  resources :pastes, except: [ :index, :show ]

  namespace :admin do
    resources :users, param: :username, only: [] do
      post :invite_codes, action: :generate_invite_codes
      get :invite_codes, action: :invite_codes
      delete :ban
    end
  end

  get "/raw/:shortcode", to: "pastes#raw", as: :raw_paste

  # MUST BE LAST: shortcode paste URL like /uUyG6pZ
  get "/:shortcode", to: "pastes#show", as: :short_paste
end
