module DataDuck
  class Table
    class << self
      attr_accessor :sources
      attr_accessor :output_schema
      attr_accessor :actions
      attr_accessor :errors
    end

    attr_accessor :data

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

    def self.source(source_name, source_data = [])
      self.sources ||= {}
      source = DataDuck::Source.source(source_name)
      self.sources[source] = source_data
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
      self.class.sources.each_pair do |source, source_columns|
        import_query = "SELECT \"#{ source_columns.sort.join('","') }\" FROM #{ self.name }"
        results = source.query(import_query)
        self.data = results
      end
      self.data
    end

    def transform!
      puts "Transforming table #{ self.name }..."

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
      DataDuck::Util.camelcase_to_underscore(self.class.name)
    end
  end
end
