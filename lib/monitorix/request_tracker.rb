# frozen_string_literal: true

module Monitorix
  class RequestTracker
    attr_reader :endpoint, :transaction_id, :started_at, :metadata
    attr_accessor :controller, :action, :http_method, :path, :status_code, :format
    attr_accessor :params, :headers, :user_agent, :ip_address

    def initialize(endpoint)
      @endpoint = endpoint
      @transaction_id = SecureRandom.uuid
      @started_at = current_time
      @finished_at = nil
      @layers = []
      @layer_stack = []
      @call_counts = Hash.new(0)
      @metadata = {}
      @errors = []
      @db_time_ms = 0
      @view_time_ms = 0
    end

    def start!
      @started_at = current_time
    end

    def finish!
      @finished_at = current_time
      persist!
    end

    def duration_ms
      return 0 if @started_at.nil?
      return (current_time - @started_at) if @finished_at.nil?

      @finished_at - @started_at
    end

    def start_layer(type, name, **options)
      layer = LayerData.new(type, name, **options)
      layer.start!

      # Track parent-child relationships
      if @layer_stack.any?
        parent = @layer_stack.last
        layer.parent = parent
        parent.children << layer
      end

      @layer_stack.push(layer)
      @layers << layer

      # Track call counts for N+1 detection
      @call_counts[layer.normalized_key] += 1

      layer
    end

    def stop_layer
      return if @layer_stack.empty?

      layer = @layer_stack.pop
      layer.finish!

      # Accumulate timing for specific layer types
      case layer.type
      when "sql"
        @db_time_ms += layer.duration_ms
      when "view", "partial"
        @view_time_ms += layer.duration_ms
      end

      layer
    end

    def current_layer
      @layer_stack.last
    end

    def root_layers
      @layers.select { |l| l.parent.nil? }
    end

    def record_error(exception)
      @errors << {
        exception: exception,
        layer: current_layer&.type
      }
    end

    def annotate(key, value)
      @metadata[key] = value
    end

    def n_plus_one_detected?
      @call_counts.any? { |_key, count| count > 5 }
    end

    def n_plus_one_queries
      @call_counts.select { |key, count| count > 5 && key.start_with?("sql:") }
    end

    private

    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
    end

    def persist!
      return unless should_persist?

      request_record = Monitorix::Request.create!(
        endpoint: @endpoint,
        controller: @controller,
        action: @action,
        http_method: @http_method,
        path: @path,
        status_code: @status_code,
        duration_ms: duration_ms,
        db_time_ms: @db_time_ms,
        view_time_ms: @view_time_ms,
        query_count: @layers.count { |l| l.type == "sql" },
        format: @format,
        transaction_id: @transaction_id,
        user_agent: @user_agent,
        ip_address: @ip_address,
        params: sanitize_params(@params),
        headers: sanitize_headers(@headers),
        metadata: @metadata
      )

      # Persist layers
      persist_layers(request_record)

      # Persist errors
      persist_errors(request_record)

      request_record
    rescue StandardError => e
      Rails.logger.error "[Monitorix] Failed to persist request: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    def persist_layers(request_record, layers = root_layers, parent_record = nil)
      layers.each do |layer|
        layer_record = Monitorix::Layer.create!(
          request: request_record,
          parent: parent_record,
          layer_type: layer.type,
          name: layer.name,
          duration_ms: layer.duration_ms,
          self_time_ms: layer.self_time_ms,
          query: layer.query,
          file: layer.file,
          line: layer.line,
          metadata: layer.metadata
        )

        # Recursively persist children
        persist_layers(request_record, layer.children, layer_record) if layer.children.any?
      end
    end

    def persist_errors(request_record)
      @errors.each do |error_data|
        Monitorix::Error.record_error(
          error_data[:exception],
          request: request_record,
          context: {
            layer: error_data[:layer],
            endpoint: @endpoint
          }
        )
      end
    end

    def should_persist?
      Monitorix.config.should_track_request?(@endpoint)
    end

    def sanitize_params(params)
      return {} if params.nil?

      # Remove sensitive parameters
      params.except(:password, :password_confirmation, :credit_card, :ssn)
    end

    def sanitize_headers(headers)
      return {} if headers.nil?

      # Keep only useful headers
      headers.slice("HTTP_ACCEPT", "HTTP_ACCEPT_LANGUAGE", "HTTP_REFERER")
    end

    # Inner class to represent layer data during collection
    class LayerData
      attr_reader :type, :name, :started_at, :finished_at, :children, :metadata
      attr_accessor :parent, :query, :file, :line

      def initialize(type, name, query: nil, file: nil, line: nil, **metadata)
        @type = type
        @name = name
        @query = query
        @file = file
        @line = line
        @metadata = metadata
        @children = []
        @parent = nil
        @started_at = nil
        @finished_at = nil
      end

      def start!
        @started_at = current_time
      end

      def finish!
        @finished_at = current_time
      end

      def duration_ms
        return 0 if @started_at.nil? || @finished_at.nil?

        @finished_at - @started_at
      end

      def self_time_ms
        total_children_time = @children.sum(&:duration_ms)
        duration_ms - total_children_time
      end

      # Normalized key for tracking call counts (for N+1 detection)
      def normalized_key
        case @type
        when "sql"
          "sql:#{normalize_sql(@query)}"
        else
          "#{@type}:#{@name}"
        end
      end

      private

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      end

      def normalize_sql(sql)
        return "" if sql.nil?

        # Basic normalization: replace numbers and strings with placeholders
        normalized = sql.gsub(/'[^']*'/, "?")
        normalized.gsub(/\b\d+\b/, "?")
      end
    end
  end
end
