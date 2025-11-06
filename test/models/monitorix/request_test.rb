# frozen_string_literal: true

require "test_helper"

module Monitorix
  class RequestTest < ActiveSupport::TestCase
    context "validations" do
      should validate_presence_of(:endpoint)
      should validate_presence_of(:duration_ms)
      should validate_numericality_of(:duration_ms).is_greater_than_or_equal_to(0)
    end

    context "associations" do
      should have_many(:layers).dependent(:destroy)
      should have_one(:error).dependent(:destroy)
    end

    context "scopes" do
      setup do
        @slow_request = FactoryBot.create(:monitorix_request, :slow)
        @fast_request = FactoryBot.create(:monitorix_request, :fast)
        @error_request = FactoryBot.create(:monitorix_request, :error)
        @old_request = FactoryBot.create(:monitorix_request, created_at: 2.days.ago)
      end

      should "return recent requests ordered by created_at desc" do
        recent = Monitorix::Request.recent.to_a
        assert_equal [@slow_request, @fast_request, @error_request, @old_request].sort_by(&:created_at).reverse.map(&:id),
                     recent.map(&:id)
      end

      should "return slow requests" do
        slow_requests = Monitorix::Request.slow(500).to_a
        assert_includes slow_requests, @slow_request
        refute_includes slow_requests, @fast_request
      end

      should "return error requests" do
        error_requests = Monitorix::Request.errors.to_a
        assert_includes error_requests, @error_request
        refute_includes error_requests, @slow_request
      end

      should "filter by endpoint" do
        endpoint_requests = Monitorix::Request.by_endpoint(@slow_request.endpoint).to_a
        assert_includes endpoint_requests, @slow_request
      end

      should "filter within timeframe" do
        within_hour = Monitorix::Request.within(1.hour).to_a
        assert_includes within_hour, @slow_request
        refute_includes within_hour, @old_request
      end
    end

    context "instance methods" do
      should "return true for slow? when duration exceeds threshold" do
        request = FactoryBot.create(:monitorix_request, :slow)
        assert request.slow?
      end

      should "return false for slow? when duration below threshold" do
        request = FactoryBot.create(:monitorix_request, :fast)
        refute request.slow?
      end

      should "return true for error? when status code >= 500" do
        request = FactoryBot.create(:monitorix_request, status_code: 500)
        assert request.error?
      end

      should "return root layers" do
        request = FactoryBot.create(:monitorix_request)
        root_layer = FactoryBot.create(:monitorix_layer, request: request, parent: nil)
        child_layer = FactoryBot.create(:monitorix_layer, request: request, parent: root_layer)

        assert_equal [root_layer], request.root_layers.to_a
      end
    end
  end
end
