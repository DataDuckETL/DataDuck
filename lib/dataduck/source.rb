module DataDuck
  class Source
    def self.source(name)
      name = name.to_s

      if DataDuck.sources[name]
        return DataDuck.sources[name]
      end

      configuration = DataDuck.config['sources'][name.to_s]
      source_type = configuration['type']

      if source_type == "postgresql"
        DataDuck.sources[name] = DataDuck::PostgresqlSource.new(configuration)
        return DataDuck.sources[name]
      else
        raise ArgumentError.new("Unknown type '#{ source_type }' for source #{ name }.")
      end
    end
  end

  def query
    raise Exception.new("Must implement query in subclass.")
  end
end
