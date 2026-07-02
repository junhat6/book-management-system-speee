Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  resources :books, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  get "signup", to: "users#new"
  resources :users, only: [ :create ]
  resource :session
  root "books#index"
end
