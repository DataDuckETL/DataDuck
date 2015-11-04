require 'typhoeus'

require_relative 'optimizely_table'

module DataDuck
  module Optimizely
    class Variations < DataDuck::Optimizely::OptimizelyTable
      # this table should contain experiment variations and either /results or /stats for the result data
    end
  end
end
