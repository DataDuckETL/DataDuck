require_relative 'database'

module DataDuck
  class Source < DataDuck::Database
    def self.load_config!
      all_sources = DataDuck.config['sources']
      return if all_sources.nil?

      all_sources.each_key do |source_name|
        configuration = all_sources[source_name]
        source_type = configuration['type']

        if source_type == "postgresql"
          DataDuck.sources[source_name] = DataDuck::PostgresqlSource.new(source_name, configuration)
        elsif source_type == "mysql"
          DataDuck.sources[source_name] = DataDuck::MysqlSource.new(source_name, configuration)
        else
          raise ArgumentError.new("Unknown type '#{ source_type }' for source #{ source_name }.")
        end
      end
    end

    def self.source_config(name)
      if DataDuck.config['sources'].nil? || DataDuck.config['sources'][name.to_s].nil?
        raise Exception.new("Could not find source #{ name } in source configs.")
      end

      DataDuck.config['sources'][name.to_s]
    end

    def self.source(name, allow_nil = false)
      name = name.to_s

      if DataDuck.sources[name]
        return DataDuck.sources[name]
      elsif allow_nil
        return nil
      else
        raise Exception.new("Could not find source #{ name } in source configs.")
      end
    end

    def self.only_source
      if DataDuck.sources.keys.length != 1
        raise ArgumentError.new("Must be exactly 1 source.")
      end

      source_name = DataDuck.sources.keys[0]
      return DataDuck::Source.source(source_name)
    end

    def escape_char
      '' # implement in subclass, e.g. " in postgresql and ` in mysql
    end

    def schema(table_name)
      self.connection.schema(table_name)
    end

    def self.skip_these_table_names
      [:delayed_jobs, :schema_migrations]
    end
  end
end
