module DataDuck

  class Source
    def self.source_config(name)
      if DataDuck.config['sources'].nil? || DataDuck.config['sources'][name.to_s].nil?
        raise Exception.new("Could not find source #{ name } in source configs.")
      end

      DataDuck.config['sources'][name.to_s]
    end

    def self.source(name)
      name = name.to_s

      if DataDuck.sources[name]
        return DataDuck.sources[name]
      end

      configuration = DataDuck::Source.source_config(name)
      source_type = configuration['type']

      if source_type == "postgresql"
        DataDuck.sources[name] = DataDuck::PostgresqlSource.new(configuration)
        return DataDuck.sources[name]
      else
        raise ArgumentError.new("Unknown type '#{ source_type }' for source #{ name }.")
      end
    end

    def connection
      raise Exception.new("Must implement connection in subclass.")
    end

    def query
      raise Exception.new("Must implement query in subclass.")
    end

    def schema(table_name)
      self.connection.schema(table_name)
    end

    def self.skip_these_table_names
      [:delayed_jobs, :schema_migrations]
    end
  end
end
