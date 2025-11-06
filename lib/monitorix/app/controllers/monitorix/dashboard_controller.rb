# frozen_string_literal: true

module Monitorix
  class DashboardController < ApplicationController
    def index
      render Monitorix::Dashboard::Index.new(
        recent_requests: Monitorix::Request.order(created_at: :desc).limit(50),
        error_count: Monitorix::Error.where("created_at > ?", 1.hour.ago).count,
        slow_request_count: Monitorix::Request
          .where("duration_ms > ?", Monitorix.config.slow_request_threshold)
          .where("created_at > ?", 1.hour.ago)
          .count,
        avg_response_time: Monitorix::Request
          .where("created_at > ?", 1.hour.ago)
          .average(:duration_ms)
          &.round(2) || 0
      )
    end
  end
end
