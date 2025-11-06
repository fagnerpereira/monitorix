# frozen_string_literal: true

class CreateMonitorixLayers < ActiveRecord::Migration[8.1]
  def change
    create_table :monitorix_layers do |t|
      t.references :request, null: false, foreign_key: { to_table: :monitorix_requests }, index: true
      t.references :parent, foreign_key: { to_table: :monitorix_layers }, index: true
      t.string :layer_type, null: false
      t.string :name, null: false
      t.float :duration_ms, null: false
      t.float :self_time_ms
      t.text :query
      t.string :file
      t.integer :line
      t.json :metadata

      t.timestamps
    end

    add_index :monitorix_layers, :layer_type
    add_index :monitorix_layers, [:request_id, :layer_type]
  end
end
