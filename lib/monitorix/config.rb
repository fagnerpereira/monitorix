# frozen_string_literal: true

module Monitorix
  class Config
    attr_accessor :disabled
    attr_accessor :ignored_endpoints
    attr_accessor :ignored_errors
    attr_accessor :sample_rate
    attr_accessor :slow_request_threshold
    attr_accessor :slow_query_threshold
    attr_accessor :enable_code_analysis
    attr_accessor :database_path

    def initialize
      @disabled = false
      @ignored_endpoints = []
      @ignored_errors = [
        "ActionController::RoutingError",
        "ActiveRecord::RecordNotFound"
      ]
      @sample_rate = 1.0 # Track 100% of requests by default
      @slow_request_threshold = 500 # milliseconds
      @slow_query_threshold = 100 # milliseconds
      @enable_code_analysis = true
      @database_path = Rails.root.join("tmp", "monitorix.sqlite3")
    end

    def disabled?
      @disabled == true
    end

    def should_track_request?(endpoint)
      return false if @ignored_endpoints.include?(endpoint)
      return true if @sample_rate >= 1.0

      rand < @sample_rate
    end

    def should_track_error?(error)
      !@ignored_errors.include?(error.class.name)
    end

    def load_from_hash(hash)
      hash.each do |key, value|
        setter = "#{key}="
        send(setter, value) if respond_to?(setter)
      end
    end

    def load_from_env
      @disabled = ENV["MONITORIX_DISABLED"] == "true" if ENV["MONITORIX_DISABLED"]
      @sample_rate = ENV["MONITORIX_SAMPLE_RATE"].to_f if ENV["MONITORIX_SAMPLE_RATE"]
      @slow_request_threshold = ENV["MONITORIX_SLOW_REQUEST_THRESHOLD"].to_i if ENV["MONITORIX_SLOW_REQUEST_THRESHOLD"]
      @slow_query_threshold = ENV["MONITORIX_SLOW_QUERY_THRESHOLD"].to_i if ENV["MONITORIX_SLOW_QUERY_THRESHOLD"]
    end
  end
end
