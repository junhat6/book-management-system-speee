Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  resources :books, only: [ :index, :show ]
  root "books#index"
end
