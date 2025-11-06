# frozen_string_literal: true

module Monitorix
  module Dashboard
    class Index < Phlex::HTML
      include Phlex::Rails::Helpers::Routes

      def initialize(recent_requests:, error_count:, slow_request_count:, avg_response_time:)
        @recent_requests = recent_requests
        @error_count = error_count
        @slow_request_count = slow_request_count
        @avg_response_time = avg_response_time
      end

      def template
        div class: "px-4 py-6 sm:px-0" do
          h2 class: "text-2xl font-bold text-gray-900 mb-6" do
            text "Dashboard"
          end

          # Stats Grid
          div class: "grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 mb-8" do
            stat_card "Avg Response Time", "#{@avg_response_time}ms", "clock"
            stat_card "Errors (Last Hour)", @error_count.to_s, "error"
            stat_card "Slow Requests (Last Hour)", @slow_request_count.to_s, "warning"
          end

          # Recent Requests
          div class: "bg-white shadow overflow-hidden sm:rounded-lg" do
            div class: "px-4 py-5 sm:px-6" do
              h3 class: "text-lg leading-6 font-medium text-gray-900" do
                text "Recent Requests"
              end
            end

            div class: "border-t border-gray-200" do
              table class: "min-w-full divide-y divide-gray-200" do
                thead class: "bg-gray-50" do
                  tr do
                    th class: table_header_classes, text: "Endpoint"
                    th class: table_header_classes, text: "Duration"
                    th class: table_header_classes, text: "Status"
                    th class: table_header_classes, text: "Time"
                  end
                end

                tbody class: "bg-white divide-y divide-gray-200" do
                  @recent_requests.each do |request|
                    render_request_row(request)
                  end
                end
              end
            end
          end
        end
      end

      private

      def stat_card(title, value, icon_type)
        div class: "bg-white overflow-hidden shadow rounded-lg" do
          div class: "p-5" do
            div class: "flex items-center" do
              div class: "flex-shrink-0" do
                render_icon(icon_type)
              end
              div class: "ml-5 w-0 flex-1" do
                dl do
                  dt class: "text-sm font-medium text-gray-500 truncate", text: title
                  dd class: "text-lg font-medium text-gray-900", text: value
                end
              end
            end
          end
        end
      end

      def render_icon(type)
        color = case type
                when "error" then "text-red-400"
                when "warning" then "text-yellow-400"
                else "text-gray-400"
                end

        svg class: "h-6 w-6 #{color}", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do |s|
          case type
          when "clock"
            s.path stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2",
                   d: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
          when "error"
            s.path stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2",
                   d: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          when "warning"
            s.path stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2",
                   d: "M13 10V3L4 14h7v7l9-11h-7z"
          end
        end
      end

      def render_request_row(request)
        tr do
          td class: table_cell_classes do
            a href: monitorix.request_path(request),
              class: "text-indigo-600 hover:text-indigo-900 font-medium" do
              text request.endpoint
            end
          end

          td class: table_cell_classes do
            span class: duration_class(request) do
              text "#{request.duration_ms.round(2)}ms"
            end
          end

          td class: table_cell_classes do
            span class: status_badge_class(request.status_code) do
              text request.status_code
            end
          end

          td class: table_cell_classes do
            text time_ago_text(request.created_at)
          end
        end
      end

      def table_header_classes
        "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
      end

      def table_cell_classes
        "px-6 py-4 whitespace-nowrap text-sm text-gray-500"
      end

      def duration_class(request)
        if request.duration_ms > Monitorix.config.slow_request_threshold
          "text-red-600 font-semibold"
        else
          ""
        end
      end

      def status_badge_class(code)
        base = "px-2 inline-flex text-xs leading-5 font-semibold rounded-full "
        if code >= 500
          base + "bg-red-100 text-red-800"
        elsif code >= 400
          base + "bg-yellow-100 text-yellow-800"
        else
          base + "bg-green-100 text-green-800"
        end
      end

      def time_ago_text(time)
        distance = Time.current - time
        if distance < 60
          "#{distance.to_i} seconds ago"
        elsif distance < 3600
          "#{(distance / 60).to_i} minutes ago"
        else
          "#{(distance / 3600).to_i} hours ago"
        end
      end
    end
  end
end
