Rails.application.routes.draw do
  devise_for :users

  root to: 'parameters#new'
  # devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }, skip: [:session]

  resources :parameters, only: [:create, :show, :new, :delete]
  resources :bookings, only: [:create, :index, :show, :delete]
  resources :users, only: [:show]
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # , :skip => [:sessions, :registrations]

  # devise_scope :user do
  #   get    "sign-in",  to: "devise/sessions#new",         as: :new_user_session
  #   post   "sign-in",  to: "devise/sessions#create",      as: :user_session
  #   delete "sign-out", to: "devise/sessions#destroy",     as: :destroy_user_session

  #   get    "sign-up",  to: "devise/registrations#new",    as: :new_user_registration
  #   post   "sign-up",  to: "devise/registrations#create", as: :user_registration
  # end
end
