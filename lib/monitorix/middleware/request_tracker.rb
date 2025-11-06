# frozen_string_literal: true

module Monitorix
  module Middleware
    class RequestTracker
      def initialize(app)
        @app = app
      end

      def call(env)
        # Skip Monitorix's own requests
        return @app.call(env) if env["PATH_INFO"]&.start_with?("/monitorix")

        endpoint = extract_endpoint(env)
        request_tracker = Monitorix::RequestTracker.new(endpoint)

        # Store in thread-local storage
        Monitorix.current_request = request_tracker

        # Extract request metadata
        request_tracker.http_method = env["REQUEST_METHOD"]
        request_tracker.path = env["PATH_INFO"]
        request_tracker.user_agent = env["HTTP_USER_AGENT"]
        request_tracker.ip_address = env["REMOTE_ADDR"]

        request_tracker.start!

        begin
          status, headers, body = @app.call(env)
          request_tracker.status_code = status
          [status, headers, body]
        rescue StandardError => e
          request_tracker.record_error(e)
          request_tracker.status_code = 500
          raise
        ensure
          request_tracker.finish!
          Monitorix.current_request = nil
        end
      end

      private

      def extract_endpoint(env)
        # Try to extract Rails route info if available
        if defined?(Rails) && Rails.application
          recognized = Rails.application.routes.recognize_path(env["PATH_INFO"], method: env["REQUEST_METHOD"]) rescue nil
          if recognized
            "#{recognized[:controller]}##{recognized[:action]}"
          else
            "#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}"
          end
        else
          "#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}"
        end
      end
    end
  end
end
