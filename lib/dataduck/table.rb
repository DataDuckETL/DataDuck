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
      self.class.actions
    end

    def output_schema
      self.class.output_schema
    end

    def output_column_names
      self.class.output_schema.keys.sort
    end

    def extract!
      puts "Extracting table #{ self.name }..."

      self.errors ||= []
      self.data = []
      self.class.sources.each do |source_spec|
        source = source_spec[:source]
        my_query = self.extract_query(source_spec)
        results = source.query(my_query)
        self.data = results
      end
      self.data
    end

    def extract_query(source_spec)
      if source_spec.has_key?(:query)
        query
      else
        "SELECT \"#{ source_spec[:columns].sort.join('","') }\" FROM #{ source_spec[:table_name] }"
      end
    end

    def transform!
      puts "Transforming table #{ self.name }..."

      self.errors ||= []
      self.class.actions ||= []
      self.class.actions.each do |action|
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
      DataDuck::Util.camelcase_to_underscore(self.class.name)
    end
  end
end
