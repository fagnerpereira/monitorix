# frozen_string_literal: true

module Monitorix
  class BackgroundJob < ApplicationRecord
    self.table_name = "monitorix_background_jobs"

    validates :job_class, presence: true

    scope :recent, -> { order(created_at: :desc) }
    scope :by_class, ->(klass) { where(job_class: klass) }
    scope :by_queue, ->(queue) { where(queue_name: queue) }
    scope :by_status, ->(status) { where(status: status) }
    scope :failed, -> { where(status: "failed") }
    scope :successful, -> { where(status: "completed") }
    scope :within, ->(timeframe) { where("created_at > ?", timeframe.ago) }

    def failed?
      status == "failed"
    end

    def completed?
      status == "completed"
    end

    def pending?
      status == "pending"
    end

    def running?
      status == "running"
    end
  end
end
