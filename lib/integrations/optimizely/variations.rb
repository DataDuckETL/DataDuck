require 'typhoeus'

require_relative 'optimizely_table'

module DataDuck
  module Optimizely
    class Variations < DataDuck::Optimizely::OptimizelyTable
      transforms :fix_fields

      def initialize(data)
        self.data = data
      end

      def extract!(*args)
        # already initialized data
      end

      def fix_fields(row)
        row[:id] = row['variation_id'].to_i
        row[:name] = row['variation_name']
        row['baseline_id'] = row['baseline_id'].to_i
        row['improvement'] = row['improvement'].to_f
        row['confidence'] = row['confidence'].to_f
        row['conversion_rate'] = row['conversion_rate'].to_f
        row['difference'] = row['difference'].to_f

        row
      end

      def indexes
        ["id", "goal_id", "experiment_id", "name"]
      end

      def should_fully_reload?
        true
      end

      output({
          :id => :bigint,
          :name => :string,
          :experiment_id => :bigint,
          :baseline_id => :bigint,
          :goal_name => :string,
          :goal_id => :bigint,
          :visitors => :integer,
          :conversions => :integer,
          :begin_time => :datetime,
          :end_time => :datetime,
          :improvement => :float,
          :confidence => :float,
          :conversion_rate => :float,
          :difference => :float,
          :status => :string,
          :dataduck_extracted_at => :datetime,
      })
    end
  end
end
