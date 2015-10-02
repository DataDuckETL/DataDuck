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

      table_instances = []
      @tables.each do |table_class|
        table_instance = table_class.new
        table_instances << table_instance
        table_instance.extract!
        table_instance.transform!
      end

      self.class.destinations.each do |destination|
        destination.before_all_loads!(table_instances)
        destination.load_tables!(table_instances)
        destination.after_all_loads!(table_instances)
      end
    end
  end
end
