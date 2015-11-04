module DataDuck
  module Optimizely
    class OptimizelyIntegration < DataDuck::Optimizely::OptimizelyTable
      def etl!(destinations, options = {})
        projects = fetch_data("projects")
        # TODO alternate way to load Optimizely data
      end

      def fetch_data(api_endpoint)
        now = DateTime.now

        response = Typhoeus.get("https://www.optimizelyapis.com/experiment/v1/#{ api_endpoint }", headers: {'Token' => self.optimizely_api_token})
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
