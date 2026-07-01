Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  resources :books, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  get "signup", to: "users#new"
  resources :users, only: [ :create ]
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  root "books#index"
end
