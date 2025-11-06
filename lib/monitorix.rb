# frozen_string_literal: true

require_relative "monitorix/version"
require_relative "monitorix/engine"

module Monitorix
  autoload :Config, "monitorix/config"
  autoload :RequestTracker, "monitorix/request_tracker"
  autoload :Layer, "monitorix/layer"
  autoload :Subscriber, "monitorix/subscriber"
  autoload :Normalizers, "monitorix/normalizers"

  module Middleware
    autoload :RequestTracker, "monitorix/middleware/request_tracker"
  end

  module Plugin
    autoload :ActionController, "monitorix/plugin/action_controller"
    autoload :ActionView, "monitorix/plugin/action_view"
    autoload :ActiveRecord, "monitorix/plugin/active_record"
    autoload :ActiveJob, "monitorix/plugin/active_job"
  end

  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end

    def configure
      config_path = Rails.root.join("config", "monitorix.yml")
      if File.exist?(config_path)
        yaml_config = YAML.load_file(config_path, aliases: true)[Rails.env] || {}
        config.load_from_hash(yaml_config)
      end
      config.load_from_env
    end

    def install!
      return if @installed

      Plugin::ActionController.install
      Plugin::ActionView.install
      Plugin::ActiveRecord.install
      Plugin::ActiveJob.install

      @installed = true
    end

    # Get the current request being tracked
    def current_request
      Thread.current[:monitorix_request]
    end

    # Set the current request being tracked
    def current_request=(request)
      Thread.current[:monitorix_request] = request
    end

    # Track a new request
    def trace_request(endpoint, &block)
      request = RequestTracker.new(endpoint)
      self.current_request = request
      request.start!

      result = block.call

      request.finish!
      result
    ensure
      self.current_request = nil
    end

    # Track a layer within the current request
    def trace_layer(type, name, **options, &block)
      request = current_request
      return yield if request.nil?

      layer = Layer.new(type, name, **options)
      request.start_layer(layer)

      result = yield

      request.stop_layer
      result
    rescue StandardError => e
      request&.record_error(e)
      raise
    end
  end
end
