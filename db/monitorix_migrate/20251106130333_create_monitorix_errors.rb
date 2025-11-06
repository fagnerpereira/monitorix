# frozen_string_literal: true

class CreateMonitorixErrors < ActiveRecord::Migration[8.1]
  def change
    create_table :monitorix_errors do |t|
      t.references :request, foreign_key: { to_table: :monitorix_requests }, index: true
      t.string :exception_class, null: false
      t.text :message
      t.text :backtrace
      t.string :file
      t.integer :line
      t.string :endpoint
      t.integer :occurrences, default: 1
      t.datetime :first_seen_at
      t.datetime :last_seen_at
      t.boolean :resolved, default: false
      t.json :context

      t.timestamps
    end

    add_index :monitorix_errors, :exception_class
    add_index :monitorix_errors, [:exception_class, :file, :line]
    add_index :monitorix_errors, :resolved
    add_index :monitorix_errors, :created_at
  end
end
