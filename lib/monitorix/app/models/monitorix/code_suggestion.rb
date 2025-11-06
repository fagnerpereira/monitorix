# frozen_string_literal: true

module Monitorix
  class CodeSuggestion < ApplicationRecord
    self.table_name = "monitorix_code_suggestions"

    validates :file, presence: true
    validates :severity, presence: true, inclusion: { in: %w[critical warning info] }
    validates :category, presence: true
    validates :message, presence: true

    scope :by_file, ->(file) { where(file: file) }
    scope :by_severity, ->(severity) { where(severity: severity) }
    scope :by_category, ->(category) { where(category: category) }
    scope :unignored, -> { where(ignored: false) }
    scope :recent, -> { order(last_seen_at: :desc) }
    scope :critical, -> { where(severity: "critical") }
    scope :warnings, -> { where(severity: "warning") }

    before_create :set_first_seen_at
    before_save :set_last_seen_at

    def self.record_suggestion(file:, line: nil, severity:, category:, message:, rule_name: nil, suggestion: nil)
      existing = find_by(file: file, line: line, rule_name: rule_name)

      if existing
        existing.increment!(:occurrences)
        existing.update(
          last_seen_at: Time.current,
          message: message,
          suggestion: suggestion
        )
        existing
      else
        create(
          file: file,
          line: line,
          severity: severity,
          category: category,
          message: message,
          rule_name: rule_name,
          suggestion: suggestion
        )
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
