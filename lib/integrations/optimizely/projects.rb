require_relative 'optimizely_table'

require 'typhoeus'
require 'oj'
require 'date'

module DataDuck
  module Optimizely
    class Projects < DataDuck::Optimizely::OptimizelyTable
      transforms :parse_datetimes

      def extract!(destination, options = {})
        self.data = []

        now = DateTime.now
        response = Typhoeus.get("https://www.optimizelyapis.com/experiment/v1/projects", headers: {'Token' => self.optimizely_api_token})

        self.data = Oj.load(response.body)
        self.data.each do |project|
          project[:dataduck_extracted_at] = now
        end
      end

      def indexes
        ["id", "account_id", "project_name"]
      end

      def parse_datetimes
        project["created"] = DateTime.parse(project["created"])
        project["last_modified"] = DateTime.parse(project["last_modified"])
      end

      output({
          :id => :bigint,
          :account_id => :bigint,
          :code_revision => :integer,
          :project_name => :string,
          :project_status => :string,
          :created => :datetime,
          :last_modified => :datetime,
          :library => :string,
          :include_jquery => :bool,
          :js_file_size => :integer,
          :project_javascript => :bigtext,
          :enable_force_variation => :boolean,
          :exclude_disabled_experiments => :boolean,
          :exclude_names => :boolean,
          :ip_anonymization => :boolean,
          :ip_filter => :string,
          :socket_token => :string,
          :dcp_service_id => :integer,
          :dataduck_extracted_at => :datetime,
      })
    end
  end
end
