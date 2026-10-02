Rails.application.routes.draw do
  devise_for :users
# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

#  ページ番号付きの専用URL
# get "libraries/:id/page/:page", to: "libraries#list", as: "libraries_page", constraints: { id: /\d+/, page: /\d+/ }

#  通常のURL（1ページ目を表示するため、あるいはデフォルト用）

resources :libraries do
    collection do
      get "list"
    end
   resources :novels
end

 resources :users, only: [ :index, :show, :create, :new, :edit, :update, :destroy ] do
    collection do
      get "myhome"
    end
  end



  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

   # Defines the root path route ("/")
   root "users#index"
end
