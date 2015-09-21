module DataDuck
  class Table
    class << self
      attr_accessor :column_data
      attr_accessor :sources
    end

    attr_accessor :data

    def self.source(source_name)
      self.sources ||= []
      self.sources << DataDuck::Source.source(source_name)
    end

    def self.columns(columns_data)
      self.column_data ||= {}
      self.column_data.merge!(columns_data)
    end

    def column_data
      self.class.column_data
    end

    def input_column_names
      self.class.column_data.keys.sort
    end

    def output_column_names
      self.class.column_data.keys.sort
    end

    def extract!
      self.data = []
      self.class.sources.each do |source|
        results = source.query(self.query)
        self.data = results
      end
      self.data
    end

    def transform!
      # TODO run through transformations
    end

    def name
      self.class.name.downcase
    end

    def query
      if self.input_column_names
        "SELECT \"#{ self.input_column_names.join('","') }\" FROM #{ self.name }"
      else
        nil
      end
    end
  end
end
