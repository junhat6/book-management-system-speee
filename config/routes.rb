Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  resources :books, only: [ :index ]
  root "books#index"
end
