# frozen_string_literal: true

module Monitorix
  class Metric < ApplicationRecord
    self.table_name = "monitorix_metrics"

    validates :name, presence: true
    validates :metric_type, presence: true
    validates :value, presence: true, numericality: true

    scope :by_name, ->(name) { where(name: name) }
    scope :by_type, ->(type) { where(metric_type: type) }
    scope :by_endpoint, ->(endpoint) { where(endpoint: endpoint) }
    scope :within, ->(timeframe) { where("created_at > ?", timeframe.ago) }
    scope :recent, -> { order(created_at: :desc) }

    def self.record(name, value, type: "gauge", endpoint: nil, tags: {})
      create(
        name: name,
        value: value,
        metric_type: type,
        endpoint: endpoint,
        tags: tags
      )
    end
  end
end
