# frozen_string_literal: true

class CreateMonitorixCodeSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :monitorix_code_suggestions do |t|
      t.string :file, null: false
      t.integer :line
      t.string :severity, null: false
      t.string :category, null: false
      t.text :message, null: false
      t.string :rule_name
      t.text :suggestion
      t.boolean :ignored, default: false
      t.integer :occurrences, default: 1
      t.datetime :first_seen_at
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :monitorix_code_suggestions, :file
    add_index :monitorix_code_suggestions, :severity
    add_index :monitorix_code_suggestions, :category
    add_index :monitorix_code_suggestions, :ignored
    add_index :monitorix_code_suggestions, [:file, :line, :rule_name], unique: true, name: "index_monitorix_code_suggestions_unique"
  end
end
