# frozen_string_literal: true

require "test_helper"
require "mocha/minitest"

module Monitorix
  module Plugin
    class ActiveRecordTest < ActiveSupport::TestCase
      setup do
        @instance = Monitorix::Plugin::ActiveRecord.new
      end

      context "normalize_sql" do
        should "replace string values with ?" do
          sql = "SELECT * FROM users WHERE name = 'John'"
          normalized = @instance.send(:normalize_sql, sql)

          assert_equal "SELECT * FROM users WHERE name = ?", normalized
        end

        should "replace numeric values with ?" do
          sql = "SELECT * FROM users WHERE id = 123"
          normalized = @instance.send(:normalize_sql, sql)

          assert_equal "SELECT * FROM users WHERE id = ?", normalized
        end

        should "replace parameter placeholders" do
          sql = "SELECT * FROM users WHERE id = $1 AND name = $2"
          normalized = @instance.send(:normalize_sql, sql)

          assert_equal "SELECT * FROM users WHERE id = ? AND name = ?", normalized
        end

        should "normalize IN clauses" do
          sql = "SELECT * FROM users WHERE id IN (1, 2, 3, 4, 5)"
          normalized = @instance.send(:normalize_sql, sql)

          assert_equal "SELECT * FROM users WHERE id IN (?)", normalized
        end

        should "remove comments" do
          sql = "SELECT * FROM users -- fetch all users\nWHERE active = 1"
          normalized = @instance.send(:normalize_sql, sql)

          refute_includes normalized, "--"
        end

        should "remove multi-line comments" do
            sql = "/* fetch all users */ SELECT * FROM users"
            normalized = @instance.send(:normalize_sql, sql)
            assert_equal "SELECT * FROM users", normalized.strip
        end

        should "return empty string for empty sql" do
            sql = ""
            normalized = @instance.send(:normalize_sql, sql)
            assert_equal "", normalized
        end

        should "return empty string for nil sql" do
            sql = nil
            normalized = @instance.send(:normalize_sql, sql)
            assert_equal "", normalized
        end

        should "return empty string for sql with only comments" do
            sql = "-- only comment"
            normalized = @instance.send(:normalize_sql, sql)
            assert_equal "", normalized
        end
      end

      context "instrumentation" do
        setup do
          @request_tracker = mock("request_tracker")
          Monitorix.stubs(:current_request).returns(@request_tracker)
          Monitorix::Plugin::ActiveRecord.instance_variable_set(:@installed, false)
          ActiveSupport::Notifications.unsubscribe("sql.active_record")
          Monitorix::Plugin::ActiveRecord.install
        end

        teardown do
            ActiveSupport::Notifications.unsubscribe("sql.active_record")
        end

        should "track sql events" do
          @request_tracker.expects(:start_layer).with("sql", "User Load", query: "SELECT users.* FROM users WHERE id = ?", original_query: "SELECT users.* FROM users WHERE id = 1" )
          @request_tracker.expects(:stop_layer)

          payload = { sql: "SELECT users.* FROM users WHERE id = 1", name: "User Load" }
          
          subscriber = ActiveSupport::Notifications.notifier.listeners_for("sql.active_record").first
          delegate = subscriber.instance_variable_get(:@delegate)
          
          delegate.start("sql.active_record", "event_id", payload)
          delegate.finish("sql.active_record", "event_id", payload)
        end

        should "not track schema queries" do
          @request_tracker.expects(:start_layer).never
          @request_tracker.expects(:stop_layer).never

          payload = { sql: "SELECT * FROM schema_migrations", name: "SCHEMA" }
          
          subscriber = ActiveSupport::Notifications.notifier.listeners_for("sql.active_record").first
          delegate = subscriber.instance_variable_get(:@delegate)

          delegate.start("sql.active_record", "event_id", payload)
          delegate.finish("sql.active_record", "event_id", payload)
        end
      end
    end
  end
end