# frozen_string_literal: true

module Monitorix
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Connect to the separate Monitorix database
    connects_to database: { writing: :monitorix, reading: :monitorix }
  end
end
