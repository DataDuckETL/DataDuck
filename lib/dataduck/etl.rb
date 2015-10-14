require_relative 'redshift_destination.rb'

module DataDuck
  class ETL
    class << self
      attr_accessor :destinations
    end

    def self.destination(destination_name)
      self.destinations ||= []
      self.destinations << DataDuck::Destination.destination(destination_name)
    end

    def initialize(options = {})
      @tables = options[:tables] || []

      @autoload_tables = options[:autoload_tables].nil? ? true : options[:autoload_tables]
      if @autoload_tables
        Dir[DataDuck.project_root + "/src/tables/*.rb"].each do |file|
          table_name_underscores = file.split("/").last.gsub(".rb", "")
          table_name_camelized = DataDuck::Util.underscore_to_camelcase(table_name_underscores)
          require file
          table = Object.const_get(table_name_camelized)
          if table <= DataDuck::Table
            @tables << table
          end
        end
      end
    end

    def process!
      puts "Processing ETL..."

      @tables.each do |table_class|
        table_to_etl = table_class.new
        table_to_etl.extract!
        table_to_etl.transform!
        self.class.destinations.each do |destination|
          destination.load_table!(table_to_etl)
        end
      end
    end
  end
end
