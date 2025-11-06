# frozen_string_literal: true

require "test_helper"

module Monitorix
  module Plugin
    class ActiveRecordTest < ActiveSupport::TestCase
      context ".normalize_sql" do
        should "replace string values with ?" do
          sql = "SELECT * FROM users WHERE name = 'John'"
          normalized = ActiveRecord.send(:normalize_sql, sql)

          assert_equal "SELECT * FROM users WHERE name = ?", normalized
        end

        should "replace numeric values with ?" do
          sql = "SELECT * FROM users WHERE id = 123"
          normalized = ActiveRecord.send(:normalize_sql, sql)

          assert_equal "SELECT * FROM users WHERE id = ?", normalized
        end

        should "replace parameter placeholders" do
          sql = "SELECT * FROM users WHERE id = $1 AND name = $2"
          normalized = ActiveRecord.send(:normalize_sql, sql)

          assert_equal "SELECT * FROM users WHERE id = ? AND name = ?", normalized
        end

        should "normalize IN clauses" do
          sql = "SELECT * FROM users WHERE id IN (1, 2, 3, 4, 5)"
          normalized = ActiveRecord.send(:normalize_sql, sql)

          assert_equal "SELECT * FROM users WHERE id IN (?)", normalized
        end

        should "remove comments" do
          sql = "SELECT * FROM users -- fetch all users\nWHERE active = 1"
          normalized = ActiveRecord.send(:normalize_sql, sql)

          refute_includes normalized, "--"
        end
      end
    end
  end
end
