require 'typhoeus'

module DataDuck
  module SEMRush
    class OrganicResults < DataDuck::IntegrationTable
      def display_limit
        25
      end

      def key
        ENV['semrush_api_key']
      end

      def phrases
        raise Exception("Must implement phrases method to be an array of the phrases you want.")
      end

      def prefix
        "semrush_"
      end

      def search_database
        'us'
      end

      def extract!(destination, options = {})
        dates = options[:dates]
        if dates.nil? || dates.length == 0
          raise Exception("Must pass at least one date.")
        end

        self.data = []

        self.phrases.each do |phrase|
          self.dates.each do |date|
            self.extract_results_for_keyword_and_date!(phrase, date)
          end
        end
      end

      def extract_results_for_keyword_and_date!(phrase, date)
        response = Typhoeus.get("http://api.semrush.com/?type=phrase_organic&key=#{ self.key }&display_limit=#{ self.display_limit }&export_columns=Dn,Ur&phrase=#{ phrase }&database=#{ self.search_database }")
        # TODO
      end

      def indexes
        ["date", "phrase", "domain"]
      end

      output({
          :date => :date,
          :phrase => :string,
          :rank => :integer,
          :domain => :string,
          :url => :string,
      })
    end
  end
end
