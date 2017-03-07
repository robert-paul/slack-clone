Rails.application.routes.draw do
  resources :chatrooms
  devise_for :users
  root to: "chatrooms#index"
end
