require_relative 'optimizely_table'

require 'typhoeus'
require 'oj'
require 'date'

module DataDuck
  module Optimizely
    class Experiments < DataDuck::Optimizely::OptimizelyTable
      transforms :percentage_included_to_float
      transforms :rename_description_to_name

      def initialize(experiments)
        self.data = experiments
      end

      def extract!(*args)
        # already initialized data
      end

      def rename_description_to_name(row)
        row[:name] = row['description']

        row
      end

      def percentage_included_to_float(row)
        row['percentage_included'] = row['percentage_included'].to_i / 100.0

        row
      end

      def should_fully_reload?
        true
      end

      def indexes
        ["id", "project_id", "primary_goal_id", "name"]
      end

      output({
          :id => :bigint,
          :project_id => :bigint, # integers have an overflow error because optimizely numbers get too big
          :name => :string,
          :shareable_results_link => :string,
          :conditional_code => :bigtext,
          :custom_js => :bigtext,
          :primary_goal_id => :integer,
          :details => :bigtext,
          :status => :string,
          :audience_ids => :bigtext,
          :url_conditions => :bigtext,
          :last_modified => :datetime,
          :is_multivariate => :boolean,
          :activation_mode => :string,
          :created => :datetime,
          :percentage_included => :float,
          :experiment_type => :string,
          :edit_url => :string,
          :auto_allocated => :boolean,
          :dataduck_extracted_at => :datetime,
      })
    end
  end
end
