# frozen_string_literal: true

module Monitorix
  class ApplicationLayout < Phlex::HTML
    include Phlex::Rails::Layout

    def template(&block)
      doctype

      html do
        head do
          title { "Monitorix" }
          meta name: "viewport", content: "width=device-width,initial-scale=1"
          csrf_meta_tags
          csp_meta_tag

          stylesheet_link_tag "application", data_turbo_track: "reload"
          javascript_importmap_tags
        end

        body class: "bg-gray-50" do
          render NavigationComponent.new
          main class: "max-w-7xl mx-auto py-6 sm:px-6 lg:px-8", &block
        end
      end
    end
  end
end
