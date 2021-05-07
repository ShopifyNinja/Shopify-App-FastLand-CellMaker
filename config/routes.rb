Rails.application.routes.draw do
  # Sidekiq
  require "sidekiq/web"
  require "sidekiq/cron/web"

  # Disable Sidekiq CSRF protection
  Sidekiq::Web.class_eval do
    use Rack::Protection, exception: :http_origin
  end
  mount Sidekiq::Web, at: "/sidekiq"

  root to: "home#index"
  mount ShopifyApp::Engine, at: "/"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      # Add product details
      post "product" => "products#create"
      # Get product details
      get "products/:handle" => "products#index"
      # Get report
      get "products/report" => "products#report"

      # Load settings
      get "settings" => "settings#index"
      # Save settings
      post "settings" => "settings#save"

      # Load sync logs
      get "logs" => "logs#index"
      # Sync now
      post "sync" => "products#sync"
      # Check sync
      post "sync/check" => "products#check_sync"
      # Clear all
      post "sync/clear" => "products#clear_sync"
      # Parse file
      post "file/parse" => "files#parse"
      get "file/parse/check" => "files#is_parsing"
      # Proccess Cell Maker
      get "settings/cellmaker" =>"settings#cell_maker"
      post "settings/cellmaker" =>"settings#update_cell_maker"

      # Installation
      get "themes" => "themes#index"
      post "themes/install" => "themes#install"
      get "themes/install/check" => "themes#is_installing"

      # Vh
      get "vhs" => "vhs#index"
      post "vhs/save" => "vhs#save"
      post "vhs/delete" => "vhs#delete"

      # Destination
      get "destinations" => "destinations#index"
      post "destinations/save" => "destinations#save"
      post "destinations/delete" => "destinations#delete"
      get "destinations/working" => "destinations#is_working"
    end
  end

  # Pages
  get "settings" => "home#settings"
end
