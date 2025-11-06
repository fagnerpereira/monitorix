# frozen_string_literal: true

module Monitorix
  # Convenience class for creating layers
  class Layer
    def self.new(type, name, **options)
      Monitorix::RequestTracker::LayerData.new(type, name, **options)
    end
  end
end
