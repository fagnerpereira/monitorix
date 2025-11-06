# frozen_string_literal: true

module Monitorix
  module Plugin
    class ActionController
      def self.install
        return if @installed
        return unless defined?(::ActionController::Base)

        ::ActionController::Base.around_action(&method(:around_action))

        if defined?(::ActionController::API) && ::ActionController::API.respond_to?(:around_action)
          ::ActionController::API.around_action(&method(:around_action))
        end

        @installed = true
      end

      def self.around_action(controller, block)
        request_tracker = Monitorix.current_request
        return block.call unless request_tracker

        controller_class = controller.class.name
        action_name = controller.action_name

        # Update request tracker with controller details
        request_tracker.controller = controller_class
        request_tracker.action = action_name
        request_tracker.endpoint = "#{controller_class}##{action_name}"

        # Extract additional metadata
        if controller.respond_to?(:request)
          request = controller.request
          request_tracker.params = request.params.to_unsafe_h rescue {}
          request_tracker.format = request.format.symbol.to_s rescue nil
        end

        # Track the controller action as a layer
        request_tracker.start_layer("controller", "#{controller_class}##{action_name}",
          file: source_file(controller, action_name),
          line: source_line(controller, action_name)
        )

        begin
          result = block.call
          request_tracker.stop_layer
          result
        rescue StandardError => e
          request_tracker.record_error(e)
          request_tracker.stop_layer
          raise
        end
      end

      def self.source_file(controller, action_name)
        method_name = controller.send(:method_for_action, action_name)
        return nil unless method_name

        file, _line = controller.method(method_name).source_location
        file&.sub(Rails.root.to_s + "/", "")
      end

      def self.source_line(controller, action_name)
        method_name = controller.send(:method_for_action, action_name)
        return nil unless method_name

        _file, line = controller.method(method_name).source_location
        line
      end
    end
  end
end
