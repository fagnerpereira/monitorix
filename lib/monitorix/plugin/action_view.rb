# frozen_string_literal: true

module Monitorix
  module Plugin
    class ActionView
      def self.install
        return if @installed
        return unless defined?(ActiveSupport::Notifications)

        # Subscribe to view rendering events
        ActiveSupport::Notifications.subscribe("render_template.action_view", new)
        ActiveSupport::Notifications.subscribe("render_partial.action_view", new)
        ActiveSupport::Notifications.subscribe("render_collection.action_view", new)

        @installed = true
      end

      def start(name, id, payload)
        request_tracker = Monitorix.current_request
        return unless request_tracker

        type = case name
               when "render_template.action_view"
                 "template"
               when "render_partial.action_view"
                 "partial"
               when "render_collection.action_view"
                 "collection"
               else
                 "view"
               end

        identifier = payload[:identifier]
        return unless identifier

        # Extract relative path
        relative_path = identifier.sub(Rails.root.to_s + "/", "")

        request_tracker.start_layer(type, relative_path,
          file: relative_path,
          count: payload[:count]
        )

        Thread.current[:monitorix_view_event_id] = id
      end

      def finish(name, id, payload)
        request_tracker = Monitorix.current_request
        return unless request_tracker

        # Only stop if this is the matching event
        return unless Thread.current[:monitorix_view_event_id] == id

        request_tracker.stop_layer
        Thread.current[:monitorix_view_event_id] = nil
      end
    end
  end
end
