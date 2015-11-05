require 'typhoeus'
require 'oj'
require 'date'

require_relative './experiments'
require_relative './projects'
require_relative './variations'

module DataDuck
  module Optimizely
    class OptimizelyIntegration < DataDuck::Optimizely::OptimizelyTable
      def etl!(destinations, options = {})
        now = DateTime.now

        projects = fetch_data("projects")

        experiments = []
        projects.each do |project|
          project["created"] = DateTime.parse(project["created"])
          project["last_modified"] = DateTime.parse(project["last_modified"])

          project_experiments = fetch_data("projects/#{ project['id'] }/experiments")
          project_experiments.each do |proj_exp|
            proj_exp['project_id'] = project['id']
            proj_exp["created"] = DateTime.parse(proj_exp["created"])
            proj_exp["last_modified"] = DateTime.parse(proj_exp["last_modified"])
          end
          experiments.concat(project_experiments)
        end

        variations = []
        # Experiments started after January 21, 2015 have statistics computed by Optimizely Stats Engine.
        # Older experiments should use the old results endpoint.
        date_for_stats_engine = DateTime.parse('Jan 22, 2015')
        date_too_old_for_api = DateTime.parse('Jan 1, 2013')
        broken_experiments = []
        experiments.each do |experiment|
          if experiment["created"] < date_too_old_for_api
            next # seems like there's a problem with the API and old experiments
          end

          endpoint = experiment["created"] >= date_for_stats_engine ? "experiments/#{ experiment["id"] }/stats" : "experiments/#{ experiment["id"] }/results"
          experiment_variations = []
          begin
            experiment_variations = fetch_data(endpoint)
          rescue Exception => err
            broken_experiments << experiment
          end
          experiment_variations.each do |exp_var|
            exp_var["begin_time"] = DateTime.parse(exp_var["begin_time"]) if exp_var["begin_time"]
            exp_var["end_time"] = DateTime.parse(exp_var["end_time"]) if exp_var["end_time"]
            exp_var["experiment_id"] = experiment["id"]
          end
          variations.concat(experiment_variations)
        end

        projects_etl_table = DataDuck::Optimizely::Projects.new(projects)
        projects_etl_table.etl!(destinations, options)

        experiments_etl_table = DataDuck::Optimizely::Experiments.new(experiments)
        experiments_etl_table.etl!(destinations, options)

        variations_etl_table = DataDuck::Optimizely::Variations.new(variations)
        variations_etl_table.etl!(destinations, options)
      end

      def fetch_data(api_endpoint)
        now = DateTime.now

        response = Typhoeus.get("https://www.optimizelyapis.com/experiment/v1/#{ api_endpoint }", headers: {'Token' => optimizely_api_token})
        if response.response_code != 200
          raise Exception.new("Optimizely API for #{ api_endpoint } returned error #{ response.response_code} #{ response.body }")
        end

        rows = Oj.load(response.body)
        rows.each do |row|
          row[:dataduck_extracted_at] = now
        end

        rows
      end
    end
  end
end
