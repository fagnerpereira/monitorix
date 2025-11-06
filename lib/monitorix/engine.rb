# frozen_string_literal: true

module Monitorix
  class Engine < ::Rails::Engine
    isolate_namespace Monitorix

    config.generators do |g|
      g.test_framework :test_unit
      g.assets false
      g.helper false
    end

    # Auto-load the engine's lib directory
    config.autoload_paths << File.expand_path("../", __dir__)
    config.autoload_paths << File.expand_path("app", __dir__)

    # Explicitly set paths for the engine
    config.paths["app/controllers"] = "lib/monitorix/app/controllers"
    config.paths["app/models"] = "lib/monitorix/app/models"
    config.paths["app/views"] = "lib/monitorix/app/views"

    # Initialize Monitorix when Rails boots
    initializer "monitorix.configure" do |app|
      # Load configuration
      Monitorix.configure

      # Install instrumentation after Rails initialization
      config.after_initialize do
        Monitorix.install! unless Monitorix.config.disabled?
      end
    end

    # Add middleware for request tracking
    initializer "monitorix.middleware" do |app|
      unless Monitorix.config.disabled?
        app.middleware.use Monitorix::Middleware::RequestTracker
      end
    end

    # Define routes for the engine
    routes do
      root "dashboard#index"

      resources :requests, only: [:index, :show]
      resources :errors, only: [:index, :show]
      resources :background_jobs, only: [:index, :show]
      resources :slow_queries, only: [:index]
      resources :code_suggestions, only: [:index]

      get "endpoints", to: "endpoints#index"
      get "endpoints/:id", to: "endpoints#show", as: :endpoint
    end
  end
end
