# frozen_string_literal: true

require "test_helper"

module Monitorix
  class RequestTrackerTest < ActiveSupport::TestCase
    setup do
      @tracker = RequestTracker.new("TestController#index")
    end

    context "initialization" do
      should "set endpoint" do
        assert_equal "TestController#index", @tracker.endpoint
      end

      should "generate transaction_id" do
        assert_not_nil @tracker.transaction_id
        assert_match /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, @tracker.transaction_id
      end
    end

    context "#start! and #finish!" do
      should "track duration" do
        @tracker.start!
        sleep 0.01 # 10ms
        @tracker.finish!

        assert @tracker.duration_ms >= 10
      end
    end

    context "#start_layer and #stop_layer" do
      should "track layer" do
        @tracker.start!
        layer = @tracker.start_layer("sql", "SELECT * FROM users")

        assert_not_nil layer
        assert_equal "sql", layer.type
        assert_equal "SELECT * FROM users", layer.name
      end

      should "track parent-child relationships" do
        @tracker.start!
        parent = @tracker.start_layer("controller", "TestController#index")
        child = @tracker.start_layer("sql", "SELECT")

        assert_equal parent, child.parent
        assert_includes parent.children, child
      end

      should "stop layer and calculate duration" do
        @tracker.start!
        @tracker.start_layer("sql", "SELECT")
        sleep 0.01
        layer = @tracker.stop_layer

        assert layer.duration_ms >= 10
      end
    end

    context "#record_error" do
      should "record error" do
        @tracker.start!
        exception = StandardError.new("Test error")

        @tracker.record_error(exception)

        assert_equal 1, @tracker.instance_variable_get(:@errors).length
      end
    end

    context "#n_plus_one_detected?" do
      should "detect N+1 queries" do
        @tracker.start!

        10.times do
          @tracker.start_layer("sql", "SELECT * FROM users WHERE id = ?", query: "SELECT * FROM users WHERE id = ?")
          @tracker.stop_layer
        end

        assert @tracker.n_plus_one_detected?
      end

      should "not detect N+1 for different queries" do
        @tracker.start!

        5.times do |i|
          @tracker.start_layer("sql", "Query #{i}")
          @tracker.stop_layer
        end

        refute @tracker.n_plus_one_detected?
      end
    end

    context "#persist!" do
      should "create Request record" do
        @tracker.start!
        @tracker.controller = "TestController"
        @tracker.action = "index"
        @tracker.status_code = 200
        @tracker.finish!

        assert_difference "Monitorix::Request.count", 1 do
          @tracker.send(:persist!)
        end
      end

      should "create Layer records" do
        @tracker.start!
        @tracker.start_layer("sql", "SELECT")
        @tracker.stop_layer
        @tracker.finish!

        assert_difference "Monitorix::Layer.count", 1 do
          @tracker.send(:persist!)
        end
      end
    end
  end
end
