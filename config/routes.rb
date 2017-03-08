Rails.application.routes.draw do

  resources :chatrooms do
    resource :chatroom_users
    resources :messages
  end

  devise_for :users

  root to: "chatrooms#index"
end
