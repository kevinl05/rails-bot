Rails.application.routes.draw do
  resources :conversations, only: [ :index, :show, :create, :destroy ] do
    resources :messages, only: [ :create ] do
      member do
        patch :feedback
      end
    end
  end

  root "conversations#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
