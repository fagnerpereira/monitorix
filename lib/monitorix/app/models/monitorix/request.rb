# frozen_string_literal: true

module Monitorix
  class Request < ApplicationRecord
    self.table_name = "monitorix_requests"

    has_many :layers, dependent: :destroy
    has_one :error, dependent: :destroy

    validates :endpoint, presence: true
    validates :duration_ms, presence: true, numericality: { greater_than_or_equal_to: 0 }

    scope :recent, -> { order(created_at: :desc) }
    scope :slow, ->(threshold = nil) {
      threshold ||= Monitorix.config.slow_request_threshold
      where("duration_ms > ?", threshold)
    }
    scope :errors, -> { where("status_code >= 500") }
    scope :by_endpoint, ->(endpoint) { where(endpoint: endpoint) }
    scope :within, ->(timeframe) { where("created_at > ?", timeframe.ago) }

    def slow?
      duration_ms > Monitorix.config.slow_request_threshold
    end

    def error?
      status_code&.>=(500) || error.present?
    end

    def root_layers
      layers.where(parent_id: nil).order(:created_at)
    end
  end
end
