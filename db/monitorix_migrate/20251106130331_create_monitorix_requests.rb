# frozen_string_literal: true

class CreateMonitorixRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :monitorix_requests do |t|
      t.string :endpoint, null: false
      t.string :controller
      t.string :action
      t.string :http_method
      t.string :path
      t.integer :status_code
      t.float :duration_ms, null: false
      t.float :db_time_ms, default: 0
      t.float :view_time_ms, default: 0
      t.integer :query_count, default: 0
      t.string :format
      t.string :transaction_id
      t.text :user_agent
      t.string :ip_address
      t.json :params
      t.json :headers
      t.json :metadata

      t.timestamps
    end

    add_index :monitorix_requests, :endpoint
    add_index :monitorix_requests, [:controller, :action]
    add_index :monitorix_requests, :transaction_id, unique: true
    add_index :monitorix_requests, :created_at
    add_index :monitorix_requests, :duration_ms
  end
end
