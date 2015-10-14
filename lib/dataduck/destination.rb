module DataDuck
  class Destination
    def self.destination_config(name)
      if DataDuck.config['destinations'].nil? || DataDuck.config['destinations'][name.to_s].nil?
        raise Exception.new("Could not find destination #{ name } in destinations configs.")
      end

      DataDuck.config['destinations'][name.to_s]
    end

    def load_table!(table)
      raise Exception.new("Must implement load_table! in subclass")
    end

    def self.destination(destination_name)
      destination_name = destination_name.to_s

      if DataDuck.destinations[destination_name]
        return DataDuck.destinations[destination_name]
      end

      destination_configuration = DataDuck::Destination.destination_config(destination_name)
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
