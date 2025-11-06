# frozen_string_literal: true

class CreateMonitorixBackgroundJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :monitorix_background_jobs do |t|
      t.string :job_id
      t.string :job_class, null: false
      t.string :queue_name
      t.string :status, default: "pending"
      t.float :duration_ms
      t.float :queue_latency_ms
      t.datetime :enqueued_at
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error_message
      t.text :error_backtrace
      t.json :arguments
      t.json :metadata

      t.timestamps
    end

    add_index :monitorix_background_jobs, :job_id
    add_index :monitorix_background_jobs, :job_class
    add_index :monitorix_background_jobs, :queue_name
    add_index :monitorix_background_jobs, :status
    add_index :monitorix_background_jobs, :created_at
  end
end
