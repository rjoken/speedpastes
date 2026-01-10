Rails.application.routes.draw do
  root "home#index"

  get "/favicon.ico", to: redirect("/assets/favicon.ico")

  get "/signup", to: "registrations#new"
  post "/signup", to: "registrations#create"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  get "/u/:id_or_username", to: "profiles#show", as: :profile

  get "/privacy", to: "pages#privacy", as: :privacy
  get "/terms", to: "pages#terms", as: :terms

  get "/profiles", to: "profiles#index", as: :profiles

  get "/pastes", to: "pastes#index", as: :pastes

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

  resource :scratchpad, only: [ :show, :update ]

  get "/account_change/:token", to: "account_changes#show", as: :account_change

  resources :pastes, except: [ :index, :show ]

  namespace :admin do
    resources :users, param: :username, only: [] do
      post :invite_codes, action: :generate_invite_codes
      get :invite_codes, action: :invite_codes
      delete :ban
      delete :remove_avatar
    end
  end

  match "/400", to: "errors#show", via: :all, defaults: { code: 400, message: "Bad Request" }
  match "/404", to: "errors#show", via: :all, defaults: { code: 404, message: "Not Found" }
  match "/406", to: "errors#show", via: :all, defaults: { code: 406, message: "Not Acceptable" }
  match "/422", to: "errors#show", via: :all, defaults: { code: 422, message: "Unprocessable Entity" }
  match "/500", to: "errors#show", via: :all, defaults: { code: 500, message: "Internal Server Error" }

  get "/raw/:shortcode", to: "pastes#raw", as: :raw_paste

  # MUST BE LAST: shortcode paste URL like /uUyG6pZ
  get "/:shortcode", to: "pastes#show", as: :short_paste
end
