class WelcomeController < ApplicationController
  def index
    # Create some test data if it doesn't exist
    if MonitoringSchema.count == 0
      5.times { MonitoringSchema.create! }
    end

    # Simulate some database queries for testing
    @monitoring_schemas = MonitoringSchema.all
    @total_count = MonitoringSchema.count

    # Simulate multiple queries (to test N+1 detection later)
    5.times do |i|
      MonitoringSchema.where(id: i + 1).first
    end
  end
end
