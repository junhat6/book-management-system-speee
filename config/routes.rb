Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check
  resources :books, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    resources :rentals, only: [ :create ]
    resources :items, controller: "book_items", only: [ :create, :destroy ]
  end
  resources :rentals, only: [ :index, :update ]
  get "signup", to: "users#new"
  resources :users, only: [ :create ]
  resource :session
  resources :passwords, param: :token, only: [ :new, :create, :edit, :update ]
  root "books#index"
end
