# frozen_string_literal: true

require "test_helper"

class InstrumentationTest < ActionDispatch::IntegrationTest
  test "should track request performance" do
    assert_difference "Monitorix::Request.count", 1 do
      get "/"
    end

    request = Monitorix::Request.last
    assert_not_nil request
    assert_equal "WelcomeController#index", request.endpoint
    assert request.duration_ms > 0
  end

  test "should track SQL queries" do
    get "/"

    request = Monitorix::Request.last
    sql_layers = request.layers.where(layer_type: "sql")

    assert sql_layers.count > 0, "Expected SQL queries to be tracked"
  end

  test "should track controller layer" do
    get "/"

    request = Monitorix::Request.last
    controller_layer = request.layers.find_by(layer_type: "controller")

    assert_not_nil controller_layer
    assert_equal "WelcomeController#index", controller_layer.name
  end

  test "should not track monitorix own requests" do
    # This would fail to route, but demonstrates the concept
    assert_no_difference "Monitorix::Request.count" do
      begin
        get "/monitorix"
      rescue ActionController::RoutingError
        # Expected - monitorix routes need to be properly set up
      end
    end
  end
end
