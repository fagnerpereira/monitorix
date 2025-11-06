# frozen_string_literal: true

class CreateMonitorixMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :monitorix_metrics do |t|
      t.string :name, null: false
      t.string :metric_type, null: false
      t.float :value, null: false
      t.string :endpoint
      t.json :tags

      t.timestamps
    end

    add_index :monitorix_metrics, :name
    add_index :monitorix_metrics, [:name, :created_at]
    add_index :monitorix_metrics, :endpoint
    add_index :monitorix_metrics, :created_at
  end
end
