module DataDuck
  module Optimizely
    class OptimizelyTable < DataDuck::IntegrationTable
      def optimizely_api_token
        ENV['optimizely_api_token']
      end

      def should_fully_reload?
        true
      end
    end
  end
end
