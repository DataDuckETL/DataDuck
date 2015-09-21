module DataDuck
  class Destination
    def load_tables!(tables)
      raise Exception.new("Must implement load_tables! in subclass")
    end

    def before_all_loads!

    end

    def after_all_loads!
      # e.g. cleanup
    end

    def self.destination(destination_name)
      destination_name = destination_name.to_s

      if DataDuck.destinations[destination_name]
        return DataDuck.destinations[destination_name]
      end

      destination_configuration = DataDuck.config['destinations'][destination_name.to_s]
      destination_type = destination_configuration['type']
      if destination_type == "redshift"
        DataDuck.destinations[destination_name] = DataDuck::RedshiftDestination.new(destination_configuration)
        return DataDuck.destinations[destination_name]
      else
        raise ArgumentError.new("Unknown type '#{ destination_type }' for destination #{ destination_name }.")
      end
    end
  end
end
