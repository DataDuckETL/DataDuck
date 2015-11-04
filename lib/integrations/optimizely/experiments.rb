require_relative 'optimizely_table'

require 'typhoeus'
require 'oj'
require 'date'

module DataDuck
  module Optimizely
    class Experiments < DataDuck::Optimizely::OptimizelyTable

      transforms :percentage_included_to_float
      transforms :parse_datetimes

      def extract!(destination, options = {})
        self.data = []

        projects_response = Typhoeus.get("https://www.optimizelyapis.com/experiment/v1/projects", headers: {'Token' => self.optimizely_api_token})
        if projects_response.response_code != 200
          raise Exception.new("Optimizely API for projects returned error #{ response.response_code} #{ response.body }")
        end
        projects = Oj.load(projects_response.body)

        projects.each do |project|
          self.extract_for_project!(project["id"])
        end
      end

      def extract_for_project!(project_id)
        now = DateTime.now

        response = Typhoeus.get("https://www.optimizelyapis.com/experiment/v1/projects/#{ project_id }/experiments", headers: {'Token' => self.optimizely_api_token})

        if response.response_code != 200
          raise Exception.new("Optimizely API for experiments returned error #{ response.response_code} #{ response.body }")
        end

        experiments = Oj.load(response.body)
        experiments.each do |experiment|
          experiment[:dataduck_extracted_at] = now
          experiment[:project_id] = project_id
        end

        self.data.concat(experiments)
      end

      def parse_datetimes(row)
        row["created"] = DateTime.parse(row["created"])
        row["last_modified"] = DateTime.parse(row["last_modified"])

        row
      end

      def rename_description_to_name
        row[:name] = row['description']

        row
      end

      def percentage_included_to_float(row)
        row['percentage_included'] = row['percentage_included'].to_i / 100.0

        row
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
          :url_conditions => :bigtext,
          :last_modified => :datetime,
          :is_multivariate => :boolean,
          :activation_mode => :string,
          :created => :datetime,
          :percentage_included => :float,
          :experiment_type => :string,
          :edit_url => :string,
          :dataduck_extracted_at => :datetime,
      })
    end
  end
end
