# frozen_string_literal: true

module Monitorix
  class ApplicationController < ActionController::Base
    # Use Phlex layout
    layout -> { ApplicationLayout }

    # Disable Monitorix tracking for its own requests
    before_action :disable_monitorix_tracking

    private

    def disable_monitorix_tracking
      Monitorix.current_request = nil
    end
  end
end
