# frozen_string_literal: true

module Monitorix
  class NavigationComponent < Phlex::HTML
    def template
      nav class: "bg-white shadow-sm" do
        div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" do
          div class: "flex justify-between h-16" do
            div class: "flex" do
              div class: "flex-shrink-0 flex items-center" do
                h1 class: "text-2xl font-bold text-gray-900" do
                  text "Monitorix"
                end
              end

              div class: "hidden sm:ml-6 sm:flex sm:space-x-8" do
                nav_link "Dashboard", monitorix.root_path
                nav_link "Requests", monitorix.requests_path
                nav_link "Errors", monitorix.errors_path
                nav_link "Endpoints", monitorix.endpoints_path
                nav_link "Jobs", monitorix.background_jobs_path
                nav_link "Slow Queries", monitorix.slow_queries_path
                nav_link "Code", monitorix.code_suggestions_path
              end
            end
          end
        end
      end
    end

    private

    def nav_link(label, url)
      a href: url, class: nav_link_classes do
        text label
      end
    end

    def nav_link_classes
      "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 " \
      "inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
    end
  end
end
