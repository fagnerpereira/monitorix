class CreateMonitoringSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :monitoring_schemas do |t|
      t.timestamps
    end
  end
end
