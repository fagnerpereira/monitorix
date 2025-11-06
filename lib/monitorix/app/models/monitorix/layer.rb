# frozen_string_literal: true

module Monitorix
  class Layer < ApplicationRecord
    self.table_name = "monitorix_layers"

    belongs_to :request
    belongs_to :parent, class_name: "Monitorix::Layer", optional: true
    has_many :children, class_name: "Monitorix::Layer", foreign_key: :parent_id, dependent: :destroy

    validates :layer_type, presence: true
    validates :name, presence: true
    validates :duration_ms, presence: true, numericality: { greater_than_or_equal_to: 0 }

    scope :by_type, ->(type) { where(layer_type: type) }
    scope :sql_queries, -> { where(layer_type: "sql") }
    scope :views, -> { where(layer_type: "view") }
    scope :slow, ->(threshold) { where("duration_ms > ?", threshold) }

    def sql?
      layer_type == "sql"
    end

    def view?
      layer_type == "view"
    end

    def controller?
      layer_type == "controller"
    end
  end
end
