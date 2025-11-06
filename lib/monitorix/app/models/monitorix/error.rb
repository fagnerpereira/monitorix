# frozen_string_literal: true

module Monitorix
  class Error < ApplicationRecord
    self.table_name = "monitorix_errors"

    belongs_to :request, optional: true

    validates :exception_class, presence: true

    scope :recent, -> { order(created_at: :desc) }
    scope :unresolved, -> { where(resolved: false) }
    scope :by_class, ->(klass) { where(exception_class: klass) }
    scope :within, ->(timeframe) { where("created_at > ?", timeframe.ago) }

    before_create :set_first_seen_at
    before_save :set_last_seen_at

    def self.record_error(exception, request: nil, context: {})
      error_attrs = {
        exception_class: exception.class.name,
        message: exception.message,
        backtrace: exception.backtrace&.join("\n"),
        file: exception.backtrace&.first&.split(":")&.first,
        line: exception.backtrace&.first&.split(":")&.second&.to_i,
        endpoint: request&.endpoint,
        context: context,
        request: request
      }

      # Try to find existing error by class + location
      existing = find_by(
        exception_class: error_attrs[:exception_class],
        file: error_attrs[:file],
        line: error_attrs[:line]
      )

      if existing
        existing.increment!(:occurrences)
        existing.update(
          last_seen_at: Time.current,
          message: error_attrs[:message], # Update with latest message
          backtrace: error_attrs[:backtrace]
        )
        existing
      else
        create(error_attrs)
      end
    end

    private

    def set_first_seen_at
      self.first_seen_at ||= Time.current
    end

    def set_last_seen_at
      self.last_seen_at = Time.current
    end
  end
end
