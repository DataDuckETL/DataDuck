require 'date'
require 'typhoeus'
require 'uri'

module DataDuck
  module SEMRush
    class OrganicResults < DataDuck::IntegrationTable
      def display_limit
        20
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
        self.data = []

        self.phrases.each do |phrase|
          self.extract_results_for_keyword_and_date!(phrase)
        end
      end

      def extract_results_for_keyword_and_date!(phrase)
        date = Date.today
        phrase.strip!
        escaped_phrase = URI.escape(phrase)
        semrush_api_url = "http://api.semrush.com/?type=phrase_organic&key=#{ self.key }&display_limit=#{ self.display_limit }&export_columns=Dn,Ur&phrase=#{ escaped_phrase }&database=#{ self.search_database }"

        response = Typhoeus.get(semrush_api_url)
        if response.response_code != 200
          raise Exception.new("SEMrush API returned error #{ response.response_code} #{ response.body }")
        end

        rank = -1
        response.body.each_line do |line|
          rank += 1
          if rank == 0
            # This is the header line
            next
          end

          domain, url = line.split(';')
          domain.strip!
          url.strip!

          self.data << {
              date: date,
              phrase: phrase,
              rank: rank,
              domain: domain,
              url: url
          }
        end
      end

      def identify_by_columns
        ["date", "phrase"]
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
