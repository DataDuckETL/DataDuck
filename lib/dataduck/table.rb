require_relative 'logs'

module DataDuck
  class Table
    class << self
      attr_accessor :sources
      attr_accessor :output_schema
      attr_accessor :actions
    end

    attr_accessor :data
    attr_accessor :errors

    def self.transforms(transformation_name)
      self.actions ||= []
      self.actions << [:transform, transformation_name]
    end
    singleton_class.send(:alias_method, :transform, :transforms)

    def self.validates(validation_name)
      self.actions ||= []
      self.actions << [:validate, validation_name]
    end
    singleton_class.send(:alias_method, :validate, :validates)

    def self.source(source_name, source_table_or_query = nil, source_columns = nil)
      self.sources ||= []

      source_spec = {}
      if source_table_or_query.respond_to?(:to_s) && source_table_or_query.to_s.downcase.include?('select ')
        source_spec = {query: source_table_or_query}
      elsif source_columns.nil? && source_table_or_query.respond_to?(:each)
        source_spec = {columns: source_table_or_query, table_name: DataDuck::Util.camelcase_to_underscore(self.name)}
      else
        source_spec = {columns: source_columns, table_name: source_table_or_query.to_s}
      end

      source_spec[:source] = DataDuck::Source.source(source_name)
      self.sources << source_spec
    end

    def self.output(schema)
      self.output_schema ||= {}
      self.output_schema.merge!(schema)
    end

    def actions
      my_actions = []
      for_class = self.class
      while for_class < Table
        my_actions.concat(for_class.actions || [])
        for_class = for_class.superclass
      end

      my_actions
    end

    def check_table_valid!
      if !self.batch_size.nil?
        raise Exception.new("Table #{ self.name }'s batch_size must be > 0") unless self.batch_size > 0
        raise Exception.new("Table #{ self.name } has batch_size defined but no extract_by_column") if self.extract_by_column.nil?
      end
    end

    def distribution_key
      if self.output_column_names.include?("id")
        "id"
      else
        nil
      end
    end

    def etl!(destinations, options = {})
      if destinations.length != 1
        raise ArgumentError.new("DataDuck can only etl to one destination at a time for now.")
      end

      if options[:dates].nil?
        options[:dates] = [Date.today]
      end

      self.check_table_valid!

      destination = destinations.first

      if self.should_fully_reload?
        destination.drop_staging_table!(self)
      end

      batch_number = 0
      while batch_number < 1_000
        batch_number += 1
        self.extract!(destination, options)
        self.transform!
        self.load!(destination)

        if self.batch_size.nil?
          break
        else
          if self.batch_size == self.data.length
            DataDuck::Logs.info "Finished batch #{ batch_number }, continuing with the next batch"
          else
            DataDuck::Logs.info "Finished batch #{ batch_number } (last batch)"
            break
          end
        end
      end

      self.data = []

      if self.should_fully_reload?
        destination.finish_fully_reloading_table!(self)
      end
    end

    def extract!(destination = nil, options = {})
      DataDuck::Logs.info "Extracting table #{ self.name }"

      self.errors ||= []
      self.data = []
      self.class.sources.each do |source_spec|
        source = source_spec[:source]
        my_query = self.extract_query(source_spec, destination)
        results = source.query(my_query)
        self.data.concat(results)
      end
      self.data
    end

    def extract_query(source_spec, destination = nil)
      escape_char = source_spec[:source].escape_char

      base_query = source_spec.has_key?(:query) ? source_spec[:query] :
         "SELECT #{ escape_char }#{ source_spec[:columns].sort.join(escape_char + ',' + escape_char) }#{ escape_char } FROM #{ source_spec[:table_name] }"

      extract_part = ""
      limit_part = self.limit_clause

      if self.extract_by_column
        if destination.table_names.include?(self.building_name)
          extract_by_column_without_table = self.extract_by_column.include?(".") ? self.extract_by_column.split(".").last : self.extract_by_column
          extract_by_value = destination.query("SELECT MAX(#{ extract_by_column_without_table }) AS val FROM #{ self.building_name }").first
          extract_by_value = extract_by_value.nil? ? nil : extract_by_value[:val]

          extract_part = self.extract_by_clause(extract_by_value)
        end
      end

      if base_part.include?(' WHERE ')
        extract_part.gsub!('WHERE ', ' ')
      end

      [base_query, extract_part, limit_part].join(' ').strip
    end

    def extract_by_clause(value)
      if value
        "WHERE #{ self.extract_by_column } >= '#{ value }'"
      else
        ""
      end
    end

    def limit_clause
      if self.extract_by_column && self.batch_size
        "ORDER BY #{ self.extract_by_column } LIMIT #{ self.batch_size }"
      else
        ""
      end
    end

    def load!(destination)
      destination.load_table!(self)
    end

    def include_with_all?
      true
    end

    def indexes
      which_columns = []
      which_columns << "id" if self.output_column_names.include?("id")
      which_columns << "created_at" if self.output_column_names.include?("created_at")
      which_columns
    end

    def batch_size
      nil
    end

    def extract_by_column
      return 'updated_at' if self.output_column_names.include?("updated_at")

      nil
    end

    def should_fully_reload?
      false # Set to true if you want to fully reload a table with each ETL
    end

    def building_name
      self.should_fully_reload? ? self.staging_name : self.name
    end

    def staging_name
      "zz_dataduck_#{ self.name }"
    end

    def output_schema
      self.class.output_schema || self.class.superclass.output_schema || {}
    end

    def output_column_names
      self.output_schema.keys.sort.map(&:to_s)
    end

    def recreate!(destination)
      destination.recreate_table!(self)
    end

    def show
      puts "Table #{ self.name }"
      self.class.sources.each do |source_spec|
        puts "\nSources from #{ source_spec[:table_name] || source_spec[:query] } on #{ source_spec[:source].name }"
        source_spec[:columns].each do |col_name|
          puts "  #{ col_name }"
        end
      end

      puts "\nOutputs "
      num_separators = self.output_schema.keys.map { |key| key.length }.max
      self.output_schema.each_pair do |name, datatype|
        puts "  #{ name }#{ ' ' * (num_separators + 2 - name.length) }#{ datatype }"
      end
    end

    def transform!
      DataDuck::Logs.info "Transforming table #{ self.name }"

      self.errors ||= []
      self.actions.each do |action|
        action_type = action[0]
        action_method_name = action[1]
        if action_type == :transform
          self.data.map! { |row| self.public_send(action_method_name, row) }
        elsif action_type == :validate
          self.data.each do |row|
            error = self.public_send(action_method_name, row)
            self.errors << error if !error.blank?
          end
        end
      end
    end

    def name
      fixed_name = DataDuck::Util.camelcase_to_underscore(self.class.name)
      if fixed_name.start_with?("data_duck/")
        fixed_name = fixed_name.split("/").last
      end

      self.prefix + fixed_name
    end

    def prefix
      ""
    end
  end
end
