# frozen_string_literal: true

require "test_helper"

module Monitorix
  class ErrorTest < ActiveSupport::TestCase
    context "validations" do
      should validate_presence_of(:exception_class)
    end

    context "associations" do
      should belong_to(:request).optional
    end

    context "scopes" do
      setup do
        @resolved_error = FactoryBot.create(:monitorix_error, :resolved)
        @unresolved_error = FactoryBot.create(:monitorix_error)
        @old_error = FactoryBot.create(:monitorix_error, created_at: 2.days.ago)
      end

      should "return recent errors ordered by created_at desc" do
        recent = Monitorix::Error.recent.to_a
        assert_equal recent.first.created_at >= recent.last.created_at, true
      end

      should "return only unresolved errors" do
        unresolved = Monitorix::Error.unresolved.to_a
        assert_includes unresolved, @unresolved_error
        refute_includes unresolved, @resolved_error
      end

      should "filter by exception class" do
        errors = Monitorix::Error.by_class(@unresolved_error.exception_class).to_a
        assert_includes errors, @unresolved_error
      end

      should "filter within timeframe" do
        within_hour = Monitorix::Error.within(1.hour).to_a
        assert_includes within_hour, @unresolved_error
        refute_includes within_hour, @old_error
      end
    end

    context ".record_error" do
      should "create new error record" do
        exception = StandardError.new("Test error")
        exception.set_backtrace(["app/controllers/test.rb:10"])

        assert_difference "Monitorix::Error.count", 1 do
          Monitorix::Error.record_error(exception)
        end
      end

      should "increment occurrences for existing error" do
        exception = StandardError.new("Test error")
        exception.set_backtrace(["app/controllers/test.rb:10"])

        first_error = Monitorix::Error.record_error(exception)

        assert_no_difference "Monitorix::Error.count" do
          second_error = Monitorix::Error.record_error(exception)
          assert_equal first_error.id, second_error.id
          assert_equal 2, second_error.occurrences
        end
      end
    end
  end
end
